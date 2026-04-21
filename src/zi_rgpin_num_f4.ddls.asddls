@AbapCatalog.sqlViewName: 'ZV_RGPIN_NUM_F4'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'RGP OUT NUM F4 Help'
define view ZI_rgpin_num_F4 as select distinct from zmm_rgp_data as rgpin
{

  key rgpin.rgpin_num,
  key rgpin.rgpin_year
 
} 
where mblnr = '' 
and rgpindeleted = ''
and rgpin_num <> ''
//and vechout = 'X'
