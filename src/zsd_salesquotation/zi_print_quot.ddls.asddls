@AbapCatalog.sqlViewName: 'ZV_PRINT_QUOT'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Quotation print'
@Metadata.ignorePropagatedAnnotations: true
define view ZI_PRINT_QUOT
  as select from I_SalesQuotation as so
{

  key  so.SalesQuotation     as SalesDocument,
       so.SalesQuotationType as SalesDocumentType,
       so.CreationDate       as CreationDate,
       so.SalesOrganization  as SalesOrganization,
       so.DistributionChannel,
       so.OrganizationDivision,
       so.SalesGroup,
       so.SalesOffice
       
     
      // so.SDDocumentCategory

}
//where so.SDDocumentCategory = 'B'
