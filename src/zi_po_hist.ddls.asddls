@AbapCatalog.sqlViewName: 'ZV_PO_HIST'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO history data'
define view ZI_PO_HIST
  as select from I_PurchaseOrderHistoryAPI01 as phist
{

  key phist.PurchaseOrder,
  key phist.PurchaseOrderItem,
      phist.GoodsMovementType,
      sum(phist.Quantity) as Quantity

}
group by
  phist.PurchaseOrder,
  phist.PurchaseOrderItem,
  phist.GoodsMovementType

