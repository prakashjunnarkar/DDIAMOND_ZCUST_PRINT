@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@ObjectModel.sapObjectNodeType.name: 'ZTAX_GST_PRCNT'
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZR_TAX_GST_PRCNT
  as select from ZTAX_GST_PRCNT
{
  key taxcode as Taxcode,
  cgstrate as Cgstrate,
  sgstrate as Sgstrate,
  igstrate as Igstrate,
  erdate as Erdate,
  uzeit as Uzeit,
  uname as Uname,
  @Semantics.user.createdBy: true
  created_by as CreatedBy,
  @Semantics.systemDateTime.createdAt: true
  created_at as CreatedAt,
  @Semantics.user.localInstanceLastChangedBy: true
  changed_by as ChangedBy,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  changed_at as ChangedAt
}
