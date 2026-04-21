@AbapCatalog.sqlViewName: 'ZV_EXP_COMM'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Export Commercial'
define view ZI_PRINT_EXP_COMM 
as select distinct from ZI_PACK_LIST_DATA as pack
{

  key pack.pack_num,
  key pack.vbeln,
  key pack.erdate
      
}
