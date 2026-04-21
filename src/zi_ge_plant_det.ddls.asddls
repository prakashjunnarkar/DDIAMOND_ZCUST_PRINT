@AbapCatalog.sqlViewName: 'ZV_GE_PLANT_DET'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Plant Detail for gate entry'
define view ZI_GE_PLANT_DET
  as select from I_Plant as A
{
  key A.Plant,
      A.PlantName
}
