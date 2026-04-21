@AbapCatalog.sqlViewName: 'ZV_INSP_LOT_REJ'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Rejected inspection lot'
define view ZI_INSP_LOT_REJ
  as select from    I_InspectionLot        as lot

    left outer join I_Supplier             as supl on supl.Supplier = lot.Supplier

    left outer join I_ProductDescription        as makt    on  makt.Product  = lot.Material
                                                           and makt.Language = 'E'
                                                           
    left outer join I_InspLotUsageDecision as des  on des.InspectionLot = lot.InspectionLot

{

  key lot.InspectionLot,
      lot.InspectionLotType,
      lot.Plant,
      lot.Material,
      lot.InspectionLotObjectText,
      lot.InspectionLotOrigin,
      lot.MaterialDocument,
      lot.ManufacturerPartNmbr,
      makt.ProductDescription,
      lot.Supplier,
      lot.Customer,
      supl.SupplierName,
      lot.ManufacturingOrder,
      lot.Batch,
      lot.InspectionLotQuantity,
      lot.InspectionLotQuantityUnit,
      lot.InspLotCreatedOnLocalDate,
      lot.InspLotQtyToFree,
      lot.InspLotQtyToBlocked,
      des.InspectionLotUsageDecisionCode,
      lot.MatlDocLatestPostgDate,
      lot.PurchasingDocument,
      lot.PurchasingDocumentItem,
      lot.MaterialDocumentYear,
      lot.DeliveryDocument,
      lot.SalesOrder,
      lot.InspectionLotSampleQuantity,
      lot.InspectionLotSampleUnit,
      des.InspectionLotUsageDecidedBy,
      des.InspectionLotUsageDecidedOn

}
where
  des.InspectionLotUsageDecisionCode >= ''
