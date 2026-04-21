@AbapCatalog.sqlViewName: 'ZV_REGIONTEXT'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'rEASON Text'
define view zi_regiontext
  as select from I_RegionText as reas
{
  key reas.Country,
  key reas.Region,
  key reas.Language,
      reas.RegionName

}
