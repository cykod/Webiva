require 'xsd/qname'

# {urn:ws.paymentech.net/PaymentechGateway}PC3LineItem
#   pCard3DtlIndex - SOAP::SOAPString
#   pCard3DtlDesc - SOAP::SOAPString
#   pCard3DtlProdCd - SOAP::SOAPString
#   pCard3DtlQty - SOAP::SOAPString
#   pCard3DtlUOM - SOAP::SOAPString
#   pCard3DtlTaxAmt - SOAP::SOAPString
#   pCard3DtlTaxRate - SOAP::SOAPString
#   pCard3Dtllinetot - SOAP::SOAPString
#   pCard3DtlDisc - SOAP::SOAPString
#   pCard3DtlCommCd - SOAP::SOAPString
#   pCard3DtlUnitCost - SOAP::SOAPString
#   pCard3DtlGrossNet - SOAP::SOAPString
#   pCard3DtlTaxType - SOAP::SOAPString
#   pCard3DtlDiscInd - SOAP::SOAPString
#   pCard3DtlDebitInd - SOAP::SOAPString
class PC3LineItem
  attr_accessor :pCard3DtlIndex
  attr_accessor :pCard3DtlDesc
  attr_accessor :pCard3DtlProdCd
  attr_accessor :pCard3DtlQty
  attr_accessor :pCard3DtlUOM
  attr_accessor :pCard3DtlTaxAmt
  attr_accessor :pCard3DtlTaxRate
  attr_accessor :pCard3Dtllinetot
  attr_accessor :pCard3DtlDisc
  attr_accessor :pCard3DtlCommCd
  attr_accessor :pCard3DtlUnitCost
  attr_accessor :pCard3DtlGrossNet
  attr_accessor :pCard3DtlTaxType
  attr_accessor :pCard3DtlDiscInd
  attr_accessor :pCard3DtlDebitInd

  def initialize(pCard3DtlIndex = nil, pCard3DtlDesc = nil, pCard3DtlProdCd = nil, pCard3DtlQty = nil, pCard3DtlUOM = nil, pCard3DtlTaxAmt = nil, pCard3DtlTaxRate = nil, pCard3Dtllinetot = nil, pCard3DtlDisc = nil, pCard3DtlCommCd = nil, pCard3DtlUnitCost = nil, pCard3DtlGrossNet = nil, pCard3DtlTaxType = nil, pCard3DtlDiscInd = nil, pCard3DtlDebitInd = nil)
    @pCard3DtlIndex = pCard3DtlIndex
    @pCard3DtlDesc = pCard3DtlDesc
    @pCard3DtlProdCd = pCard3DtlProdCd
    @pCard3DtlQty = pCard3DtlQty
    @pCard3DtlUOM = pCard3DtlUOM
    @pCard3DtlTaxAmt = pCard3DtlTaxAmt
    @pCard3DtlTaxRate = pCard3DtlTaxRate
    @pCard3Dtllinetot = pCard3Dtllinetot
    @pCard3DtlDisc = pCard3DtlDisc
    @pCard3DtlCommCd = pCard3DtlCommCd
    @pCard3DtlUnitCost = pCard3DtlUnitCost
    @pCard3DtlGrossNet = pCard3DtlGrossNet
    @pCard3DtlTaxType = pCard3DtlTaxType
    @pCard3DtlDiscInd = pCard3DtlDiscInd
    @pCard3DtlDebitInd = pCard3DtlDebitInd
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}PC3LineItemArray
class PC3LineItemArray < ::Array
end

# {urn:ws.paymentech.net/PaymentechGateway}NewOrderRequestElement
#   industryType - SOAP::SOAPString
#   transType - SOAP::SOAPString
#   bin - SOAP::SOAPString
#   merchantID - SOAP::SOAPString
#   terminalID - SOAP::SOAPString
#   cardBrand - SOAP::SOAPString
#   ccAccountNum - SOAP::SOAPString
#   ccExp - SOAP::SOAPString
#   ccCardVerifyPresenceInd - SOAP::SOAPString
#   ccCardVerifyNum - SOAP::SOAPString
#   switchSoloIssueNum - SOAP::SOAPString
#   switchSoloCardStartDate - SOAP::SOAPString
#   ecpCheckRT - SOAP::SOAPString
#   ecpCheckDDA - SOAP::SOAPString
#   ecpBankAcctType - SOAP::SOAPString
#   ecpAuthMethod - SOAP::SOAPString
#   ecpDelvMethod - SOAP::SOAPString
#   avsZip - SOAP::SOAPString
#   avsAddress1 - SOAP::SOAPString
#   avsAddress2 - SOAP::SOAPString
#   avsCity - SOAP::SOAPString
#   avsState - SOAP::SOAPString
#   avsName - SOAP::SOAPString
#   avsCountryCode - SOAP::SOAPString
#   avsPhone - SOAP::SOAPString
#   useCustomerRefNum - SOAP::SOAPString
#   addProfileFromOrder - SOAP::SOAPString
#   customerRefNum - SOAP::SOAPString
#   profileOrderOverideInd - SOAP::SOAPString
#   authenticationECIInd - SOAP::SOAPString
#   verifyByVisaCAVV - SOAP::SOAPString
#   verifyByVisaXID - SOAP::SOAPString
#   priorAuthCd - SOAP::SOAPString
#   orderID - SOAP::SOAPString
#   amount - SOAP::SOAPString
#   comments - SOAP::SOAPString
#   shippingRef - SOAP::SOAPString
#   taxInd - SOAP::SOAPString
#   taxAmount - SOAP::SOAPString
#   amexTranAdvAddn1 - SOAP::SOAPString
#   amexTranAdvAddn2 - SOAP::SOAPString
#   amexTranAdvAddn3 - SOAP::SOAPString
#   amexTranAdvAddn4 - SOAP::SOAPString
#   mcSecureCodeAAV - SOAP::SOAPString
#   softDescMercName - SOAP::SOAPString
#   softDescProdDesc - SOAP::SOAPString
#   softDescMercCity - SOAP::SOAPString
#   softDescMercPhone - SOAP::SOAPString
#   softDescMercURL - SOAP::SOAPString
#   softDescMercEmail - SOAP::SOAPString
#   recurringInd - SOAP::SOAPString
#   retryTrace - SOAP::SOAPString
#   pCardOrderID - SOAP::SOAPString
#   pCardDestZip - SOAP::SOAPString
#   pCardDestName - SOAP::SOAPString
#   pCardDestAddress - SOAP::SOAPString
#   pCardDestAddress2 - SOAP::SOAPString
#   pCardDestCity - SOAP::SOAPString
#   pCardDestStateCd - SOAP::SOAPString
#   pCard3FreightAmt - SOAP::SOAPString
#   pCard3DutyAmt - SOAP::SOAPString
#   pCard3DestCountryCd - SOAP::SOAPString
#   pCard3ShipFromZip - SOAP::SOAPString
#   pCard3DiscAmt - SOAP::SOAPString
#   pCard3VATtaxAmt - SOAP::SOAPString
#   pCard3VATtaxRate - SOAP::SOAPString
#   pCard3AltTaxInd - SOAP::SOAPString
#   pCard3AltTaxAmt - SOAP::SOAPString
#   pCard3LineItemCount - SOAP::SOAPString
#   pCard3LineItems - PC3LineItemArray
#   magStripeTrack1 - SOAP::SOAPString
#   magStripeTrack2 - SOAP::SOAPString
#   retailTransInfo - SOAP::SOAPString
#   customerName - SOAP::SOAPString
#   customerEmail - SOAP::SOAPString
#   customerPhone - SOAP::SOAPString
#   cardPresentInd - SOAP::SOAPString
#   euddBankSortCode - SOAP::SOAPString
#   euddCountryCode - SOAP::SOAPString
#   euddRibCode - SOAP::SOAPString
#   bmlCustomerIP - SOAP::SOAPString
#   bmlCustomerEmail - SOAP::SOAPString
#   bmlShippingCost - SOAP::SOAPString
#   bmlTNCVersion - SOAP::SOAPString
#   bmlCustomerRegistrationDate - SOAP::SOAPString
#   bmlCustomerTypeFlag - SOAP::SOAPString
#   bmlItemCategory - SOAP::SOAPString
#   bmlPreapprovalInvitationNum - SOAP::SOAPString
#   bmlMerchantPromotionalCode - SOAP::SOAPString
#   bmlCustomerBirthDate - SOAP::SOAPString
#   bmlCustomerSSN - SOAP::SOAPString
#   bmlCustomerAnnualIncome - SOAP::SOAPString
#   bmlCustomerResidenceStatus - SOAP::SOAPString
#   bmlCustomerCheckingAccount - SOAP::SOAPString
#   bmlCustomerSavingsAccount - SOAP::SOAPString
#   bmlProductDeliveryType - SOAP::SOAPString
#   avsDestName - SOAP::SOAPString
#   avsDestAddress1 - SOAP::SOAPString
#   avsDestAddress2 - SOAP::SOAPString
#   avsDestCity - SOAP::SOAPString
#   avsDestState - SOAP::SOAPString
#   avsDestZip - SOAP::SOAPString
#   avsDestCountryCode - SOAP::SOAPString
#   avsDestPhoneNum - SOAP::SOAPString
#   debitBillerReferenceNumber - SOAP::SOAPString
class NewOrderRequestElement
  attr_accessor :industryType
  attr_accessor :transType
  attr_accessor :bin
  attr_accessor :merchantID
  attr_accessor :terminalID
  attr_accessor :cardBrand
  attr_accessor :ccAccountNum
  attr_accessor :ccExp
  attr_accessor :ccCardVerifyPresenceInd
  attr_accessor :ccCardVerifyNum
  attr_accessor :switchSoloIssueNum
  attr_accessor :switchSoloCardStartDate
  attr_accessor :ecpCheckRT
  attr_accessor :ecpCheckDDA
  attr_accessor :ecpBankAcctType
  attr_accessor :ecpAuthMethod
  attr_accessor :ecpDelvMethod
  attr_accessor :avsZip
  attr_accessor :avsAddress1
  attr_accessor :avsAddress2
  attr_accessor :avsCity
  attr_accessor :avsState
  attr_accessor :avsName
  attr_accessor :avsCountryCode
  attr_accessor :avsPhone
  attr_accessor :useCustomerRefNum
  attr_accessor :addProfileFromOrder
  attr_accessor :customerRefNum
  attr_accessor :profileOrderOverideInd
  attr_accessor :authenticationECIInd
  attr_accessor :verifyByVisaCAVV
  attr_accessor :verifyByVisaXID
  attr_accessor :priorAuthCd
  attr_accessor :orderID
  attr_accessor :amount
  attr_accessor :comments
  attr_accessor :shippingRef
  attr_accessor :taxInd
  attr_accessor :taxAmount
  attr_accessor :amexTranAdvAddn1
  attr_accessor :amexTranAdvAddn2
  attr_accessor :amexTranAdvAddn3
  attr_accessor :amexTranAdvAddn4
  attr_accessor :mcSecureCodeAAV
  attr_accessor :softDescMercName
  attr_accessor :softDescProdDesc
  attr_accessor :softDescMercCity
  attr_accessor :softDescMercPhone
  attr_accessor :softDescMercURL
  attr_accessor :softDescMercEmail
  attr_accessor :recurringInd
  attr_accessor :retryTrace
  attr_accessor :pCardOrderID
  attr_accessor :pCardDestZip
  attr_accessor :pCardDestName
  attr_accessor :pCardDestAddress
  attr_accessor :pCardDestAddress2
  attr_accessor :pCardDestCity
  attr_accessor :pCardDestStateCd
  attr_accessor :pCard3FreightAmt
  attr_accessor :pCard3DutyAmt
  attr_accessor :pCard3DestCountryCd
  attr_accessor :pCard3ShipFromZip
  attr_accessor :pCard3DiscAmt
  attr_accessor :pCard3VATtaxAmt
  attr_accessor :pCard3VATtaxRate
  attr_accessor :pCard3AltTaxInd
  attr_accessor :pCard3AltTaxAmt
  attr_accessor :pCard3LineItemCount
  attr_accessor :pCard3LineItems
  attr_accessor :magStripeTrack1
  attr_accessor :magStripeTrack2
  attr_accessor :retailTransInfo
  attr_accessor :customerName
  attr_accessor :customerEmail
  attr_accessor :customerPhone
  attr_accessor :cardPresentInd
  attr_accessor :euddBankSortCode
  attr_accessor :euddCountryCode
  attr_accessor :euddRibCode
  attr_accessor :bmlCustomerIP
  attr_accessor :bmlCustomerEmail
  attr_accessor :bmlShippingCost
  attr_accessor :bmlTNCVersion
  attr_accessor :bmlCustomerRegistrationDate
  attr_accessor :bmlCustomerTypeFlag
  attr_accessor :bmlItemCategory
  attr_accessor :bmlPreapprovalInvitationNum
  attr_accessor :bmlMerchantPromotionalCode
  attr_accessor :bmlCustomerBirthDate
  attr_accessor :bmlCustomerSSN
  attr_accessor :bmlCustomerAnnualIncome
  attr_accessor :bmlCustomerResidenceStatus
  attr_accessor :bmlCustomerCheckingAccount
  attr_accessor :bmlCustomerSavingsAccount
  attr_accessor :bmlProductDeliveryType
  attr_accessor :avsDestName
  attr_accessor :avsDestAddress1
  attr_accessor :avsDestAddress2
  attr_accessor :avsDestCity
  attr_accessor :avsDestState
  attr_accessor :avsDestZip
  attr_accessor :avsDestCountryCode
  attr_accessor :avsDestPhoneNum
  attr_accessor :debitBillerReferenceNumber

  def initialize(industryType = nil, transType = nil, bin = nil, merchantID = nil, terminalID = nil, cardBrand = nil, ccAccountNum = nil, ccExp = nil, ccCardVerifyPresenceInd = nil, ccCardVerifyNum = nil, switchSoloIssueNum = nil, switchSoloCardStartDate = nil, ecpCheckRT = nil, ecpCheckDDA = nil, ecpBankAcctType = nil, ecpAuthMethod = nil, ecpDelvMethod = nil, avsZip = nil, avsAddress1 = nil, avsAddress2 = nil, avsCity = nil, avsState = nil, avsName = nil, avsCountryCode = nil, avsPhone = nil, useCustomerRefNum = nil, addProfileFromOrder = nil, customerRefNum = nil, profileOrderOverideInd = nil, authenticationECIInd = nil, verifyByVisaCAVV = nil, verifyByVisaXID = nil, priorAuthCd = nil, orderID = nil, amount = nil, comments = nil, shippingRef = nil, taxInd = nil, taxAmount = nil, amexTranAdvAddn1 = nil, amexTranAdvAddn2 = nil, amexTranAdvAddn3 = nil, amexTranAdvAddn4 = nil, mcSecureCodeAAV = nil, softDescMercName = nil, softDescProdDesc = nil, softDescMercCity = nil, softDescMercPhone = nil, softDescMercURL = nil, softDescMercEmail = nil, recurringInd = nil, retryTrace = nil, pCardOrderID = nil, pCardDestZip = nil, pCardDestName = nil, pCardDestAddress = nil, pCardDestAddress2 = nil, pCardDestCity = nil, pCardDestStateCd = nil, pCard3FreightAmt = nil, pCard3DutyAmt = nil, pCard3DestCountryCd = nil, pCard3ShipFromZip = nil, pCard3DiscAmt = nil, pCard3VATtaxAmt = nil, pCard3VATtaxRate = nil, pCard3AltTaxInd = nil, pCard3AltTaxAmt = nil, pCard3LineItemCount = nil, pCard3LineItems = nil, magStripeTrack1 = nil, magStripeTrack2 = nil, retailTransInfo = nil, customerName = nil, customerEmail = nil, customerPhone = nil, cardPresentInd = nil, euddBankSortCode = nil, euddCountryCode = nil, euddRibCode = nil, bmlCustomerIP = nil, bmlCustomerEmail = nil, bmlShippingCost = nil, bmlTNCVersion = nil, bmlCustomerRegistrationDate = nil, bmlCustomerTypeFlag = nil, bmlItemCategory = nil, bmlPreapprovalInvitationNum = nil, bmlMerchantPromotionalCode = nil, bmlCustomerBirthDate = nil, bmlCustomerSSN = nil, bmlCustomerAnnualIncome = nil, bmlCustomerResidenceStatus = nil, bmlCustomerCheckingAccount = nil, bmlCustomerSavingsAccount = nil, bmlProductDeliveryType = nil, avsDestName = nil, avsDestAddress1 = nil, avsDestAddress2 = nil, avsDestCity = nil, avsDestState = nil, avsDestZip = nil, avsDestCountryCode = nil, avsDestPhoneNum = nil, debitBillerReferenceNumber = nil)
    @industryType = industryType
    @transType = transType
    @bin = bin
    @merchantID = merchantID
    @terminalID = terminalID
    @cardBrand = cardBrand
    @ccAccountNum = ccAccountNum
    @ccExp = ccExp
    @ccCardVerifyPresenceInd = ccCardVerifyPresenceInd
    @ccCardVerifyNum = ccCardVerifyNum
    @switchSoloIssueNum = switchSoloIssueNum
    @switchSoloCardStartDate = switchSoloCardStartDate
    @ecpCheckRT = ecpCheckRT
    @ecpCheckDDA = ecpCheckDDA
    @ecpBankAcctType = ecpBankAcctType
    @ecpAuthMethod = ecpAuthMethod
    @ecpDelvMethod = ecpDelvMethod
    @avsZip = avsZip
    @avsAddress1 = avsAddress1
    @avsAddress2 = avsAddress2
    @avsCity = avsCity
    @avsState = avsState
    @avsName = avsName
    @avsCountryCode = avsCountryCode
    @avsPhone = avsPhone
    @useCustomerRefNum = useCustomerRefNum
    @addProfileFromOrder = addProfileFromOrder
    @customerRefNum = customerRefNum
    @profileOrderOverideInd = profileOrderOverideInd
    @authenticationECIInd = authenticationECIInd
    @verifyByVisaCAVV = verifyByVisaCAVV
    @verifyByVisaXID = verifyByVisaXID
    @priorAuthCd = priorAuthCd
    @orderID = orderID
    @amount = amount
    @comments = comments
    @shippingRef = shippingRef
    @taxInd = taxInd
    @taxAmount = taxAmount
    @amexTranAdvAddn1 = amexTranAdvAddn1
    @amexTranAdvAddn2 = amexTranAdvAddn2
    @amexTranAdvAddn3 = amexTranAdvAddn3
    @amexTranAdvAddn4 = amexTranAdvAddn4
    @mcSecureCodeAAV = mcSecureCodeAAV
    @softDescMercName = softDescMercName
    @softDescProdDesc = softDescProdDesc
    @softDescMercCity = softDescMercCity
    @softDescMercPhone = softDescMercPhone
    @softDescMercURL = softDescMercURL
    @softDescMercEmail = softDescMercEmail
    @recurringInd = recurringInd
    @retryTrace = retryTrace
    @pCardOrderID = pCardOrderID
    @pCardDestZip = pCardDestZip
    @pCardDestName = pCardDestName
    @pCardDestAddress = pCardDestAddress
    @pCardDestAddress2 = pCardDestAddress2
    @pCardDestCity = pCardDestCity
    @pCardDestStateCd = pCardDestStateCd
    @pCard3FreightAmt = pCard3FreightAmt
    @pCard3DutyAmt = pCard3DutyAmt
    @pCard3DestCountryCd = pCard3DestCountryCd
    @pCard3ShipFromZip = pCard3ShipFromZip
    @pCard3DiscAmt = pCard3DiscAmt
    @pCard3VATtaxAmt = pCard3VATtaxAmt
    @pCard3VATtaxRate = pCard3VATtaxRate
    @pCard3AltTaxInd = pCard3AltTaxInd
    @pCard3AltTaxAmt = pCard3AltTaxAmt
    @pCard3LineItemCount = pCard3LineItemCount
    @pCard3LineItems = pCard3LineItems
    @magStripeTrack1 = magStripeTrack1
    @magStripeTrack2 = magStripeTrack2
    @retailTransInfo = retailTransInfo
    @customerName = customerName
    @customerEmail = customerEmail
    @customerPhone = customerPhone
    @cardPresentInd = cardPresentInd
    @euddBankSortCode = euddBankSortCode
    @euddCountryCode = euddCountryCode
    @euddRibCode = euddRibCode
    @bmlCustomerIP = bmlCustomerIP
    @bmlCustomerEmail = bmlCustomerEmail
    @bmlShippingCost = bmlShippingCost
    @bmlTNCVersion = bmlTNCVersion
    @bmlCustomerRegistrationDate = bmlCustomerRegistrationDate
    @bmlCustomerTypeFlag = bmlCustomerTypeFlag
    @bmlItemCategory = bmlItemCategory
    @bmlPreapprovalInvitationNum = bmlPreapprovalInvitationNum
    @bmlMerchantPromotionalCode = bmlMerchantPromotionalCode
    @bmlCustomerBirthDate = bmlCustomerBirthDate
    @bmlCustomerSSN = bmlCustomerSSN
    @bmlCustomerAnnualIncome = bmlCustomerAnnualIncome
    @bmlCustomerResidenceStatus = bmlCustomerResidenceStatus
    @bmlCustomerCheckingAccount = bmlCustomerCheckingAccount
    @bmlCustomerSavingsAccount = bmlCustomerSavingsAccount
    @bmlProductDeliveryType = bmlProductDeliveryType
    @avsDestName = avsDestName
    @avsDestAddress1 = avsDestAddress1
    @avsDestAddress2 = avsDestAddress2
    @avsDestCity = avsDestCity
    @avsDestState = avsDestState
    @avsDestZip = avsDestZip
    @avsDestCountryCode = avsDestCountryCode
    @avsDestPhoneNum = avsDestPhoneNum
    @debitBillerReferenceNumber = debitBillerReferenceNumber
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}NewOrderResponseElement
#   industryType - SOAP::SOAPString
#   transType - SOAP::SOAPString
#   bin - SOAP::SOAPString
#   merchantID - SOAP::SOAPString
#   terminalID - SOAP::SOAPString
#   cardBrand - SOAP::SOAPString
#   orderID - SOAP::SOAPString
#   txRefNum - SOAP::SOAPString
#   txRefIdx - SOAP::SOAPString
#   respDateTime - SOAP::SOAPString
#   procStatus - SOAP::SOAPString
#   approvalStatus - SOAP::SOAPString
#   respCode - SOAP::SOAPString
#   avsRespCode - SOAP::SOAPString
#   cvvRespCode - SOAP::SOAPString
#   authorizationCode - SOAP::SOAPString
#   mcRecurringAdvCode - SOAP::SOAPString
#   visaVbVRespCode - SOAP::SOAPString
#   procStatusMessage - SOAP::SOAPString
#   respCodeMessage - SOAP::SOAPString
#   hostRespCode - SOAP::SOAPString
#   hostAVSRespCode - SOAP::SOAPString
#   hostCVVRespCode - SOAP::SOAPString
#   retryTrace - SOAP::SOAPString
#   retryAttempCount - SOAP::SOAPString
#   lastRetryDate - SOAP::SOAPString
#   customerRefNum - SOAP::SOAPString
#   customerName - SOAP::SOAPString
#   profileProcStatus - SOAP::SOAPString
#   profileProcStatusMsg - SOAP::SOAPString
#   giftCardInd - SOAP::SOAPString
#   remainingBalance - SOAP::SOAPString
#   requestAmount - SOAP::SOAPString
#   redeemedAmount - SOAP::SOAPString
#   ccAccountNum - SOAP::SOAPString
#   debitBillerReferenceNumber - SOAP::SOAPString
class NewOrderResponseElement
  attr_accessor :industryType
  attr_accessor :transType
  attr_accessor :bin
  attr_accessor :merchantID
  attr_accessor :terminalID
  attr_accessor :cardBrand
  attr_accessor :orderID
  attr_accessor :txRefNum
  attr_accessor :txRefIdx
  attr_accessor :respDateTime
  attr_accessor :procStatus
  attr_accessor :approvalStatus
  attr_accessor :respCode
  attr_accessor :avsRespCode
  attr_accessor :cvvRespCode
  attr_accessor :authorizationCode
  attr_accessor :mcRecurringAdvCode
  attr_accessor :visaVbVRespCode
  attr_accessor :procStatusMessage
  attr_accessor :respCodeMessage
  attr_accessor :hostRespCode
  attr_accessor :hostAVSRespCode
  attr_accessor :hostCVVRespCode
  attr_accessor :retryTrace
  attr_accessor :retryAttempCount
  attr_accessor :lastRetryDate
  attr_accessor :customerRefNum
  attr_accessor :customerName
  attr_accessor :profileProcStatus
  attr_accessor :profileProcStatusMsg
  attr_accessor :giftCardInd
  attr_accessor :remainingBalance
  attr_accessor :requestAmount
  attr_accessor :redeemedAmount
  attr_accessor :ccAccountNum
  attr_accessor :debitBillerReferenceNumber

  def initialize(industryType = nil, transType = nil, bin = nil, merchantID = nil, terminalID = nil, cardBrand = nil, orderID = nil, txRefNum = nil, txRefIdx = nil, respDateTime = nil, procStatus = nil, approvalStatus = nil, respCode = nil, avsRespCode = nil, cvvRespCode = nil, authorizationCode = nil, mcRecurringAdvCode = nil, visaVbVRespCode = nil, procStatusMessage = nil, respCodeMessage = nil, hostRespCode = nil, hostAVSRespCode = nil, hostCVVRespCode = nil, retryTrace = nil, retryAttempCount = nil, lastRetryDate = nil, customerRefNum = nil, customerName = nil, profileProcStatus = nil, profileProcStatusMsg = nil, giftCardInd = nil, remainingBalance = nil, requestAmount = nil, redeemedAmount = nil, ccAccountNum = nil, debitBillerReferenceNumber = nil)
    @industryType = industryType
    @transType = transType
    @bin = bin
    @merchantID = merchantID
    @terminalID = terminalID
    @cardBrand = cardBrand
    @orderID = orderID
    @txRefNum = txRefNum
    @txRefIdx = txRefIdx
    @respDateTime = respDateTime
    @procStatus = procStatus
    @approvalStatus = approvalStatus
    @respCode = respCode
    @avsRespCode = avsRespCode
    @cvvRespCode = cvvRespCode
    @authorizationCode = authorizationCode
    @mcRecurringAdvCode = mcRecurringAdvCode
    @visaVbVRespCode = visaVbVRespCode
    @procStatusMessage = procStatusMessage
    @respCodeMessage = respCodeMessage
    @hostRespCode = hostRespCode
    @hostAVSRespCode = hostAVSRespCode
    @hostCVVRespCode = hostCVVRespCode
    @retryTrace = retryTrace
    @retryAttempCount = retryAttempCount
    @lastRetryDate = lastRetryDate
    @customerRefNum = customerRefNum
    @customerName = customerName
    @profileProcStatus = profileProcStatus
    @profileProcStatusMsg = profileProcStatusMsg
    @giftCardInd = giftCardInd
    @remainingBalance = remainingBalance
    @requestAmount = requestAmount
    @redeemedAmount = redeemedAmount
    @ccAccountNum = ccAccountNum
    @debitBillerReferenceNumber = debitBillerReferenceNumber
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}MarkForCaptureElement
#   orderID - SOAP::SOAPString
#   amount - SOAP::SOAPString
#   taxInd - SOAP::SOAPString
#   taxAmount - SOAP::SOAPString
#   bin - SOAP::SOAPString
#   merchantID - SOAP::SOAPString
#   terminalID - SOAP::SOAPString
#   txRefNum - SOAP::SOAPString
#   retryTrace - SOAP::SOAPString
#   pCardOrderID - SOAP::SOAPString
#   pCardDestZip - SOAP::SOAPString
#   pCardDestName - SOAP::SOAPString
#   pCardDestAddress - SOAP::SOAPString
#   pCardDestAddress2 - SOAP::SOAPString
#   pCardDestCity - SOAP::SOAPString
#   pCardDestStateCd - SOAP::SOAPString
#   amexTranAdvAddn1 - SOAP::SOAPString
#   amexTranAdvAddn2 - SOAP::SOAPString
#   amexTranAdvAddn3 - SOAP::SOAPString
#   amexTranAdvAddn4 - SOAP::SOAPString
#   pCard3FreightAmt - SOAP::SOAPString
#   pCard3DutyAmt - SOAP::SOAPString
#   pCard3DestCountryCd - SOAP::SOAPString
#   pCard3ShipFromZip - SOAP::SOAPString
#   pCard3DiscAmt - SOAP::SOAPString
#   pCard3VATtaxAmt - SOAP::SOAPString
#   pCard3VATtaxRate - SOAP::SOAPString
#   pCard3AltTaxInd - SOAP::SOAPString
#   pCard3AltTaxAmt - SOAP::SOAPString
#   pCard3LineItemCount - SOAP::SOAPString
#   pCard3LineItems - PC3LineItemArray
class MarkForCaptureElement
  attr_accessor :orderID
  attr_accessor :amount
  attr_accessor :taxInd
  attr_accessor :taxAmount
  attr_accessor :bin
  attr_accessor :merchantID
  attr_accessor :terminalID
  attr_accessor :txRefNum
  attr_accessor :retryTrace
  attr_accessor :pCardOrderID
  attr_accessor :pCardDestZip
  attr_accessor :pCardDestName
  attr_accessor :pCardDestAddress
  attr_accessor :pCardDestAddress2
  attr_accessor :pCardDestCity
  attr_accessor :pCardDestStateCd
  attr_accessor :amexTranAdvAddn1
  attr_accessor :amexTranAdvAddn2
  attr_accessor :amexTranAdvAddn3
  attr_accessor :amexTranAdvAddn4
  attr_accessor :pCard3FreightAmt
  attr_accessor :pCard3DutyAmt
  attr_accessor :pCard3DestCountryCd
  attr_accessor :pCard3ShipFromZip
  attr_accessor :pCard3DiscAmt
  attr_accessor :pCard3VATtaxAmt
  attr_accessor :pCard3VATtaxRate
  attr_accessor :pCard3AltTaxInd
  attr_accessor :pCard3AltTaxAmt
  attr_accessor :pCard3LineItemCount
  attr_accessor :pCard3LineItems

  def initialize(orderID = nil, amount = nil, taxInd = nil, taxAmount = nil, bin = nil, merchantID = nil, terminalID = nil, txRefNum = nil, retryTrace = nil, pCardOrderID = nil, pCardDestZip = nil, pCardDestName = nil, pCardDestAddress = nil, pCardDestAddress2 = nil, pCardDestCity = nil, pCardDestStateCd = nil, amexTranAdvAddn1 = nil, amexTranAdvAddn2 = nil, amexTranAdvAddn3 = nil, amexTranAdvAddn4 = nil, pCard3FreightAmt = nil, pCard3DutyAmt = nil, pCard3DestCountryCd = nil, pCard3ShipFromZip = nil, pCard3DiscAmt = nil, pCard3VATtaxAmt = nil, pCard3VATtaxRate = nil, pCard3AltTaxInd = nil, pCard3AltTaxAmt = nil, pCard3LineItemCount = nil, pCard3LineItems = nil)
    @orderID = orderID
    @amount = amount
    @taxInd = taxInd
    @taxAmount = taxAmount
    @bin = bin
    @merchantID = merchantID
    @terminalID = terminalID
    @txRefNum = txRefNum
    @retryTrace = retryTrace
    @pCardOrderID = pCardOrderID
    @pCardDestZip = pCardDestZip
    @pCardDestName = pCardDestName
    @pCardDestAddress = pCardDestAddress
    @pCardDestAddress2 = pCardDestAddress2
    @pCardDestCity = pCardDestCity
    @pCardDestStateCd = pCardDestStateCd
    @amexTranAdvAddn1 = amexTranAdvAddn1
    @amexTranAdvAddn2 = amexTranAdvAddn2
    @amexTranAdvAddn3 = amexTranAdvAddn3
    @amexTranAdvAddn4 = amexTranAdvAddn4
    @pCard3FreightAmt = pCard3FreightAmt
    @pCard3DutyAmt = pCard3DutyAmt
    @pCard3DestCountryCd = pCard3DestCountryCd
    @pCard3ShipFromZip = pCard3ShipFromZip
    @pCard3DiscAmt = pCard3DiscAmt
    @pCard3VATtaxAmt = pCard3VATtaxAmt
    @pCard3VATtaxRate = pCard3VATtaxRate
    @pCard3AltTaxInd = pCard3AltTaxInd
    @pCard3AltTaxAmt = pCard3AltTaxAmt
    @pCard3LineItemCount = pCard3LineItemCount
    @pCard3LineItems = pCard3LineItems
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}MarkForCaptureResponseElement
#   bin - SOAP::SOAPString
#   merchantID - SOAP::SOAPString
#   terminalID - SOAP::SOAPString
#   orderID - SOAP::SOAPString
#   txRefNum - SOAP::SOAPString
#   txRefIdx - SOAP::SOAPString
#   splitTxRefIdx - SOAP::SOAPString
#   amount - SOAP::SOAPString
#   respDateTime - SOAP::SOAPString
#   procStatus - SOAP::SOAPString
#   procStatusMessage - SOAP::SOAPString
#   retryTrace - SOAP::SOAPString
#   retryAttempCount - SOAP::SOAPString
#   lastRetryDate - SOAP::SOAPString
class MarkForCaptureResponseElement
  attr_accessor :bin
  attr_accessor :merchantID
  attr_accessor :terminalID
  attr_accessor :orderID
  attr_accessor :txRefNum
  attr_accessor :txRefIdx
  attr_accessor :splitTxRefIdx
  attr_accessor :amount
  attr_accessor :respDateTime
  attr_accessor :procStatus
  attr_accessor :procStatusMessage
  attr_accessor :retryTrace
  attr_accessor :retryAttempCount
  attr_accessor :lastRetryDate

  def initialize(bin = nil, merchantID = nil, terminalID = nil, orderID = nil, txRefNum = nil, txRefIdx = nil, splitTxRefIdx = nil, amount = nil, respDateTime = nil, procStatus = nil, procStatusMessage = nil, retryTrace = nil, retryAttempCount = nil, lastRetryDate = nil)
    @bin = bin
    @merchantID = merchantID
    @terminalID = terminalID
    @orderID = orderID
    @txRefNum = txRefNum
    @txRefIdx = txRefIdx
    @splitTxRefIdx = splitTxRefIdx
    @amount = amount
    @respDateTime = respDateTime
    @procStatus = procStatus
    @procStatusMessage = procStatusMessage
    @retryTrace = retryTrace
    @retryAttempCount = retryAttempCount
    @lastRetryDate = lastRetryDate
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}ReversalElement
#   txRefNum - SOAP::SOAPString
#   txRefIdx - SOAP::SOAPString
#   adjustedAmount - SOAP::SOAPString
#   orderID - SOAP::SOAPString
#   bin - SOAP::SOAPString
#   merchantID - SOAP::SOAPString
#   terminalID - SOAP::SOAPString
#   retryTrace - SOAP::SOAPString
class ReversalElement
  attr_accessor :txRefNum
  attr_accessor :txRefIdx
  attr_accessor :adjustedAmount
  attr_accessor :orderID
  attr_accessor :bin
  attr_accessor :merchantID
  attr_accessor :terminalID
  attr_accessor :retryTrace

  def initialize(txRefNum = nil, txRefIdx = nil, adjustedAmount = nil, orderID = nil, bin = nil, merchantID = nil, terminalID = nil, retryTrace = nil)
    @txRefNum = txRefNum
    @txRefIdx = txRefIdx
    @adjustedAmount = adjustedAmount
    @orderID = orderID
    @bin = bin
    @merchantID = merchantID
    @terminalID = terminalID
    @retryTrace = retryTrace
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}ReversalResponseElement
#   outstandingAmt - SOAP::SOAPString
#   bin - SOAP::SOAPString
#   merchantID - SOAP::SOAPString
#   terminalID - SOAP::SOAPString
#   orderID - SOAP::SOAPString
#   txRefNum - SOAP::SOAPString
#   txRefIdx - SOAP::SOAPString
#   respDateTime - SOAP::SOAPString
#   procStatus - SOAP::SOAPString
#   procStatusMessage - SOAP::SOAPString
#   retryTrace - SOAP::SOAPString
#   retryAttempCount - SOAP::SOAPString
#   lastRetryDate - SOAP::SOAPString
class ReversalResponseElement
  attr_accessor :outstandingAmt
  attr_accessor :bin
  attr_accessor :merchantID
  attr_accessor :terminalID
  attr_accessor :orderID
  attr_accessor :txRefNum
  attr_accessor :txRefIdx
  attr_accessor :respDateTime
  attr_accessor :procStatus
  attr_accessor :procStatusMessage
  attr_accessor :retryTrace
  attr_accessor :retryAttempCount
  attr_accessor :lastRetryDate

  def initialize(outstandingAmt = nil, bin = nil, merchantID = nil, terminalID = nil, orderID = nil, txRefNum = nil, txRefIdx = nil, respDateTime = nil, procStatus = nil, procStatusMessage = nil, retryTrace = nil, retryAttempCount = nil, lastRetryDate = nil)
    @outstandingAmt = outstandingAmt
    @bin = bin
    @merchantID = merchantID
    @terminalID = terminalID
    @orderID = orderID
    @txRefNum = txRefNum
    @txRefIdx = txRefIdx
    @respDateTime = respDateTime
    @procStatus = procStatus
    @procStatusMessage = procStatusMessage
    @retryTrace = retryTrace
    @retryAttempCount = retryAttempCount
    @lastRetryDate = lastRetryDate
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}EndOfDayElement
#   bin - SOAP::SOAPString
#   merchantID - SOAP::SOAPString
#   terminalID - SOAP::SOAPString
#   settleRejectedHoldingBin - SOAP::SOAPString
class EndOfDayElement
  attr_accessor :bin
  attr_accessor :merchantID
  attr_accessor :terminalID
  attr_accessor :settleRejectedHoldingBin

  def initialize(bin = nil, merchantID = nil, terminalID = nil, settleRejectedHoldingBin = nil)
    @bin = bin
    @merchantID = merchantID
    @terminalID = terminalID
    @settleRejectedHoldingBin = settleRejectedHoldingBin
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}EndOfDayResponseElement
#   bin - SOAP::SOAPString
#   merchantID - SOAP::SOAPString
#   terminalID - SOAP::SOAPString
#   procStatus - SOAP::SOAPString
#   batchSeqNum - SOAP::SOAPString
#   procStatusMessage - SOAP::SOAPString
class EndOfDayResponseElement
  attr_accessor :bin
  attr_accessor :merchantID
  attr_accessor :terminalID
  attr_accessor :procStatus
  attr_accessor :batchSeqNum
  attr_accessor :procStatusMessage

  def initialize(bin = nil, merchantID = nil, terminalID = nil, procStatus = nil, batchSeqNum = nil, procStatusMessage = nil)
    @bin = bin
    @merchantID = merchantID
    @terminalID = terminalID
    @procStatus = procStatus
    @batchSeqNum = batchSeqNum
    @procStatusMessage = procStatusMessage
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}ProfileResponseElement
#   bin - SOAP::SOAPString
#   merchantID - SOAP::SOAPString
#   customerName - SOAP::SOAPString
#   customerRefNum - SOAP::SOAPString
#   profileAction - SOAP::SOAPString
#   procStatus - SOAP::SOAPString
#   procStatusMessage - SOAP::SOAPString
#   customerAddress1 - SOAP::SOAPString
#   customerAddress2 - SOAP::SOAPString
#   customerCity - SOAP::SOAPString
#   customerState - SOAP::SOAPString
#   customerZIP - SOAP::SOAPString
#   customerEmail - SOAP::SOAPString
#   customerPhone - SOAP::SOAPString
#   profileOrderOverideInd - SOAP::SOAPString
#   orderDefaultDescription - SOAP::SOAPString
#   orderDefaultAmount - SOAP::SOAPString
#   customerAccountType - SOAP::SOAPString
#   ccAccountNum - SOAP::SOAPString
#   ccExp - SOAP::SOAPString
#   ecpCheckDDA - SOAP::SOAPString
#   ecpBankAcctType - SOAP::SOAPString
#   ecpCheckRT - SOAP::SOAPString
#   ecpDelvMethod - SOAP::SOAPString
#   switchSoloCardStartDate - SOAP::SOAPString
#   switchSoloIssueNum - SOAP::SOAPString
class ProfileResponseElement
  attr_accessor :bin
  attr_accessor :merchantID
  attr_accessor :customerName
  attr_accessor :customerRefNum
  attr_accessor :profileAction
  attr_accessor :procStatus
  attr_accessor :procStatusMessage
  attr_accessor :customerAddress1
  attr_accessor :customerAddress2
  attr_accessor :customerCity
  attr_accessor :customerState
  attr_accessor :customerZIP
  attr_accessor :customerEmail
  attr_accessor :customerPhone
  attr_accessor :profileOrderOverideInd
  attr_accessor :orderDefaultDescription
  attr_accessor :orderDefaultAmount
  attr_accessor :customerAccountType
  attr_accessor :ccAccountNum
  attr_accessor :ccExp
  attr_accessor :ecpCheckDDA
  attr_accessor :ecpBankAcctType
  attr_accessor :ecpCheckRT
  attr_accessor :ecpDelvMethod
  attr_accessor :switchSoloCardStartDate
  attr_accessor :switchSoloIssueNum

  def initialize(bin = nil, merchantID = nil, customerName = nil, customerRefNum = nil, profileAction = nil, procStatus = nil, procStatusMessage = nil, customerAddress1 = nil, customerAddress2 = nil, customerCity = nil, customerState = nil, customerZIP = nil, customerEmail = nil, customerPhone = nil, profileOrderOverideInd = nil, orderDefaultDescription = nil, orderDefaultAmount = nil, customerAccountType = nil, ccAccountNum = nil, ccExp = nil, ecpCheckDDA = nil, ecpBankAcctType = nil, ecpCheckRT = nil, ecpDelvMethod = nil, switchSoloCardStartDate = nil, switchSoloIssueNum = nil)
    @bin = bin
    @merchantID = merchantID
    @customerName = customerName
    @customerRefNum = customerRefNum
    @profileAction = profileAction
    @procStatus = procStatus
    @procStatusMessage = procStatusMessage
    @customerAddress1 = customerAddress1
    @customerAddress2 = customerAddress2
    @customerCity = customerCity
    @customerState = customerState
    @customerZIP = customerZIP
    @customerEmail = customerEmail
    @customerPhone = customerPhone
    @profileOrderOverideInd = profileOrderOverideInd
    @orderDefaultDescription = orderDefaultDescription
    @orderDefaultAmount = orderDefaultAmount
    @customerAccountType = customerAccountType
    @ccAccountNum = ccAccountNum
    @ccExp = ccExp
    @ecpCheckDDA = ecpCheckDDA
    @ecpBankAcctType = ecpBankAcctType
    @ecpCheckRT = ecpCheckRT
    @ecpDelvMethod = ecpDelvMethod
    @switchSoloCardStartDate = switchSoloCardStartDate
    @switchSoloIssueNum = switchSoloIssueNum
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}ProfileResponse
#   m_return - ProfileResponseElement
class ProfileResponse
  def m_return
    @v_return
  end

  def m_return=(value)
    @v_return = value
  end

  def initialize(v_return = nil)
    @v_return = v_return
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}ProfileAddElement
#   bin - SOAP::SOAPString
#   merchantID - SOAP::SOAPString
#   customerName - SOAP::SOAPString
#   customerRefNum - SOAP::SOAPString
#   customerAddress1 - SOAP::SOAPString
#   customerAddress2 - SOAP::SOAPString
#   customerCity - SOAP::SOAPString
#   customerState - SOAP::SOAPString
#   customerZIP - SOAP::SOAPString
#   customerEmail - SOAP::SOAPString
#   customerPhone - SOAP::SOAPString
#   customerProfileOrderOverideInd - SOAP::SOAPString
#   customerProfileFromOrderInd - SOAP::SOAPString
#   orderDefaultDescription - SOAP::SOAPString
#   orderDefaultAmount - SOAP::SOAPString
#   customerAccountType - SOAP::SOAPString
#   ccAccountNum - SOAP::SOAPString
#   ccExp - SOAP::SOAPString
#   ecpCheckDDA - SOAP::SOAPString
#   ecpBankAcctType - SOAP::SOAPString
#   ecpCheckRT - SOAP::SOAPString
#   ecpDelvMethod - SOAP::SOAPString
#   switchSoloCardStartDate - SOAP::SOAPString
#   switchSoloIssueNum - SOAP::SOAPString
class ProfileAddElement
  attr_accessor :bin
  attr_accessor :merchantID
  attr_accessor :customerName
  attr_accessor :customerRefNum
  attr_accessor :customerAddress1
  attr_accessor :customerAddress2
  attr_accessor :customerCity
  attr_accessor :customerState
  attr_accessor :customerZIP
  attr_accessor :customerEmail
  attr_accessor :customerPhone
  attr_accessor :customerProfileOrderOverideInd
  attr_accessor :customerProfileFromOrderInd
  attr_accessor :orderDefaultDescription
  attr_accessor :orderDefaultAmount
  attr_accessor :customerAccountType
  attr_accessor :ccAccountNum
  attr_accessor :ccExp
  attr_accessor :ecpCheckDDA
  attr_accessor :ecpBankAcctType
  attr_accessor :ecpCheckRT
  attr_accessor :ecpDelvMethod
  attr_accessor :switchSoloCardStartDate
  attr_accessor :switchSoloIssueNum

  def initialize(bin = nil, merchantID = nil, customerName = nil, customerRefNum = nil, customerAddress1 = nil, customerAddress2 = nil, customerCity = nil, customerState = nil, customerZIP = nil, customerEmail = nil, customerPhone = nil, customerProfileOrderOverideInd = nil, customerProfileFromOrderInd = nil, orderDefaultDescription = nil, orderDefaultAmount = nil, customerAccountType = nil, ccAccountNum = nil, ccExp = nil, ecpCheckDDA = nil, ecpBankAcctType = nil, ecpCheckRT = nil, ecpDelvMethod = nil, switchSoloCardStartDate = nil, switchSoloIssueNum = nil)
    @bin = bin
    @merchantID = merchantID
    @customerName = customerName
    @customerRefNum = customerRefNum
    @customerAddress1 = customerAddress1
    @customerAddress2 = customerAddress2
    @customerCity = customerCity
    @customerState = customerState
    @customerZIP = customerZIP
    @customerEmail = customerEmail
    @customerPhone = customerPhone
    @customerProfileOrderOverideInd = customerProfileOrderOverideInd
    @customerProfileFromOrderInd = customerProfileFromOrderInd
    @orderDefaultDescription = orderDefaultDescription
    @orderDefaultAmount = orderDefaultAmount
    @customerAccountType = customerAccountType
    @ccAccountNum = ccAccountNum
    @ccExp = ccExp
    @ecpCheckDDA = ecpCheckDDA
    @ecpBankAcctType = ecpBankAcctType
    @ecpCheckRT = ecpCheckRT
    @ecpDelvMethod = ecpDelvMethod
    @switchSoloCardStartDate = switchSoloCardStartDate
    @switchSoloIssueNum = switchSoloIssueNum
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}ProfileChangeElement
#   bin - SOAP::SOAPString
#   merchantID - SOAP::SOAPString
#   customerName - SOAP::SOAPString
#   customerRefNum - SOAP::SOAPString
#   customerAddress1 - SOAP::SOAPString
#   customerAddress2 - SOAP::SOAPString
#   customerCity - SOAP::SOAPString
#   customerState - SOAP::SOAPString
#   customerZIP - SOAP::SOAPString
#   customerEmail - SOAP::SOAPString
#   customerPhone - SOAP::SOAPString
#   customerProfileOrderOverideInd - SOAP::SOAPString
#   orderDefaultDescription - SOAP::SOAPString
#   orderDefaultAmount - SOAP::SOAPString
#   customerAccountType - SOAP::SOAPString
#   ccAccountNum - SOAP::SOAPString
#   ccExp - SOAP::SOAPString
#   ecpCheckDDA - SOAP::SOAPString
#   ecpBankAcctType - SOAP::SOAPString
#   ecpCheckRT - SOAP::SOAPString
#   ecpDelvMethod - SOAP::SOAPString
#   switchSoloCardStartDate - SOAP::SOAPString
#   switchSoloIssueNum - SOAP::SOAPString
class ProfileChangeElement
  attr_accessor :bin
  attr_accessor :merchantID
  attr_accessor :customerName
  attr_accessor :customerRefNum
  attr_accessor :customerAddress1
  attr_accessor :customerAddress2
  attr_accessor :customerCity
  attr_accessor :customerState
  attr_accessor :customerZIP
  attr_accessor :customerEmail
  attr_accessor :customerPhone
  attr_accessor :customerProfileOrderOverideInd
  attr_accessor :orderDefaultDescription
  attr_accessor :orderDefaultAmount
  attr_accessor :customerAccountType
  attr_accessor :ccAccountNum
  attr_accessor :ccExp
  attr_accessor :ecpCheckDDA
  attr_accessor :ecpBankAcctType
  attr_accessor :ecpCheckRT
  attr_accessor :ecpDelvMethod
  attr_accessor :switchSoloCardStartDate
  attr_accessor :switchSoloIssueNum

  def initialize(bin = nil, merchantID = nil, customerName = nil, customerRefNum = nil, customerAddress1 = nil, customerAddress2 = nil, customerCity = nil, customerState = nil, customerZIP = nil, customerEmail = nil, customerPhone = nil, customerProfileOrderOverideInd = nil, orderDefaultDescription = nil, orderDefaultAmount = nil, customerAccountType = nil, ccAccountNum = nil, ccExp = nil, ecpCheckDDA = nil, ecpBankAcctType = nil, ecpCheckRT = nil, ecpDelvMethod = nil, switchSoloCardStartDate = nil, switchSoloIssueNum = nil)
    @bin = bin
    @merchantID = merchantID
    @customerName = customerName
    @customerRefNum = customerRefNum
    @customerAddress1 = customerAddress1
    @customerAddress2 = customerAddress2
    @customerCity = customerCity
    @customerState = customerState
    @customerZIP = customerZIP
    @customerEmail = customerEmail
    @customerPhone = customerPhone
    @customerProfileOrderOverideInd = customerProfileOrderOverideInd
    @orderDefaultDescription = orderDefaultDescription
    @orderDefaultAmount = orderDefaultAmount
    @customerAccountType = customerAccountType
    @ccAccountNum = ccAccountNum
    @ccExp = ccExp
    @ecpCheckDDA = ecpCheckDDA
    @ecpBankAcctType = ecpBankAcctType
    @ecpCheckRT = ecpCheckRT
    @ecpDelvMethod = ecpDelvMethod
    @switchSoloCardStartDate = switchSoloCardStartDate
    @switchSoloIssueNum = switchSoloIssueNum
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}ProfileDeleteElement
#   bin - SOAP::SOAPString
#   merchantID - SOAP::SOAPString
#   customerName - SOAP::SOAPString
#   customerRefNum - SOAP::SOAPString
class ProfileDeleteElement
  attr_accessor :bin
  attr_accessor :merchantID
  attr_accessor :customerName
  attr_accessor :customerRefNum

  def initialize(bin = nil, merchantID = nil, customerName = nil, customerRefNum = nil)
    @bin = bin
    @merchantID = merchantID
    @customerName = customerName
    @customerRefNum = customerRefNum
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}ProfileFetchElement
#   bin - SOAP::SOAPString
#   merchantID - SOAP::SOAPString
#   customerName - SOAP::SOAPString
#   customerRefNum - SOAP::SOAPString
class ProfileFetchElement
  attr_accessor :bin
  attr_accessor :merchantID
  attr_accessor :customerName
  attr_accessor :customerRefNum

  def initialize(bin = nil, merchantID = nil, customerName = nil, customerRefNum = nil)
    @bin = bin
    @merchantID = merchantID
    @customerName = customerName
    @customerRefNum = customerRefNum
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}FlexCacheElement
#   bin - SOAP::SOAPString
#   merchantID - SOAP::SOAPString
#   terminalID - SOAP::SOAPString
#   ccAccountNum - SOAP::SOAPString
#   orderID - SOAP::SOAPString
#   amount - SOAP::SOAPString
#   ccCardVerifyNum - SOAP::SOAPString
#   comments - SOAP::SOAPString
#   shippingRef - SOAP::SOAPString
#   industryType - SOAP::SOAPString
#   flexAutoAuthInd - SOAP::SOAPString
#   flexPartialRedemptionInd - SOAP::SOAPString
#   flexAction - SOAP::SOAPString
#   startAccountNum - SOAP::SOAPString
#   activationCount - SOAP::SOAPString
#   txRefNum - SOAP::SOAPString
#   sequenceNumber - SOAP::SOAPString
#   retryTrace - SOAP::SOAPString
#   employeeNumber - SOAP::SOAPString
#   magStripeTrack1 - SOAP::SOAPString
#   magStripeTrack2 - SOAP::SOAPString
#   retailTransInfo - SOAP::SOAPString
#   priorAuthCd - SOAP::SOAPString
class FlexCacheElement
  attr_accessor :bin
  attr_accessor :merchantID
  attr_accessor :terminalID
  attr_accessor :ccAccountNum
  attr_accessor :orderID
  attr_accessor :amount
  attr_accessor :ccCardVerifyNum
  attr_accessor :comments
  attr_accessor :shippingRef
  attr_accessor :industryType
  attr_accessor :flexAutoAuthInd
  attr_accessor :flexPartialRedemptionInd
  attr_accessor :flexAction
  attr_accessor :startAccountNum
  attr_accessor :activationCount
  attr_accessor :txRefNum
  attr_accessor :sequenceNumber
  attr_accessor :retryTrace
  attr_accessor :employeeNumber
  attr_accessor :magStripeTrack1
  attr_accessor :magStripeTrack2
  attr_accessor :retailTransInfo
  attr_accessor :priorAuthCd

  def initialize(bin = nil, merchantID = nil, terminalID = nil, ccAccountNum = nil, orderID = nil, amount = nil, ccCardVerifyNum = nil, comments = nil, shippingRef = nil, industryType = nil, flexAutoAuthInd = nil, flexPartialRedemptionInd = nil, flexAction = nil, startAccountNum = nil, activationCount = nil, txRefNum = nil, sequenceNumber = nil, retryTrace = nil, employeeNumber = nil, magStripeTrack1 = nil, magStripeTrack2 = nil, retailTransInfo = nil, priorAuthCd = nil)
    @bin = bin
    @merchantID = merchantID
    @terminalID = terminalID
    @ccAccountNum = ccAccountNum
    @orderID = orderID
    @amount = amount
    @ccCardVerifyNum = ccCardVerifyNum
    @comments = comments
    @shippingRef = shippingRef
    @industryType = industryType
    @flexAutoAuthInd = flexAutoAuthInd
    @flexPartialRedemptionInd = flexPartialRedemptionInd
    @flexAction = flexAction
    @startAccountNum = startAccountNum
    @activationCount = activationCount
    @txRefNum = txRefNum
    @sequenceNumber = sequenceNumber
    @retryTrace = retryTrace
    @employeeNumber = employeeNumber
    @magStripeTrack1 = magStripeTrack1
    @magStripeTrack2 = magStripeTrack2
    @retailTransInfo = retailTransInfo
    @priorAuthCd = priorAuthCd
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}FlexCacheResponseElement
#   merchantID - SOAP::SOAPString
#   terminalID - SOAP::SOAPString
#   orderID - SOAP::SOAPString
#   ccAccountNum - SOAP::SOAPString
#   startAccountNum - SOAP::SOAPString
#   flexAcctBalance - SOAP::SOAPString
#   flexAcctPriorBalance - SOAP::SOAPString
#   flexAcctExpireDate - SOAP::SOAPString
#   cardType - SOAP::SOAPString
#   txRefIdx - SOAP::SOAPString
#   txRefNum - SOAP::SOAPString
#   procStatus - SOAP::SOAPString
#   procStatusMessage - SOAP::SOAPString
#   approvalStatus - SOAP::SOAPString
#   authorizationCode - SOAP::SOAPString
#   respCode - SOAP::SOAPString
#   batchFailedAcctNum - SOAP::SOAPString
#   flexRequestedAmount - SOAP::SOAPString
#   flexRedeemedAmt - SOAP::SOAPString
#   flexHostTrace - SOAP::SOAPString
#   flexAction - SOAP::SOAPString
#   respDateTime - SOAP::SOAPString
#   autoAuthTxRefIdx - SOAP::SOAPString
#   autoAuthTxRefNum - SOAP::SOAPString
#   autoAuthProcStatus - SOAP::SOAPString
#   autoAuthStatusMsg - SOAP::SOAPString
#   autoAuthApprovalStatus - SOAP::SOAPString
#   autoAuthFlexRedeemedAmt - SOAP::SOAPString
#   autoAuthResponseCodes - SOAP::SOAPString
#   autoAuthFlexHostTrace - SOAP::SOAPString
#   autoAuthFlexAction - SOAP::SOAPString
#   autoAuthRespTime - SOAP::SOAPString
#   retryTrace - SOAP::SOAPString
#   retryAttempCount - SOAP::SOAPString
#   lastRetryDate - SOAP::SOAPString
#   cvvRespCode - SOAP::SOAPString
#   superBlockID - SOAP::SOAPString
class FlexCacheResponseElement
  attr_accessor :merchantID
  attr_accessor :terminalID
  attr_accessor :orderID
  attr_accessor :ccAccountNum
  attr_accessor :startAccountNum
  attr_accessor :flexAcctBalance
  attr_accessor :flexAcctPriorBalance
  attr_accessor :flexAcctExpireDate
  attr_accessor :cardType
  attr_accessor :txRefIdx
  attr_accessor :txRefNum
  attr_accessor :procStatus
  attr_accessor :procStatusMessage
  attr_accessor :approvalStatus
  attr_accessor :authorizationCode
  attr_accessor :respCode
  attr_accessor :batchFailedAcctNum
  attr_accessor :flexRequestedAmount
  attr_accessor :flexRedeemedAmt
  attr_accessor :flexHostTrace
  attr_accessor :flexAction
  attr_accessor :respDateTime
  attr_accessor :autoAuthTxRefIdx
  attr_accessor :autoAuthTxRefNum
  attr_accessor :autoAuthProcStatus
  attr_accessor :autoAuthStatusMsg
  attr_accessor :autoAuthApprovalStatus
  attr_accessor :autoAuthFlexRedeemedAmt
  attr_accessor :autoAuthResponseCodes
  attr_accessor :autoAuthFlexHostTrace
  attr_accessor :autoAuthFlexAction
  attr_accessor :autoAuthRespTime
  attr_accessor :retryTrace
  attr_accessor :retryAttempCount
  attr_accessor :lastRetryDate
  attr_accessor :cvvRespCode
  attr_accessor :superBlockID

  def initialize(merchantID = nil, terminalID = nil, orderID = nil, ccAccountNum = nil, startAccountNum = nil, flexAcctBalance = nil, flexAcctPriorBalance = nil, flexAcctExpireDate = nil, cardType = nil, txRefIdx = nil, txRefNum = nil, procStatus = nil, procStatusMessage = nil, approvalStatus = nil, authorizationCode = nil, respCode = nil, batchFailedAcctNum = nil, flexRequestedAmount = nil, flexRedeemedAmt = nil, flexHostTrace = nil, flexAction = nil, respDateTime = nil, autoAuthTxRefIdx = nil, autoAuthTxRefNum = nil, autoAuthProcStatus = nil, autoAuthStatusMsg = nil, autoAuthApprovalStatus = nil, autoAuthFlexRedeemedAmt = nil, autoAuthResponseCodes = nil, autoAuthFlexHostTrace = nil, autoAuthFlexAction = nil, autoAuthRespTime = nil, retryTrace = nil, retryAttempCount = nil, lastRetryDate = nil, cvvRespCode = nil, superBlockID = nil)
    @merchantID = merchantID
    @terminalID = terminalID
    @orderID = orderID
    @ccAccountNum = ccAccountNum
    @startAccountNum = startAccountNum
    @flexAcctBalance = flexAcctBalance
    @flexAcctPriorBalance = flexAcctPriorBalance
    @flexAcctExpireDate = flexAcctExpireDate
    @cardType = cardType
    @txRefIdx = txRefIdx
    @txRefNum = txRefNum
    @procStatus = procStatus
    @procStatusMessage = procStatusMessage
    @approvalStatus = approvalStatus
    @authorizationCode = authorizationCode
    @respCode = respCode
    @batchFailedAcctNum = batchFailedAcctNum
    @flexRequestedAmount = flexRequestedAmount
    @flexRedeemedAmt = flexRedeemedAmt
    @flexHostTrace = flexHostTrace
    @flexAction = flexAction
    @respDateTime = respDateTime
    @autoAuthTxRefIdx = autoAuthTxRefIdx
    @autoAuthTxRefNum = autoAuthTxRefNum
    @autoAuthProcStatus = autoAuthProcStatus
    @autoAuthStatusMsg = autoAuthStatusMsg
    @autoAuthApprovalStatus = autoAuthApprovalStatus
    @autoAuthFlexRedeemedAmt = autoAuthFlexRedeemedAmt
    @autoAuthResponseCodes = autoAuthResponseCodes
    @autoAuthFlexHostTrace = autoAuthFlexHostTrace
    @autoAuthFlexAction = autoAuthFlexAction
    @autoAuthRespTime = autoAuthRespTime
    @retryTrace = retryTrace
    @retryAttempCount = retryAttempCount
    @lastRetryDate = lastRetryDate
    @cvvRespCode = cvvRespCode
    @superBlockID = superBlockID
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}UnmarkElement
#   merchantID - SOAP::SOAPString
#   terminalID - SOAP::SOAPString
#   bin - SOAP::SOAPString
#   txRefNum - SOAP::SOAPString
#   txRefIdx - SOAP::SOAPString
#   orderID - SOAP::SOAPString
#   retryTrace - SOAP::SOAPString
#   retryAttempCount - SOAP::SOAPString
class UnmarkElement
  attr_accessor :merchantID
  attr_accessor :terminalID
  attr_accessor :bin
  attr_accessor :txRefNum
  attr_accessor :txRefIdx
  attr_accessor :orderID
  attr_accessor :retryTrace
  attr_accessor :retryAttempCount

  def initialize(merchantID = nil, terminalID = nil, bin = nil, txRefNum = nil, txRefIdx = nil, orderID = nil, retryTrace = nil, retryAttempCount = nil)
    @merchantID = merchantID
    @terminalID = terminalID
    @bin = bin
    @txRefNum = txRefNum
    @txRefIdx = txRefIdx
    @orderID = orderID
    @retryTrace = retryTrace
    @retryAttempCount = retryAttempCount
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}UnmarkResponseElement
#   merchantID - SOAP::SOAPString
#   terminalID - SOAP::SOAPString
#   bin - SOAP::SOAPString
#   orderID - SOAP::SOAPString
#   txRefNum - SOAP::SOAPString
#   txRefIdx - SOAP::SOAPString
#   procStatus - SOAP::SOAPString
#   procStatusMessage - SOAP::SOAPString
#   retryTrace - SOAP::SOAPString
#   retryAttempCount - SOAP::SOAPString
#   lastRetryDate - SOAP::SOAPString
class UnmarkResponseElement
  attr_accessor :merchantID
  attr_accessor :terminalID
  attr_accessor :bin
  attr_accessor :orderID
  attr_accessor :txRefNum
  attr_accessor :txRefIdx
  attr_accessor :procStatus
  attr_accessor :procStatusMessage
  attr_accessor :retryTrace
  attr_accessor :retryAttempCount
  attr_accessor :lastRetryDate

  def initialize(merchantID = nil, terminalID = nil, bin = nil, orderID = nil, txRefNum = nil, txRefIdx = nil, procStatus = nil, procStatusMessage = nil, retryTrace = nil, retryAttempCount = nil, lastRetryDate = nil)
    @merchantID = merchantID
    @terminalID = terminalID
    @bin = bin
    @orderID = orderID
    @txRefNum = txRefNum
    @txRefIdx = txRefIdx
    @procStatus = procStatus
    @procStatusMessage = procStatusMessage
    @retryTrace = retryTrace
    @retryAttempCount = retryAttempCount
    @lastRetryDate = lastRetryDate
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}NewOrder
#   newOrderRequest - NewOrderRequestElement
class NewOrder
  attr_accessor :newOrderRequest

  def initialize(newOrderRequest = nil)
    @newOrderRequest = newOrderRequest
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}NewOrderResponse
#   m_return - NewOrderResponseElement
class NewOrderResponse
  def m_return
    @v_return
  end

  def m_return=(value)
    @v_return = value
  end

  def initialize(v_return = nil)
    @v_return = v_return
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}MarkForCapture
#   markForCaptureRequest - MarkForCaptureElement
class MarkForCapture
  attr_accessor :markForCaptureRequest

  def initialize(markForCaptureRequest = nil)
    @markForCaptureRequest = markForCaptureRequest
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}MarkForCaptureResponse
#   m_return - MarkForCaptureResponseElement
class MarkForCaptureResponse
  def m_return
    @v_return
  end

  def m_return=(value)
    @v_return = value
  end

  def initialize(v_return = nil)
    @v_return = v_return
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}Reversal
#   reversalRequest - ReversalElement
class Reversal
  attr_accessor :reversalRequest

  def initialize(reversalRequest = nil)
    @reversalRequest = reversalRequest
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}ReversalResponse
#   m_return - ReversalResponseElement
class ReversalResponse
  def m_return
    @v_return
  end

  def m_return=(value)
    @v_return = value
  end

  def initialize(v_return = nil)
    @v_return = v_return
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}EndOfDay
#   endOfDayRequest - EndOfDayElement
class EndOfDay
  attr_accessor :endOfDayRequest

  def initialize(endOfDayRequest = nil)
    @endOfDayRequest = endOfDayRequest
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}EndOfDayResponse
#   m_return - EndOfDayResponseElement
class EndOfDayResponse
  def m_return
    @v_return
  end

  def m_return=(value)
    @v_return = value
  end

  def initialize(v_return = nil)
    @v_return = v_return
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}ProfileAdd
#   profileAddRequest - ProfileAddElement
class ProfileAdd
  attr_accessor :profileAddRequest

  def initialize(profileAddRequest = nil)
    @profileAddRequest = profileAddRequest
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}ProfileAddResponse
#   m_return - ProfileResponseElement
class ProfileAddResponse
  def m_return
    @v_return
  end

  def m_return=(value)
    @v_return = value
  end

  def initialize(v_return = nil)
    @v_return = v_return
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}ProfileChange
#   profileChangeRequest - ProfileChangeElement
class ProfileChange
  attr_accessor :profileChangeRequest

  def initialize(profileChangeRequest = nil)
    @profileChangeRequest = profileChangeRequest
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}ProfileChangeResponse
#   m_return - ProfileResponseElement
class ProfileChangeResponse
  def m_return
    @v_return
  end

  def m_return=(value)
    @v_return = value
  end

  def initialize(v_return = nil)
    @v_return = v_return
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}ProfileDelete
#   profileDeleteRequest - ProfileDeleteElement
class ProfileDelete
  attr_accessor :profileDeleteRequest

  def initialize(profileDeleteRequest = nil)
    @profileDeleteRequest = profileDeleteRequest
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}ProfileDeleteResponse
#   m_return - ProfileResponseElement
class ProfileDeleteResponse
  def m_return
    @v_return
  end

  def m_return=(value)
    @v_return = value
  end

  def initialize(v_return = nil)
    @v_return = v_return
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}ProfileFetch
#   profileFetchRequest - ProfileFetchElement
class ProfileFetch
  attr_accessor :profileFetchRequest

  def initialize(profileFetchRequest = nil)
    @profileFetchRequest = profileFetchRequest
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}ProfileFetchResponse
#   m_return - ProfileResponseElement
class ProfileFetchResponse
  def m_return
    @v_return
  end

  def m_return=(value)
    @v_return = value
  end

  def initialize(v_return = nil)
    @v_return = v_return
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}FlexCache
#   flexCacheRequest - FlexCacheElement
class FlexCache
  attr_accessor :flexCacheRequest

  def initialize(flexCacheRequest = nil)
    @flexCacheRequest = flexCacheRequest
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}FlexCacheResponse
#   m_return - FlexCacheResponseElement
class FlexCacheResponse
  def m_return
    @v_return
  end

  def m_return=(value)
    @v_return = value
  end

  def initialize(v_return = nil)
    @v_return = v_return
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}Unmark
#   unmarkRequest - UnmarkElement
class Unmark
  attr_accessor :unmarkRequest

  def initialize(unmarkRequest = nil)
    @unmarkRequest = unmarkRequest
  end
end

# {urn:ws.paymentech.net/PaymentechGateway}UnmarkResponse
#   m_return - UnmarkResponseElement
class UnmarkResponse
  def m_return
    @v_return
  end

  def m_return=(value)
    @v_return = value
  end

  def initialize(v_return = nil)
    @v_return = v_return
  end
end
