@AbapCatalog.sqlViewName: 'ZSTICKER'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sticker Print Data'
@Metadata.ignorePropagatedAnnotations: true
define view Zi_sticker_print as select from I_MaterialDocumentItem_2
{
key MaterialDocument ,
key MaterialDocumentItem ,
key MaterialDocumentYear ,
    Plant ,
    PostingDate   
}
