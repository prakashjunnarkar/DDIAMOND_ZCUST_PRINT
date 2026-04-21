@AbapCatalog.sqlViewName: 'ZV_DLV_CHLN '
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Delivery Challan'
define view ZI_PRINT_DLV_CHLN 
as select from I_BillingDocument as bl
{
    key bl.BillingDocument,
    bl.BillingDocumentType,
    bl.BillingDocumentDate,
    bl.DistributionChannel

}
where ( bl.BillingDocumentType = 'JDC' or 
        bl.BillingDocumentType = 'JSN' or 
        bl.BillingDocumentType = 'F2' or 
        bl.BillingDocumentType = 'JVR' )
and 
( 
  bl.DistributionChannel = '40' or bl.DistributionChannel = '10'
 )
  
and bl.BillingDocumentIsCancelled = ''
