@AbapCatalog.sqlViewName: 'ZI_CUST_ADD'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Customer Address'
define view ZI_CUSTOMER_ADDRESS 
as select from    I_Customer  as kna1
left outer join I_Address_2 as adrc on kna1.AddressID = adrc.AddressID
{

  key kna1.Customer,
      kna1.CustomerName,
      kna1.CustomerFullName,
      kna1.Country,
      kna1.TaxNumber3,
      kna1.AddressID,
      kna1.TelephoneNumber1 as PhoneNumber1,
      kna1.TelephoneNumber1 as PhoneNumber2,
      kna1.Region as REGIO,
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
