# Copyright (C) Doug Youch

=begin rdoc
ActiveWebService's are used to communicate to RESTful Web Services.

Example:

class ChargifyWebService < ActiveWebService
  # always send Chargify data in json
  headers 'Content-Type' => 'application/json'

  rest :customer, :customers, '/customers.json'
  route :find_customer, '/customers/lookup.json', :resource => 'customer'
  # find_customer_by_reference
  route :customer_subscriptions, '/customers/:customer_id/subscriptions.json', :resource => :subscription

  route :product_families, '/product_families.xml', :resource => :product_families

  route :products, '/products.json', :resource => :product
  route :product, '/products/:product_id.json', :resource => :product
  route :find_product_by_handle, '/products/handle/:handle.json', :resource => :product

  rest :subscription, :subscriptions, '/subscriptions.json'
  route :cancel_subscription, '/subscriptions/:subscription_id.json', :resource => :subscription, :method => :delete, :expected_status => [200, 204]
  route :reactivate_subscription, '/subscriptions/:subscription_id/reactivate.xml', :resource => :subscription, :method => :put, :expected_status => 200
  route :subscription_transactions, '/subscriptions/:subscription_id/transactions.json', :resource => :transaction
  # Chargify offers the ability to upgrade or downgrade a Customer's subscription in the middle of a billing period.
  route :create_subscription_migration, '/subscriptions/:subscription_id/migrations.json', :resource => :subscription, :expected_status => 200
  route :reactivate_subscription, '/subscriptions/:subscription_id/reactivate.xml', :resource => :subscription, :method => :put, :expected_status => 200
  route :create_subscription_credit, '/subscriptions/:subscription_id/credits.json', :resource => :credit
  route :reset_subscription_balance, '/subscriptions/:subscription_id/reset_balance.xml', :resource => :subscription, :method => :put, :expected_status => 200

  route :transactions, '/transactions.json', :resource => :transaction

  route :create_charge, '/subscriptions/:subscription_id/charges.json', :resource => :charge

  route :components, '/product_families/:product_family_id/components.json', :resource => :component
  route :component_usages, '/subscriptions/:subscription_id/components/:component_id/usages.json', :resource => :usage
  route :create_component_usage, '/subscriptions/:subscription_id/components/:component_id/usages.json', :resource => :usage, :expected_status => 200

  route :coupon, '/product_families/:product_family_id/coupons/:coupon_id.json', :resource => :coupon
  route :find_coupon, '/product_families/:product_family_id/coupons/find.json', :resource => :coupon
  # find_coupon_by_code

  route :subscription_components, '/subscriptions/:subscription_id/components.json', :resource => :component
  route :edit_subscription_component, '/subscriptions/:subscription_id/components/:component_id.json', :resource => :component

  def initialize(api_key, subdomain)
    self.base_uri = "https://#{subdomain}.chargify.com"
    self.basic_auth = {:username => api_key, :password => 'x'}
  end

  # Need to convert the body from a hash to json by default HTTParty::Request calls to_params if body is a Hash
  def build_options!(options)
    super
    options[:body] = options[:body].to_json if options[:body]
  end
end

@service = ChargifyWebService 'my api key', 'my-subdomain'

# Would return all the products
@service.products

# List customers
@service.customers

# Get a customer
@service.customer 90

# Create a new customer
@service.create_customer {:first_name => 'Doug', :last_name => 'Youch', :email => 'dougyouch@test.dev'}

# Edit an existing customer
@service.edit_customer 90, {:first_name => 'Douglas'}

# Save a customer
@service.save :customer, {:reference => '581', :first_name => 'Doug', :last_name => 'Youch', :email => 'dougyouch@test.dev'} # create
@service.save :customer, {:first_name => 'Douglas', :id => 90} # edit

# Find a customer by reference
@service.find_customer_by_reference '581'
=end

class ActiveWebService
  class Error < Exception; end
  class InvalidResponse < Error; end
  class MethodMissing < Error; end

  include HTTParty

  attr_accessor :base_uri, :basic_auth
  attr_reader :response, :request_url, :request_options, :request_method

  # Defines a web service route
  #
  # name of the method to create
  # name has special meaning.
  # If starts with create or add the method will be set to post.
  # If starts with edit or update the method will be set to put.
  # If starts with delete the method will be set to delete.
  # Else by default the method is get.
  #
  # path is the path to the web service
  #
  # === Options
  #
  # [:method]
  #   The request method get/post/put/delete. Default is get.
  # [:expected_status]
  #   Expected status code of the response, will raise InvalidResponse. Can be an array of codes.
  # [:return]
  #   The method to call or the class to create before method returns.
  # [:resource]
  #   The name of the element to return from the response.
  def self.route(name, path, options={})
    args = path.scan /:[a-z_]+/
    function_args = args.collect{ |arg| arg[1..-1] }

    method = options[:method]
    expected_status = options[:expected_status]
    if method.nil?
      if name.to_s =~ /^(create|add|edit|update|delete)_/
        case $1
        when 'create'
          method = 'post'
          expected_status ||= 201
        when 'add'
          method = 'post'
          expected_status ||= 201
        when 'edit'
          method = 'put'
          expected_status ||= 200
        when 'update'
          method = 'put'
          expected_status ||= 200
        when 'delete'
          method = 'delete'
          expected_status ||= [200, 204]
        end
      else
        method = 'get'
        expected_status ||= 200
      end
    end

    method = method.to_s
    function_args << 'body' if method == 'post' || method == 'put'
    function_args << 'options={}'

    method_src = <<-METHOD
    def #{name}(#{function_args.join(',')})
      path = "#{path}"
    METHOD

    args.each_with_index do |arg, idx|
      method_src << "path.sub! '#{arg}', #{function_args[idx]}.to_s\n"
    end

    if method == 'post' || method == 'put'
      if options[:resource]
        method_src << "options[:body] = {'#{options[:resource].to_s}' => body}\n"
      else
        method_src << "options[:body] = body\n"
      end
    end

    method_src << "request :#{method}, path, options\n"

    if expected_status
      if expected_status.is_a?(Array)
        method_src << 'raise InvalidResponse.new "Invalid response code #{response.code}" if ! [' + expected_status.join(',') + "].include?(response.code)\n"
      else
        method_src << 'raise InvalidResponse.new "Invalid response code #{response.code}" if response.code != ' + expected_status.to_s + "\n"
      end
    end

    return_resource = options[:resource] ? "['#{options[:resource].to_s}']" : ''
    if options[:return]
      if options[:return].is_a?(Class)
        return_method = "#{options[:return].to_s}.new"
      else
        return_method = "#{options[:return]}"
      end

      method_src << "return #{return_method}(response) unless response.is_a?(Array) || response.is_a?(Hash)\n"
      method_src << "return #{return_method}(response#{return_resource}) unless response.is_a?(Array)\n"
      method_src << "response.to_a.collect { |obj| #{return_method}(obj#{return_resource}) }\n"
    else
      method_src << "return response unless response.is_a?(Array) || response.is_a?(Hash)\n"
      method_src << "return response#{return_resource} unless response.is_a?(Array)\n"
      method_src << "response.to_a.collect { |obj| obj#{return_resource} }\n"
    end
    method_src << "end\n"

    self.class_eval method_src, __FILE__, __LINE__
  end

  # Creates routes for a RESTful API
  #
  # resource_name is the name of the items returned by the API
  #
  # collection_name is the plural name of the items
  #
  # base_path is the path to the collection
  def self.rest(resource_name, collection_name, base_path, options={})
    options[:resource] ||= resource_name
    self.route collection_name, base_path, options
    self.route resource_name, base_path.sub(/(\.[a-zA-Z0-9]+)$/, "/:#{resource_name}_id\\1"), options
    self.route "edit_#{resource_name}", base_path.sub(/(\.[a-zA-Z0-9]+)$/, "/:#{resource_name}_id\\1"), options
    self.route "create_#{resource_name}", base_path, options
    self.route "delete_#{resource_name}", base_path.sub(/(\.[a-zA-Z0-9]+)$/, "/:#{resource_name}_id\\1"), options
  end

  # Creates the url
  def build_url(path)
    "#{self.base_uri}#{path}"
  end

  # Adds the basic_auth options
  # This method should be overwritten as needed.
  def build_options!(options)
    options[:basic_auth] = self.basic_auth if self.basic_auth
  end

  # Makes the request using HTTParty. Save the method, path and options used.
  def request(method, path, options)
    build_options! options
    url = build_url path
    @request_method = method
    @request_url = url
    @request_options = options

    @response = self.class.send(method, url, options)
  end

  # Will either call edit_<name> or add_<name> based on wether or not the body[:id] exists.
  def save(name, body, options={})
    id = body[:id] || body['id']
    if id
      if self.class.method_defined?("edit_#{name}")
        self.send("edit_#{name}", id, body, options)
      elsif self.class.method_defined?("update_#{name}")
        self.send("update_#{name}", id, body, options)
      else
        raise MethodMissing.new "No edit/update method found for #{name}"
      end
    else
      if self.class.method_defined?("add_#{name}")
        self.send("add_#{name}", body, options)
      elsif self.class.method_defined?("create_#{name}")
        self.send("create_#{name}", body, options)
      else
        raise MethodMissing.new "No add/create method found for #{name}"
      end
    end
  end

  def method_missing(method, *args) #:nodoc:
    if method.to_s =~ /^find_(.*?)_by_(.*)$/
      find_method = "find_#{$1}"
      find_args = $2.split '_and_'
      raise MethodMissing.new "Missing method #{find_method}" unless self.class.method_defined?(find_method)
      start = (self.method(find_method).arity + 1).abs
      options = args[-1].is_a?(Hash) ? args[-1] : {}
      options[:query] ||= {}
      find_args.each_with_index do |find_arg, idx|
        options[:query][find_arg] = args[start+idx]
      end

      if start > 0
        send_args = args[0..(start-1)]
        send_args << options
        return self.send(find_method, *send_args)
      else
        return self.send(find_method, options)
      end
    else
      super
    end
  end
end
