@AbapCatalog.sqlViewName: 'ZV_PORT_ADDRESS'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Port address'
@Metadata.ignorePropagatedAnnotations: true
define view ZI_PORT_ADDRESS
  as select from    I_BusinessPartner         as bp
    left outer join I_BusinessPartnerCustomer as bpc  on bpc.BusinessPartner = bp.BusinessPartner
    left outer join I_Address_2               as adrc on adrc.AddressID = bpc.AddressID
{

  key bp.BusinessPartner,
  key bpc.AddressID,
  bp.BusinessPartnerCategory,
  bpc.Customer,
  bpc.Country,
  adrc.AddresseeFullName,
  adrc.OrganizationName1,
  adrc.OrganizationName2,
  adrc.StreetPrefixName1,
  adrc.StreetPrefixName2,
  adrc.StreetName,
  adrc.StreetSuffixName1,
  adrc.DistrictName,
  adrc.CityName,
  adrc.PostalCode,
  adrc.AddressRepresentationCode,
  adrc.Region,
  adrc.AddressPersonID,
  adrc.Street,
  adrc.HouseNumber,
  adrc.FormOfAddress,
  adrc.AddressTimeZone,
  adrc._EmailAddress.EmailAddress


}
