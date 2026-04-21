@EndUserText.label: 'Tax code GST percent'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_TaxCodeGstPercent
  as select from ZTAX_GST_PRCNT
  association to parent ZI_TaxCodeGstPercent_S as _TaxCodeGstPercenAll on $projection.SingletonID = _TaxCodeGstPercenAll.SingletonID
{
  key TAXCODE as Taxcode,
  CGSTRATE as Cgstrate,
  SGSTRATE as Sgstrate,
  IGSTRATE as Igstrate,
  @Consumption.hidden: true
  1 as SingletonID,
  _TaxCodeGstPercenAll
}
