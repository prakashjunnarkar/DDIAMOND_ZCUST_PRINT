@AbapCatalog.sqlViewName: 'ZV_PLANT_ADRS'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Plant Address'
define view ZI_PLANT_ADDRESS
  as select from    I_Plant               as plant
    left outer join I_OrganizationAddress as adrc on plant.AddressID = adrc.AddressID
    left outer join I_RegionText as regiontxt on regiontxt.Region = adrc.Region and
                                                 regiontxt.Language = 'E' and
                                                 regiontxt.Country = 'IN'
{

  key plant.Plant,
      plant.PlantName,
      plant.AddressID,
      adrc.AddresseeFullName,
      adrc.StreetPrefixName1,
      adrc.StreetPrefixName2,
      adrc.StreetName,
      adrc.StreetSuffixName1,
      adrc.DistrictName,
      adrc.CityName,
      adrc.PostalCode,
      adrc.AddressRepresentationCode,
      adrc.Region,
      adrc.Country,
      regiontxt.RegionName,
      adrc.AddressPersonID,
      adrc.Street,
      adrc.HouseNumber,
      adrc.FormOfAddress,
      adrc.AddressTimeZone,
      adrc._PhoneNumber.PhoneAreaCodeSubscriberNumber,
      adrc._EmailAddress.EmailAddress      

}
