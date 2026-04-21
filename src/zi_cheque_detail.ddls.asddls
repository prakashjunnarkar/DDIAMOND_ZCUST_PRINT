@AbapCatalog.sqlViewName: 'ZV_CHQ_DETAIL'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Cheque Detail'
define view ZI_CHEQUE_DETAIL
  as select from I_OutgoingCheck as chq
{

  key chq.PaymentCompanyCode,
  key chq.HouseBank,
  key chq.HouseBankAccount,
  key chq.PaymentMethod,
  key chq.OutgoingCheque,
      chq.IsIntercompanyPayment,
      chq.ChequeIsManuallyIssued,
      chq.ChequebookFirstCheque,
      chq.PaymentDocument,
      chq.ChequePaymentDate,
      chq.PaymentCurrency,
      chq.PaidAmountInPaytCurrency,
      chq.Supplier,
      chq.PaymentDocPrintDate,
      chq.PaymentDocPrintTime,
      chq.ChequePrintDateTime,
      chq.PaymentDocPrintedByUser,
      chq.ChequeEncashmentDate,
      chq.ChequeLastExtractDate,
      chq.ChequeLastExtractDateTime,
      chq.PayeeTitle,
      chq.PayeeName,
      chq.PayeeAdditionalName,
      chq.PayeePostalCode,
      chq.PayeeCityName,
      chq.PayeeStreet,
      chq.PayeePOBox,
      chq.PayeePOBoxPostalCode,
      chq.PayeePOBoxCityName,
      chq.Country,
      chq.Region,
      chq.ChequeVoidReason,
      chq.ChequeVoidedDate,
      chq.ChequeVoidedByUser,
      chq.ChequeIsCashed,
      chq.CashDiscountAmount,
      chq.FiscalYear,
      chq.ChequeType,
      chq.VoidedChequeUsage,
      chq.ChequeStatus,
      chq.ChequeIssuingType,
      chq.BankName,
      chq.CompanyCodeCountry,
      chq.CompanyCodeName

}
