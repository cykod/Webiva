gem 'soap4r'
require File.dirname(__FILE__) + '/PaymentechGateway.rb'
require File.dirname(__FILE__) + '/PaymentechGatewayMappingRegistry.rb'
require 'soap/rpc/driver'

class PaymentechGatewayPortType < ::SOAP::RPC::Driver
  DefaultEndpointUrl = "https://ws.paymentech.net/PaymentechGateway"

  Methods = [
    [ "",
      "newOrder",
      [ ["in", "parameters", ["::SOAP::SOAPElement", "urn:ws.paymentech.net/PaymentechGateway", "NewOrder"]],
        ["out", "parameters", ["::SOAP::SOAPElement", "urn:ws.paymentech.net/PaymentechGateway", "NewOrderResponse"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ],
    [ "",
      "markForCapture",
      [ ["in", "parameters", ["::SOAP::SOAPElement", "urn:ws.paymentech.net/PaymentechGateway", "MarkForCapture"]],
        ["out", "parameters", ["::SOAP::SOAPElement", "urn:ws.paymentech.net/PaymentechGateway", "MarkForCaptureResponse"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ],
    [ "",
      "reversal",
      [ ["in", "parameters", ["::SOAP::SOAPElement", "urn:ws.paymentech.net/PaymentechGateway", "Reversal"]],
        ["out", "parameters", ["::SOAP::SOAPElement", "urn:ws.paymentech.net/PaymentechGateway", "ReversalResponse"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ],
    [ "",
      "endOfDay",
      [ ["in", "parameters", ["::SOAP::SOAPElement", "urn:ws.paymentech.net/PaymentechGateway", "EndOfDay"]],
        ["out", "parameters", ["::SOAP::SOAPElement", "urn:ws.paymentech.net/PaymentechGateway", "EndOfDayResponse"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ],
    [ "",
      "profileAdd",
      [ ["in", "parameters", ["::SOAP::SOAPElement", "urn:ws.paymentech.net/PaymentechGateway", "ProfileAdd"]],
        ["out", "parameters", ["::SOAP::SOAPElement", "urn:ws.paymentech.net/PaymentechGateway", "ProfileAddResponse"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ],
    [ "",
      "profileChange",
      [ ["in", "parameters", ["::SOAP::SOAPElement", "urn:ws.paymentech.net/PaymentechGateway", "ProfileChange"]],
        ["out", "parameters", ["::SOAP::SOAPElement", "urn:ws.paymentech.net/PaymentechGateway", "ProfileChangeResponse"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ],
    [ "",
      "profileDelete",
      [ ["in", "parameters", ["::SOAP::SOAPElement", "urn:ws.paymentech.net/PaymentechGateway", "ProfileDelete"]],
        ["out", "parameters", ["::SOAP::SOAPElement", "urn:ws.paymentech.net/PaymentechGateway", "ProfileDeleteResponse"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ],
    [ "",
      "profileFetch",
      [ ["in", "parameters", ["::SOAP::SOAPElement", "urn:ws.paymentech.net/PaymentechGateway", "ProfileFetch"]],
        ["out", "parameters", ["::SOAP::SOAPElement", "urn:ws.paymentech.net/PaymentechGateway", "ProfileFetchResponse"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ],
    [ "",
      "flexCache",
      [ ["in", "parameters", ["::SOAP::SOAPElement", "urn:ws.paymentech.net/PaymentechGateway", "FlexCache"]],
        ["out", "parameters", ["::SOAP::SOAPElement", "urn:ws.paymentech.net/PaymentechGateway", "FlexCacheResponse"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ],
    [ "",
      "unmark",
      [ ["in", "parameters", ["::SOAP::SOAPElement", "urn:ws.paymentech.net/PaymentechGateway", "Unmark"]],
        ["out", "parameters", ["::SOAP::SOAPElement", "urn:ws.paymentech.net/PaymentechGateway", "UnmarkResponse"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ]
  ]

  def initialize(endpoint_url = nil)
    endpoint_url ||= DefaultEndpointUrl
    super(endpoint_url, nil)
    self.mapping_registry = PaymentechGatewayMappingRegistry::EncodedRegistry
    self.literal_mapping_registry = PaymentechGatewayMappingRegistry::LiteralRegistry
    init_methods
  end

private

  def init_methods
    Methods.each do |definitions|
      opt = definitions.last
      if opt[:request_style] == :document
        add_document_operation(*definitions)
      else
        add_rpc_operation(*definitions)
        qname = definitions[0]
        name = definitions[2]
        if qname.name != name and qname.name.capitalize == name.capitalize
          ::SOAP::Mapping.define_singleton_method(self, qname.name) do |*arg|
            __send__(name, *arg)
          end
        end
      end
    end
  end
end

