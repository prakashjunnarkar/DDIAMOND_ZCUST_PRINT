@EndUserText.label: 'Sale Quotation print line item Tax data'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_SaleQuotationPrintL
  as select from ZSALESQU_TAX
  association to parent ZI_SaleQuotationPrintL_S as _SaleQuotationPriAll on $projection.SingletonID = _SaleQuotationPriAll.SingletonID
{
  key ZVBELN as Zvbeln,
  key ZPOSNR as Zposnr,
  PARTSCOST as Partscost,
  SUBMATERIALCOST as Submaterialcost,
  ASSEMBLINGCOST as Assemblingcost,
  PACKINGANDTRASNPORTINGCOST as Packingandtrasnportingcost,
  ADMINSTRATIONCOSTANDPROFIT as Adminstrationcostandprofit,
  TTL_WITHOUTGST_INR as TtlWithoutgstInr,
  AMORITISATIONCOSTOFTOOLING as Amoritisationcostoftooling,
  TTL_WITHOUT_GST_INR_AMORITISAT as TtlWithoutGstInrAmoritisat,
  REMARKS1 as Remarks1,
  REMARKS2 as Remarks2,
  REMARKS3 as Remarks3,
  REMARKS4 as Remarks4,
  REMARKS5 as Remarks5,
  @Semantics.user.createdBy: true
  LOCAL_CREATED_BY as LocalCreatedBy,
  @Semantics.systemDateTime.createdAt: true
  LOCAL_CEATED_AT as LocalCeatedAt,
  @Semantics.user.localInstanceLastChangedBy: true
  @Consumption.hidden: true
  LOCAL_LAST_CHANGED_BY as LocalLastChangedBy,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  @Consumption.hidden: true
  LOCAL_LAST_CHANGED_AT as LocalLastChangedAt,
  @Semantics.systemDateTime.lastChangedAt: true
  LAST_CHANGED_AT as LastChangedAt,
  @Consumption.hidden: true
  1 as SingletonID,
  _SaleQuotationPriAll
  
}
