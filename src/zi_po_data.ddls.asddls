@AbapCatalog.sqlViewName: 'ZV_PO_DATA'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO Data'
define view ZI_PO_DATA
  as select from    I_PurchaseOrderItemAPI01 as ekpo

    left outer join I_PurchaseOrderAPI01     as ekko on ekpo.PurchaseOrder = ekko.PurchaseOrder

    left outer join I_ProductDescription     as makt on  makt.Product  = ekpo.Material
                                                     and makt.Language = 'E'
{

  key ekpo.PurchaseOrder,
  key ekpo.PurchaseOrderItem,
      ekpo.OrderQuantity,
      ekpo.OverdelivTolrtdLmtRatioInPct,
      ekpo.Material,
      ekpo.Plant,
      ekpo.DocumentCurrency,
      ekpo.ReferenceDeliveryAddressID,
      ekko.Customer,
      ekko.Supplier,
      ekko.ValidityStartDate,
      ekko.ValidityEndDate,
      ekko.PurchaseOrderDate,
      ekko.PurchasingProcessingStatus,
      ekko.PurchaseOrderType,
      ekko.PaymentTerms,
      makt.ProductDescription,
      ekpo.OrderPriceUnit,
      ekpo.NetAmount,
      ekpo.NetPriceAmount,
      ekpo.BaseUnit,
      ekpo.Subtotal1Amount,
      ekpo.Subtotal6Amount

}
where
      ekpo.PurchasingDocumentDeletionCode = ''
  and ekpo.IsCompletelyDelivered          = ''
