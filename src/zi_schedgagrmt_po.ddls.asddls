@AbapCatalog.sqlViewName: 'ZV_SCHDAGR_PO'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Scheduling agreement po'
define view ZI_Schedgagrmt_PO
  as select from    I_SchedgagrmthdrApi01 as sagrhdr

    left outer join I_SchedgAgrmtItmApi01 as sagritm  on sagritm.SchedulingAgreement = sagrhdr.SchedulingAgreement

    left outer join I_SchedglineApi01     as schdline on  schdline.SchedulingAgreement     = sagrhdr.SchedulingAgreement
                                                      and schdline.SchedulingAgreementItem = sagritm.SchedulingAgreementItem

    left outer join I_ProductPlantBasic   as marc     on  sagritm.Material = marc.Product
                                                      and sagritm.Plant    = marc.Plant

    left outer join I_ProductDescription  as makt     on  makt.Product  = sagritm.Material
                                                      and makt.Language = 'E'
    left outer join I_PaymentTermsText as payterm     on payterm.PaymentTerms =  sagrhdr.PaymentTerms
                                                      and payterm.Language = 'E'                                                          
{

  key sagrhdr.SchedulingAgreement,
  key sagritm.SchedulingAgreementItem,
  key schdline.ScheduleLine,
      schdline.ScheduleLineDeliveryDate,
      sagritm.Material,
      sagritm.Plant,
      sagritm.MaterialGroup,
      sagritm.MaterialType,
      sagrhdr.Supplier,
      sagrhdr.CompanyCode,
      sagrhdr.DocumentCurrency,
      sagrhdr.PurchasingDocumentCategory,
      sagrhdr.PurchasingDocumentType,
      sagrhdr.PurchasingDocumentTypeName,
      sagrhdr.PurchasingOrganization,
      sagrhdr.PurchasingGroup,
      sagrhdr.CreationDate,
      sagrhdr.ValidityStartDate,
      sagrhdr.ValidityEndDate,
      sagrhdr.PaymentTerms,
      payterm.PaymentTermsName,
      sagritm.OrderQuantityUnit,
      sagritm.NetPriceAmount,
      sagritm.NetPriceQuantity,
      sagritm.OrderPriceUnit,
      sagritm.OverdelivTolrtdLmtRatioInPct,
      sagritm.UnderdelivTolrtdLmtRatioInPct,
      sagritm.TargetQuantity,
      schdline.ScheduleLineOrderQuantity,
      makt.ProductDescription,
      marc.ConsumptionTaxCtrlCode,
      $session.system_date as currentdate,
      dats_add_days(sagrhdr.ValidityEndDate, 15, 'NULL' ) as days_15
}
