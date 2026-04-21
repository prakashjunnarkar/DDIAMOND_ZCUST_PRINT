@AbapCatalog.sqlViewName: 'ZV_PR_DATA'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PR DATA'
@Metadata.ignorePropagatedAnnotations: true
define view ZI_PR_DATA

  as select from    I_PurchaseRequisitionItemAPI01 as EBAN

      left outer join I_PurchaseRequisitionAPI01     as EBKN on EBAN.PurchaseRequisition = EBKN.PurchaseRequisition
                                                     and EBAN.PurchasingDocument = ''

    left outer join I_ProductDescription           as makt on  makt.Product  = EBAN.Material
                                                           and makt.Language = 'E'


    left outer join I_ProductPlantBasic            as HSN  on HSN.Product = EBAN.Material

{

  key EBAN.PurchaseRequisition,
  key EBAN.PurchaseRequisitionItem,      
      EBAN.Material,
      EBAN.BaseUnit,
      EBAN.RequestedQuantity,
      EBAN.PurchaseRequisitionPrice,
      EBAN.Plant,
      EBAN.TaxCode,
      makt.ProductDescription,
      HSN.ConsumptionTaxCtrlCode

}
where
      EBAN.PurchasingDocument = ''
  and EBAN.IsDeleted          = ''
  and EBAN.IsClosed           = ''
