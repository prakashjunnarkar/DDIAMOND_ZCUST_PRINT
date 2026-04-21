@AbapCatalog.sqlViewName: 'ZV_DC_NOTE1'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'DC Note'
define view ZI_DC_NOTE
  as select from    I_OperationalAcctgDocItem as dc
    left outer join I_JournalEntry            as bkpf  on  bkpf.AccountingDocument = dc.AccountingDocument
                                                       and bkpf.CompanyCode        = dc.CompanyCode
                                                       and bkpf.FiscalYear         = dc.FiscalYear  
                                                                                                       
    left outer join I_CompanyCode             as comp  on comp.CompanyCode = dc.CompanyCode

    left outer join ZI_SUPPLIER_ADDRESS       as suppl on suppl.Supplier = dc.Supplier

    left outer join ZI_CUSTOMER_ADDRESS       as cust  on cust.Customer = dc.Customer
{

  key dc.CompanyCode, 
  key dc.AccountingDocument,
  key dc.FiscalYear,
  key dc.AccountingDocumentItem,
      dc.FinancialAccountType,
      dc.ChartOfAccounts,
      dc.AccountingDocumentItemType,
      dc.PostingKey,
      dc.Product,
      dc.Plant,
      dc.PostingDate,
      dc.DocumentDate,
      dc.DebitCreditCode,
      dc.TaxCode,
      dc.TaxItemGroup,
      dc.TransactionTypeDetermination, //CGST, SGST code
      dc.GLAccount,
      dc.Customer,
      dc.Supplier,
      dc.PurchasingDocument,
      dc.PurchasingDocumentItem,
      dc.PurchaseOrderQty,
      dc.ProfitCenter,
      dc.DocumentItemText,
      dc.AmountInCompanyCodeCurrency,
      dc.AmountInTransactionCurrency,

      dc.CashDiscountBaseAmount,
      dc.NetPaymentAmount,

      dc.AssignmentReference,
      dc.InvoiceReference,
      dc.InvoiceReferenceFiscalYear,
      dc.InvoiceItemReference,


      dc.Quantity,
      dc.BaseUnit,
      dc.MaterialPriceUnitQty,
      dc.TaxBaseAmountInTransCrcy,

      dc.ClearingJournalEntry,
      dc.ClearingDate,
      dc.ClearingCreationDate,
      dc.ClearingJournalEntryFiscalYear,
      dc.ClearingItem,
      dc.HouseBank,
      dc.BPBankAccountInternalID,
      dc.HouseBankAccount,
      dc.IN_HSNOrSACCode,
      dc.CostCenter,
      dc.AccountingDocumentType,
      dc.NetDueDate,
      dc.OffsettingAccount,
      dc.TransactionCurrency,
      dc.PaymentTerms,
      dc.BusinessPlace,
      dc.ValueDate,
      dc.PaymentMethod,
      dc.SpecialGLCode,
      dc.SpecialGLTransactionType,
      dc.WithholdingTaxAbsoluteAmount,
      dc.CashDiscountAbsoluteBaseAmount,
      bkpf.DocumentReferenceID,
      bkpf.AlternativeReferenceDocument,
      bkpf.AccountingDocumentHeaderText,
      comp.CompanyCodeName,
      comp.AddressID,
      suppl.SupplierFullName,
      cust.CustomerFullName   
          

}
