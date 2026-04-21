@AbapCatalog.sqlViewName: 'ZV_MATERIAL_F4'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'F4 help for material'
define view ZI_MATERIAL_F4 
as select from I_Product as mara
inner join I_ProductText as makt on mara.Product = makt.Product and makt.Language = 'E'
{

key mara.Product,
    mara.ProductGroup,
    mara.ProductType,
    mara.BaseUnit,
    makt.ProductName
    
}
