@AbapCatalog.sqlViewName: 'ZV_COUNTRYTEXT'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Country text'
define view ZI_CountryText as select from I_CountryText as cntry
{
   key cntry.Country,
   key cntry.Language,
   cntry.CountryName,
   cntry.NationalityName,
   cntry.NationalityLongName,
   cntry.CountryShortName
}
