@AbapCatalog.sqlViewName: 'ZV_LOT_DATA'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Lot Print Data'
define view ZI_LOT_PRINT_DATA as select from I_InspectionLot as lot
left outer join I_Supplier as supl on supl.Supplier = lot.Supplier
{

  key lot.InspectionLot,
      lot.MaterialDocument,
      lot.MaterialDocumentYear,
      lot.PurchasingDocument,
      lot.PurchasingDocumentItem,
      lot.InspLotCreatedOnLocalDate,
      lot.InspectionLotType,
      lot.Plant,
      lot.Material,
      lot.InspectionLotObjectText,
      lot.InspectionLotOrigin,
      lot.Supplier,
      supl.SupplierName    
}
