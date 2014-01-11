# encoding: utf-8
#
# Copyright 2013 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

require "katello_test_helper"

module Katello
class Api::V2::ProductsControllerTest < ActionController::TestCase

  def self.before_suite
    models = ["Product"]
    disable_glue_layers(%w(Candlepin Pulp ElasticSearch), models)
    super
  end

  def models
    @organization = get_organization(:organization1)
    @provider = katello_providers(:fedora_hosted)
    @product = katello_products(:empty_product)
  end

  def permissions
    @read_permission = UserPermission.new(:read, :providers)
    @create_permission = UserPermission.new(:create, :providers)
    @update_permission = UserPermission.new(:update, :providers)
    @no_permission = NO_PERMISSION
  end

  def setup
    setup_controller_defaults_api
    @fake_search_service = @controller.load_search_service(Support::SearchService::FakeSearchService.new)
    models
    permissions
  end

  def test_index
    get :index, :organization_id => @organization.label

    assert_response :success
    assert_template 'api/v2/products/index'
  end

  def test_search_service_queries_for_enabled_products
    @fake_search_service.expects(:retrieve).with { |*args| args[2][:filters][1][:terms][:enabled] == 'true' }

    get :index, :organization_id => @organization.label, :enabled => 'true'
  end

  def test_search_service_does_not_query_for_enabled_products
    @fake_search_service.expects(:retrieve).with { |*args| args[2][:filters][1].nil?}

    get :index, :organization_id => @organization.label
  end

  def test_index_fail_without_organization_id
    get :index

    assert_response :internal_server_error
  end

  def test_index_protected
    allowed_perms = [@read_permission]
    denied_perms = [@no_permission]

    assert_protected_action(:index, allowed_perms, denied_perms) do
      get :index, :organization_id => @organization.label
    end
  end

  def test_create
    product_params = {
      :name => 'fedora product',
      :provider_id => @provider.id,
      :description => 'this is my cool new product.'
    }
    post :create, {:product => product_params, :organization_id => @organization.label}

    assert_response :success
    assert_template %w(katello/api/v2/common/create katello/api/v2/layouts/resource)
  end

  def test_create_fail_without_product
    post :create, {:organization_id => @organization.label}
    # provider_id is required to check if user can update providers.
    # if not, then cryptic 500 given:
    #["{\"displayMessage\":\"undefined method `[]' for nil:NilClass\",\"errors\":[\"undefined method `[]' for nil:NilClass\"]}"],
    assert_response :internal_server_error
  end

  def test_create_fail_with_empty_product
    post :create, {:product => {}, :organization_id => @organization.label}
    # provider_id is required to check if user can update providers.
    # if not, then cryptic 500 given:
    #["{\"displayMessage\":\"undefined method `[]' for nil:NilClass\",\"errors\":[\"undefined method `[]' for nil:NilClass\"]}"],
    assert_response :internal_server_error
  end

  def test_create_fail_with_only_provider_id
    # without provider_id it's 500 and this test is for 422 errors
    post :create, {:product => {:provider_id => @provider.id}}

    errors = JSON.parse(response.body)["errors"]

    assert_response :unprocessable_entity

    assert_nil errors[:provider_id]
    assert_nil errors[:description]

    assert_includes errors["label"], "can't be blank"
    assert_includes errors["name"], "cannot be blank"
  end

  def test_create_protected
    allowed_perms = [@create_permission]
    denied_perms = [@read_permission, @no_permission]

    assert_protected_action(:create, allowed_perms, denied_perms) do
      post :create, :product => {:provider_id => @provider.id}, :organization_id => @organization.label
    end
  end

  def test_show
    get :show, :id => @product.cp_id

    assert_response :success
    assert_template 'api/v2/products/show'
  end

  def test_show_protected
    allowed_perms = [@read_permission, @update_permission, @create_permission]
    denied_perms = [@no_permission]

    assert_protected_action(:show, allowed_perms, denied_perms) do
      get :show, :id => @product.cp_id
    end
  end

  def test_update
    get :update, :id => @product.cp_id, :product => {:name => 'New Name'}

    assert_response :success
    assert_template %w(katello/api/v2/common/update katello/api/v2/layouts/resource)
    assert_equal assigns[:product].name, 'New Name'
  end

  def test_update_protected
    allowed_perms = [@update_permission]
    denied_perms = [@read_permission, @no_permission]

    assert_protected_action(:update, allowed_perms, denied_perms) do
      put :update, :id => @product.cp_id, :name => 'New Name'
    end
  end

  def test_destroy
    delete :destroy, :id => @product.cp_id

    assert_response :success
  end

  def test_destroy_protected
    allowed_perms = [@update_permission, @create_permission]
    denied_perms = [@no_permission, @read_permission]

    assert_protected_action(:destroy, allowed_perms, denied_perms) do
      delete :destroy, :id => @product.cp_id
    end
  end

end
end
