@AbapCatalog.sqlViewName: 'ZV_PAY_ADV'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Payment Advice'
define view ZI_FI_PAY_ADV 
as select distinct from I_OperationalAcctgDocItem as bkpf
{
  
  key bkpf.CompanyCode,
  key bkpf.AccountingDocument,
  key bkpf.FiscalYear,
      bkpf.PostingDate,
      bkpf.DocumentDate,
      bkpf.AccountingDocumentType
    
}
