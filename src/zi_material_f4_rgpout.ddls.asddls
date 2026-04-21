@AbapCatalog.sqlViewName: 'ZV_MAT_F4_RGP'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Material f4 rgpout'
@Metadata.ignorePropagatedAnnotations: true
define view zi_material_f4_rgpout
  as select from    I_Product           as mara
    inner join      I_ProductText       as makt on  mara.Product  = makt.Product
                                                and makt.Language = 'E'
    left outer join I_ProductPlantBasic as HSN  on HSN.Product = mara.Product
{

  key mara.Product,
      mara.BaseUnit as UOM,
      makt.ProductName,      
      HSN.ConsumptionTaxCtrlCode,
      HSN.Plant
      
}
