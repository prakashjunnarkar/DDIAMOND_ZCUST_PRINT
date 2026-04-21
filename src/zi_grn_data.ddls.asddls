@AbapCatalog.sqlViewName: 'ZV_GRN_DATA'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'GRN Data'
define view ZI_GRN_DATA as select from I_MaterialDocumentHeader_2 ghdr
{
 
 key ghdr.MaterialDocument,
 key ghdr.MaterialDocumentYear,
 ghdr.DocumentDate,
 ghdr.PostingDate,
 ghdr.MaterialDocumentHeaderText,
 ghdr.DeliveryDocument,
 ghdr.ReferenceDocument,
 ghdr.BillOfLading,
 ghdr.Plant
   
}
