@AbapCatalog.sqlViewName: 'ZV_RGPOUT_NUM_F4'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'RGP OUT NUM F4 Help'
define view ZI_rgpout_num_F4
  as select distinct from zmm_rgp_data as rgpout
{

  key rgpout.rgpout_num,
  key rgpout.rgpout_year

}
where
      mblnr         =  ''
  and rgpoutdeleted =  ''
  and rgpout_num    <> ''
  and rgpin_num     =  ''
// and vechout = 'X'
