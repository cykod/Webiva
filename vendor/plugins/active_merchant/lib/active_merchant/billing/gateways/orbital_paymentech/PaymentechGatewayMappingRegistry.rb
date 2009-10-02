require File.dirname(__FILE__) + '/PaymentechGateway.rb'
require 'soap/mapping'

module PaymentechGatewayMappingRegistry
  EncodedRegistry = ::SOAP::Mapping::EncodedRegistry.new
  LiteralRegistry = ::SOAP::Mapping::LiteralRegistry.new
  NsPaymentechGateway = "urn:ws.paymentech.net/PaymentechGateway"

  EncodedRegistry.register(
    :class => PC3LineItem,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "PC3LineItem"),
    :schema_element => [
      ["pCard3DtlIndex", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlDesc", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlProdCd", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlQty", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlUOM", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlTaxAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlTaxRate", "SOAP::SOAPString", [0, 1]],
      ["pCard3Dtllinetot", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlDisc", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlCommCd", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlUnitCost", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlGrossNet", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlTaxType", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlDiscInd", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlDebitInd", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => PC3LineItemArray,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "PC3LineItemArray"),
    :schema_element => [
      ["item", "PC3LineItem[]", [0, nil]]
    ]
  )

  EncodedRegistry.register(
    :class => NewOrderRequestElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "NewOrderRequestElement"),
    :schema_element => [
      ["industryType", "SOAP::SOAPString"],
      ["transType", "SOAP::SOAPString"],
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["cardBrand", "SOAP::SOAPString", [0, 1]],
      ["ccAccountNum", "SOAP::SOAPString", [0, 1]],
      ["ccExp", "SOAP::SOAPString", [0, 1]],
      ["ccCardVerifyPresenceInd", "SOAP::SOAPString", [0, 1]],
      ["ccCardVerifyNum", "SOAP::SOAPString", [0, 1]],
      ["switchSoloIssueNum", "SOAP::SOAPString", [0, 1]],
      ["switchSoloCardStartDate", "SOAP::SOAPString", [0, 1]],
      ["ecpCheckRT", "SOAP::SOAPString", [0, 1]],
      ["ecpCheckDDA", "SOAP::SOAPString", [0, 1]],
      ["ecpBankAcctType", "SOAP::SOAPString", [0, 1]],
      ["ecpAuthMethod", "SOAP::SOAPString", [0, 1]],
      ["ecpDelvMethod", "SOAP::SOAPString", [0, 1]],
      ["avsZip", "SOAP::SOAPString", [0, 1]],
      ["avsAddress1", "SOAP::SOAPString", [0, 1]],
      ["avsAddress2", "SOAP::SOAPString", [0, 1]],
      ["avsCity", "SOAP::SOAPString", [0, 1]],
      ["avsState", "SOAP::SOAPString", [0, 1]],
      ["avsName", "SOAP::SOAPString", [0, 1]],
      ["avsCountryCode", "SOAP::SOAPString", [0, 1]],
      ["avsPhone", "SOAP::SOAPString", [0, 1]],
      ["useCustomerRefNum", "SOAP::SOAPString", [0, 1]],
      ["addProfileFromOrder", "SOAP::SOAPString", [0, 1]],
      ["customerRefNum", "SOAP::SOAPString", [0, 1]],
      ["profileOrderOverideInd", "SOAP::SOAPString", [0, 1]],
      ["authenticationECIInd", "SOAP::SOAPString", [0, 1]],
      ["verifyByVisaCAVV", "SOAP::SOAPString", [0, 1]],
      ["verifyByVisaXID", "SOAP::SOAPString", [0, 1]],
      ["priorAuthCd", "SOAP::SOAPString", [0, 1]],
      ["orderID", "SOAP::SOAPString", [0, 1]],
      ["amount", "SOAP::SOAPString", [0, 1]],
      ["comments", "SOAP::SOAPString", [0, 1]],
      ["shippingRef", "SOAP::SOAPString", [0, 1]],
      ["taxInd", "SOAP::SOAPString", [0, 1]],
      ["taxAmount", "SOAP::SOAPString", [0, 1]],
      ["amexTranAdvAddn1", "SOAP::SOAPString", [0, 1]],
      ["amexTranAdvAddn2", "SOAP::SOAPString", [0, 1]],
      ["amexTranAdvAddn3", "SOAP::SOAPString", [0, 1]],
      ["amexTranAdvAddn4", "SOAP::SOAPString", [0, 1]],
      ["mcSecureCodeAAV", "SOAP::SOAPString", [0, 1]],
      ["softDescMercName", "SOAP::SOAPString", [0, 1]],
      ["softDescProdDesc", "SOAP::SOAPString", [0, 1]],
      ["softDescMercCity", "SOAP::SOAPString", [0, 1]],
      ["softDescMercPhone", "SOAP::SOAPString", [0, 1]],
      ["softDescMercURL", "SOAP::SOAPString", [0, 1]],
      ["softDescMercEmail", "SOAP::SOAPString", [0, 1]],
      ["recurringInd", "SOAP::SOAPString", [0, 1]],
      ["retryTrace", "SOAP::SOAPString", [0, 1]],
      ["pCardOrderID", "SOAP::SOAPString", [0, 1]],
      ["pCardDestZip", "SOAP::SOAPString", [0, 1]],
      ["pCardDestName", "SOAP::SOAPString", [0, 1]],
      ["pCardDestAddress", "SOAP::SOAPString", [0, 1]],
      ["pCardDestAddress2", "SOAP::SOAPString", [0, 1]],
      ["pCardDestCity", "SOAP::SOAPString", [0, 1]],
      ["pCardDestStateCd", "SOAP::SOAPString", [0, 1]],
      ["pCard3FreightAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3DutyAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3DestCountryCd", "SOAP::SOAPString", [0, 1]],
      ["pCard3ShipFromZip", "SOAP::SOAPString", [0, 1]],
      ["pCard3DiscAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3VATtaxAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3VATtaxRate", "SOAP::SOAPString", [0, 1]],
      ["pCard3AltTaxInd", "SOAP::SOAPString", [0, 1]],
      ["pCard3AltTaxAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3LineItemCount", "SOAP::SOAPString", [0, 1]],
      ["pCard3LineItems", "PC3LineItemArray", [0, 1]],
      ["magStripeTrack1", "SOAP::SOAPString", [0, 1]],
      ["magStripeTrack2", "SOAP::SOAPString", [0, 1]],
      ["retailTransInfo", "SOAP::SOAPString", [0, 1]],
      ["customerName", "SOAP::SOAPString", [0, 1]],
      ["customerEmail", "SOAP::SOAPString", [0, 1]],
      ["customerPhone", "SOAP::SOAPString", [0, 1]],
      ["cardPresentInd", "SOAP::SOAPString", [0, 1]],
      ["euddBankSortCode", "SOAP::SOAPString", [0, 1]],
      ["euddCountryCode", "SOAP::SOAPString", [0, 1]],
      ["euddRibCode", "SOAP::SOAPString", [0, 1]],
      ["bmlCustomerIP", "SOAP::SOAPString", [0, 1]],
      ["bmlCustomerEmail", "SOAP::SOAPString", [0, 1]],
      ["bmlShippingCost", "SOAP::SOAPString", [0, 1]],
      ["bmlTNCVersion", "SOAP::SOAPString", [0, 1]],
      ["bmlCustomerRegistrationDate", "SOAP::SOAPString", [0, 1]],
      ["bmlCustomerTypeFlag", "SOAP::SOAPString", [0, 1]],
      ["bmlItemCategory", "SOAP::SOAPString", [0, 1]],
      ["bmlPreapprovalInvitationNum", "SOAP::SOAPString", [0, 1]],
      ["bmlMerchantPromotionalCode", "SOAP::SOAPString", [0, 1]],
      ["bmlCustomerBirthDate", "SOAP::SOAPString", [0, 1]],
      ["bmlCustomerSSN", "SOAP::SOAPString", [0, 1]],
      ["bmlCustomerAnnualIncome", "SOAP::SOAPString", [0, 1]],
      ["bmlCustomerResidenceStatus", "SOAP::SOAPString", [0, 1]],
      ["bmlCustomerCheckingAccount", "SOAP::SOAPString", [0, 1]],
      ["bmlCustomerSavingsAccount", "SOAP::SOAPString", [0, 1]],
      ["bmlProductDeliveryType", "SOAP::SOAPString", [0, 1]],
      ["avsDestName", "SOAP::SOAPString", [0, 1]],
      ["avsDestAddress1", "SOAP::SOAPString", [0, 1]],
      ["avsDestAddress2", "SOAP::SOAPString", [0, 1]],
      ["avsDestCity", "SOAP::SOAPString", [0, 1]],
      ["avsDestState", "SOAP::SOAPString", [0, 1]],
      ["avsDestZip", "SOAP::SOAPString", [0, 1]],
      ["avsDestCountryCode", "SOAP::SOAPString", [0, 1]],
      ["avsDestPhoneNum", "SOAP::SOAPString", [0, 1]],
      ["debitBillerReferenceNumber", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => NewOrderResponseElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "NewOrderResponseElement"),
    :schema_element => [
      ["industryType", "SOAP::SOAPString"],
      ["transType", "SOAP::SOAPString"],
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["cardBrand", "SOAP::SOAPString"],
      ["orderID", "SOAP::SOAPString"],
      ["txRefNum", "SOAP::SOAPString"],
      ["txRefIdx", "SOAP::SOAPString"],
      ["respDateTime", "SOAP::SOAPString"],
      ["procStatus", "SOAP::SOAPString"],
      ["approvalStatus", "SOAP::SOAPString"],
      ["respCode", "SOAP::SOAPString"],
      ["avsRespCode", "SOAP::SOAPString"],
      ["cvvRespCode", "SOAP::SOAPString"],
      ["authorizationCode", "SOAP::SOAPString"],
      ["mcRecurringAdvCode", "SOAP::SOAPString"],
      ["visaVbVRespCode", "SOAP::SOAPString"],
      ["procStatusMessage", "SOAP::SOAPString"],
      ["respCodeMessage", "SOAP::SOAPString"],
      ["hostRespCode", "SOAP::SOAPString"],
      ["hostAVSRespCode", "SOAP::SOAPString"],
      ["hostCVVRespCode", "SOAP::SOAPString"],
      ["retryTrace", "SOAP::SOAPString"],
      ["retryAttempCount", "SOAP::SOAPString"],
      ["lastRetryDate", "SOAP::SOAPString"],
      ["customerRefNum", "SOAP::SOAPString"],
      ["customerName", "SOAP::SOAPString"],
      ["profileProcStatus", "SOAP::SOAPString"],
      ["profileProcStatusMsg", "SOAP::SOAPString"],
      ["giftCardInd", "SOAP::SOAPString", [0, 1]],
      ["remainingBalance", "SOAP::SOAPString", [0, 1]],
      ["requestAmount", "SOAP::SOAPString", [0, 1]],
      ["redeemedAmount", "SOAP::SOAPString", [0, 1]],
      ["ccAccountNum", "SOAP::SOAPString", [0, 1]],
      ["debitBillerReferenceNumber", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => MarkForCaptureElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "MarkForCaptureElement"),
    :schema_element => [
      ["orderID", "SOAP::SOAPString"],
      ["amount", "SOAP::SOAPString"],
      ["taxInd", "SOAP::SOAPString", [0, 1]],
      ["taxAmount", "SOAP::SOAPString", [0, 1]],
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["txRefNum", "SOAP::SOAPString"],
      ["retryTrace", "SOAP::SOAPString", [0, 1]],
      ["pCardOrderID", "SOAP::SOAPString", [0, 1]],
      ["pCardDestZip", "SOAP::SOAPString", [0, 1]],
      ["pCardDestName", "SOAP::SOAPString", [0, 1]],
      ["pCardDestAddress", "SOAP::SOAPString", [0, 1]],
      ["pCardDestAddress2", "SOAP::SOAPString", [0, 1]],
      ["pCardDestCity", "SOAP::SOAPString", [0, 1]],
      ["pCardDestStateCd", "SOAP::SOAPString", [0, 1]],
      ["amexTranAdvAddn1", "SOAP::SOAPString", [0, 1]],
      ["amexTranAdvAddn2", "SOAP::SOAPString", [0, 1]],
      ["amexTranAdvAddn3", "SOAP::SOAPString", [0, 1]],
      ["amexTranAdvAddn4", "SOAP::SOAPString", [0, 1]],
      ["pCard3FreightAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3DutyAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3DestCountryCd", "SOAP::SOAPString", [0, 1]],
      ["pCard3ShipFromZip", "SOAP::SOAPString", [0, 1]],
      ["pCard3DiscAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3VATtaxAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3VATtaxRate", "SOAP::SOAPString", [0, 1]],
      ["pCard3AltTaxInd", "SOAP::SOAPString", [0, 1]],
      ["pCard3AltTaxAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3LineItemCount", "SOAP::SOAPString", [0, 1]],
      ["pCard3LineItems", "PC3LineItemArray", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => MarkForCaptureResponseElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "MarkForCaptureResponseElement"),
    :schema_element => [
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["orderID", "SOAP::SOAPString"],
      ["txRefNum", "SOAP::SOAPString"],
      ["txRefIdx", "SOAP::SOAPString"],
      ["splitTxRefIdx", "SOAP::SOAPString"],
      ["amount", "SOAP::SOAPString"],
      ["respDateTime", "SOAP::SOAPString"],
      ["procStatus", "SOAP::SOAPString"],
      ["procStatusMessage", "SOAP::SOAPString"],
      ["retryTrace", "SOAP::SOAPString"],
      ["retryAttempCount", "SOAP::SOAPString"],
      ["lastRetryDate", "SOAP::SOAPString"]
    ]
  )

  EncodedRegistry.register(
    :class => ReversalElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "ReversalElement"),
    :schema_element => [
      ["txRefNum", "SOAP::SOAPString"],
      ["txRefIdx", "SOAP::SOAPString"],
      ["adjustedAmount", "SOAP::SOAPString", [0, 1]],
      ["orderID", "SOAP::SOAPString", [0, 1]],
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["retryTrace", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => ReversalResponseElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "ReversalResponseElement"),
    :schema_element => [
      ["outstandingAmt", "SOAP::SOAPString"],
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["orderID", "SOAP::SOAPString"],
      ["txRefNum", "SOAP::SOAPString"],
      ["txRefIdx", "SOAP::SOAPString"],
      ["respDateTime", "SOAP::SOAPString"],
      ["procStatus", "SOAP::SOAPString"],
      ["procStatusMessage", "SOAP::SOAPString"],
      ["retryTrace", "SOAP::SOAPString"],
      ["retryAttempCount", "SOAP::SOAPString"],
      ["lastRetryDate", "SOAP::SOAPString"]
    ]
  )

  EncodedRegistry.register(
    :class => EndOfDayElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "EndOfDayElement"),
    :schema_element => [
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["settleRejectedHoldingBin", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => EndOfDayResponseElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "EndOfDayResponseElement"),
    :schema_element => [
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["procStatus", "SOAP::SOAPString"],
      ["batchSeqNum", "SOAP::SOAPString"],
      ["procStatusMessage", "SOAP::SOAPString"]
    ]
  )

  EncodedRegistry.register(
    :class => ProfileResponseElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "ProfileResponseElement"),
    :schema_element => [
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["customerName", "SOAP::SOAPString"],
      ["customerRefNum", "SOAP::SOAPString"],
      ["profileAction", "SOAP::SOAPString"],
      ["procStatus", "SOAP::SOAPString"],
      ["procStatusMessage", "SOAP::SOAPString"],
      ["customerAddress1", "SOAP::SOAPString"],
      ["customerAddress2", "SOAP::SOAPString"],
      ["customerCity", "SOAP::SOAPString"],
      ["customerState", "SOAP::SOAPString"],
      ["customerZIP", "SOAP::SOAPString"],
      ["customerEmail", "SOAP::SOAPString"],
      ["customerPhone", "SOAP::SOAPString"],
      ["profileOrderOverideInd", "SOAP::SOAPString"],
      ["orderDefaultDescription", "SOAP::SOAPString"],
      ["orderDefaultAmount", "SOAP::SOAPString"],
      ["customerAccountType", "SOAP::SOAPString"],
      ["ccAccountNum", "SOAP::SOAPString"],
      ["ccExp", "SOAP::SOAPString"],
      ["ecpCheckDDA", "SOAP::SOAPString"],
      ["ecpBankAcctType", "SOAP::SOAPString"],
      ["ecpCheckRT", "SOAP::SOAPString"],
      ["ecpDelvMethod", "SOAP::SOAPString"],
      ["switchSoloCardStartDate", "SOAP::SOAPString"],
      ["switchSoloIssueNum", "SOAP::SOAPString"]
    ]
  )

  EncodedRegistry.register(
    :class => ProfileResponse,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "ProfileResponse"),
    :schema_element => [
      ["v_return", ["ProfileResponseElement", XSD::QName.new(NsPaymentechGateway, "return")]]
    ]
  )

  EncodedRegistry.register(
    :class => ProfileAddElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "ProfileAddElement"),
    :schema_element => [
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["customerName", "SOAP::SOAPString", [0, 1]],
      ["customerRefNum", "SOAP::SOAPString", [0, 1]],
      ["customerAddress1", "SOAP::SOAPString", [0, 1]],
      ["customerAddress2", "SOAP::SOAPString", [0, 1]],
      ["customerCity", "SOAP::SOAPString", [0, 1]],
      ["customerState", "SOAP::SOAPString", [0, 1]],
      ["customerZIP", "SOAP::SOAPString", [0, 1]],
      ["customerEmail", "SOAP::SOAPString", [0, 1]],
      ["customerPhone", "SOAP::SOAPString", [0, 1]],
      ["customerProfileOrderOverideInd", "SOAP::SOAPString"],
      ["customerProfileFromOrderInd", "SOAP::SOAPString"],
      ["orderDefaultDescription", "SOAP::SOAPString", [0, 1]],
      ["orderDefaultAmount", "SOAP::SOAPString", [0, 1]],
      ["customerAccountType", "SOAP::SOAPString"],
      ["ccAccountNum", "SOAP::SOAPString", [0, 1]],
      ["ccExp", "SOAP::SOAPString", [0, 1]],
      ["ecpCheckDDA", "SOAP::SOAPString", [0, 1]],
      ["ecpBankAcctType", "SOAP::SOAPString", [0, 1]],
      ["ecpCheckRT", "SOAP::SOAPString", [0, 1]],
      ["ecpDelvMethod", "SOAP::SOAPString", [0, 1]],
      ["switchSoloCardStartDate", "SOAP::SOAPString", [0, 1]],
      ["switchSoloIssueNum", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => ProfileChangeElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "ProfileChangeElement"),
    :schema_element => [
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["customerName", "SOAP::SOAPString", [0, 1]],
      ["customerRefNum", "SOAP::SOAPString"],
      ["customerAddress1", "SOAP::SOAPString", [0, 1]],
      ["customerAddress2", "SOAP::SOAPString", [0, 1]],
      ["customerCity", "SOAP::SOAPString", [0, 1]],
      ["customerState", "SOAP::SOAPString", [0, 1]],
      ["customerZIP", "SOAP::SOAPString", [0, 1]],
      ["customerEmail", "SOAP::SOAPString", [0, 1]],
      ["customerPhone", "SOAP::SOAPString", [0, 1]],
      ["customerProfileOrderOverideInd", "SOAP::SOAPString", [0, 1]],
      ["orderDefaultDescription", "SOAP::SOAPString", [0, 1]],
      ["orderDefaultAmount", "SOAP::SOAPString", [0, 1]],
      ["customerAccountType", "SOAP::SOAPString", [0, 1]],
      ["ccAccountNum", "SOAP::SOAPString", [0, 1]],
      ["ccExp", "SOAP::SOAPString", [0, 1]],
      ["ecpCheckDDA", "SOAP::SOAPString", [0, 1]],
      ["ecpBankAcctType", "SOAP::SOAPString", [0, 1]],
      ["ecpCheckRT", "SOAP::SOAPString", [0, 1]],
      ["ecpDelvMethod", "SOAP::SOAPString", [0, 1]],
      ["switchSoloCardStartDate", "SOAP::SOAPString", [0, 1]],
      ["switchSoloIssueNum", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => ProfileDeleteElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "ProfileDeleteElement"),
    :schema_element => [
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["customerName", "SOAP::SOAPString"],
      ["customerRefNum", "SOAP::SOAPString"]
    ]
  )

  EncodedRegistry.register(
    :class => ProfileFetchElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "ProfileFetchElement"),
    :schema_element => [
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["customerName", "SOAP::SOAPString"],
      ["customerRefNum", "SOAP::SOAPString"]
    ]
  )

  EncodedRegistry.register(
    :class => FlexCacheElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "FlexCacheElement"),
    :schema_element => [
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["ccAccountNum", "SOAP::SOAPString", [0, 1]],
      ["orderID", "SOAP::SOAPString", [0, 1]],
      ["amount", "SOAP::SOAPString", [0, 1]],
      ["ccCardVerifyNum", "SOAP::SOAPString", [0, 1]],
      ["comments", "SOAP::SOAPString", [0, 1]],
      ["shippingRef", "SOAP::SOAPString", [0, 1]],
      ["industryType", "SOAP::SOAPString", [0, 1]],
      ["flexAutoAuthInd", "SOAP::SOAPString", [0, 1]],
      ["flexPartialRedemptionInd", "SOAP::SOAPString", [0, 1]],
      ["flexAction", "SOAP::SOAPString", [0, 1]],
      ["startAccountNum", "SOAP::SOAPString", [0, 1]],
      ["activationCount", "SOAP::SOAPString", [0, 1]],
      ["txRefNum", "SOAP::SOAPString", [0, 1]],
      ["sequenceNumber", "SOAP::SOAPString", [0, 1]],
      ["retryTrace", "SOAP::SOAPString", [0, 1]],
      ["employeeNumber", "SOAP::SOAPString", [0, 1]],
      ["magStripeTrack1", "SOAP::SOAPString", [0, 1]],
      ["magStripeTrack2", "SOAP::SOAPString", [0, 1]],
      ["retailTransInfo", "SOAP::SOAPString", [0, 1]],
      ["priorAuthCd", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => FlexCacheResponseElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "FlexCacheResponseElement"),
    :schema_element => [
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["orderID", "SOAP::SOAPString"],
      ["ccAccountNum", "SOAP::SOAPString"],
      ["startAccountNum", "SOAP::SOAPString"],
      ["flexAcctBalance", "SOAP::SOAPString"],
      ["flexAcctPriorBalance", "SOAP::SOAPString"],
      ["flexAcctExpireDate", "SOAP::SOAPString"],
      ["cardType", "SOAP::SOAPString"],
      ["txRefIdx", "SOAP::SOAPString"],
      ["txRefNum", "SOAP::SOAPString"],
      ["procStatus", "SOAP::SOAPString"],
      ["procStatusMessage", "SOAP::SOAPString"],
      ["approvalStatus", "SOAP::SOAPString"],
      ["authorizationCode", "SOAP::SOAPString"],
      ["respCode", "SOAP::SOAPString"],
      ["batchFailedAcctNum", "SOAP::SOAPString"],
      ["flexRequestedAmount", "SOAP::SOAPString"],
      ["flexRedeemedAmt", "SOAP::SOAPString"],
      ["flexHostTrace", "SOAP::SOAPString"],
      ["flexAction", "SOAP::SOAPString"],
      ["respDateTime", "SOAP::SOAPString"],
      ["autoAuthTxRefIdx", "SOAP::SOAPString"],
      ["autoAuthTxRefNum", "SOAP::SOAPString"],
      ["autoAuthProcStatus", "SOAP::SOAPString"],
      ["autoAuthStatusMsg", "SOAP::SOAPString"],
      ["autoAuthApprovalStatus", "SOAP::SOAPString"],
      ["autoAuthFlexRedeemedAmt", "SOAP::SOAPString"],
      ["autoAuthResponseCodes", "SOAP::SOAPString"],
      ["autoAuthFlexHostTrace", "SOAP::SOAPString"],
      ["autoAuthFlexAction", "SOAP::SOAPString"],
      ["autoAuthRespTime", "SOAP::SOAPString"],
      ["retryTrace", "SOAP::SOAPString"],
      ["retryAttempCount", "SOAP::SOAPString"],
      ["lastRetryDate", "SOAP::SOAPString"],
      ["cvvRespCode", "SOAP::SOAPString"],
      ["superBlockID", "SOAP::SOAPString"]
    ]
  )

  EncodedRegistry.register(
    :class => UnmarkElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "UnmarkElement"),
    :schema_element => [
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["bin", "SOAP::SOAPString"],
      ["txRefNum", "SOAP::SOAPString"],
      ["txRefIdx", "SOAP::SOAPString"],
      ["orderID", "SOAP::SOAPString"],
      ["retryTrace", "SOAP::SOAPString", [0, 1]],
      ["retryAttempCount", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => UnmarkResponseElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "UnmarkResponseElement"),
    :schema_element => [
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["bin", "SOAP::SOAPString"],
      ["orderID", "SOAP::SOAPString"],
      ["txRefNum", "SOAP::SOAPString"],
      ["txRefIdx", "SOAP::SOAPString"],
      ["procStatus", "SOAP::SOAPString"],
      ["procStatusMessage", "SOAP::SOAPString"],
      ["retryTrace", "SOAP::SOAPString"],
      ["retryAttempCount", "SOAP::SOAPString"],
      ["lastRetryDate", "SOAP::SOAPString"]
    ]
  )

  LiteralRegistry.register(
    :class => PC3LineItem,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "PC3LineItem"),
    :schema_element => [
      ["pCard3DtlIndex", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlDesc", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlProdCd", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlQty", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlUOM", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlTaxAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlTaxRate", "SOAP::SOAPString", [0, 1]],
      ["pCard3Dtllinetot", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlDisc", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlCommCd", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlUnitCost", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlGrossNet", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlTaxType", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlDiscInd", "SOAP::SOAPString", [0, 1]],
      ["pCard3DtlDebitInd", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => PC3LineItemArray,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "PC3LineItemArray"),
    :schema_element => [
      ["item", "PC3LineItem[]", [0, nil]]
    ]
  )

  LiteralRegistry.register(
    :class => NewOrderRequestElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "NewOrderRequestElement"),
    :schema_element => [
      ["industryType", "SOAP::SOAPString"],
      ["transType", "SOAP::SOAPString"],
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["cardBrand", "SOAP::SOAPString", [0, 1]],
      ["ccAccountNum", "SOAP::SOAPString", [0, 1]],
      ["ccExp", "SOAP::SOAPString", [0, 1]],
      ["ccCardVerifyPresenceInd", "SOAP::SOAPString", [0, 1]],
      ["ccCardVerifyNum", "SOAP::SOAPString", [0, 1]],
      ["switchSoloIssueNum", "SOAP::SOAPString", [0, 1]],
      ["switchSoloCardStartDate", "SOAP::SOAPString", [0, 1]],
      ["ecpCheckRT", "SOAP::SOAPString", [0, 1]],
      ["ecpCheckDDA", "SOAP::SOAPString", [0, 1]],
      ["ecpBankAcctType", "SOAP::SOAPString", [0, 1]],
      ["ecpAuthMethod", "SOAP::SOAPString", [0, 1]],
      ["ecpDelvMethod", "SOAP::SOAPString", [0, 1]],
      ["avsZip", "SOAP::SOAPString", [0, 1]],
      ["avsAddress1", "SOAP::SOAPString", [0, 1]],
      ["avsAddress2", "SOAP::SOAPString", [0, 1]],
      ["avsCity", "SOAP::SOAPString", [0, 1]],
      ["avsState", "SOAP::SOAPString", [0, 1]],
      ["avsName", "SOAP::SOAPString", [0, 1]],
      ["avsCountryCode", "SOAP::SOAPString", [0, 1]],
      ["avsPhone", "SOAP::SOAPString", [0, 1]],
      ["useCustomerRefNum", "SOAP::SOAPString", [0, 1]],
      ["addProfileFromOrder", "SOAP::SOAPString", [0, 1]],
      ["customerRefNum", "SOAP::SOAPString", [0, 1]],
      ["profileOrderOverideInd", "SOAP::SOAPString", [0, 1]],
      ["authenticationECIInd", "SOAP::SOAPString", [0, 1]],
      ["verifyByVisaCAVV", "SOAP::SOAPString", [0, 1]],
      ["verifyByVisaXID", "SOAP::SOAPString", [0, 1]],
      ["priorAuthCd", "SOAP::SOAPString", [0, 1]],
      ["orderID", "SOAP::SOAPString", [0, 1]],
      ["amount", "SOAP::SOAPString", [0, 1]],
      ["comments", "SOAP::SOAPString", [0, 1]],
      ["shippingRef", "SOAP::SOAPString", [0, 1]],
      ["taxInd", "SOAP::SOAPString", [0, 1]],
      ["taxAmount", "SOAP::SOAPString", [0, 1]],
      ["amexTranAdvAddn1", "SOAP::SOAPString", [0, 1]],
      ["amexTranAdvAddn2", "SOAP::SOAPString", [0, 1]],
      ["amexTranAdvAddn3", "SOAP::SOAPString", [0, 1]],
      ["amexTranAdvAddn4", "SOAP::SOAPString", [0, 1]],
      ["mcSecureCodeAAV", "SOAP::SOAPString", [0, 1]],
      ["softDescMercName", "SOAP::SOAPString", [0, 1]],
      ["softDescProdDesc", "SOAP::SOAPString", [0, 1]],
      ["softDescMercCity", "SOAP::SOAPString", [0, 1]],
      ["softDescMercPhone", "SOAP::SOAPString", [0, 1]],
      ["softDescMercURL", "SOAP::SOAPString", [0, 1]],
      ["softDescMercEmail", "SOAP::SOAPString", [0, 1]],
      ["recurringInd", "SOAP::SOAPString", [0, 1]],
      ["retryTrace", "SOAP::SOAPString", [0, 1]],
      ["pCardOrderID", "SOAP::SOAPString", [0, 1]],
      ["pCardDestZip", "SOAP::SOAPString", [0, 1]],
      ["pCardDestName", "SOAP::SOAPString", [0, 1]],
      ["pCardDestAddress", "SOAP::SOAPString", [0, 1]],
      ["pCardDestAddress2", "SOAP::SOAPString", [0, 1]],
      ["pCardDestCity", "SOAP::SOAPString", [0, 1]],
      ["pCardDestStateCd", "SOAP::SOAPString", [0, 1]],
      ["pCard3FreightAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3DutyAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3DestCountryCd", "SOAP::SOAPString", [0, 1]],
      ["pCard3ShipFromZip", "SOAP::SOAPString", [0, 1]],
      ["pCard3DiscAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3VATtaxAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3VATtaxRate", "SOAP::SOAPString", [0, 1]],
      ["pCard3AltTaxInd", "SOAP::SOAPString", [0, 1]],
      ["pCard3AltTaxAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3LineItemCount", "SOAP::SOAPString", [0, 1]],
      ["pCard3LineItems", "PC3LineItemArray", [0, 1]],
      ["magStripeTrack1", "SOAP::SOAPString", [0, 1]],
      ["magStripeTrack2", "SOAP::SOAPString", [0, 1]],
      ["retailTransInfo", "SOAP::SOAPString", [0, 1]],
      ["customerName", "SOAP::SOAPString", [0, 1]],
      ["customerEmail", "SOAP::SOAPString", [0, 1]],
      ["customerPhone", "SOAP::SOAPString", [0, 1]],
      ["cardPresentInd", "SOAP::SOAPString", [0, 1]],
      ["euddBankSortCode", "SOAP::SOAPString", [0, 1]],
      ["euddCountryCode", "SOAP::SOAPString", [0, 1]],
      ["euddRibCode", "SOAP::SOAPString", [0, 1]],
      ["bmlCustomerIP", "SOAP::SOAPString", [0, 1]],
      ["bmlCustomerEmail", "SOAP::SOAPString", [0, 1]],
      ["bmlShippingCost", "SOAP::SOAPString", [0, 1]],
      ["bmlTNCVersion", "SOAP::SOAPString", [0, 1]],
      ["bmlCustomerRegistrationDate", "SOAP::SOAPString", [0, 1]],
      ["bmlCustomerTypeFlag", "SOAP::SOAPString", [0, 1]],
      ["bmlItemCategory", "SOAP::SOAPString", [0, 1]],
      ["bmlPreapprovalInvitationNum", "SOAP::SOAPString", [0, 1]],
      ["bmlMerchantPromotionalCode", "SOAP::SOAPString", [0, 1]],
      ["bmlCustomerBirthDate", "SOAP::SOAPString", [0, 1]],
      ["bmlCustomerSSN", "SOAP::SOAPString", [0, 1]],
      ["bmlCustomerAnnualIncome", "SOAP::SOAPString", [0, 1]],
      ["bmlCustomerResidenceStatus", "SOAP::SOAPString", [0, 1]],
      ["bmlCustomerCheckingAccount", "SOAP::SOAPString", [0, 1]],
      ["bmlCustomerSavingsAccount", "SOAP::SOAPString", [0, 1]],
      ["bmlProductDeliveryType", "SOAP::SOAPString", [0, 1]],
      ["avsDestName", "SOAP::SOAPString", [0, 1]],
      ["avsDestAddress1", "SOAP::SOAPString", [0, 1]],
      ["avsDestAddress2", "SOAP::SOAPString", [0, 1]],
      ["avsDestCity", "SOAP::SOAPString", [0, 1]],
      ["avsDestState", "SOAP::SOAPString", [0, 1]],
      ["avsDestZip", "SOAP::SOAPString", [0, 1]],
      ["avsDestCountryCode", "SOAP::SOAPString", [0, 1]],
      ["avsDestPhoneNum", "SOAP::SOAPString", [0, 1]],
      ["debitBillerReferenceNumber", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => NewOrderResponseElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "NewOrderResponseElement"),
    :schema_element => [
      ["industryType", "SOAP::SOAPString"],
      ["transType", "SOAP::SOAPString"],
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["cardBrand", "SOAP::SOAPString"],
      ["orderID", "SOAP::SOAPString"],
      ["txRefNum", "SOAP::SOAPString"],
      ["txRefIdx", "SOAP::SOAPString"],
      ["respDateTime", "SOAP::SOAPString"],
      ["procStatus", "SOAP::SOAPString"],
      ["approvalStatus", "SOAP::SOAPString"],
      ["respCode", "SOAP::SOAPString"],
      ["avsRespCode", "SOAP::SOAPString"],
      ["cvvRespCode", "SOAP::SOAPString"],
      ["authorizationCode", "SOAP::SOAPString"],
      ["mcRecurringAdvCode", "SOAP::SOAPString"],
      ["visaVbVRespCode", "SOAP::SOAPString"],
      ["procStatusMessage", "SOAP::SOAPString"],
      ["respCodeMessage", "SOAP::SOAPString"],
      ["hostRespCode", "SOAP::SOAPString"],
      ["hostAVSRespCode", "SOAP::SOAPString"],
      ["hostCVVRespCode", "SOAP::SOAPString"],
      ["retryTrace", "SOAP::SOAPString"],
      ["retryAttempCount", "SOAP::SOAPString"],
      ["lastRetryDate", "SOAP::SOAPString"],
      ["customerRefNum", "SOAP::SOAPString"],
      ["customerName", "SOAP::SOAPString"],
      ["profileProcStatus", "SOAP::SOAPString"],
      ["profileProcStatusMsg", "SOAP::SOAPString"],
      ["giftCardInd", "SOAP::SOAPString", [0, 1]],
      ["remainingBalance", "SOAP::SOAPString", [0, 1]],
      ["requestAmount", "SOAP::SOAPString", [0, 1]],
      ["redeemedAmount", "SOAP::SOAPString", [0, 1]],
      ["ccAccountNum", "SOAP::SOAPString", [0, 1]],
      ["debitBillerReferenceNumber", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => MarkForCaptureElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "MarkForCaptureElement"),
    :schema_element => [
      ["orderID", "SOAP::SOAPString"],
      ["amount", "SOAP::SOAPString"],
      ["taxInd", "SOAP::SOAPString", [0, 1]],
      ["taxAmount", "SOAP::SOAPString", [0, 1]],
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["txRefNum", "SOAP::SOAPString"],
      ["retryTrace", "SOAP::SOAPString", [0, 1]],
      ["pCardOrderID", "SOAP::SOAPString", [0, 1]],
      ["pCardDestZip", "SOAP::SOAPString", [0, 1]],
      ["pCardDestName", "SOAP::SOAPString", [0, 1]],
      ["pCardDestAddress", "SOAP::SOAPString", [0, 1]],
      ["pCardDestAddress2", "SOAP::SOAPString", [0, 1]],
      ["pCardDestCity", "SOAP::SOAPString", [0, 1]],
      ["pCardDestStateCd", "SOAP::SOAPString", [0, 1]],
      ["amexTranAdvAddn1", "SOAP::SOAPString", [0, 1]],
      ["amexTranAdvAddn2", "SOAP::SOAPString", [0, 1]],
      ["amexTranAdvAddn3", "SOAP::SOAPString", [0, 1]],
      ["amexTranAdvAddn4", "SOAP::SOAPString", [0, 1]],
      ["pCard3FreightAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3DutyAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3DestCountryCd", "SOAP::SOAPString", [0, 1]],
      ["pCard3ShipFromZip", "SOAP::SOAPString", [0, 1]],
      ["pCard3DiscAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3VATtaxAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3VATtaxRate", "SOAP::SOAPString", [0, 1]],
      ["pCard3AltTaxInd", "SOAP::SOAPString", [0, 1]],
      ["pCard3AltTaxAmt", "SOAP::SOAPString", [0, 1]],
      ["pCard3LineItemCount", "SOAP::SOAPString", [0, 1]],
      ["pCard3LineItems", "PC3LineItemArray", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => MarkForCaptureResponseElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "MarkForCaptureResponseElement"),
    :schema_element => [
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["orderID", "SOAP::SOAPString"],
      ["txRefNum", "SOAP::SOAPString"],
      ["txRefIdx", "SOAP::SOAPString"],
      ["splitTxRefIdx", "SOAP::SOAPString"],
      ["amount", "SOAP::SOAPString"],
      ["respDateTime", "SOAP::SOAPString"],
      ["procStatus", "SOAP::SOAPString"],
      ["procStatusMessage", "SOAP::SOAPString"],
      ["retryTrace", "SOAP::SOAPString"],
      ["retryAttempCount", "SOAP::SOAPString"],
      ["lastRetryDate", "SOAP::SOAPString"]
    ]
  )

  LiteralRegistry.register(
    :class => ReversalElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "ReversalElement"),
    :schema_element => [
      ["txRefNum", "SOAP::SOAPString"],
      ["txRefIdx", "SOAP::SOAPString"],
      ["adjustedAmount", "SOAP::SOAPString", [0, 1]],
      ["orderID", "SOAP::SOAPString", [0, 1]],
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["retryTrace", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => ReversalResponseElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "ReversalResponseElement"),
    :schema_element => [
      ["outstandingAmt", "SOAP::SOAPString"],
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["orderID", "SOAP::SOAPString"],
      ["txRefNum", "SOAP::SOAPString"],
      ["txRefIdx", "SOAP::SOAPString"],
      ["respDateTime", "SOAP::SOAPString"],
      ["procStatus", "SOAP::SOAPString"],
      ["procStatusMessage", "SOAP::SOAPString"],
      ["retryTrace", "SOAP::SOAPString"],
      ["retryAttempCount", "SOAP::SOAPString"],
      ["lastRetryDate", "SOAP::SOAPString"]
    ]
  )

  LiteralRegistry.register(
    :class => EndOfDayElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "EndOfDayElement"),
    :schema_element => [
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["settleRejectedHoldingBin", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => EndOfDayResponseElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "EndOfDayResponseElement"),
    :schema_element => [
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["procStatus", "SOAP::SOAPString"],
      ["batchSeqNum", "SOAP::SOAPString"],
      ["procStatusMessage", "SOAP::SOAPString"]
    ]
  )

  LiteralRegistry.register(
    :class => ProfileResponseElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "ProfileResponseElement"),
    :schema_element => [
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["customerName", "SOAP::SOAPString"],
      ["customerRefNum", "SOAP::SOAPString"],
      ["profileAction", "SOAP::SOAPString"],
      ["procStatus", "SOAP::SOAPString"],
      ["procStatusMessage", "SOAP::SOAPString"],
      ["customerAddress1", "SOAP::SOAPString"],
      ["customerAddress2", "SOAP::SOAPString"],
      ["customerCity", "SOAP::SOAPString"],
      ["customerState", "SOAP::SOAPString"],
      ["customerZIP", "SOAP::SOAPString"],
      ["customerEmail", "SOAP::SOAPString"],
      ["customerPhone", "SOAP::SOAPString"],
      ["profileOrderOverideInd", "SOAP::SOAPString"],
      ["orderDefaultDescription", "SOAP::SOAPString"],
      ["orderDefaultAmount", "SOAP::SOAPString"],
      ["customerAccountType", "SOAP::SOAPString"],
      ["ccAccountNum", "SOAP::SOAPString"],
      ["ccExp", "SOAP::SOAPString"],
      ["ecpCheckDDA", "SOAP::SOAPString"],
      ["ecpBankAcctType", "SOAP::SOAPString"],
      ["ecpCheckRT", "SOAP::SOAPString"],
      ["ecpDelvMethod", "SOAP::SOAPString"],
      ["switchSoloCardStartDate", "SOAP::SOAPString"],
      ["switchSoloIssueNum", "SOAP::SOAPString"]
    ]
  )

  LiteralRegistry.register(
    :class => ProfileResponse,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "ProfileResponse"),
    :schema_element => [
      ["v_return", ["ProfileResponseElement", XSD::QName.new(NsPaymentechGateway, "return")]]
    ]
  )

  LiteralRegistry.register(
    :class => ProfileAddElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "ProfileAddElement"),
    :schema_element => [
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["customerName", "SOAP::SOAPString", [0, 1]],
      ["customerRefNum", "SOAP::SOAPString", [0, 1]],
      ["customerAddress1", "SOAP::SOAPString", [0, 1]],
      ["customerAddress2", "SOAP::SOAPString", [0, 1]],
      ["customerCity", "SOAP::SOAPString", [0, 1]],
      ["customerState", "SOAP::SOAPString", [0, 1]],
      ["customerZIP", "SOAP::SOAPString", [0, 1]],
      ["customerEmail", "SOAP::SOAPString", [0, 1]],
      ["customerPhone", "SOAP::SOAPString", [0, 1]],
      ["customerProfileOrderOverideInd", "SOAP::SOAPString"],
      ["customerProfileFromOrderInd", "SOAP::SOAPString"],
      ["orderDefaultDescription", "SOAP::SOAPString", [0, 1]],
      ["orderDefaultAmount", "SOAP::SOAPString", [0, 1]],
      ["customerAccountType", "SOAP::SOAPString"],
      ["ccAccountNum", "SOAP::SOAPString", [0, 1]],
      ["ccExp", "SOAP::SOAPString", [0, 1]],
      ["ecpCheckDDA", "SOAP::SOAPString", [0, 1]],
      ["ecpBankAcctType", "SOAP::SOAPString", [0, 1]],
      ["ecpCheckRT", "SOAP::SOAPString", [0, 1]],
      ["ecpDelvMethod", "SOAP::SOAPString", [0, 1]],
      ["switchSoloCardStartDate", "SOAP::SOAPString", [0, 1]],
      ["switchSoloIssueNum", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => ProfileChangeElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "ProfileChangeElement"),
    :schema_element => [
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["customerName", "SOAP::SOAPString", [0, 1]],
      ["customerRefNum", "SOAP::SOAPString"],
      ["customerAddress1", "SOAP::SOAPString", [0, 1]],
      ["customerAddress2", "SOAP::SOAPString", [0, 1]],
      ["customerCity", "SOAP::SOAPString", [0, 1]],
      ["customerState", "SOAP::SOAPString", [0, 1]],
      ["customerZIP", "SOAP::SOAPString", [0, 1]],
      ["customerEmail", "SOAP::SOAPString", [0, 1]],
      ["customerPhone", "SOAP::SOAPString", [0, 1]],
      ["customerProfileOrderOverideInd", "SOAP::SOAPString", [0, 1]],
      ["orderDefaultDescription", "SOAP::SOAPString", [0, 1]],
      ["orderDefaultAmount", "SOAP::SOAPString", [0, 1]],
      ["customerAccountType", "SOAP::SOAPString", [0, 1]],
      ["ccAccountNum", "SOAP::SOAPString", [0, 1]],
      ["ccExp", "SOAP::SOAPString", [0, 1]],
      ["ecpCheckDDA", "SOAP::SOAPString", [0, 1]],
      ["ecpBankAcctType", "SOAP::SOAPString", [0, 1]],
      ["ecpCheckRT", "SOAP::SOAPString", [0, 1]],
      ["ecpDelvMethod", "SOAP::SOAPString", [0, 1]],
      ["switchSoloCardStartDate", "SOAP::SOAPString", [0, 1]],
      ["switchSoloIssueNum", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => ProfileDeleteElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "ProfileDeleteElement"),
    :schema_element => [
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["customerName", "SOAP::SOAPString"],
      ["customerRefNum", "SOAP::SOAPString"]
    ]
  )

  LiteralRegistry.register(
    :class => ProfileFetchElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "ProfileFetchElement"),
    :schema_element => [
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["customerName", "SOAP::SOAPString"],
      ["customerRefNum", "SOAP::SOAPString"]
    ]
  )

  LiteralRegistry.register(
    :class => FlexCacheElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "FlexCacheElement"),
    :schema_element => [
      ["bin", "SOAP::SOAPString"],
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["ccAccountNum", "SOAP::SOAPString", [0, 1]],
      ["orderID", "SOAP::SOAPString", [0, 1]],
      ["amount", "SOAP::SOAPString", [0, 1]],
      ["ccCardVerifyNum", "SOAP::SOAPString", [0, 1]],
      ["comments", "SOAP::SOAPString", [0, 1]],
      ["shippingRef", "SOAP::SOAPString", [0, 1]],
      ["industryType", "SOAP::SOAPString", [0, 1]],
      ["flexAutoAuthInd", "SOAP::SOAPString", [0, 1]],
      ["flexPartialRedemptionInd", "SOAP::SOAPString", [0, 1]],
      ["flexAction", "SOAP::SOAPString", [0, 1]],
      ["startAccountNum", "SOAP::SOAPString", [0, 1]],
      ["activationCount", "SOAP::SOAPString", [0, 1]],
      ["txRefNum", "SOAP::SOAPString", [0, 1]],
      ["sequenceNumber", "SOAP::SOAPString", [0, 1]],
      ["retryTrace", "SOAP::SOAPString", [0, 1]],
      ["employeeNumber", "SOAP::SOAPString", [0, 1]],
      ["magStripeTrack1", "SOAP::SOAPString", [0, 1]],
      ["magStripeTrack2", "SOAP::SOAPString", [0, 1]],
      ["retailTransInfo", "SOAP::SOAPString", [0, 1]],
      ["priorAuthCd", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => FlexCacheResponseElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "FlexCacheResponseElement"),
    :schema_element => [
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["orderID", "SOAP::SOAPString"],
      ["ccAccountNum", "SOAP::SOAPString"],
      ["startAccountNum", "SOAP::SOAPString"],
      ["flexAcctBalance", "SOAP::SOAPString"],
      ["flexAcctPriorBalance", "SOAP::SOAPString"],
      ["flexAcctExpireDate", "SOAP::SOAPString"],
      ["cardType", "SOAP::SOAPString"],
      ["txRefIdx", "SOAP::SOAPString"],
      ["txRefNum", "SOAP::SOAPString"],
      ["procStatus", "SOAP::SOAPString"],
      ["procStatusMessage", "SOAP::SOAPString"],
      ["approvalStatus", "SOAP::SOAPString"],
      ["authorizationCode", "SOAP::SOAPString"],
      ["respCode", "SOAP::SOAPString"],
      ["batchFailedAcctNum", "SOAP::SOAPString"],
      ["flexRequestedAmount", "SOAP::SOAPString"],
      ["flexRedeemedAmt", "SOAP::SOAPString"],
      ["flexHostTrace", "SOAP::SOAPString"],
      ["flexAction", "SOAP::SOAPString"],
      ["respDateTime", "SOAP::SOAPString"],
      ["autoAuthTxRefIdx", "SOAP::SOAPString"],
      ["autoAuthTxRefNum", "SOAP::SOAPString"],
      ["autoAuthProcStatus", "SOAP::SOAPString"],
      ["autoAuthStatusMsg", "SOAP::SOAPString"],
      ["autoAuthApprovalStatus", "SOAP::SOAPString"],
      ["autoAuthFlexRedeemedAmt", "SOAP::SOAPString"],
      ["autoAuthResponseCodes", "SOAP::SOAPString"],
      ["autoAuthFlexHostTrace", "SOAP::SOAPString"],
      ["autoAuthFlexAction", "SOAP::SOAPString"],
      ["autoAuthRespTime", "SOAP::SOAPString"],
      ["retryTrace", "SOAP::SOAPString"],
      ["retryAttempCount", "SOAP::SOAPString"],
      ["lastRetryDate", "SOAP::SOAPString"],
      ["cvvRespCode", "SOAP::SOAPString"],
      ["superBlockID", "SOAP::SOAPString"]
    ]
  )

  LiteralRegistry.register(
    :class => UnmarkElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "UnmarkElement"),
    :schema_element => [
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["bin", "SOAP::SOAPString"],
      ["txRefNum", "SOAP::SOAPString"],
      ["txRefIdx", "SOAP::SOAPString"],
      ["orderID", "SOAP::SOAPString"],
      ["retryTrace", "SOAP::SOAPString", [0, 1]],
      ["retryAttempCount", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => UnmarkResponseElement,
    :schema_type => XSD::QName.new(NsPaymentechGateway, "UnmarkResponseElement"),
    :schema_element => [
      ["merchantID", "SOAP::SOAPString"],
      ["terminalID", "SOAP::SOAPString"],
      ["bin", "SOAP::SOAPString"],
      ["orderID", "SOAP::SOAPString"],
      ["txRefNum", "SOAP::SOAPString"],
      ["txRefIdx", "SOAP::SOAPString"],
      ["procStatus", "SOAP::SOAPString"],
      ["procStatusMessage", "SOAP::SOAPString"],
      ["retryTrace", "SOAP::SOAPString"],
      ["retryAttempCount", "SOAP::SOAPString"],
      ["lastRetryDate", "SOAP::SOAPString"]
    ]
  )

  LiteralRegistry.register(
    :class => NewOrder,
    :schema_name => XSD::QName.new(NsPaymentechGateway, "NewOrder"),
    :schema_element => [
      ["newOrderRequest", "NewOrderRequestElement"]
    ]
  )

  LiteralRegistry.register(
    :class => NewOrderResponse,
    :schema_name => XSD::QName.new(NsPaymentechGateway, "NewOrderResponse"),
    :schema_element => [
      ["v_return", ["NewOrderResponseElement", XSD::QName.new(NsPaymentechGateway, "return")]]
    ]
  )

  LiteralRegistry.register(
    :class => MarkForCapture,
    :schema_name => XSD::QName.new(NsPaymentechGateway, "MarkForCapture"),
    :schema_element => [
      ["markForCaptureRequest", "MarkForCaptureElement"]
    ]
  )

  LiteralRegistry.register(
    :class => MarkForCaptureResponse,
    :schema_name => XSD::QName.new(NsPaymentechGateway, "MarkForCaptureResponse"),
    :schema_element => [
      ["v_return", ["MarkForCaptureResponseElement", XSD::QName.new(NsPaymentechGateway, "return")]]
    ]
  )

  LiteralRegistry.register(
    :class => Reversal,
    :schema_name => XSD::QName.new(NsPaymentechGateway, "Reversal"),
    :schema_element => [
      ["reversalRequest", "ReversalElement"]
    ]
  )

  LiteralRegistry.register(
    :class => ReversalResponse,
    :schema_name => XSD::QName.new(NsPaymentechGateway, "ReversalResponse"),
    :schema_element => [
      ["v_return", ["ReversalResponseElement", XSD::QName.new(NsPaymentechGateway, "return")]]
    ]
  )

  LiteralRegistry.register(
    :class => EndOfDay,
    :schema_name => XSD::QName.new(NsPaymentechGateway, "EndOfDay"),
    :schema_element => [
      ["endOfDayRequest", "EndOfDayElement"]
    ]
  )

  LiteralRegistry.register(
    :class => EndOfDayResponse,
    :schema_name => XSD::QName.new(NsPaymentechGateway, "EndOfDayResponse"),
    :schema_element => [
      ["v_return", ["EndOfDayResponseElement", XSD::QName.new(NsPaymentechGateway, "return")]]
    ]
  )

  LiteralRegistry.register(
    :class => ProfileAdd,
    :schema_name => XSD::QName.new(NsPaymentechGateway, "ProfileAdd"),
    :schema_element => [
      ["profileAddRequest", "ProfileAddElement"]
    ]
  )

  LiteralRegistry.register(
    :class => ProfileAddResponse,
    :schema_name => XSD::QName.new(NsPaymentechGateway, "ProfileAddResponse"),
    :schema_element => [
      ["v_return", ["ProfileResponseElement", XSD::QName.new(NsPaymentechGateway, "return")]]
    ]
  )

  LiteralRegistry.register(
    :class => ProfileChange,
    :schema_name => XSD::QName.new(NsPaymentechGateway, "ProfileChange"),
    :schema_element => [
      ["profileChangeRequest", "ProfileChangeElement"]
    ]
  )

  LiteralRegistry.register(
    :class => ProfileChangeResponse,
    :schema_name => XSD::QName.new(NsPaymentechGateway, "ProfileChangeResponse"),
    :schema_element => [
      ["v_return", ["ProfileResponseElement", XSD::QName.new(NsPaymentechGateway, "return")]]
    ]
  )

  LiteralRegistry.register(
    :class => ProfileDelete,
    :schema_name => XSD::QName.new(NsPaymentechGateway, "ProfileDelete"),
    :schema_element => [
      ["profileDeleteRequest", "ProfileDeleteElement"]
    ]
  )

  LiteralRegistry.register(
    :class => ProfileDeleteResponse,
    :schema_name => XSD::QName.new(NsPaymentechGateway, "ProfileDeleteResponse"),
    :schema_element => [
      ["v_return", ["ProfileResponseElement", XSD::QName.new(NsPaymentechGateway, "return")]]
    ]
  )

  LiteralRegistry.register(
    :class => ProfileFetch,
    :schema_name => XSD::QName.new(NsPaymentechGateway, "ProfileFetch"),
    :schema_element => [
      ["profileFetchRequest", "ProfileFetchElement"]
    ]
  )

  LiteralRegistry.register(
    :class => ProfileFetchResponse,
    :schema_name => XSD::QName.new(NsPaymentechGateway, "ProfileFetchResponse"),
    :schema_element => [
      ["v_return", ["ProfileResponseElement", XSD::QName.new(NsPaymentechGateway, "return")]]
    ]
  )

  LiteralRegistry.register(
    :class => FlexCache,
    :schema_name => XSD::QName.new(NsPaymentechGateway, "FlexCache"),
    :schema_element => [
      ["flexCacheRequest", "FlexCacheElement"]
    ]
  )

  LiteralRegistry.register(
    :class => FlexCacheResponse,
    :schema_name => XSD::QName.new(NsPaymentechGateway, "FlexCacheResponse"),
    :schema_element => [
      ["v_return", ["FlexCacheResponseElement", XSD::QName.new(NsPaymentechGateway, "return")]]
    ]
  )

  LiteralRegistry.register(
    :class => Unmark,
    :schema_name => XSD::QName.new(NsPaymentechGateway, "Unmark"),
    :schema_element => [
      ["unmarkRequest", "UnmarkElement"]
    ]
  )

  LiteralRegistry.register(
    :class => UnmarkResponse,
    :schema_name => XSD::QName.new(NsPaymentechGateway, "UnmarkResponse"),
    :schema_element => [
      ["v_return", ["UnmarkResponseElement", XSD::QName.new(NsPaymentechGateway, "return")]]
    ]
  )
end
