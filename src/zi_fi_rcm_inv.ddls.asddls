@AbapCatalog.sqlViewName: 'ZV_RCM_INV'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RCM Invoice'
define view ZI_FI_RCM_INV 
as select distinct from I_OperationalAcctgDocItem as bkpf
{
  
  key bkpf.CompanyCode,
  key bkpf.AccountingDocument,
  key bkpf.FiscalYear,
      bkpf.PostingDate,
      bkpf.DocumentDate,
      bkpf.AccountingDocumentType
    
}
