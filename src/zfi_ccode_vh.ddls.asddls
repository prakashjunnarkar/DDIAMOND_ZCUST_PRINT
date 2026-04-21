@AbapCatalog.sqlViewName: 'ZV_CCODE_VH'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Company code Value Help'
@Metadata.ignorePropagatedAnnotations: true
define view ZFI_CCODE_VH as select from I_CompanyCodeVH
{
    key CompanyCode,
    CompanyCodeName    
    
}
