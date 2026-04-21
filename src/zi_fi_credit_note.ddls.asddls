@AbapCatalog.sqlViewName: 'ZV_FI_CREDT_NOTE'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'FI-Credit Note'
define view ZI_FI_CREDIT_NOTE 
as select distinct from I_OperationalAcctgDocItem as bkpf
{
  
  key bkpf.CompanyCode,
  key bkpf.AccountingDocument,
  key bkpf.FiscalYear,
      bkpf.PostingDate,
      bkpf.DocumentDate,
      bkpf.AccountingDocumentType
    
}
