@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText: {
  label: '###GENERATED Core Data Service Entity'
}
@ObjectModel: {
  sapObjectNodeType.name: 'ZTAX_GST_PRCNT'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_TAX_GST_PRCNT
  provider contract transactional_query
  as projection on ZR_TAX_GST_PRCNT
  association [1..1] to ZR_TAX_GST_PRCNT as _BaseEntity on  $projection.Taxcode = _BaseEntity.Taxcode
  association [0..1] to I_TaxCodeText    as _Text       on  _Text.TaxCode  = ZR_TAX_GST_PRCNT.Taxcode
                                                        and _Text.Language = 'E' //$session.system_language
{
  key Taxcode,      
      Cgstrate,
      Sgstrate,
      Igstrate,
      Erdate,
      Uzeit,
      Uname,
      @Semantics: {
        user.createdBy: true
      }
      CreatedBy,
      @Semantics: {
        systemDateTime.createdAt: true
      }
      CreatedAt,
      @Semantics: {
        user.localInstanceLastChangedBy: true
      }
      ChangedBy,
      @Semantics: {
        systemDateTime.localInstanceLastChangedAt: true
      }
      ChangedAt,
      _BaseEntity,
      _Text
}
