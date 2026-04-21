@AbapCatalog.sqlViewName: 'ZV_PO_PRINT'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO Print Data'
@Metadata.ignorePropagatedAnnotations: true
define view ZI_PO_PRINT_DATA 
  as select from    I_PurchaseOrderItemAPI01 as ekpo

    left outer join I_PurchaseOrderAPI01     as ekko on ekpo.PurchaseOrder = ekko.PurchaseOrder

{

  key ekpo.PurchaseOrder,
      ekpo.Plant,
      ekko.PurchaseOrderType,
      ekko.PurchaseOrderDate

}
