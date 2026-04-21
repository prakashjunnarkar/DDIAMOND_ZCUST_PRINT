@AbapCatalog.sqlViewName: 'ZV_RTP_DATA'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RTP Data'
define view ZI_GRN_RTP_DATA as select distinct from I_MaterialDocumentHeader_2 mkpf
    left outer join I_MaterialDocumentItem_2    as mseg    on  mkpf.MaterialDocument     = mseg.MaterialDocument
                                                           and mkpf.MaterialDocumentYear = mseg.MaterialDocumentYear
{
 
 key mkpf.MaterialDocument,
 key mkpf.MaterialDocumentYear,
 mkpf.DocumentDate,
 mkpf.PostingDate,
 mkpf.MaterialDocumentHeaderText,
 mkpf.DeliveryDocument,
 mkpf.ReferenceDocument,
 mkpf.BillOfLading,
 mkpf.Plant
   
}
where mseg.GoodsMovementType = '502'
