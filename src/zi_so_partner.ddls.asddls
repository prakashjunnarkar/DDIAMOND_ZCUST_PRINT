@AbapCatalog.sqlViewName: 'ZV_SO_PARTNER'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'SO Partner Address'
define view ZI_SO_PARTNER
  as select from    I_SalesDocumentPartner as so_partner
    left outer join I_Address_2  as adrs_i_so on adrs_i_so.AddressID = so_partner.AddressID
                                                                                       
{

  key so_partner.SalesDocument,

      max( case so_partner.PartnerFunction when 'WE' then adrs_i_so.AddresseeFullName end )                          as WE_NAME,
      max( case so_partner.PartnerFunction when 'WE' then adrs_i_so.CityName end )                                   as WE_CITY,
      max( case so_partner.PartnerFunction when 'WE' then adrs_i_so.PostalCode end )                                 as WE_PIN,
      max( case so_partner.PartnerFunction when 'WE' then adrs_i_so.Street end )                                     as WE_STREET,
      max( case so_partner.PartnerFunction when 'WE' then adrs_i_so.StreetName end )                                 as WE_STREET1,
      max( case so_partner.PartnerFunction when 'WE' then adrs_i_so.HouseNumber end )                                as WE_HOUSE_NO,
      max( case so_partner.PartnerFunction when 'WE' then adrs_i_so.Country end )                                    as WE_COUNTRY,
      max( case so_partner.PartnerFunction when 'WE' then adrs_i_so.Region end )                                     as WE_REGION,
      max( case so_partner.PartnerFunction when 'WE' then adrs_i_so.FormOfAddress end )                              as WE_FROM_OF_ADD,
      max( case so_partner.PartnerFunction when 'WE' then adrs_i_so._EmailAddress.EmailAddress end )                 as WE_EMAIL,
      max( case so_partner.PartnerFunction when 'WE' then adrs_i_so._PhoneNumber.PhoneAreaCodeSubscriberNumber end ) as WE_PHONE4,
      max( case so_partner.PartnerFunction when 'WE' then adrs_i_so.StreetPrefixName1 end )                          as WE_StreetPrefixName1,
      max( case so_partner.PartnerFunction when 'WE' then adrs_i_so.StreetPrefixName2 end )                          as WE_StreetPrefixName2,
      max( case so_partner.PartnerFunction when 'WE' then adrs_i_so.StreetSuffixName1 end )                          as WE_StreetSuffixName1,
      max( case so_partner.PartnerFunction when 'WE' then so_partner.Customer end )                                  as ship_to_party,

      max( case so_partner.PartnerFunction when 'AG' then adrs_i_so.AddresseeFullName end )                          as AG_NAME,
      max( case so_partner.PartnerFunction when 'AG' then adrs_i_so.CityName end )                                   as AG_CITY,
      max( case so_partner.PartnerFunction when 'AG' then adrs_i_so.PostalCode end )                                 as AG_PIN,
      max( case so_partner.PartnerFunction when 'AG' then adrs_i_so.Street end )                                     as AG_STREET,
      max( case so_partner.PartnerFunction when 'AG' then adrs_i_so.StreetName end )                                 as AG_STREET1,
      max( case so_partner.PartnerFunction when 'AG' then adrs_i_so.HouseNumber end )                                as AG_HOUSE_NO,
      max( case so_partner.PartnerFunction when 'AG' then adrs_i_so.Country end )                                    as AG_COUNTRY,
      max( case so_partner.PartnerFunction when 'AG' then adrs_i_so.Region end )                                     as AG_REGION,
      max( case so_partner.PartnerFunction when 'AG' then adrs_i_so.FormOfAddress end )                              as AG_FROM_OF_ADD,
      max( case so_partner.PartnerFunction when 'AG' then adrs_i_so._EmailAddress.EmailAddress end )                 as AG_EMAIL,
      max( case so_partner.PartnerFunction when 'AG' then adrs_i_so._PhoneNumber.PhoneAreaCodeSubscriberNumber end ) as AG_PHONE4,
      max( case so_partner.PartnerFunction when 'AG' then adrs_i_so.StreetPrefixName1 end )                          as AG_StreetPrefixName1,
      max( case so_partner.PartnerFunction when 'AG' then adrs_i_so.StreetPrefixName2 end )                          as AG_StreetPrefixName2,
      max( case so_partner.PartnerFunction when 'AG' then adrs_i_so.StreetSuffixName1 end )                          as AG_StreetSuffixName1,
      max( case so_partner.PartnerFunction when 'AG' then so_partner.Customer end )                                  as AG_code

}
group by
  so_partner.SalesDocument
 // so_partner.Customer
