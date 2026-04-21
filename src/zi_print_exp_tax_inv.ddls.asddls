@AbapCatalog.sqlViewName: 'ZV_EXP_TAX'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Export Tax Invoice'
define view ZI_PRINT_EXP_TAX_INV 
as select from I_BillingDocument as bl
{
    key bl.BillingDocument,
    bl.BillingDocumentType,
    bl.BillingDocumentDate,
    bl.DistributionChannel

}
where bl.BillingDocumentIsCancelled = ''
and bl.DistributionChannel = '30'

//( bl.BillingDocumentType = 'X8' or 
//        bl.BillingDocumentType = 'F8' )
//and 
//( bl.DistributionChannel = '30' or 
//  bl.DistributionChannel = '40' )
//  
//and bl.BillingDocumentIsCancelled = ''

