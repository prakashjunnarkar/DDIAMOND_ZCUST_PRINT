@AbapCatalog.sqlViewName: 'ZV_SCH_AGMNT'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Scheduling agreement Data'
@Metadata.ignorePropagatedAnnotations: true
define view ZI_SCHEDULE_AGREEMENT as select from I_SchedgagrmthdrApi01 as sahdr
{

key sahdr.SchedulingAgreement,
sahdr.CompanyCode,
sahdr.PurchasingDocumentType,
sahdr.PurchasingDocumentTypeName,
sahdr.CreationDate
    
}
