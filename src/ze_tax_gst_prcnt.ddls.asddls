@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'View entity'
@Metadata.allowExtensions: true
define root view entity ze_tax_gst_prcnt 
as select from ztax_gst_prcnt as tax
{

 key tax.taxcode,
 tax.cgstrate,
 tax.sgstrate,
 tax.igstrate
}
