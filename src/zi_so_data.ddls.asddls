@AbapCatalog.sqlViewName: 'ZV_SO_DATA'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'SO Data'
define view ZI_SO_DATA as select from I_SalesDocument as so
{
 
 key so.SalesDocument,
 so.SalesDocumentType,
 so.CreationDate,
 so.SalesOrganization,
 so.DistributionChannel,
 so.OrganizationDivision,
 so.SalesGroup,
 so.SalesOffice
    
}
