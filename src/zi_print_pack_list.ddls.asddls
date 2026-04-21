@AbapCatalog.sqlViewName: 'ZV_PACK_PRINT'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Packing List print'
define view ZI_PRINT_PACK_LIST 
as select distinct from ZI_PACK_LIST_DATA as pack
{

  key pack.pack_num,
  key pack.vbeln,
  key pack.erdate
      
}
