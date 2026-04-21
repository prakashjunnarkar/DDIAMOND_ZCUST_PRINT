@AbapCatalog.sqlViewName: 'ZV_TAXCODE_F4'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Tax Code value help'
/*+[hideWarning] { "IDS" : [ "CARDINALITY_CHECK" ]  } */
define view ZI_taxcode_f4
////////  as select from ZI_TaxCodeGstPercent as A
////////
////////{
////////  key A.Taxcode  as Taxcode,
////////      A.Cgstrate as Cgstrate,
////////      A.Sgstrate as Sgstrate,
////////      A.Igstrate as Igstrate
////////}
as select from ZI_TaxCodeGstPercent 
 association [0..1] to I_TaxCodeText as _Text     
  on _Text.TaxCode = ZI_TaxCodeGstPercent .Taxcode
 and _Text.Language = 'E'//$session.system_language

{
  key ZI_TaxCodeGstPercent .Taxcode        as TaxCode,
      _Text.TaxCodeName        as TaxCodeText
}
