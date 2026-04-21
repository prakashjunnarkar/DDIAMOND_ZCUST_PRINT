@AbapCatalog.sqlViewName: 'ZV_NRGP_NUM_F4'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'RGP OUT NUM F4 Help'
define view ZI_nrgp_num_F4 as select distinct from zmm_nrgp_data as nrgp
{

  key nrgp.nrgp_num,
  key nrgp.nrgp_year
   
} 
where nrgpdeleted = ''

