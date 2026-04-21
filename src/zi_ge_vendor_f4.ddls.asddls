@AbapCatalog.sqlViewName: 'ZV_GE_VENDOR'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Plant Detail for gate entry'
define view ZI_GE_VENDOR_F4
  as select from I_Supplier as lfa1
{
  key lfa1.Supplier,
      lfa1.SupplierName
}
