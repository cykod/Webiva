require File.dirname(__FILE__) + '/orbital_paymentech/PaymentechGatewayDriver.rb'
require File.dirname(__FILE__) + '/orbital_paymentech/PaymentechGatewayConstants.rb'
require 'scanf'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    # This gateway implementation provides authorization, capture, and void
    # functionality for the Orbital Paymentech gateway. Although Paymentech
    # supports b2b purchasing card functionality through their web service API,
    # this implementation does not provide an interface for this functionality.
    # See http://www.chasepaymentech.com/download for more details.
    #
    class OrbitalPaymentechGateway < Gateway
      include PaymentechGatewayConstants
      
      attr_reader :url 
      attr_reader :response
      attr_reader :options

      self.supported_cardtypes = [:visa, :master, :american_express, :discover]
      self.homepage_url = 'http://www.chasepaymentech.com'
      self.display_name = 'Orbital Paymentech'
      
      # Required options:
      # :call-seq:
      #   :login => VT Gateway User ID
      #   :password => VT Gateway Password
      #   :merchant_id -> Merchant ID assigned by Chase Paymentech
      #   :terminal_id => Merchant Terminal ID assigned by Chase Paymentech
      #   :routing_id => Transaction Routing Definition assigned by Chase 
      #                  Paymentech (000001 => Salem, 000002 => PNS)
      #
      # Supported options:
      # :call-seq:
      #   :url => SOAP web service url for endpoint (defaults to test unless 
      #           test option is set to false.)
      #   :test => Set to false if you want to use the default live endpoint URL.
      #
      def initialize(options = {})
        @errors = []
        requires!(options, :login, :password, :merchant_id, :terminal_id, :routing_id)
      #  validates(options, :merchant_id, "Merchant ID must be a 6-digit numeric value") {|mid| mid.to_s.strip =~ /^\d{6}$/}
        validates(options, :terminal_id, "Terminal ID must be a 3-digit numeric value") {|tid| tid.to_s.strip =~ /^\d{3}$/}
        validates(options, :routing_id, "Routing ID must be either '000001' (salem) or '000002' (tampa)") {|bin| bin.to_s.strip =~/00000[12]/}
        validate!

        @options = options
        @url = (options[:url] || LIVE_URL) if (options[:url] || options[:test] == false)
        @url ||= TEST_URL
        super
      end  
      
      # Performs an authorization on the credit card for the specified amount.
      # See the documentation of #add_invoice, #add_address, and
      # #add_customer_data for the list of supported options.
      # 
      # Returns a Response object with the authorization transaction identifier
      # and other response information detailed in the documentation for
      # #parse_new_order_response.
      #
      def authorize(money, creditcard, options = {})
        request_element = NewOrderRequestElement.new
        add_new_order_data(request_element, creditcard, options)
        add_commit_data(request_element, :authonly, money)
        
        response_message = port_call do |port| 
          port.newOrder(NewOrder.new(request_element))
        end
        @response = parse_new_order_response(response_message)
      end
      
      # Performs an authorization and immediate capture of the specified amount.
      # See the documentation of #add_invoice, #add_address, and
      # #add_customer_data for the list of supported options.
      #
      # Returns a Response object with the transaction identifier
      # and other response information detailed in the documentation for
      # #parse_new_order_response.
      #
      def purchase(money, creditcard, options = {})
        request_element = NewOrderRequestElement.new
        add_new_order_data(request_element, creditcard, options)
        add_commit_data(request_element, :sale, money)
        
        response_message = port_call do |port| 
          port.newOrder(NewOrder.new(request_element))          
        end
        @response = parse_new_order_response(response_message)
      end                       
    
      # NOT YET IMPLEMENTED
      # 
      # Performs a credit for the specified amount.
      # See the documentation of #add_invoice, #add_address, and
      # #add_customer_data for the list of supported options.
      #
      def credit(money, identification, options = {})
        raise NotImplementedError.new("Credit operation not yet supported by Orbital Paymentech gateway.")
        #        request_element = NewOrderRequestElement.new
        #        add_merchant_data(request_element)
        #        add_invoice(request_element, options)
        #        add_creditcard(request_element, creditcard)        
        #        add_address(request_element, creditcard, options)
        #        add_customer_data(request_element, options)
        #        add_commit_data(request_element, :credit, money)
        #        
        #        response_message = port_call{|port| port.newOrder(NewOrder.new(request_element))}
        #        @response = parse_new_order_response(response_message)
      end
    
      # Marks a previously authorized transaction for capture. The amount of
      # the capture can be any value up to the amount authorized; if less than
      # the full authorization amount the transaction will be recorded as
      # a split transaction and the result parameters will supply an additional
      # split transaction identifier. The authorization parameter should 
      # correspond to the :transaction_id parameter in the result from the
      # authorization transaction.
      # 
      # See the documentation of #add_invoice for a list of additional supported options.
      #
      def capture(money, authorization, options = {})
        validates("authorization", authorization, "Missing authorization transaction identifier!") {|auth| !(auth.nil? || auth.to_s.blank?)}
        
        request_element = MarkForCaptureElement.new
        add_merchant_data(request_element)
        add_invoice(request_element, options)
        request_element.txRefNum = authorization
        add_commit_data(request_element, :capture, money)
        
        response_message = port_call do |port| 
          port.markForCapture(MarkForCapture.new(request_element))
        end
        @response = parse_mark_capture_response(response_message)
      end
      
      # Reverses the transaction specified by the identification parameter, which
      # corresponds to the transaction_id parameter returned by the action that
      # entered the transaction to be voided.
      # 
      # Required options: all options required by #add_invoice
      # :call-seq:
      #   :transaction_ref_index => The :transaction_ref_index for the 
      #                             transaction to be voided. This is required
      #                             in addition to the identification parameter
      #                             as that identifier may have multiple 
      #                             individual transactions (say, credits and
      #                             partial voids) applied to it.
      # 
      # Supported options:
      # :call-seq:
      #   :adjustment_amount => The amount to void. If this is not supplied, a
      #                         full reversal will be performed.
      #
      def void(identification, options = {})
        validates("identification", identification, "Missing transaction identifier!") {|id| !(id.nil? || id.to_s.blank?)}
        requires!(options, :transaction_ref_index)
        
        request_element = ReversalElement.new
        add_merchant_data(request_element)
        add_invoice(request_element, options)
        request_element.txRefNum = identification
        request_element.txRefIdx = options[:transaction_ref_index]
        request_element.adjustedAmt = options[:adjusted_amount] if options[:adjusted_amount]
        
        response_message = port_call do |port| 
          port.reversal(Reversal.new(request_element))
        end
        @response = parse_reversal_response(response_message)
      end
               
      protected                       

      # This validation method supports two call signatures:
      # :call-seq:
      #   validates(options = {}, option_key, message = nil, &block)
      #   validates(parameter_name, value, message = nil, &block)
      #
      def validates(*args, &block)
        label = args[0].is_a?(Hash) ? args[1] : args[0]
        value = args[0].is_a?(Hash) ? args[0][args[1]] : args[1];
        unless block.call(value)
          @errors << "#{args[0].is_a?(Hash) ? 'Option' : 'Parameter'} #{label} with value #{value} failed validation#{args[2].nil? ? '.' : ': ' + args[2]}"
        end
      end

      def validate!
        raise ArgumentError.new(@errors.join("\n")) and @errors = [] unless @errors.empty?
      end

      # Convenience method for adding the standard set of information to
      # a NewOrderRequestElement object that is used irrespective of whether
      # the transaction is to be an authorization, capture, or credit.
      # 
      # See the documentation of #add_invoice, #add_address, and
      # #add_customer_data for the list of supported and required parameters.
      #
      def add_new_order_data(req, creditcard, options)
        req.industryType = 'EC' # eCommerce transaction; use 'MO' for Mail Order, RC for Recurring Payment, IV for IVR
        add_merchant_data(req)
        add_invoice(req, options)
        add_creditcard(req, creditcard)        
        add_address(req, creditcard, options)
        add_customer_data(req, options)        
      end
      
      # Adds the merchant identifiers to the request. These are set in the
      # options hash passed to the #initialize method.
      #
      def add_merchant_data(req)
        # validation is performed on initialize for these options.
        req.merchantID = @options[:merchant_id]
        req.terminalID = @options[:terminal_id]
        req.bin = @options[:routing_id]
      end
            
      # Adds invoice information to the request element based upon the options 
      # hash. 
      # 
      # Required options:
      # :call-seq:
      #   :order_id => Unique order identifier. For void and capture transactions,
      #                this must be the same as the order_id of the original
      #                transaction or authorization, respectively.
      #   
      # Optional:
      # :call-seq:
      #   :retry_trace => Retry trace identifier if retrying an incomplete 
      #                   transaction
      #   :description => Arbitrary string describing the transaction.
      #
      def add_invoice(req, options)
        requires!(options, :order_id)
        req.orderID = options[:order_id]
        req.retryTrace = options[:retry_trace] if options[:retry_trace]
        req.comments = options[:description] if req.respond_to?(:comments=)
      end
      
      def add_creditcard(req, creditcard)
        req.ccAccountNum = creditcard.number
        req.ccExp = expdate(creditcard)
        req.avsName = "#{creditcard.first_name} #{creditcard.last_name}"
        
        if creditcard.verification_value && ['visa','master','discover'].include?(creditcard.type)
          req.ccCardVerifyNum = creditcard.verification_value
          req.ccCardVerifyPresenceInd = 1
        end
        
        if ['switch','solo'].include?(creditcard.type)
          req.switchSoloIssueNum = creditcard.issue_number
          req.switchSoloCardStartDate = "#{creditcard.start_month}#{creditcard.start_year}"
        end
      end
      
      # Adds address information to the request element based upon the options
      # hash. The creditcard parameter is not currently used. 
      # 
      # Supported options:
      # :call-seq:
      #   address = options[:billing_address] || options[:address]
      #   address[:address1]
      #   address[:address2]
      #   address[:phone]
      #   address[:zip]
      #   address[:city]
      #   address[:country]
      #   address[:state]
      #
      def add_address(req, creditcard, options)
        if address = (options[:billing_address] || options[:address])
          validates(address, :country, "Supported countries are 'US', 'CA', 'GB', 'UK'") do |country| 
            country.nil? || country.strip.empty? || %w(US CA GB UK).include?(country.strip)
          end
          validates(address, :zip, "Zipcode must be in the format \d{5}(-\d{4})?") {|zip| (zip && address[:country] == 'US') ? zip.to_s.strip =~ /\d{5}(-\d{4})?/ : true}

          req.avsAddress1    = address[:address1].to_s if address[:address1]
          req.avsAddress2    = address[:address2].to_s if address[:address2]
          req.avsPhone       = address[:phone].to_s    if address[:phone]
          req.avsZip         = address[:zip].to_s      if address[:zip]
          req.avsCity        = address[:city].to_s     if address[:city]
          req.avsState       = address[:state].to_s    if address[:state]
          req.avsCountryCode = address[:country].to_s  if address[:country]
        end
      end

      # Adds the customer data to the request element based upon the options
      # hash. 
      # 
      # Supported options:
      # :call-seq:
      #   options[:email]
      #   options[:billing_address || :address][:phone]
      #   options[:customer_name]
      #
      def add_customer_data(req, options)
        if options.has_key?(:email)
          req.customerEmail = options[:email]
        end

        if (address = (options[:billing_address] || options[:address])) && address.has_key?(:phone)
          req.customerPhone = address[:phone]
        end
        
        if options.has_key?(:customer_name)
          req.customerName = options[:customer_name]
        end
      end

      # Adds the transaction type and monetary amount for the new order
      # transaction. This includes the authorization, purchase, credit
      # and capture actions. Money amounts are reformatted to integer values
      # in cents.
      #
      def add_commit_data(req, action, money)
        validates("amount", money, "Money amount must be implied decimal (i.e., $10.00 = 1000)") {|amt| amt.to_s =~ /^\d+$/}
        
        case action
        when :authonly
          req.transType = TRANS_TYPE[:auth_only]
        when :sale
          req.transType = TRANS_TYPE[:auth_mark_capture]
        when :credit
          req.transType = TRANS_TYPE[:refund]
        when :capture
          # since this uses a different message type, no transType is necessary
        else
          raise ArgumentError.new("Unsupported transaction type: #{action}")
        end
        
        req.amount = money
      end

      # Yields a new port instance and interprets soap fault messages
      # from the execution of the block. The block given to this method should 
      # return the response from the method call on the port.
      #
      def port_call
        validate!
        port = PaymentechGatewayPortType.new(self.url)
        #        begin
        return(yield port)
        #        rescue SOAP::Error
        #          # not sure what to do here yet
        #        end
      end
      
      # Retrieves a number of the elements that are present in all responses
      # into a hash that can be merged with data from the type-specific responses
      #
      def parse_common(resp_elem)
        {
          :routing_id => resp_elem.bin,
          :merchant_id => resp_elem.merchantID,
          :terminal_id => resp_elem.terminalID,
          :order_id => resp_elem.orderID,
          :transaction_id => resp_elem.txRefNum,
          :transaction_ref_index => resp_elem.txRefIdx,
          :transaction_date => Time.mktime(*resp_elem.respDateTime.scanf("%4d%2d%2d%2d%2d%2d")),
          :retry_trace => resp_elem.retryTrace,
          :proc_status => resp_elem.procStatus,
          :proc_status_message => resp_elem.procStatusMessage
        }
      end
      
      # Creates a Response object from the NewOrderResponse message.
      #
      def parse_new_order_response(resp)
        raise ArgumentError.new("Response must be a NewOrderResponse (was #{resp.class.name})") unless resp.instance_of?(NewOrderResponse)
        resp_elem = resp.m_return
        Response.new(
          new_order_success?(resp_elem),
          resp_elem.respCodeMessage,
          {
            :response_code => resp_elem.respCode,
            :response_reason_code => resp_elem.respCode,
            :response_reason_text => resp_elem.respCodeMessage,
            :amount => resp_elem.requestAmount,
            :bank_auth_id => resp_elem.authorizationCode
          }.merge(parse_common(resp_elem)),
          {
            :test => @options[:test] || false,
            :authorization => resp_elem.txRefNum,
            :avs_result => {
              :code => resp_elem.avsRespCode.strip
            },
            :cvv_result => resp_elem.cvvRespCode,
            :fraud_review => new_order_fraud_review?(resp_elem)
          }
        )        
      end
      
      # Creates a Response object from the MarkForCaptureResponse message.
      #
      def parse_mark_capture_response(resp)
        raise ArgumentError.new("Response must be a MarkForCaptureResponse (was #{resp.class.name})") unless resp.instance_of?(MarkForCaptureResponse)
        resp_elem = resp.m_return
        Response.new(
          mark_capture_success?(resp_elem),
          resp_elem.procStatusMessage,
          {
            :split_trans_ref_index => resp_elem.splitTxRefIdx,
            :capture_amount => resp_elem.amount
          }.merge(parse_common(resp_elem)),
          {            
            :test => @options[:test] || false
          }
        )        
      end
      
      # Creates a Respone object from the ReversalResponse message. (void 
      # transaction)
      #
      def parse_reversal_response(resp)
        raise ArgumentError.new("Response must be a ReversalResponse (was #{resp.class.name})") unless resp.instance_of?(ReversalResponse)
        resp_elem = resp.m_return
        Response.new(
          reversal_success?(resp_elem),
          resp_elem.procStatusMessage,
          {
            :outstanding_amount => resp_elem.outstandingAmt
          }.merge(parse_common(resp_elem)),
          {
            :test => @options[:test] || false
          }
        )        
      end      
      
      # Formats the expiration date of the credit card to YYYYMM
      #
      def expdate(creditcard)
        Time.mktime(creditcard.year, creditcard.month).strftime("%Y%m")
      end                 
    end
  end
end

