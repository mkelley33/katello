#
# Copyright 2012 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

require 'test/models/repository_base'
require 'test/models/authorization/repository_authorization_test'


class RepositoryCreateTest < MiniTest::Rails::ActiveSupport::TestCase
  include RepositoryTestBase

  def setup
    super
    User.current = @admin
    @repo = Repository.new(:name => 'repository_test_name', :pulp_id => 'This is not a feal pulp ID', 
                          :environment_product_id => environment_products(:library_fedora).id, :content_id => 'FakeContentID',
                          :label => "repository_test_name_label")
  end

  def teardown
    @repo.destroy
  end

  def test_create
    assert @repo.save
    assert !Repository.where(:id=>@repo.id).empty?
  end

end


class RepositoryInstanceTest < MiniTest::Rails::ActiveSupport::TestCase
  include RepositoryTestBase

  def setup
    super
    User.current = @admin
  end

  def test_product
    assert @fedora == @fedora_17.product
  end

  def test_environment
    assert @library == @fedora_17.environment
  end

  def test_organization
    assert @acme_corporation == @fedora_17.organization
  end

  def test_redhat?
    assert !@fedora_17.redhat?
  end

  def test_custom?
    assert @fedora_17.custom?
  end

  def test_in_environment
    assert Repository.in_environment(@library).include?(@fedora_17)
  end

  def test_in_product
    assert Repository.in_product(@fedora).include?(@fedora_17)
  end

  def test_other_repos_with_same_content
    assert @fedora_17.other_repos_with_same_content.include?(@fedora_17_dev)
  end

  def test_other_repos_with_same_product_and_content
    assert @fedora_17.other_repos_with_same_product_and_content.include?(@fedora_17_dev)
  end

  def test_environment_id
    assert @fedora_17.environment_id == @library.id
  end

  def test_yum_gpg_key_url
    assert !@fedora_17.yum_gpg_key_url.nil?
  end

  def test_has_filters?
    assert @fedora_17.has_filters?
  end

  def test_does_not_have_filters?
    assert !@fedora_17_dev.has_filters?
  end

  def test_clones
    assert @fedora_17.clones == [@fedora_17_dev]
  end

  def test_is_cloned_in?
    assert @fedora_17.is_cloned_in?(@dev)
  end

  def test_promoted?
    assert @fedora_17.promoted?
  end

  def test_get_clone
    assert @fedora_17.get_clone(@dev) == @fedora_17_dev
  end

  def test_gpg_key_name
    @fedora_17.gpg_key_name = @unassigned_gpg_key.name
    assert @fedora_17.gpg_key == @unassigned_gpg_key
  end

  def test_as_json
    assert @fedora_17.as_json.has_key? "gpg_key_name"
  end

  def test_environmental_instances
    assert @fedora_17.environmental_instances.include? @fedora_17
    assert @fedora_17.environmental_instances.include? @fedora_17_dev
  end

  def test_applicable_filters
    assert @fedora_17_dev.applicable_filters.include?(@fedora_filter)
  end

end