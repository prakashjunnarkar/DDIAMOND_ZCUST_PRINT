@EndUserText.label: 'Tax code GST percent Singleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'TaxCodeGstPercenAll'
  }
}
define root view entity ZI_TaxCodeGstPercent_S
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_TAXCODEGSTPERCENT'
  composition [0..*] of ZI_TaxCodeGstPercent as _TaxCodeGstPercent
{
  @UI.facet: [ {
    id: 'ZI_TaxCodeGstPercent', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'Tax code GST percent', 
    position: 1 , 
    targetElement: '_TaxCodeGstPercent'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _TaxCodeGstPercent,
  @UI.hidden: true
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax
}
where I_Language.Language = $session.system_language
