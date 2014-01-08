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

module Katello
  class Api::V2::ProductsController < Api::V2::ApiController

    before_filter :find_provider, :only => [:create]
    before_filter :find_organization, :only => [:index, :show]
    before_filter :find_product, :only => [:show, :update, :destroy]
    before_filter :authorize

    def_param_group :product do
      param :product, Hash, :action_aware => true do
        param :name, String, :required => true
        param :label, String, :required => false
        param :provider_id, :number, :required => true, :desc => "Provider the product belongs to"
        param :description, String, :desc => "Product description"
        param :gpg_key_id, :number, :desc => "Identifier of the GPG key"
      end
    end

  def rules
    index_test = lambda { Product.any_readable?(@organization) }
    create_test = lambda { @provider.nil? ? true : Product.creatable?(@provider) }
    read_test  = lambda { @product.readable? }
    edit_test  = lambda { @product.editable? }

    {
      :index => index_test,
      :create => create_test,
      :show => read_test,
      :update => edit_test,
      :destroy => edit_test
    }
  end

    api :GET, "/products", "List of organization products"
    api :GET, "/subscriptions/:subscription_id/products", "List of subscription products in an organization"
    api :GET, "/organizations/:organization_id/products", "List of products in an organization"
    param :enabled, String, :desc => "Filter enabled products"
    param :name, :identifier, :desc => "Filter products by name"
    param :organization_id, :identifier, :desc => "Filter products by organization name or label", :required => true
    param :subscription_id, :number, :desc => "Filter products by subscription identifier"
    param_group :search, Api::V2::ApiController
    def index
      filters = [filter_terms(product_ids_filter)]
      filters << filter_terms(enabled_filter) if enabled_filter.present?
      options = sort_params.merge(:filters => filters, :load_records => true)

      respond(:collection => search_products(options))
    end

    api :POST, "/products", "Create a product"
    param_group :product
    def create
      params[:product][:label] = labelize_params(params[:product]) if params[:product]
      product = Product.create!(product_params)

      respond(:resource => product)
    end

    api :GET, "/products/:id", "Show a product"
    param :id, :number, :desc => "product numeric identifier", :required => true
    def show
      respond(:resource => @product)
    end

    api :PUT, "/products/:id", "Updates a product"
    param :id, :number, :desc => "product numeric identifier"
    param_group :product
    def update
      reset_gpg_keys = (product_params[:gpg_key_id] != @product.gpg_key_id)
      @product.reset_repo_gpgs! if reset_gpg_keys

      @product.update_attributes!(product_params)

      respond(:resource => @product)
    end

    api :DELETE, "/products/:id", "Destroy a product"
    param :id, :number, :desc => "Candlepin product numeric identifier"
    def destroy
      @product.destroy

      respond
    end

    protected

    def find_provider
      @provider = Provider.find(product_params[:provider_id]) if product_params[:provider_id] || organization.provider
    end

    def find_product
      @product = Product.find_by_cp_id(params[:id], params[:organization_id]) if params[:id]
    end

    def search_products(options)
      empty_results = {:results => []}

      # Don't orchestrate a big search unless we have product ids
      filters = options[:filters]
      return empty_results unless filters.find { |filter| filter[:terms] && filter[:terms][:id].to_a.count != 0 }

      # First, search the index to get product ids and counts
      items = item_search(Product, params, options)
      return empty_results unless items[:results].any?

      # Then query AR for products so that response will have association's data as well
      items[:results] = Product.where(:id => items[:results].map(&:id))
        .select("#{Katello::Product.table_name}.*, #{Katello::Provider.table_name}.name AS provider_name")
        .joins(:provider).all

      items
    end

    def product_ids_filter
      ids = Product.all_readable(@organization).pluck(:id)
      if (subscription_id = params[:subscription_id])
        @subscription = Pool.find_by_organization_and_id!(@organization, subscription_id)
        ids &= @subscription.products.pluck("#{Product.table_name}.id")
      end
      {:id => ids}
    end

    def product_params
      params.require(:product).permit(:name, :label, :provider_id, :gpg_key_id, :description)
    end

    def enabled_filter
      if (enabled = params[:enabled])
        {:enabled => enabled}
      end
    end

    def filter_terms(terms)
      {:terms => terms}
    end
  end
end
