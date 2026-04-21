@AbapCatalog.sqlViewName: 'ZV_GATE_F4'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Gate entry F4 Help'
define view ZI_GATE_ENTRY_F4 as select distinct from zmm_ge_data as ge
{

  key ge.gentry_num,
  key ge.gentry_year
   
} 
where mblnr = '' and gedeleted = ''
