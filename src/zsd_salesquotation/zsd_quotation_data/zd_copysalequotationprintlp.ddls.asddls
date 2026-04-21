@EndUserText.label: 'Copy Sale Quotation print line item Tax data'
define abstract entity ZD_CopySaleQuotationPrintLP
{
  @EndUserText.label: 'New Sales Quatation'
  @UI.defaultValue: #( 'ELEMENT_OF_REFERENCED_ENTITY: Zvbeln' )
  Zvbeln : ZDE_CHAR10;
  @EndUserText.label: 'New Item'
  @UI.defaultValue: #( 'ELEMENT_OF_REFERENCED_ENTITY: Zposnr' )
  Zposnr : ZDE_CHAR6;
  
}
