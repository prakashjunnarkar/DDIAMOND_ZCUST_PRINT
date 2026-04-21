@AbapCatalog.sqlViewName: 'ZI_VEN_ADD'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vendor Address'
define view ZI_SUPPLIER_ADDRESS
  as select from    I_Supplier  as lfa1
    left outer join I_Address_2 as adrc on lfa1.AddressID = adrc.AddressID
{

  key lfa1.Supplier,
      lfa1.SupplierName,
      lfa1.SupplierFullName,
      lfa1.Country,
      lfa1.TaxNumber3,
      lfa1.AddressID,
      lfa1.PhoneNumber1,
      lfa1.PhoneNumber2,
      lfa1.Region as REGIO,
      lfa1.SuplrManufacturerExternalName,
      lfa1.BusinessPartnerPanNumber,      
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
