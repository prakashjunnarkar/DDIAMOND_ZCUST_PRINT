@AbapCatalog.sqlViewName: 'ZV_GRN_DETAIL'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'GRN Print Data'
define view ZI_GRN_DETAIL
  as select from    ZI_GRN_DATA                 as mkpf

    left outer join I_MaterialDocumentItem_2    as mseg    on  mkpf.MaterialDocument     = mseg.MaterialDocument
                                                           and mkpf.MaterialDocumentYear = mseg.MaterialDocumentYear

    left outer join I_PurchaseOrderItemAPI01    as ekpo    on  mseg.PurchaseOrder     = ekpo.PurchaseOrder
                                                           and mseg.PurchaseOrderItem = ekpo.PurchaseOrderItem

    left outer join I_PurchaseOrderAPI01        as ekko    on mseg.PurchaseOrder = ekko.PurchaseOrder

    left outer join I_Supplier                  as lfa1    on mseg.Supplier = lfa1.Supplier

    left outer join I_InspectionLot             as insplot on  mseg.MaterialDocument     = insplot.MaterialDocument
                                                           and mseg.MaterialDocumentYear = insplot.MaterialDocumentYear
                                                           and mseg.MaterialDocumentItem = insplot.MaterialDocumentItem
    
    left outer join I_InspLotUsageDecision as des  on des.InspectionLot = insplot.InspectionLot
    
    left outer join I_Address_2                 as adrc    on lfa1.AddressID = adrc.AddressID

    left outer join I_ProductDescription        as makt    on  makt.Product  = mseg.Material
                                                           and makt.Language = 'E'

    left outer join I_PurchaseOrderHistoryAPI01 as pohist  on  pohist.PurchaseOrder                 = mseg.PurchaseOrder
                                                           and pohist.PurchaseOrderItem             = mseg.PurchaseOrderItem
                                                           and pohist.PurchasingHistoryDocument     = mseg.MaterialDocument
                                                           and pohist.PurchasingHistoryDocumentItem = mseg.MaterialDocumentItem

{

  key mkpf.MaterialDocument,
  key mkpf.MaterialDocumentYear,
      mkpf.DocumentDate,
      mkpf.PostingDate,
      mkpf.MaterialDocumentHeaderText,
      mkpf.DeliveryDocument,
      mkpf.ReferenceDocument,
      mkpf.BillOfLading,
      mkpf.Plant,
      mseg.MaterialDocumentItem,
      mseg.GoodsMovementType,
      mseg.Supplier,
      mseg.PurchaseOrder,
      mseg.PurchaseOrderItem,
      mseg.Material,
      mseg.EntryUnit,
      mseg.QuantityInEntryUnit,
      mseg.TotalGoodsMvtAmtInCCCrcy,
      mseg.InventorySpecialStockType,
      mseg.InventoryStockType,
      mseg.ReversedMaterialDocument,
      mseg.ReversedMaterialDocumentItem,
      mseg.ReversedMaterialDocumentYear,
      mseg.Batch,
      mseg.GoodsMovementIsCancelled,
      mseg.GoodsRecipientName,
      mseg.UnloadingPointName,
      mseg.IsAutomaticallyCreated,
      mseg.ManufacturingOrder,
      mseg.Reservation,
      mseg.ReservationItem,
      mseg.StorageLocation,
      mseg.StorageBin,
      mseg.IssgOrRcvgBatch,
      mseg.IssuingOrReceivingStorageLoc,
      mseg.EWMStorageBin,
      ekko.PurchaseOrderDate,
      ekko.ExchangeRate,
      ekko.DocumentCurrency,
      ekpo.OrderQuantity,
      ekpo.NetPriceAmount,
      pohist.QuantityInDeliveryQtyUnit,
      lfa1.SupplierName,
      lfa1.Country,
      lfa1.AddressID,
      insplot.InspectionLot,
      insplot.InspLotQtyToBlocked,
      insplot.InspLotQtyToFree,
      insplot.MatlDocLatestPostgDate,
      insplot.InspectionLotType,
      des.InspectionLotUsageDecidedBy,
      des.InspectionLotUsageDecidedOn,      
      adrc.StreetPrefixName1,
      adrc.StreetPrefixName2,
      adrc.StreetName,
      adrc.StreetSuffixName1,
      adrc.DistrictName,
      adrc.CityName,
      adrc.PostalCode,
      adrc.AddressRepresentationCode,
      adrc.AddressPersonID,
      adrc.Region,
      adrc._EmailAddress.EmailAddress as supll_email,
      makt.ProductDescription

}
