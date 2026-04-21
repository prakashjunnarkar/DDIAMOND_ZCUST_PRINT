@EndUserText.label: 'Sale Quotation print line item Tax data'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'SaleQuotationPriAll'
  }
}
define root view entity ZI_SaleQuotationPrintL_S
  as select from I_Language
    left outer join ZSALESQU_TAX on 0 = 0
  composition [0..*] of ZI_SaleQuotationPrintL as _SaleQuotationPrintL
{
  @UI.facet: [ {
    id: 'ZI_SaleQuotationPrintL', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'Sale Quotation print line item Tax data', 
    position: 1 , 
    targetElement: '_SaleQuotationPrintL'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _SaleQuotationPrintL,
  @UI.hidden: true
  max( ZSALESQU_TAX.LAST_CHANGED_AT ) as LastChangedAtMax
  
}
where I_Language.Language = $session.system_language
