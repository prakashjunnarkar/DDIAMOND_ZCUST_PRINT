@AbapCatalog.sqlViewName: 'ZI_PRINT_PORD'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Production order print'
@Metadata.ignorePropagatedAnnotations: true
define view ZI_PRINT_PROD_ORD
  as select from I_ManufacturingOrder as prod
{

  key prod.ManufacturingOrder,
      prod.ManufacturingOrderType,
      prod.CreationDate

}
