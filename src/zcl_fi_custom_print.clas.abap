CLASS zcl_fi_custom_print DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA:
      gt_dbnote TYPE TABLE OF zstr_fi_debit_note,
      gs_dbnote TYPE zstr_fi_debit_note,
      gt_item   TYPE TABLE OF zstr_fi_debit_note_item,
      xt_item   TYPE TABLE OF zstr_fi_debit_note_item,
      gs_item   TYPE zstr_fi_debit_note_item.

    DATA:
      gt_final TYPE TABLE OF zstr_voucher_print,
      gs_final TYPE zstr_voucher_print,
      lt_item  TYPE TABLE OF zstr_voucher_print_item,
      ls_item  TYPE zstr_voucher_print_item.

    DATA:
      lv_char10  TYPE c LENGTH 10,
      lv_char4   TYPE c LENGTH 4,
      lv_char120 TYPE c LENGTH 120.

    DATA:
      sys_date     TYPE d,
      sys_time     TYPE t,
      sys_timezone TYPE timezone,
      sy_uname     TYPE c LENGTH 20.

    METHODS:
      get_fidebit_data
        IMPORTING
                  im_bukrs         LIKE lv_char4
                  im_belnr         LIKE lv_char10
                  im_gjahr         TYPE zi_dc_note-FiscalYear
                  im_action        LIKE lv_char10
        RETURNING VALUE(et_dbdata) LIKE gt_dbnote,

      get_payadv_data
        IMPORTING
                  im_bukrs         LIKE lv_char4
                  im_belnr         LIKE lv_char10
                  im_gjahr         TYPE zi_dc_note-FiscalYear
                  im_action        LIKE lv_char10
        RETURNING VALUE(et_payadv) LIKE gt_dbnote,

      get_chqprnt_data
        IMPORTING
                  im_bukrs          LIKE lv_char4
                  im_belnr          LIKE lv_char10
                  im_gjahr          TYPE zi_dc_note-FiscalYear
                  im_action         LIKE lv_char10
        RETURNING VALUE(et_chqprnt) LIKE gt_dbnote,

      prep_xml_fidebit
        IMPORTING
                  it_dbnote            LIKE gt_dbnote
                  im_action            LIKE lv_char10
        RETURNING VALUE(iv_xml_base64) TYPE string,

      prep_xml_payadv
        IMPORTING
                  it_payadv            LIKE gt_dbnote
                  im_action            LIKE lv_char10
        RETURNING VALUE(iv_xml_base64) TYPE string,

      prep_xml_chqprnt
        IMPORTING
                  it_chqprnt           LIKE gt_dbnote
                  im_action            LIKE lv_char10
        RETURNING VALUE(iv_xml_base64) TYPE string,

      get_voucher_data
        IMPORTING
                  im_bukrs        LIKE lv_char4
                  im_belnr        LIKE lv_char10
                  im_gjahr        TYPE zi_dc_note-FiscalYear
                  im_action       LIKE lv_char10
        RETURNING VALUE(et_final) LIKE gt_final,

      prep_xml_voucher_print
        IMPORTING
                  it_final             LIKE gt_final
                  iv_action            LIKE lv_char10
        RETURNING VALUE(iv_xml_base64) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS ZCL_FI_CUSTOM_PRINT IMPLEMENTATION.


  METHOD get_chqprnt_data.

    DATA:
      lo_amt_words   TYPE REF TO zcl_amt_words,
      lv_sum_chq_amt TYPE p LENGTH 16 DECIMALS 2.

    DATA:
      lv_amount_neg TYPE c LENGTH 20.

    CREATE OBJECT lo_amt_words.

    IF im_belnr IS NOT INITIAL.

      SELECT
      *
      FROM zi_dc_note
      WHERE
        companycode = @im_bukrs AND AccountingDocument = @im_belnr AND FiscalYear = @im_gjahr
        INTO TABLE @DATA(lt_acc).             "#EC CI_ALL_FIELDS_NEEDED

      SELECT * FROM zi_cheque_detail
      WHERE
      PaymentCompanyCode = @im_bukrs AND PaymentDocument = @im_belnr AND FiscalYear = @im_gjahr
      INTO TABLE @DATA(lt_chq).               "#EC CI_ALL_FIELDS_NEEDED

      DATA(xt_acc) = lt_acc[].
      READ TABLE xt_acc INTO DATA(xs_acc) INDEX 1.      "#EC CI_NOORDER

      SELECT SINGLE * FROM zi_supplier_address
      WHERE Supplier = @xs_acc-Supplier INTO @DATA(ls_supplier). "#EC CI_ALL_FIELDS_NEEDED

      gs_dbnote-companycode          = xs_acc-CompanyCode.
      gs_dbnote-accountingdocument   = xs_acc-AccountingDocument.
      gs_dbnote-fiscalyear           = xs_acc-FiscalYear.
      gs_dbnote-postingdate          = xs_acc-PostingDate.
      gs_dbnote-documentdate         = xs_acc-DocumentDate.
      gs_dbnote-acc_payee            = 'A/C Payee' ##NO_TEXT.


      READ TABLE lt_chq INTO DATA(ls_chq) WITH KEY PaymentDocument = xs_acc-AccountingDocument
                                                   ChequeStatus    = '10'.

      IF sy-subrc EQ 0.

        gs_dbnote-bank_name         = ls_chq-BankName.
        gs_dbnote-bank_det1         = ls_chq-HouseBankAccount.
        gs_dbnote-suppl_code        = ls_chq-Supplier.  "ls_supplier-Supplier.
        gs_dbnote-suppl_name        = ls_chq-PayeeName. "ls_supplier-AddresseeFullName.
        gs_dbnote-cheque_no         = ls_chq-OutgoingCheque.
        gs_dbnote-cheque_date       = ls_chq-ChequePaymentDate.

        lv_amount_neg = ls_chq-PaidAmountInPaytCurrency. "xs_acc-AmountInCompanyCodeCurrency.
        IF lv_amount_neg CA '-'.
          gs_dbnote-chq_amt   = ls_chq-PaidAmountInPaytCurrency * -1. "xs_acc-AmountInCompanyCodeCurrency * -1.
        ELSE.
          gs_dbnote-chq_amt   = ls_chq-PaidAmountInPaytCurrency. "xs_acc-AmountInCompanyCodeCurrency.
        ENDIF.

      ENDIF.

      DATA: lv_grand_tot_word TYPE string.

      IF gs_dbnote-chq_amt IS NOT INITIAL.

        lv_grand_tot_word = gs_dbnote-chq_amt.

        lo_amt_words->number_to_words(
          EXPORTING
            iv_num   = lv_grand_tot_word
          RECEIVING
            rv_words = DATA(amt_words)
        ).

        gs_dbnote-tot_amt_words = amt_words.

      ENDIF.

      APPEND gs_dbnote TO et_chqprnt.

    ENDIF.

  ENDMETHOD.


  METHOD get_fidebit_data .

    DATA:
      lo_amt_words     TYPE REF TO zcl_amt_words,
      lv_total_value   TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_frt_amt   TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_cgst_amt  TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_sgst_amt  TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_igst_amt  TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_tcs_amt   TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_load_amt  TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_rndf_amt  TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_other_amt TYPE p LENGTH 16 DECIMALS 2,
      lv_grand_total   TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_gst_amt   TYPE p LENGTH 16 DECIMALS 2,
      lv_amount_neg    TYPE c LENGTH 20,
      region_desc      TYPE c LENGTH 20.

    CREATE OBJECT lo_amt_words.

    IF im_belnr IS NOT INITIAL.

      SELECT
        *
        FROM zi_dc_note
        WHERE companycode = @im_bukrs AND accountingdocument = @im_belnr AND fiscalyear = @im_gjahr
        INTO TABLE @DATA(lt_acc) .

      IF ( im_action = 'fidebit' OR im_action = 'fircm' ).

        SELECT
          *
          FROM zi_dc_note
          WHERE companycode = @im_bukrs AND accountingdocument = @im_belnr
             AND fiscalyear = @im_gjahr AND TransactionTypeDetermination IN ( 'WRX', 'BSX', 'PRD' ,' ' )
             INTO TABLE @DATA(lt_wrx_bsx).

*              SELECT *
*          FROM zi_dc_note
*          WHERE companycode = @im_bukrs AND accountingdocument = @im_belnr
*             AND fiscalyear = @im_gjahr AND TransactionTypeDetermination IN ('WRX', 'BSX',  'EGK', 'PRD' )
*             INTO TABLE @DATA(lt_wrx_bsx).

      ELSEIF ( im_action = 'ficredit' OR im_action = 'fitaxinv' ).

        SELECT
          *
          FROM zi_dc_note
          WHERE companycode = @im_bukrs AND accountingdocument = @im_belnr
             AND fiscalyear = @im_gjahr AND TransactionTypeDetermination EQ ''
             INTO TABLE @lt_wrx_bsx.

      ENDIF.

      DATA(xt_acc) = lt_acc[].
      SORT xt_acc BY companycode accountingdocument fiscalyear.
      DELETE ADJACENT DUPLICATES FROM xt_acc COMPARING companycode accountingdocument fiscalyear.

      LOOP AT xt_acc INTO DATA(xs_acc).

        """******Header Data
        gs_dbnote-companycode          = xs_acc-CompanyCode.
        gs_dbnote-accountingdocument   = xs_acc-AccountingDocument.
        gs_dbnote-accountingdocumenttype = xs_acc-AccountingDocumentType.
        gs_dbnote-fiscalyear           = xs_acc-FiscalYear.
        gs_dbnote-postingdate          = xs_acc-PostingDate.
        gs_dbnote-documentdate         = xs_acc-DocumentDate.


        DATA(lt_acc_plant) = lt_acc[].
        DELETE lt_acc_plant WHERE plant EQ ''.
        IF lt_acc_plant[] IS INITIAL.
          lt_acc_plant[] = lt_acc[].
          DELETE lt_acc_plant WHERE BusinessPlace EQ ''.
        ENDIF.

        READ TABLE lt_acc_plant INTO DATA(ls_acc_plant) INDEX 1. "#EC CI_NOORDER
        IF sy-subrc EQ 0.

          SELECT SINGLE * FROM zi_plant_address
          WHERE plant = @ls_acc_plant-BusinessPlace INTO @DATA(ls_plant_adrs). "#EC CI_NOORDER

          SELECT SINGLE
          CompanyCode,
          BusinessPlace,
          BusinessPlaceDescription,
          AddressID,
          IN_GSTIdentificationNumber
          FROM I_IN_BusinessPlaceTaxDetail
          WHERE CompanyCode = @ls_acc_plant-CompanyCode AND BusinessPlace = @ls_acc_plant-BusinessPlace
          INTO @DATA(ls_bus_place).

          gs_dbnote-suppl_code         = ls_acc_plant-BusinessPlace. "ls_acc_plant-Plant.
          gs_dbnote-suppl_name         = ls_plant_adrs-AddresseeFullName. "ls_plant_adrs-PlantName.

          IF ls_plant_adrs-StreetPrefixName2 IS NOT INITIAL.
            gs_dbnote-suppl_addr1        = ls_plant_adrs-StreetPrefixName1 && ',' && ls_plant_adrs-StreetPrefixName2.
          ELSE.
            gs_dbnote-suppl_addr1        = ls_plant_adrs-StreetPrefixName1.
          ENDIF.

          gs_dbnote-suppl_addr2        = ls_plant_adrs-StreetName &&  ',' && ls_plant_adrs-StreetSuffixName1. "&&  ',' && ls_plant_adrs-DistrictName.

          IF ls_plant_adrs-Region EQ 'HR'.
            region_desc = 'Haryana' ##NO_TEXT.
          ENDIF.

          gs_dbnote-suppl_cin          = 'U31908HR2007FTC039788' ##NO_TEXT.

          CONDENSE gs_dbnote-suppl_code.
          IF gs_dbnote-suppl_code = '1001'.
            gs_dbnote-suppl_gstin        = '06AACCD6342B1Z6' ##NO_TEXT. "for plant 1001

          ELSEIF xs_acc-companycode = '1002'.
            gs_dbnote-suppl_gstin        = '33AACCD6342B1Z9' ##NO_TEXT. "for plant 1001

          ELSEIF xs_acc-companycode = '1003'.
            gs_dbnote-suppl_gstin        = '06AACCD6342B1Z6' ##NO_TEXT.

          ELSEIF xs_acc-companycode = '1004'.
            gs_dbnote-suppl_gstin        = '24AACCD6342B1Z8' ##NO_TEXT.

          ELSEIF xs_acc-companycode = '1005'.
            gs_dbnote-suppl_gstin        = '37AACCD6342B1Z1' ##NO_TEXT.

          ELSEIF xs_acc-companycode = '1006'.
            gs_dbnote-suppl_gstin        = '33AACCD6342B1Z9' ##NO_TEXT.

          ELSEIF xs_acc-companycode = '1007'.
            gs_dbnote-suppl_gstin        = '08AACCD6342B1Z2' ##NO_TEXT.

          ENDIF.

          gs_dbnote-suppl_pan          = gs_dbnote-suppl_gstin+0(10).

          gs_dbnote-suppl_addr3        = ls_plant_adrs-CityName &&  ',' &&  region_desc && ',' && ls_plant_adrs-PostalCode .
*          gs_dbnote-suppl_cin          = '' ##NO_TEXT.
*          gs_dbnote-suppl_gstin        = ls_bus_place-IN_GSTIdentificationNumber ##NO_TEXT. "for plant 1001
*          gs_dbnote-suppl_pan          = gs_dbnote-suppl_gstin+0(10).

          SELECT SINGLE * FROM zi_regiontext WHERE Region = @ls_plant_adrs-Region AND Language = 'E' AND Country = @ls_plant_adrs-Country
           INTO @DATA(lv_st_nm).              "#EC CI_ALL_FIELDS_NEEDED

          gs_dbnote-suppl_stat_code    = lv_st_nm-RegionName. "ls_plant_adrs-Region.
          gs_dbnote-suppl_phone        = ''.
          gs_dbnote-suppl_email        = 'info@ddmnd.com'.

        ENDIF.

        IF ( im_action = 'fidebit' OR im_action = 'fircm' ).

          READ TABLE lt_acc INTO DATA(ls_acc_kbs) WITH KEY TransactionTypeDetermination = 'KBS'. " and K
          SELECT SINGLE * FROM zi_supplier_address
          WHERE Supplier = @ls_acc_kbs-Supplier INTO @DATA(ls_supplier).

          IF ls_acc_kbs IS INITIAL.
            READ TABLE lt_acc INTO ls_acc_kbs WITH KEY TransactionTypeDetermination = 'EGK'. " and K
            SELECT SINGLE * FROM zi_supplier_address
            WHERE Supplier = @ls_acc_kbs-Supplier INTO @ls_supplier.
          ENDIF.

        ELSEIF ( im_action = 'ficredit' OR im_action = 'fitaxinv' ).

          CLEAR: ls_acc_kbs.
          READ TABLE lt_acc INTO ls_acc_kbs WITH KEY TransactionTypeDetermination = 'AGD'.
          SELECT SINGLE * FROM zi_customer_address
          WHERE Customer = @ls_acc_kbs-Customer INTO @DATA(ls_customer).

          ls_supplier = CORRESPONDING #( ls_customer ).

        ENDIF.

        IF sy-subrc EQ 0.

          SELECT SINGLE * FROM ZI_CountryText   WHERE Country = @ls_supplier-country AND Language = 'E'
          INTO @DATA(lv_cn_name_we).          "#EC CI_ALL_FIELDS_NEEDED

          SELECT SINGLE * FROM zi_regiontext  WHERE Region = @ls_supplier-regio AND Language = 'E' AND Country = @ls_supplier-country
          INTO @DATA(lv_st_name_we).          "#EC CI_ALL_FIELDS_NEEDED

          gs_dbnote-billto_code        = xs_acc-Supplier.
          gs_dbnote-billto_name        = ls_supplier-AddresseeFullName.
          gs_dbnote-billto_addr1       = ls_supplier-StreetPrefixName1 && ',' && ls_supplier-StreetPrefixName2.
          gs_dbnote-billto_addr2       = ls_supplier-StreetName &&  ',' && ls_supplier-StreetSuffixName1 &&  ',' && ls_supplier-DistrictName.
          gs_dbnote-billto_addr3       = ls_supplier-CityName &&  ',' && ls_supplier-PostalCode &&  ',' && lv_cn_name_we-CountryName.
          gs_dbnote-billto_cin         = ''.
          gs_dbnote-billto_gstin       = ls_supplier-TaxNumber3.
          gs_dbnote-billto_pan         = ''.
          gs_dbnote-billto_stat_code   = lv_st_name_we-RegionName. "ls_supplier-regio.
          gs_dbnote-billto_phone       = ls_supplier-PhoneNumber1.
          gs_dbnote-billto_email       = ''.

          gs_dbnote-shipto_code        = xs_acc-Supplier.
          gs_dbnote-shipto_name        = ls_supplier-AddresseeFullName.
          gs_dbnote-shipto_addr1       = ls_supplier-StreetPrefixName1 && ',' && ls_supplier-StreetPrefixName2.
          gs_dbnote-shipto_addr2       = ls_supplier-StreetName &&  ',' && ls_supplier-StreetSuffixName1 &&  ',' && ls_supplier-DistrictName.
          gs_dbnote-shipto_addr3       = ls_supplier-CityName &&  ',' && ls_supplier-PostalCode &&  ',' && lv_cn_name_we-CountryName.
          gs_dbnote-shipto_cin         = ''.
          gs_dbnote-shipto_gstin       = ls_supplier-TaxNumber3.
          gs_dbnote-shipto_pan         = ls_supplier-TaxNumber3+2(10).
          gs_dbnote-shipto_stat_code   = lv_st_name_we-RegionName. "ls_supplier-regio.
*          gs_dbnote-shipto_phone       = ls_supplier-PhoneNumber1.
          gs_dbnote-shipto_email       = ''.
          gs_dbnote-shipto_place_supply  = ''.

          CLEAR: lv_amount_neg.
          lv_amount_neg = xs_acc-AmountInCompanyCodeCurrency.
          CONDENSE lv_amount_neg.
          IF lv_amount_neg CA '-'.
            lv_grand_total = xs_acc-AmountInCompanyCodeCurrency * -1.
          ELSE.
            lv_grand_total = xs_acc-AmountInCompanyCodeCurrency.
          ENDIF.

        ENDIF.

        gs_dbnote-veh_no               = ''.
        gs_dbnote-trnas_mode           = ''.
        gs_dbnote-inv_no               = xs_acc-AccountingDocument.
        gs_dbnote-inv_date             = xs_acc-PostingDate+6(2) && '.' && xs_acc-PostingDate+4(2) && '.' && xs_acc-PostingDate+0(4).
        gs_dbnote-inv_ref_no           = xs_acc-DocumentReferenceID. "InvoiceReference.
        gs_dbnote-tax_payable_rev      = ''.
        gs_dbnote-remark               = xs_acc-DocumentItemText.
        gs_dbnote-trans_curr           = xs_acc-TransactionCurrency.

        IF im_action = 'fircm'.
          gs_dbnote-inv_date             = xs_acc-DocumentDate+6(2) && '.' && xs_acc-DocumentDate+4(2) && '.' && xs_acc-DocumentDate+0(4).
          gs_dbnote-inv_ref_no           = xs_acc-AccountingDocument. "xs_acc-AlternativeReferenceDocument.
          gs_dbnote-inv_no               = xs_acc-DocumentReferenceID.
          gs_dbnote-inv_ref_date         = xs_acc-PostingDate+6(2) && '.' && xs_acc-PostingDate+4(2) && '.' && xs_acc-PostingDate+0(4).
          READ TABLE lt_acc INTO DATA(xs_remark) WITH KEY FinancialAccountType = 'K'.
          gs_dbnote-remark               = xs_remark-DocumentItemText.
        ENDIF.

        IF im_action = 'fidebit'.

          CLEAR: xs_remark .
          READ TABLE lt_acc INTO xs_remark WITH KEY FinancialAccountType = 'K'.
          gs_dbnote-remark               = xs_remark-DocumentItemText.

          SELECT SINGLE DocumentDate FROM zi_dc_note
                 WHERE AccountingDocument = @xs_remark-InvoiceReference AND
                       FiscalYear         = @xs_remark-InvoiceReferenceFiscalYear
                       INTO @DATA(lv_doc_date).

          gs_dbnote-inv_no               = xs_acc-AccountingDocument.
          gs_dbnote-ref_doc_no           = xs_remark-InvoiceReference.
          gs_dbnote-inv_ref_date         = lv_doc_date+6(2) && '.' && lv_doc_date+4(2) && '.' && lv_doc_date+0(4).

        ENDIF.

        IF im_action = 'ficredit'.

          CLEAR: xs_remark .
          READ TABLE lt_acc INTO xs_remark WITH KEY FinancialAccountType = 'D'.
          gs_dbnote-remark               = xs_remark-DocumentItemText.
          gs_dbnote-inv_no               = xs_acc-DocumentReferenceID.

          SELECT SINGLE PostingDate FROM zi_dc_note
                 WHERE AccountingDocument = @xs_acc-InvoiceReference AND
                       FiscalYear         = @xs_acc-InvoiceReferenceFiscalYear
                       INTO @lv_doc_date.

          gs_dbnote-inv_ref_no           = xs_acc-InvoiceReference.
          gs_dbnote-inv_ref_date         = lv_doc_date+6(2) && '.' && lv_doc_date+4(2) && '.' && lv_doc_date+0(4). "xs_acc-DocumentDate+6(2) && '.' && xs_acc-DocumentDate+4(2) && '.' && xs_acc-DocumentDate+0(4).

          IF gs_dbnote-accountingdocumenttype = 'DR'.
            gs_dbnote-inv_no               = ''.
            gs_dbnote-inv_ref_no           = xs_acc-DocumentReferenceID.
            gs_dbnote-inv_ref_date         = gs_dbnote-inv_date.
            gs_dbnote-inv_date             = ''.
          ENDIF.

        ENDIF.

        IF im_action = 'fitaxinv'.
          CLEAR: xs_remark .
          READ TABLE lt_acc INTO xs_remark WITH KEY FinancialAccountType = 'D'.
          gs_dbnote-remark               = xs_remark-DocumentItemText.
          gs_dbnote-inv_no               = xs_acc-DocumentReferenceID.
          gs_dbnote-inv_date             = xs_acc-DocumentDate+6(2) && '.' && xs_acc-DocumentDate+4(2) && '.' && xs_acc-DocumentDate+0(4).
        ENDIF.

        """******Item Data
        CLEAR: gs_item.
        LOOP AT lt_acc INTO DATA(ls_acc)
                       WHERE companycode  = xs_acc-CompanyCode AND
                       accountingdocument = xs_acc-AccountingDocument AND
                       fiscalyear = xs_acc-FiscalYear AND
                       ( TransactionTypeDetermination = 'JIC' OR TransactionTypeDetermination = 'JIS' OR
                         TransactionTypeDetermination = 'JII' OR TransactionTypeDetermination = 'FR1' OR
                         TransactionTypeDetermination = 'RND' OR TransactionTypeDetermination = 'LOD' OR
                         TransactionTypeDetermination = 'OTH' OR TransactionTypeDetermination = 'TCS' OR
                         TransactionTypeDetermination = 'JOC' OR TransactionTypeDetermination = 'JOS' OR
                         TransactionTypeDetermination = 'JOI' OR TransactionTypeDetermination = 'JSN'
                         OR TransactionTypeDetermination = 'JCN'
                       ).


          gs_item-companycode            = ls_acc-CompanyCode.
          gs_item-accountingdocument     = ls_acc-AccountingDocument.
          gs_item-fiscalyear             = ls_acc-FiscalYear.
          gs_item-accountingdocumentitem = ls_acc-AccountingDocumentItem.
          gs_item-TaxItemGroup           = ls_acc-TaxItemGroup.

          CLEAR: lv_amount_neg.
          lv_amount_neg = ls_acc-AmountInCompanyCodeCurrency.
          CONDENSE lv_amount_neg.
          IF lv_amount_neg CA '-'.
            ls_acc-AmountInCompanyCodeCurrency = ls_acc-AmountInCompanyCodeCurrency * -1.
          ENDIF.

          IF ( ls_acc-TransactionTypeDetermination = 'JIC' OR ls_acc-TransactionTypeDetermination = 'JOC' ).

            gs_item-Cgst_amt     = ls_acc-AmountInCompanyCodeCurrency.
            lv_sum_cgst_amt      = lv_sum_cgst_amt  + ls_acc-AmountInCompanyCodeCurrency.
            gs_item-cgst_rate    = ''.

          ELSEIF ( ls_acc-TransactionTypeDetermination = 'JIS' OR ls_acc-TransactionTypeDetermination = 'JOS' ).

            gs_item-Sgst_amt            = ls_acc-AmountInCompanyCodeCurrency.
            lv_sum_sgst_amt  = lv_sum_sgst_amt + ls_acc-AmountInCompanyCodeCurrency.
            gs_item-sgst_rate           = ''.

          ELSEIF ( ls_acc-TransactionTypeDetermination = 'JSN' ).

            gs_item-Sgst_amt            = ls_acc-AmountInCompanyCodeCurrency.
            lv_sum_sgst_amt  = lv_sum_sgst_amt + ls_acc-AmountInCompanyCodeCurrency.
            gs_item-sgst_rate           = ''.

          ELSEIF ( ls_acc-TransactionTypeDetermination = 'JCN' ).

            gs_item-Cgst_amt     = ls_acc-AmountInCompanyCodeCurrency.
            lv_sum_cgst_amt      = lv_sum_cgst_amt  + ls_acc-AmountInCompanyCodeCurrency.
            gs_item-cgst_rate    = ''.


          ELSEIF ( ls_acc-TransactionTypeDetermination = 'JII' OR ls_acc-TransactionTypeDetermination = 'JOI' ).

            gs_item-igst_amt     = ls_acc-AmountInCompanyCodeCurrency.
            lv_sum_igst_amt  = lv_sum_igst_amt + ls_acc-AmountInCompanyCodeCurrency.
            gs_item-igst_rate           = ''.

          ELSEIF ls_acc-TransactionTypeDetermination = 'FR1'.

            gs_item-frt_amt             = ls_acc-AmountInCompanyCodeCurrency.
            lv_sum_frt_amt  = lv_sum_frt_amt + ls_acc-AmountInCompanyCodeCurrency.

          ELSEIF ls_acc-TransactionTypeDetermination = 'RND'.

            gs_item-rndf_amt            = ls_acc-AmountInCompanyCodeCurrency.
            lv_sum_rndf_amt  = lv_sum_rndf_amt + ls_acc-AmountInCompanyCodeCurrency.

          ELSEIF ls_acc-TransactionTypeDetermination = 'LOD'.

            gs_item-load_amt            = ls_acc-AmountInCompanyCodeCurrency.
            lv_sum_load_amt  = lv_sum_load_amt + ls_acc-AmountInCompanyCodeCurrency.

          ELSEIF ls_acc-TransactionTypeDetermination = 'OTH'.

            gs_item-othr_amt            = ls_acc-AmountInCompanyCodeCurrency.
            lv_sum_other_amt  = lv_sum_other_amt + ls_acc-AmountInCompanyCodeCurrency.

          ELSEIF ls_acc-TransactionTypeDetermination = 'TCS'.

            gs_item-tcs_amt            = ls_acc-AmountInCompanyCodeCurrency.
            lv_sum_tcs_amt  = lv_sum_tcs_amt + ls_acc-AmountInCompanyCodeCurrency.

          ENDIF.
          APPEND gs_item TO xt_item.

          CLEAR: ls_acc, gs_item.
        ENDLOOP.

        gs_dbnote-sum_cgst_amt1         = lv_sum_cgst_amt.
        gs_dbnote-sum_sgst_amt1         = lv_sum_sgst_amt.
        gs_dbnote-sum_igst_amt1         = lv_sum_igst_amt.
        lv_sum_gst_amt = lv_sum_cgst_amt + lv_sum_sgst_amt + lv_sum_igst_amt.

        CLEAR: ls_acc, gs_item.
        CLEAR: lv_sum_cgst_amt, lv_sum_sgst_amt, lv_sum_igst_amt.
        DATA(lt_bsx) = lt_wrx_bsx[].
        DATA(lt_prd) = lt_wrx_bsx[].
        DELETE lt_bsx WHERE TransactionTypeDetermination NE 'BSX'.
        DELETE lt_prd WHERE TransactionTypeDetermination NE 'PRD'.

        IF im_action NE 'ficredit'.

          IF lt_wrx_bsx[] IS NOT INITIAL.
            DATA(lv_wrx_bsx_line) = lines( lt_wrx_bsx ).
            IF lv_wrx_bsx_line GT 1.

              READ TABLE lt_wrx_bsx INTO DATA(lvs_egk) WITH KEY TransactionTypeDetermination = 'EGK'.
              IF sy-subrc NE 0.

                READ TABLE lt_wrx_bsx INTO DATA(cs_wrx) WITH KEY TransactionTypeDetermination = 'WRX'.
                IF sy-subrc EQ 0.
                  DELETE lt_wrx_bsx WHERE TransactionTypeDetermination NE 'WRX'.
                ELSE.
                  DELETE lt_wrx_bsx WHERE TransactionTypeDetermination NE 'BSX'.
                ENDIF.

              ENDIF.

            ENDIF.
          ENDIF.

        ENDIF.

        LOOP AT lt_wrx_bsx INTO ls_acc
                       WHERE companycode  = xs_acc-CompanyCode AND
                       accountingdocument = xs_acc-AccountingDocument AND
                       fiscalyear = xs_acc-FiscalYear. "AND
          "TransactionTypeDetermination ne 'BSX'.

          READ TABLE lt_bsx INTO DATA(ls_bsx) INDEX 1.  "#EC CI_NOORDER
          READ TABLE lt_prd INTO DATA(ls_prd) INDEX 1.  "#EC CI_NOORDER

          IF ls_acc-TransactionTypeDetermination = 'EGK'.

            READ TABLE lt_acc INTO DATA(cs_acc) WITH KEY companycode  = xs_acc-CompanyCode
                                                   accountingdocument = xs_acc-AccountingDocument
                                                           fiscalyear = xs_acc-FiscalYear
                                                           TransactionTypeDetermination = ' '.

            ls_acc-Product      = cs_acc-Product.
            ls_acc-BaseUnit     = cs_acc-BaseUnit.
            ls_acc-Quantity     = cs_acc-Quantity.
            ls_acc-TaxItemGroup = cs_acc-TaxItemGroup.
            ls_acc-Plant        = cs_acc-plant.
            ls_acc-AmountInCompanyCodeCurrency = cs_acc-AmountInCompanyCodeCurrency .
            ls_acc-IN_HSNOrSACCode = cs_acc-IN_HSNOrSACCode.
            gs_dbnote-remark = cs_acc-DocumentItemText.

          ENDIF.

          gs_item-companycode            = ls_acc-CompanyCode.
          gs_item-accountingdocument     = ls_acc-AccountingDocument.
          gs_item-fiscalyear             = ls_acc-FiscalYear.
          gs_item-accountingdocumentitem = ls_acc-AccountingDocumentItem.
          gs_item-trans_curr             = ls_acc-TransactionCurrency.


          SELECT SINGLE * FROM I_ProductDescription
                          WHERE Product = @ls_acc-Product AND Language = 'E'
                          INTO @DATA(ls_maktx). "#EC CI_ALL_FIELDS_NEEDED

          SELECT SINGLE * FROM I_GLAccountText
                          WHERE GLAccount = @ls_acc-GLAccount AND Language = 'E'
                          AND ChartOfAccounts = 'YCOA'
                          INTO @DATA(ls_gltext). "#EC CI_ALL_FIELDS_NEEDED


          SELECT SINGLE
          Product,
          plant,
          ConsumptionTaxCtrlCode
          FROM I_ProductPlantBasic
          WHERE Product = @ls_acc-Product AND plant = @ls_acc-Plant
          INTO @DATA(ls_hsn).




          CLEAR: lv_amount_neg.
          lv_amount_neg = ls_acc-AmountInCompanyCodeCurrency.
          CONDENSE lv_amount_neg.
          IF lv_amount_neg CA '-'.
            ls_acc-AmountInCompanyCodeCurrency = ls_acc-AmountInCompanyCodeCurrency * -1.
          ENDIF.



          CLEAR: lv_amount_neg.
          lv_amount_neg = ls_bsx-AmountInCompanyCodeCurrency.
          CONDENSE lv_amount_neg.
          IF lv_amount_neg CA '-'.
            ls_bsx-AmountInCompanyCodeCurrency = ls_bsx-AmountInCompanyCodeCurrency * -1.
          ENDIF.

          CLEAR: lv_amount_neg.
          lv_amount_neg = ls_prd-AmountInCompanyCodeCurrency.
          CONDENSE lv_amount_neg.
          IF lv_amount_neg CA '-'.
            ls_prd-AmountInCompanyCodeCurrency = ls_prd-AmountInCompanyCodeCurrency * -1.
          ENDIF.


          IF ls_acc-Product IS NOT INITIAL.
            gs_item-itemcode    = ls_acc-Product.
          ELSE.
            gs_item-itemcode =  ls_gltext-GLAccount.

          ENDIF.

*          gs_item-itemdesc            = ls_maktx-ProductDescription. "ls_gltext-GLAccountName. comment by 26-05-2025

          IF ls_maktx-ProductDescription IS  NOT INITIAL.
            gs_item-itemdesc          = ls_maktx-ProductDescription. "ls_maktx-ProductDescription.
          ELSE.
            gs_item-itemdesc          =  ls_gltext-GLAccountLongName.  "ls_gltext-GLAccountName.

          ENDIF.


          gs_item-hsncode             = ls_acc-IN_HSNOrSACCode. "ls_hsn-ConsumptionTaxCtrlCode.
          gs_item-uom                 = ls_acc-BaseUnit.
          gs_item-itmqty              = ls_acc-Quantity.

          IF ls_acc-TransactionTypeDetermination EQ 'PRD'.
            gs_item-amount              =  ls_prd-AmountInCompanyCodeCurrency.
            gs_item-taxable_amt         =  ls_prd-AmountInCompanyCodeCurrency.
          ELSEIF ls_acc-TransactionTypeDetermination NE 'BSX'.
            gs_item-amount              = ls_acc-AmountInCompanyCodeCurrency + ls_bsx-AmountInCompanyCodeCurrency + ls_prd-AmountInCompanyCodeCurrency.
            gs_item-taxable_amt         = ls_acc-AmountInCompanyCodeCurrency + ls_bsx-AmountInCompanyCodeCurrency + ls_prd-AmountInCompanyCodeCurrency.
          ELSE.
            gs_item-amount              = ls_acc-AmountInCompanyCodeCurrency + ls_prd-AmountInCompanyCodeCurrency.
            gs_item-taxable_amt         = ls_acc-AmountInCompanyCodeCurrency + ls_prd-AmountInCompanyCodeCurrency.
          ENDIF.

          gs_item-discount            = ''.


          lv_total_value              = lv_total_value + gs_item-taxable_amt.
          IF gs_item-itmqty IS NOT INITIAL.
            gs_item-unit_rate           = gs_item-amount / gs_item-itmqty.
          ENDIF.

          LOOP AT xt_item INTO DATA(xs_item) WHERE TaxItemGroup = ls_acc-TaxItemGroup.

            IF xs_item-cgst_amt IS NOT INITIAL.
              gs_item-cgst_amt   = xs_item-cgst_amt.
              lv_sum_cgst_amt    = lv_sum_cgst_amt + gs_item-cgst_amt.
            ENDIF.

            IF xs_item-sgst_amt IS NOT INITIAL.
              gs_item-sgst_amt   = xs_item-sgst_amt.
              lv_sum_sgst_amt    = lv_sum_sgst_amt + gs_item-sgst_amt.
            ENDIF.

            IF xs_item-igst_amt IS NOT INITIAL.
              gs_item-igst_amt   = xs_item-igst_amt.
              lv_sum_igst_amt    = lv_sum_igst_amt + gs_item-igst_amt.
            ENDIF.

            CLEAR: xs_item.
          ENDLOOP.

          IF  ls_acc-TaxCode = 'D1' OR
                       ls_acc-TaxCode = 'D2' OR
                       ls_acc-TaxCode = 'D3' OR
                       ls_acc-TaxCode = 'D4' OR
                       ls_acc-TaxCode = 'D5' OR
                       ls_acc-TaxCode = 'D6' OR
                       ls_acc-TaxCode = 'D7' OR
                       ls_acc-TaxCode = 'D8'.

            gs_item-taxable_amt   =  gs_item-taxable_amt -  gs_dbnote-sum_cgst_amt1.
            gs_item-taxable_amt = gs_item-taxable_amt -  gs_dbnote-sum_sgst_amt1.
            lv_total_value = lv_total_value - ( gs_dbnote-sum_sgst_amt1 + gs_dbnote-sum_sgst_amt1 ).
            xs_item-taxable_amt =   xs_item-taxable_amt -  ( gs_dbnote-sum_sgst_amt1 + gs_dbnote-sum_sgst_amt1 ).
            gs_item-amount =   gs_item-amount -  ( gs_dbnote-sum_sgst_amt1 + gs_dbnote-sum_sgst_amt1 ).

            IF gs_item-cgst_amt IS NOT INITIAL.
              gs_item-cgst_rate    = ( gs_item-cgst_amt * 100 ) / gs_item-taxable_amt.
            ENDIF.

            IF gs_item-sgst_amt IS NOT INITIAL.
              gs_item-sgst_rate    = ( gs_item-sgst_amt * 100 ) / gs_item-taxable_amt.
            ENDIF.

            IF gs_item-igst_amt IS NOT INITIAL.
              gs_item-igst_rate    = ( gs_item-igst_amt * 100 ) / gs_item-taxable_amt.
            ENDIF.

          ELSE.
            IF gs_item-cgst_amt IS NOT INITIAL.
              gs_item-cgst_rate    = ( gs_item-cgst_amt * 100 ) / gs_item-taxable_amt.
            ENDIF.

            IF gs_item-sgst_amt IS NOT INITIAL.
              gs_item-sgst_rate    = ( gs_item-sgst_amt * 100 ) / gs_item-taxable_amt.
            ENDIF.

            IF gs_item-igst_amt IS NOT INITIAL.
              gs_item-igst_rate    = ( gs_item-igst_amt * 100 ) / gs_item-taxable_amt.
            ENDIF.
          ENDIF.
          IF ls_acc-TaxCode = 'C1' OR
             ls_acc-TaxCode = 'C2' OR
             ls_acc-TaxCode = 'C3' OR
             ls_acc-TaxCode = 'C4' OR
             ls_acc-TaxCode = 'C5' OR
             ls_acc-TaxCode = 'C6' OR
             ls_acc-TaxCode = 'C7' OR
             ls_acc-TaxCode = 'C8' OR
             ls_acc-TaxCode = 'D1' OR
             ls_acc-TaxCode = 'D2' OR
             ls_acc-TaxCode = 'D3' OR
             ls_acc-TaxCode = 'D4' OR
             ls_acc-TaxCode = 'D5' OR
             ls_acc-TaxCode = 'D6' OR
             ls_acc-TaxCode = 'D7' OR
             ls_acc-TaxCode = 'D8'.

            gs_dbnote-revrs_yes_no = 'Yes'.

          ELSE.

            gs_dbnote-revrs_yes_no = 'No'.

          ENDIF.

          APPEND gs_item TO gt_item.
          CLEAR: ls_acc, gs_item.
        ENDLOOP.

        lv_grand_total = lv_total_value +
                         lv_sum_frt_amt +
                         lv_sum_cgst_amt +
                         lv_sum_sgst_amt +
                         lv_sum_igst_amt +
                         lv_sum_load_amt +
                         lv_sum_rndf_amt.

        gs_dbnote-sum_frt_amt          = lv_sum_frt_amt.
        gs_dbnote-sum_other_amt        = lv_sum_frt_amt. "lv_sum_other_amt.
        gs_dbnote-sum_cgst_amt         = lv_sum_cgst_amt.
        gs_dbnote-sum_sgst_amt         = lv_sum_sgst_amt.
        gs_dbnote-sum_igst_amt         = lv_sum_igst_amt.
        gs_dbnote-sum_tcs_amt          = lv_sum_tcs_amt.
        gs_dbnote-sum_load_amt         = lv_sum_load_amt.
        gs_dbnote-sum_rndf_amt         = lv_sum_rndf_amt.
        gs_dbnote-sum_gst_amt          = lv_sum_gst_amt.
        gs_dbnote-total_value          = lv_total_value.
        gs_dbnote-grand_total          = lv_grand_total.

        DATA: lv_grand_tot_word TYPE string,
              lv_gst_amt_word   TYPE string.

        lv_grand_tot_word = gs_dbnote-grand_total.
        lo_amt_words->number_to_words(
          EXPORTING
            iv_num   = lv_grand_tot_word
          RECEIVING
            rv_words = DATA(amt_words)
        ).

        lv_gst_amt_word = gs_dbnote-sum_gst_amt.
        lo_amt_words->number_to_words(
          EXPORTING
            iv_num   = lv_gst_amt_word
          RECEIVING
            rv_words = DATA(amt_words_gst)
        ).

        CONCATENATE amt_words 'Only' INTO gs_dbnote-tot_amt_words SEPARATED BY space ##NO_TEXT.
        CONCATENATE amt_words_gst 'Only' INTO gs_dbnote-gst_amt_words SEPARATED BY space ##NO_TEXT.


        INSERT LINES OF gt_item INTO TABLE gs_dbnote-gt_item.
        APPEND gs_dbnote TO et_dbdata. "gt_dbnote.

      ENDLOOP.

    ENDIF.

  ENDMETHOD.


  METHOD get_payadv_data.

    DATA:
      lo_amt_words    TYPE REF TO zcl_amt_words,

*      lv_total_value   TYPE p LENGTH 16 DECIMALS 2,
*      lv_sum_frt_amt   TYPE p LENGTH 16 DECIMALS 2,
*      lv_sum_cgst_amt  TYPE p LENGTH 16 DECIMALS 2,
*      lv_sum_sgst_amt  TYPE p LENGTH 16 DECIMALS 2,
*      lv_sum_igst_amt  TYPE p LENGTH 16 DECIMALS 2,
*      lv_sum_tcs_amt   TYPE p LENGTH 16 DECIMALS 2,
*      lv_sum_load_amt  TYPE p LENGTH 16 DECIMALS 2,
*      lv_sum_rndf_amt  TYPE p LENGTH 16 DECIMALS 2,
*      lv_sum_other_amt TYPE p LENGTH 16 DECIMALS 2,

      lv_grand_total  TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_bill_amt TYPE p LENGTH 16 DECIMALS 2,
      lv_sum_tds_amt  TYPE p LENGTH 16 DECIMALS 2.

    DATA:
      lv_amount_neg TYPE c LENGTH 20,
      lv_advanced   TYPE c.

    CREATE OBJECT lo_amt_words.

    IF im_belnr IS NOT INITIAL.

      SELECT
      *
      FROM zi_dc_note
      WHERE
      companycode = @im_bukrs AND ClearingJournalEntry = @im_belnr AND ClearingJournalEntryFiscalYear = @im_gjahr
      INTO TABLE @DATA(lt_acc).               "#EC CI_ALL_FIELDS_NEEDED

      DATA(at_acc) = lt_acc[].
      DELETE at_acc WHERE AccountingDocument NE im_belnr.
      IF at_acc[] IS INITIAL.

        SELECT
        *
        FROM zi_dc_note
        WHERE
        companycode = @im_bukrs AND AccountingDocument = @im_belnr AND fiscalyear = @im_gjahr
        INTO TABLE @lt_acc.                   "#EC CI_ALL_FIELDS_NEEDED

        lv_advanced = abap_true.

      ENDIF.

      IF lt_acc[] IS NOT INITIAL.

        SELECT
        CompanyCode,
        AccountingDocument,
        FiscalYear,
        AccountingDocumentItem,
        FinancialAccountType,
        ChartOfAccounts,
        AccountingDocumentItemType,
        PostingKey,
        Product,
        Plant,
        PostingDate,
        DocumentDate,
        DebitCreditCode,
        TaxCode,
        TaxItemGroup,
        TransactionTypeDetermination,
        GLAccount,
        Customer,
        Supplier,
        PurchasingDocument,
        PurchasingDocumentItem,
        PurchaseOrderQty,
        ProfitCenter,
        DocumentItemText,
        AmountInCompanyCodeCurrency,
        AmountInTransactionCurrency,
        CashDiscountBaseAmount,
        NetPaymentAmount,
        AssignmentReference,
        InvoiceReference,
        InvoiceReferenceFiscalYear,
        InvoiceItemReference,
        Quantity,
        BaseUnit,
        MaterialPriceUnitQty,
        TaxBaseAmountInTransCrcy,
        ClearingJournalEntry,
        ClearingDate,
        ClearingCreationDate,
        ClearingJournalEntryFiscalYear,
        ClearingItem,
        HouseBank,
        BPBankAccountInternalID,
        HouseBankAccount,
        IN_HSNOrSACCode,
        CostCenter,
        AccountingDocumentType,
        NetDueDate,
        OffsettingAccount,
        TransactionCurrency,
        PaymentTerms,
        BusinessPlace,
        ValueDate,
        PaymentMethod,
        SpecialGLCode,
        SpecialGLTransactionType,
        DocumentReferenceID,
        AlternativeReferenceDocument,
        AccountingDocumentHeaderText,
        CompanyCodeName,
        AddressID,
        SupplierFullName,
        CustomerFullName

          FROM zi_dc_note
          FOR ALL ENTRIES IN @lt_acc
          WHERE companycode = @lt_acc-CompanyCode AND
          accountingdocument = @lt_acc-AccountingDocument AND fiscalyear = @lt_acc-FiscalYear
          INTO TABLE @DATA(lt_acc_clear).          "#EC CI_NO_TRANSFORM

        IF lt_acc_clear[] IS NOT INITIAL.

          READ TABLE lt_acc_clear INTO DATA(lcs_acc_clear) INDEX 1. "#EC CI_NOORDER

          SELECT SINGLE
CompanyCode,
AccountingDocument,
FiscalYear,
AccountingDocumentItem,
FinancialAccountType,
ChartOfAccounts,
AccountingDocumentItemType,
PostingKey,
Product,
Plant,
PostingDate,
DocumentDate,
DebitCreditCode,
TaxCode,
TaxItemGroup,
TransactionTypeDetermination,
GLAccount,
Customer,
Supplier,
PurchasingDocument,
PurchasingDocumentItem,
PurchaseOrderQty,
ProfitCenter,
DocumentItemText,
AmountInCompanyCodeCurrency,
AmountInTransactionCurrency,
CashDiscountBaseAmount,
NetPaymentAmount,
AssignmentReference,
InvoiceReference,
InvoiceReferenceFiscalYear,
InvoiceItemReference,
Quantity,
BaseUnit,
MaterialPriceUnitQty,
TaxBaseAmountInTransCrcy,
ClearingJournalEntry,
ClearingDate,
ClearingCreationDate,
ClearingJournalEntryFiscalYear,
ClearingItem,
HouseBank,
BPBankAccountInternalID,
HouseBankAccount,
IN_HSNOrSACCode,
CostCenter,
AccountingDocumentType,
NetDueDate,
OffsettingAccount,
TransactionCurrency,
PaymentTerms,
BusinessPlace,
DocumentReferenceID,
ValueDate,
PaymentMethod,
BusinessPartner,
BusinessPartnerName,
BankAccount AS BenefBankAccount,
BankNumber,
BankAccountHolderName,
BankCountryKey,
SWIFTCode,
BankControlKey,
CityName,
EmailAddress,
SupplierName,
BankAccount,
PaymentMethodDescription,
BankName
          FROM zi_bank_payment
          WHERE CompanyCode        = @lcs_acc_clear-CompanyCode AND
                AccountingDocument = @lcs_acc_clear-AccountingDocument AND
                FiscalYear         = @lcs_acc_clear-FiscalYear AND
                FinancialAccountType = 'K'
          INTO @DATA(ls_bank).                     "#EC CI_NO_TRANSFORM


          SELECT * FROM I_HouseBankAccountLinkage
          FOR ALL ENTRIES IN @lt_acc_clear
          WHERE companycode = @lt_acc_clear-CompanyCode AND
                HouseBank    = @lt_acc_clear-HouseBank AND
                HouseBankAccount = @lt_acc_clear-HouseBankAccount
                INTO TABLE @DATA(lt_bank_acc). "#EC CI_ALL_FIELDS_NEEDED

        ENDIF.

      ENDIF.

      SELECT * FROM zi_cheque_detail
      WHERE
      PaymentCompanyCode = @im_bukrs AND PaymentDocument = @im_belnr AND FiscalYear = @im_gjahr
      INTO TABLE @DATA(lt_chq).               "#EC CI_ALL_FIELDS_NEEDED

      DATA(xt_acc) = lt_acc[].
      DELETE xt_acc WHERE accountingdocument NE im_belnr.
      SORT xt_acc BY accountingdocument.
      DELETE ADJACENT DUPLICATES FROM xt_acc COMPARING accountingdocument.


      SELECT
        *
        FROM zi_dc_note
        WHERE companycode = @im_bukrs AND
        accountingdocument = @im_belnr AND fiscalyear = @im_gjahr
        AND InvoiceReference NE ''
        INTO TABLE @DATA(xt_part).            "#EC CI_ALL_FIELDS_NEEDED

      IF xt_part[] IS NOT INITIAL.

        LOOP AT xt_part ASSIGNING FIELD-SYMBOL(<lfs_part>).
          <lfs_part>-AccountingDocument = <lfs_part>-InvoiceReference.
        ENDLOOP.

        SELECT
          *
          FROM zi_dc_note
          FOR ALL ENTRIES IN @xt_part
          WHERE companycode = @xt_part-CompanyCode AND
          accountingdocument = @xt_part-AccountingDocument AND fiscalyear = @xt_part-FiscalYear
          INTO TABLE @DATA(xt_acc_part).      "#EC CI_ALL_FIELDS_NEEDED

        APPEND LINES OF xt_part TO lt_acc.
      ENDIF.

      LOOP AT xt_acc INTO DATA(xs_acc).

        """******Header Data
        gs_dbnote-companycode          = xs_acc-CompanyCode.
        gs_dbnote-accountingdocument   = xs_acc-AccountingDocument.
        gs_dbnote-fiscalyear           = xs_acc-FiscalYear.
        gs_dbnote-postingdate          = xs_acc-PostingDate.
        gs_dbnote-documentdate         = xs_acc-DocumentDate.
        gs_dbnote-trans_curr           = xs_acc-TransactionCurrency.

        gs_dbnote-voucher_no        = xs_acc-ClearingJournalEntry.
        gs_dbnote-voucher_date      = xs_acc-DocumentDate+6(2) && '.' && xs_acc-DocumentDate+4(2) && '.' && xs_acc-DocumentDate+0(4).

        READ TABLE lt_chq INTO DATA(ls_chq) WITH KEY PaymentDocument = xs_acc-ClearingJournalEntry
                                                     ChequeStatus    = '10'.

        gs_dbnote-bank_name         = ls_bank-BankName.
        gs_dbnote-bank_acc_no       = ls_bank-BenefBankAccount.
        gs_dbnote-bank_ifsc_code    = ls_bank-BankNumber.
        gs_dbnote-payment_mode      = ls_bank-PaymentMethodDescription.
        gs_dbnote-bank_utr_no       = xs_acc-AccountingDocumentHeaderText.

        gs_dbnote-bank_det1         = ls_chq-HouseBankAccount.
        gs_dbnote-bank_det2         = ''.
        gs_dbnote-cheque_no         = ls_chq-OutgoingCheque.
        gs_dbnote-cheque_date       = ls_chq-ChequePaymentDate+6(2) && '.' && ls_chq-ChequePaymentDate+4(2) && '.' && ls_chq-ChequePaymentDate+0(4).
        gs_dbnote-po_num            = ''.

        IF gs_dbnote-bank_name IS INITIAL.

          READ TABLE lt_acc_clear INTO DATA(ls_acc_wit1) WITH KEY
                                       CompanyCode = xs_acc-CompanyCode
                                       AccountingDocument =  xs_acc-AccountingDocument
                                       FiscalYear = xs_acc-FiscalYear
                                       debitCreditCode = 'H'.

          IF sy-subrc EQ 0.

            READ TABLE lt_bank_acc INTO DATA(ls_bank_acc) WITH KEY
                                   CompanyCode = xs_acc-CompanyCode
                                   HouseBank     = ls_acc_wit1-HouseBank
                                   HouseBankAccount = ls_acc_wit1-HouseBankAccount.

            "gs_dbnote-bank_name  = ls_bank_acc-BankAccountNumber.     "ls_acc_wit1-HouseBank.
            gs_dbnote-bank_det1  = ''. "ls_acc_wit1-HouseBankAccount.s

          ENDIF.
        ENDIF.

*        DATA(lt_acc_plant) = lt_acc[].
*        DELETE lt_acc_plant WHERE Plant EQ ''.
*        READ TABLE lt_acc_plant INTO DATA(ls_acc_plant) INDEX 1.
*        IF sy-subrc EQ 0.
*
*          SELECT SINGLE * FROM zi_plant_address
*          WHERE plant = @ls_acc_plant-Plant INTO @DATA(ls_plant_adrs).
*
*          gs_dbnote-suppl_code         = ls_acc_plant-Plant.
*          gs_dbnote-suppl_name         = ls_plant_adrs-PlantName.
*          gs_dbnote-suppl_addr1        = ls_plant_adrs-StreetPrefixName1 && ',' && ls_plant_adrs-StreetPrefixName2.
*          gs_dbnote-suppl_addr2        = ls_plant_adrs-StreetName &&  ',' && ls_plant_adrs-StreetSuffixName1 &&  ',' && ls_plant_adrs-DistrictName.
*          gs_dbnote-suppl_addr3        = ls_plant_adrs-CityName &&  ',' && ls_plant_adrs-PostalCode .
*          gs_dbnote-suppl_cin          = 'U74899DL1988PTC031984'.
*          gs_dbnote-suppl_gstin        = '06AAECA0297J1ZO'. "for plant 1001
*          gs_dbnote-suppl_pan          = gs_dbnote-suppl_gstin+0(10).
*          gs_dbnote-suppl_stat_code    = ls_plant_adrs-Region.
*          gs_dbnote-suppl_phone        = ''.
*          gs_dbnote-suppl_email        = 'info@anandnvh.com'.
*
*        ENDIF.

        DATA(lt_acc_suppl) = lt_acc[].
        DELETE lt_acc_suppl WHERE Supplier EQ ''.
        READ TABLE lt_acc_suppl INTO DATA(ls_acc_suppl) INDEX 1. "#EC CI_NOORDER
        IF sy-subrc EQ 0.

          SELECT SINGLE * FROM zi_supplier_address
          WHERE Supplier = @ls_acc_suppl-Supplier INTO @DATA(ls_supplier). "#EC CI_NOORDER

          gs_dbnote-suppl_code         = ls_supplier-Supplier.
          gs_dbnote-suppl_name         = ls_supplier-SupplierName.
          gs_dbnote-suppl_addr1        = ls_supplier-StreetPrefixName1 && ',' && ls_supplier-StreetPrefixName2.
          gs_dbnote-suppl_addr2        = ls_supplier-StreetName &&  ',' && ls_supplier-StreetSuffixName1 &&  ',' && ls_supplier-DistrictName.
          gs_dbnote-suppl_addr3        = ls_supplier-CityName &&  ',' && ls_supplier-PostalCode .

          gs_dbnote-suppl_cin          = 'U31908HR2007FTC039788' ##NO_TEXT.
          gs_dbnote-suppl_gstin        = '06AAACI2419N1ZK' ##NO_TEXT. "for plant 1001
          gs_dbnote-suppl_pan          = gs_dbnote-suppl_gstin+0(10).

          gs_dbnote-suppl_stat_code    = ls_supplier-Region.
          gs_dbnote-suppl_phone        = ''.
          gs_dbnote-suppl_email        = 'info@ddmnd.com' ##NO_TEXT.


*          clear: lv_amount_neg.
*          lv_amount_neg = xs_acc-AmountInCompanyCodeCurrency .
*          CONDENSE lv_amount_neg.
*          IF lv_amount_neg CA '-'.
*            lv_grand_total = xs_acc-AmountInCompanyCodeCurrency * -1.
*          else.
*            lv_grand_total = xs_acc-AmountInCompanyCodeCurrency.
*          ENDIF.

        ENDIF.

        """******Item Data


        CLEAR: gs_item.
        LOOP AT lt_acc INTO DATA(ls_acc).

          IF ls_acc-accountingdocument NE xs_acc-AccountingDocument.

            gs_item-companycode            = ls_acc-CompanyCode.
            gs_item-accountingdocument     = ls_acc-AccountingDocument.
            gs_item-fiscalyear             = ls_acc-FiscalYear.
            gs_item-accountingdocumentitem = ls_acc-AccountingDocumentItem.

            gs_item-bill_num        = ls_acc-DocumentReferenceID.
            gs_item-bill_date       = ls_acc-PostingDate+6(2) && '.' && ls_acc-PostingDate+4(2) && '.' && ls_acc-PostingDate+0(4).
            gs_item-debit_note_no   = ''.
            gs_item-debit_date      = ''.
            gs_item-debit_amt       = ''.

            READ TABLE xt_acc_part INTO DATA(xs_acc_part) WITH KEY
                                         CompanyCode = ls_acc-CompanyCode
                                         AccountingDocument =  ls_acc-AccountingDocument
                                         FiscalYear = ls_acc-FiscalYear.

            IF sy-subrc NE 0.

              READ TABLE lt_acc_clear INTO DATA(ls_acc_wit) WITH KEY
                                           CompanyCode = ls_acc-CompanyCode
                                           AccountingDocument =  ls_acc-AccountingDocument
                                           FiscalYear = ls_acc-FiscalYear
                                           TransactionTypeDetermination = 'WIT'.

              IF sy-subrc EQ 0.

                CLEAR: lv_amount_neg.
                lv_amount_neg = ls_acc_wit-AmountInCompanyCodeCurrency .
                CONDENSE lv_amount_neg.
                IF lv_amount_neg CA '-'.
                  ls_acc_wit-AmountInCompanyCodeCurrency =  ls_acc_wit-AmountInCompanyCodeCurrency * -1.
                ENDIF.

                gs_item-tds_amt         = ls_acc_wit-AmountInCompanyCodeCurrency .
                "*lv_sum_tds_amt          = lv_sum_tds_amt + ls_acc_wit-AmountInCompanyCodeCurrency .

                IF ls_acc-SpecialGLCode = 'A'.

                  CLEAR: lv_amount_neg.
                  lv_amount_neg = ls_acc-AmountInCompanyCodeCurrency.
                  CONDENSE lv_amount_neg.
                  IF lv_amount_neg CA '-'.
                    gs_item-bill_amt        = ls_acc-AmountInCompanyCodeCurrency * -1.
                  ELSE.
                    gs_item-bill_amt        = ls_acc-AmountInCompanyCodeCurrency.
                  ENDIF.

                ELSE.

*                  CLEAR: lv_amount_neg.
*                  lv_amount_neg = ls_acc-CashDiscountBaseAmount.
*                  CONDENSE lv_amount_neg.
*                  IF lv_amount_neg CA '-'.
*                    gs_item-bill_amt        = ls_acc-CashDiscountBaseAmount * -1.
*                  ELSE.
*                    gs_item-bill_amt        = ls_acc-CashDiscountBaseAmount.
*                  ENDIF.

                CLEAR: lv_amount_neg.
                  lv_amount_neg = ls_acc-AmountInCompanyCodeCurrency.
                  CONDENSE lv_amount_neg.
                  IF lv_amount_neg CA '-'.
                    gs_item-bill_amt        = ls_acc-AmountInCompanyCodeCurrency * -1.
                  ELSE.
                    gs_item-bill_amt        = ls_acc-AmountInCompanyCodeCurrency.
                  ENDIF.

                ENDIF.

              ELSE.

                CLEAR: lv_amount_neg.
                lv_amount_neg = ls_acc-AmountInCompanyCodeCurrency. "ls_acc-CashDiscountBaseAmount.
                CONDENSE lv_amount_neg.
                IF lv_amount_neg CA '-'.
                  gs_item-bill_amt        = ls_acc-AmountInCompanyCodeCurrency * -1.
                ELSE.
                  gs_item-bill_amt        = ls_acc-AmountInCompanyCodeCurrency.
                ENDIF.

              ENDIF.

*              gs_item-net_amt         = gs_item-bill_amt + ( gs_item-tds_amt * -1 ).
                gs_item-bill_amt         = gs_item-bill_amt - ( gs_item-tds_amt * -1 ).
                gs_item-net_amt         = gs_item-bill_amt + ( gs_item-tds_amt * -1 ).

              IF ls_acc-DebitCreditCode EQ 'S'.
                gs_item-dr_cr           = 'Dr'.
                lv_grand_total          = lv_grand_total + ( gs_item-net_amt * -1 ).
                lv_sum_bill_amt         = lv_sum_bill_amt + ( gs_item-bill_amt * -1 ).
                lv_sum_tds_amt          = lv_sum_tds_amt + ( gs_item-tds_amt * -1 ) .
              ELSE.
                gs_item-dr_cr           = 'Cr'.
                lv_grand_total          = lv_grand_total + gs_item-net_amt.
                lv_sum_bill_amt         = lv_sum_bill_amt + gs_item-bill_amt.
                lv_sum_tds_amt          = lv_sum_tds_amt + gs_item-tds_amt.
              ENDIF.

            ELSE.

              READ TABLE xt_acc_part INTO DATA(xs_acc_egk) WITH KEY
                                           CompanyCode = ls_acc-CompanyCode
                                           AccountingDocument =  ls_acc-AccountingDocument
                                           FiscalYear = ls_acc-FiscalYear
                                           TransactionTypeDetermination = 'EGK'.

              gs_item-bill_num        = xs_acc_egk-DocumentReferenceID.
              gs_item-bill_date       = xs_acc_egk-PostingDate+6(2) && '.' && xs_acc_egk-PostingDate+4(2) && '.' && xs_acc_egk-PostingDate+0(4).

              READ TABLE xt_acc_part INTO DATA(xs_acc_wit) WITH KEY
                                           CompanyCode = ls_acc-CompanyCode
                                           AccountingDocument =  ls_acc-AccountingDocument
                                           FiscalYear = ls_acc-FiscalYear
                                           TransactionTypeDetermination = 'WIT'.

              IF sy-subrc EQ 0.

                CLEAR: lv_amount_neg.
                lv_amount_neg = xs_acc_wit-AmountInCompanyCodeCurrency .
                CONDENSE lv_amount_neg.
                IF lv_amount_neg CA '-'.
                  xs_acc_wit-AmountInCompanyCodeCurrency =  xs_acc_wit-AmountInCompanyCodeCurrency * -1.
                ENDIF.

                gs_item-tds_amt         = xs_acc_wit-AmountInCompanyCodeCurrency .
                lv_sum_tds_amt          = lv_sum_tds_amt + xs_acc_wit-AmountInCompanyCodeCurrency .

                CLEAR: lv_amount_neg.
                lv_amount_neg = xs_acc_egk-AmountInCompanyCodeCurrency. "xs_acc_egk-CashDiscountBaseAmount.
                CONDENSE lv_amount_neg.
                IF lv_amount_neg CA '-'.
                  gs_item-bill_amt        = xs_acc_egk-AmountInCompanyCodeCurrency * -1.
                ELSE.
                  gs_item-bill_amt        = xs_acc_egk-AmountInCompanyCodeCurrency.
                ENDIF.

              ELSE.

                CLEAR: lv_amount_neg.
                lv_amount_neg = xs_acc_egk-CashDiscountBaseAmount.
                CONDENSE lv_amount_neg.
                IF lv_amount_neg CA '-'.
                  gs_item-bill_amt        = xs_acc_egk-CashDiscountBaseAmount * -1.
                ELSE.
                  gs_item-bill_amt        = xs_acc_egk-CashDiscountBaseAmount.
                ENDIF.

              ENDIF.




              READ TABLE xt_part INTO DATA(cs_part)
                                         WITH KEY CompanyCode = ls_acc-CompanyCode
                                           AccountingDocument =  ls_acc-AccountingDocument
                                           FiscalYear = ls_acc-FiscalYear.
              IF sy-subrc EQ 0.

                CLEAR: lv_amount_neg.
                lv_amount_neg = cs_part-AmountInCompanyCodeCurrency.
                CONDENSE lv_amount_neg.

                IF lv_amount_neg CA '-'.
                  gs_item-net_amt         = cs_part-AmountInCompanyCodeCurrency * -1.
                ELSE.
                  gs_item-net_amt         = cs_part-AmountInCompanyCodeCurrency.
                ENDIF.

              ELSE.

                gs_item-net_amt         = gs_item-bill_amt + ( gs_item-tds_amt * -1 ).

              ENDIF.

              IF xs_acc_egk-DebitCreditCode EQ 'S'.
                gs_item-dr_cr           = 'Dr'.
                lv_grand_total          = lv_grand_total + ( gs_item-net_amt * -1 ).
                lv_sum_bill_amt         = lv_sum_bill_amt + ( gs_item-bill_amt * -1 ).
              ELSE.
                gs_item-dr_cr           = 'Cr'.
                lv_grand_total          = lv_grand_total + gs_item-net_amt.
                lv_sum_bill_amt         = lv_sum_bill_amt + gs_item-bill_amt.
              ENDIF.


              CLEAR: xs_acc_egk, xs_acc_wit.

            ENDIF.

            gs_item-trans_curr = ls_acc-TransactionCurrency.

            APPEND gs_item TO gt_item.

          ENDIF.

          """*****For Advanced*************************************************
          IF lv_advanced = abap_true AND
             ls_acc-ClearingJournalEntry NE ls_acc-AccountingDocument AND
             ls_acc-SpecialGLCode NE ''.

            gs_item-companycode            = ls_acc-CompanyCode.
            gs_item-accountingdocument     = ls_acc-AccountingDocument.
            gs_item-fiscalyear             = ls_acc-FiscalYear.
            gs_item-accountingdocumentitem = ls_acc-AccountingDocumentItem.
            gs_item-bill_num               = ls_acc-DocumentReferenceID.
            gs_item-trans_curr             = ls_acc-TransactionCurrency.


            gs_item-bill_num        = ls_acc-DocumentReferenceID.
            gs_item-bill_date       = ls_acc-PostingDate+6(2) && '.' && ls_acc-PostingDate+4(2) && '.' && ls_acc-PostingDate+0(4).

            CLEAR: ls_acc_wit.
            READ TABLE lt_acc_clear INTO ls_acc_wit WITH KEY
                                         CompanyCode = ls_acc-CompanyCode
                                         AccountingDocument =  ls_acc-AccountingDocument
                                         FiscalYear = ls_acc-FiscalYear
                                         TransactionTypeDetermination = 'WIT'.

            IF sy-subrc EQ 0.

              CLEAR: lv_amount_neg.
              lv_amount_neg = ls_acc_wit-AmountInCompanyCodeCurrency .
              CONDENSE lv_amount_neg.
              IF lv_amount_neg CA '-'.
                ls_acc_wit-AmountInCompanyCodeCurrency =  ls_acc_wit-AmountInCompanyCodeCurrency * -1.
              ENDIF.

              gs_item-tds_amt         = ls_acc_wit-AmountInCompanyCodeCurrency .

              CLEAR: lv_amount_neg.
              lv_amount_neg = ls_acc-AmountInCompanyCodeCurrency.
              CONDENSE lv_amount_neg.
              IF lv_amount_neg CA '-'.
                gs_item-bill_amt        = ls_acc-AmountInCompanyCodeCurrency * -1.
              ELSE.
                gs_item-bill_amt        = ls_acc-AmountInCompanyCodeCurrency.
              ENDIF.

            ENDIF.

            gs_item-net_amt         = gs_item-bill_amt + ( gs_item-tds_amt * -1 ).

            IF ls_acc-DebitCreditCode EQ 'S'.
              gs_item-dr_cr           = 'Dr'.
            ELSE.
              gs_item-dr_cr           = 'Cr'.
            ENDIF.

            lv_grand_total          = lv_grand_total + gs_item-net_amt.
            lv_sum_bill_amt         = lv_sum_bill_amt + gs_item-bill_amt.
            lv_sum_tds_amt          = lv_sum_tds_amt + gs_item-tds_amt.

            APPEND gs_item TO gt_item.

          ENDIF.

          CLEAR: ls_acc, ls_acc_wit, gs_item.
        ENDLOOP.


        gs_dbnote-grand_total     = lv_grand_total.
        gs_dbnote-chq_amt         = ''.
        gs_dbnote-sum_bil_amt     = lv_sum_bill_amt.
        gs_dbnote-sum_tds_amt     = lv_sum_tds_amt.
        gs_dbnote-sum_debit_amt   = ''.
        gs_dbnote-sum_net_amt     = lv_grand_total.

        CLEAR: lv_amount_neg.
        lv_amount_neg = lv_grand_total.
        CONDENSE lv_amount_neg.
        CONCATENATE 'Being amount of INR'
                    lv_amount_neg
                    'Paid To'
                    gs_dbnote-suppl_name
*                    'against bill no'
*                    im_belnr
                    INTO gs_dbnote-narration SEPARATED BY space ##NO_TEXT.


        DATA: lv_grand_tot_word TYPE string,
              lv_gst_amt_word   TYPE string.

        IF gs_dbnote-grand_total IS NOT INITIAL.

          lv_grand_tot_word = gs_dbnote-grand_total.
          lo_amt_words->number_to_words(
            EXPORTING
              iv_num   = lv_grand_tot_word
            RECEIVING
              rv_words = DATA(amt_words)
          ).

        ENDIF.

        gs_dbnote-tot_amt_words = amt_words.

        INSERT LINES OF gt_item INTO TABLE gs_dbnote-gt_item.
        APPEND gs_dbnote TO et_payadv.

      ENDLOOP.

    ENDIF.

  ENDMETHOD.


  METHOD get_voucher_data .

    DATA:
      lo_amt_words  TYPE REF TO zcl_amt_words,
      lv_amount_neg TYPE c LENGTH 20,
      lv_dr_amount  TYPE p LENGTH 16 DECIMALS 2,
      region_desc   TYPE c LENGTH 20.

    sys_date = cl_abap_context_info=>get_system_date( ).
    sys_time = cl_abap_context_info=>get_system_time( ).
    sy_uname = cl_abap_context_info=>get_user_technical_name( ).

    CREATE OBJECT lo_amt_words.

    SELECT * FROM I_JournalEntry
             WHERE CompanyCode  = @im_bukrs AND
                   FiscalYear   = @im_gjahr AND
                   AccountingDocument = @im_belnr
             INTO TABLE @DATA(lt_bkpf).       "#EC CI_ALL_FIELDS_NEEDED

    SELECT * FROM zi_dc_note
             WHERE CompanyCode  = @im_bukrs AND
                   FiscalYear   = @im_gjahr AND
                   AccountingDocument = @im_belnr
             INTO TABLE @DATA(lt_acodca).     "#EC CI_ALL_FIELDS_NEEDED

    READ TABLE lt_bkpf INTO DATA(ls_bkpf) INDEX 1.      "#EC CI_NOORDER
    READ TABLE lt_acodca INTO DATA(ls_acdoca1) INDEX 1. "#EC CI_NOORDER

    gs_final-companycode          = ls_bkpf-CompanyCode.
    gs_final-accountingdocument   = ls_bkpf-AccountingDocument.
    gs_final-fiscalyear           = ls_bkpf-FiscalYear.
    gs_final-heading              = 'DE DIAMOND ELECTRIC INDIA PVT.LTD'. "ls_acdoca1-CompanyCodeName.

    DATA(lt_acc_plant) = lt_acodca[].
    DELETE lt_acc_plant WHERE plant EQ ''.
    IF lt_acc_plant[] IS INITIAL.

      lt_acc_plant[] = lt_acodca[].
      DELETE lt_acc_plant WHERE BusinessPlace EQ ''.

      READ TABLE lt_acc_plant INTO DATA(ls_acc_plant) INDEX 1.
      SELECT SINGLE * FROM zi_plant_address
      WHERE plant = @ls_acc_plant-BusinessPlace INTO @DATA(ls_plant_adrs). "#EC CI_ALL_FIELDS_NEEDED

    ELSE.

      READ TABLE lt_acc_plant INTO ls_acc_plant INDEX 1.
      SELECT SINGLE * FROM zi_plant_address
      WHERE plant = @ls_acc_plant-plant INTO @ls_plant_adrs. "#EC CI_ALL_FIELDS_NEEDED

    ENDIF.


  """""""""""""""
    SELECT SINGLE FROM  i_companycode WITH PRIVILEGED ACCESS AS a  inner JOIN i_accountingdocumentjournal AS b
                                        ON a~CompanyCode = b~CompanyCode
*                               LEFT JOIN i_address_2 WITH PRIVILEGED ACCESS AS c ON a~AddressID = c~AddressID
                               inner JOIN i_supplier WITH PRIVILEGED ACCESS AS d ON d~Supplier = b~Supplier

         FIELDS b~CompanyCode , b~AccountingDocument , b~FiscalYear,
                d~SupplierName , d~StreetName AS ven_StreetName  , d~PostalCode AS ven_postalcode ,
                d~CityName AS ven_cityName , d~Region AS ven_region , d~Country AS Ven_country,
                d~PhoneNumber1
         WHERE b~CompanyCode = @im_bukrs
               AND b~AccountingDocument = @im_belnr
                 AND b~FiscalYear = @im_gjahr
         INTO @DATA(lv_header).

    DATA : Vendor_adress TYPE string.
    CONCATENATE lv_header-SupplierName cl_abap_char_utilities=>newline
                lv_header-ven_streetname lv_header-ven_cityname lv_header-ven_postalcode
                lv_header-ven_country lv_header-ven_region
                INTO Vendor_adress  SEPARATED BY ' '.

                 """"""""""""""""""

    """"""""""""""""""
    gs_final-vend_address = Vendor_adress.
    """""""""""""""

*    IF ls_plant_adrs-StreetPrefixName2 IS NOT INITIAL.
*      gs_final-sub_heading        = ls_plant_adrs-StreetPrefixName1 && ',' && ls_plant_adrs-StreetPrefixName2.
*    ELSE.
*      gs_final-sub_heading        = ls_plant_adrs-StreetPrefixName1.
*    ENDIF.
*    gs_final-header_1         = ls_plant_adrs-StreetName &&  ',' && ls_plant_adrs-StreetSuffixName1. "&&  ',' && ls_plant_adrs-DistrictName.
*
*    IF ls_plant_adrs-Region EQ 'HR'.
*      region_desc = 'Haryana' ##NO_TEXT.
*    ENDIF.

    gs_final-header_3         = ls_plant_adrs-CityName &&  ',' &&  region_desc && ',' && ls_plant_adrs-PostalCode .
    gs_final-sub_heading          = 'Sector - 5, HSIIDC Growth Centre, Plot no. 38,' ##NO_TEXT. "gs_final-sub_heading && gs_final-header_1. "
    gs_final-header_1             = 'Phase-II, Industrial Model Twp, Bawal, Haryana 123501' ##NO_TEXT. "gs_final-header_3. "

    gs_final-plant_code           = ls_plant_adrs-Plant.
    gs_final-plant_name           = ls_plant_adrs-AddresseeFullName.
    gs_final-plant_address_l1     = |{ ls_plant_adrs-HouseNumber },{ ls_plant_adrs-StreetName }, { ls_plant_adrs-StreetSuffixName1 }|.
    gs_final-plant_address_l2     = ls_plant_adrs-CityName &&  ',' &&  region_desc && ',' && ls_plant_adrs-PostalCode.
    gs_final-plant_address_l3     = ''.

    if ls_acc_plant-BusinessPlace = '1099' .
    gs_final-plant_code           = '1099'.
    gs_final-plant_name           = 'De Diamond Electric India Pvt. Ltd.' .
    gs_final-plant_address_l1     = 'PLOT NO. 38, SECTOR-5, HSIIDC GROWTH CENTER'.
    gs_final-plant_address_l2     = 'Rewari,123501'.
    gs_final-plant_address_l3     = ''.
    endif.

    gs_final-header_2             = 'Journal Voucher' ##NO_TEXT.
    gs_final-comp_name            = ls_acdoca1-CompanyCodeName.
    gs_final-comp_adrs1           = ''.
    gs_final-comp_adrs2           = ''.
    gs_final-comp_adrs3           = ''.

    gs_final-voucher_no           = ls_bkpf-AccountingDocument.
    gs_final-voucher_date         = ls_bkpf-PostingDate.
    gs_final-doc_type             = ls_bkpf-AccountingDocumentType.

    SELECT SINGLE * FROM I_AccountingDocumentTypeText
                    WHERE AccountingDocumentType = @ls_bkpf-AccountingDocumentType AND Language = 'E'
                    INTO @DATA(ls_doctype_text). "#EC CI_ALL_FIELDS_NEEDED


    gs_final-doc_type_desc        = ls_doctype_text-AccountingDocumentTypeName.
    gs_final-ref_num              = ls_bkpf-DocumentReferenceID.
    gs_final-posting_date         = ls_bkpf-PostingDate+6(2) && '.' &&
                                    ls_bkpf-PostingDate+4(2) && '.' &&
                                    ls_bkpf-PostingDate+0(4).

    gs_final-doc_date             = ls_bkpf-DocumentDate+6(2) && '.' &&
                                    ls_bkpf-DocumentDate+4(2) && '.' &&
                                    ls_bkpf-DocumentDate+0(4).

    gs_final-currency             = ls_bkpf-TransactionCurrency.
    gs_final-park_by              = ls_bkpf-ParkedByUser.
    gs_final-posted_by            = ls_bkpf-AccountingDocCreatedByUser.
    gs_final-amt_words            = ''.

    LOOP AT lt_acodca INTO DATA(ls_acdoca).



*      IF ls_acdoca-FinancialAccountType = 'S' OR
*         ls_acdoca-FinancialAccountType = 'K' OR
*         ls_acdoca-FinancialAccountType = 'D'.

      SELECT SINGLE * FROM I_GLAccountText
                      WHERE GLAccount = @ls_acdoca-GLAccount AND Language = 'E'
                      INTO @DATA(ls_gltext).  "#EC CI_ALL_FIELDS_NEEDED

      ls_item-companycode         = ls_acdoca-CompanyCode.
      ls_item-accountingdocument  = ls_acdoca-AccountingDocument.
      ls_item-fiscalyear          = ls_acdoca-FiscalYear.
      ls_item-sr_num              = ''.
      ls_item-acc_doc_item        = ls_acdoca-AccountingDocumentItem .
      ls_item-bill_num            = ls_acdoca-DocumentReferenceID.
      ls_item-posting_key         = ls_acdoca-PostingKey.

      IF ls_acdoca-FinancialAccountType = 'S'.

        ls_item-gl_code             = ls_acdoca-GLAccount.
        ls_item-gl_desc             = ls_gltext-GLAccountLongName.

      ELSEIF ls_acdoca-FinancialAccountType = 'A'.

        ls_item-gl_code             = ls_acdoca-GLAccount.
        ls_item-gl_desc             = ls_gltext-GLAccountLongName.

      ELSEIF ls_acdoca-FinancialAccountType = 'M'.

        ls_item-gl_code             = ls_acdoca-GLAccount.
        ls_item-gl_desc             = ls_gltext-GLAccountLongName.

      ELSEIF ls_acdoca-FinancialAccountType = 'K'.

        ls_item-gl_code             = ls_acdoca-Supplier.
        ls_item-gl_desc             = ls_acdoca-SupplierFullName.

      ELSEIF ls_acdoca-FinancialAccountType = 'D'.

        ls_item-gl_code             = ls_acdoca-Customer.
        ls_item-gl_desc             = ls_acdoca-CustomerFullName .

      ENDIF.

      CLEAR: lv_amount_neg.
      lv_amount_neg = ls_acdoca-AmountInTransactionCurrency.
      CONDENSE lv_amount_neg.
      IF lv_amount_neg CA '-'.
        lv_dr_amount = ls_acdoca-AmountInTransactionCurrency * -1.
      ELSE.
        lv_dr_amount = ls_acdoca-AmountInTransactionCurrency.
      ENDIF.

      IF ls_acdoca-DebitCreditCode = 'S'.
        ls_item-dr_amt              = lv_dr_amount.
      ELSE.
        ls_item-cr_amt              = lv_dr_amount.
      ENDIF.

      if ls_acdoca-TransactionCurrency = 'JPY'.
       ls_item-dr_amt              = ls_item-dr_amt * 100.
       ls_item-cr_amt              = ls_item-CR_AMT * 100.
      ENDIF.

*        lv_dr_amount                = ls_acdoca-AmountInTransactionCurrency.
*        ls_item-dr_amt              = lv_dr_amount.
*        ls_item-cr_amt              = lv_dr_amount.

      ls_item-c_center            = ''.
      ls_item-plant               = ls_acdoca-Plant.
      ls_item-assign_ref          = ls_acdoca-AssignmentReference.
      ls_item-tax_code            = ls_acdoca-TaxCode.
      ls_item-item_qty            = ls_acdoca-Quantity.
      ls_item-narration           = ls_acdoca-DocumentItemText.
      APPEND ls_item TO lt_item.

      IF ls_acdoca-FinancialAccountType = 'K' OR  ls_acdoca-FinancialAccountType = 'D'.
        gs_final-header_3     = ls_acdoca-DocumentItemText.. "*Used as Narration
      ENDIF.

      gs_final-sum_cr_amt   = gs_final-sum_cr_amt + ls_item-cr_amt.
      gs_final-sum_dr_amt   = gs_final-sum_dr_amt + ls_item-dr_amt.
      gs_final-sum_item_qty = gs_final-sum_item_qty + ls_acdoca-Quantity.

*      ENDIF.

      CLEAR: ls_acdoca, ls_gltext, ls_item.
    ENDLOOP.

    DATA: lv_grand_tot_word TYPE string.

    lv_grand_tot_word = gs_final-sum_dr_amt.

    lo_amt_words->number_to_words(
      EXPORTING
        iv_num   = lv_grand_tot_word
      RECEIVING
        rv_words = DATA(amt_words)
    ).

    CONCATENATE amt_words 'Only' INTO gs_final-amt_words SEPARATED BY space ##NO_TEXT.

    INSERT LINES OF lt_item INTO TABLE gs_final-gt_item.
    APPEND gs_final TO et_final.

  ENDMETHOD.


  METHOD prep_xml_chqprnt.

    DATA : heading      TYPE c LENGTH 100,
           lv_xml_final TYPE string.

    heading      = 'DE DIAMOND ELECTRIC INDIA PVT.LTD'.

    READ TABLE it_chqprnt INTO DATA(ls_chqprnt) INDEX 1.

    DATA(lv_xml) =  |<Form>| &&
                    |<AccountDocumentNode>| &&
                    |<heading>{ ls_chqprnt-suppl_name }</heading>| &&
                    |<cheque_no>{ ls_chqprnt-cheque_no }</cheque_no>| &&
                    |<cheque_date>{ ls_chqprnt-cheque_date }</cheque_date>| &&
                    |<chq_amt>{ ls_chqprnt-chq_amt }</chq_amt>| &&
                    |<amt_words>{ ls_chqprnt-tot_amt_words }</amt_words>| &&
                    |<ac_payee>{ ls_chqprnt-acc_payee  }</ac_payee>| &&
                    |<ItemData>| .

    DATA : lv_item TYPE string,
           lv_date TYPE c LENGTH 10,
           lv_dat1 TYPE c,
           lv_dat2 TYPE c,
           lv_dat3 TYPE c,
           lv_dat4 TYPE c,
           lv_dat5 TYPE c,
           lv_dat6 TYPE c,
           lv_dat7 TYPE c,
           lv_dat8 TYPE c.

    lv_date = ls_chqprnt-postingdate.
    lv_date = lv_date+6(2) && lv_date+4(2) && lv_date+0(4).

    lv_dat1 =  lv_date+0(1).
    lv_dat2 =  lv_date+1(1).
    lv_dat3 =  lv_date+2(1).
    lv_dat4 =  lv_date+3(1).
    lv_dat5 =  lv_date+4(1).
    lv_dat6 =  lv_date+5(1).
    lv_dat7 =  lv_date+6(1).
    lv_dat8 =  lv_date+7(1).

    CLEAR : lv_item.
    lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                    |<chq_d1>{ lv_dat1 }</chq_d1>| &&
                    |<chq_d2>{ lv_dat2 }</chq_d2>| &&
                    |<chq_d3>{ lv_dat3 }</chq_d3>| &&
                    |<chq_d4>{ lv_dat4 }</chq_d4>| &&
                    |<chq_d5>{ lv_dat5 }</chq_d5>| &&
                    |<chq_d6>{ lv_dat6 }</chq_d6>| &&
                    |<chq_d7>{ lv_dat7 }</chq_d7>| &&
                    |<chq_d8>{ lv_dat8 }</chq_d8>| &&
              |</ItemDataNode>|  .

    lv_xml = |{ lv_xml }{ lv_item }| &&
                       |</ItemData>| &&
                       |</AccountDocumentNode>| &&
                       |</Form>|.

    DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
    iv_xml_base64 = ls_data_xml_64.

  ENDMETHOD.


  METHOD prep_xml_fidebit .

    DATA : lv_qty          TYPE p LENGTH 16 DECIMALS 2,
           lv_netwt        TYPE p LENGTH 16 DECIMALS 2,
           lv_grosswt      TYPE p LENGTH 16 DECIMALS 2,
           lv_dis          TYPE p LENGTH 16 DECIMALS 2,
           lv_tot_amt      TYPE p LENGTH 16 DECIMALS 2,
           lv_tax_amt      TYPE p LENGTH 16 DECIMALS 2,
           lv_tot_sgst     TYPE p LENGTH 16 DECIMALS 2,
           lv_tot_cgst     TYPE p LENGTH 16 DECIMALS 2,
           lv_tot_igst     TYPE p LENGTH 16 DECIMALS 2,
           lv_tot_igst1    TYPE p LENGTH 16 DECIMALS 2,
           lv_tot_cgst1    TYPE p LENGTH 16 DECIMALS 2,
           lv_tot_sgst1    TYPE p LENGTH 16 DECIMALS 2,
           lv_tcs          TYPE p LENGTH 16 DECIMALS 2,
           lv_other_chrg   TYPE p LENGTH 16 DECIMALS 2,
           lv_round_off    TYPE p LENGTH 16 DECIMALS 2,
           lv_tot_gst      TYPE p LENGTH 16 DECIMALS 2,
           lv_grand_tot    TYPE p LENGTH 16 DECIMALS 2,
           lv_gross        TYPE p LENGTH 16 DECIMALS 2,
           lv_net          TYPE p LENGTH 16 DECIMALS 2,
           heading         TYPE c LENGTH 100,
           sub_heading_new TYPE c LENGTH 100,
           for_sign        TYPE c LENGTH 100,
           odte_text       TYPE c LENGTH 20,
           head_lut        TYPE c LENGTH 100,
           curr            TYPE c LENGTH 100,
           exc_rt          TYPE c LENGTH 100,
           lv_dt_bill      TYPE c LENGTH 10,
           lv_dt_po        TYPE c LENGTH 10,
           lv_dt_ack       TYPE c LENGTH 10,
           lv_item         TYPE string,
           srn             TYPE c LENGTH 3.

    DATA: lv_vbeln_n   TYPE c LENGTH 10,
          lv_qr_code   TYPE string,
          lv_irn_num   TYPE c LENGTH 64, "w_irn-irnno
          lv_ack_no    TYPE c LENGTH 20, "w_irn-ackno
          lv_ack_date  TYPE c LENGTH 10, "w_irn-ackdat
          lv_ref_sddoc TYPE c LENGTH 20. "w_item-ReferenceSDDocument

    READ TABLE it_dbnote INTO DATA(ls_dbnote) INDEX 1.

    SELECT SINGLE
    signedqrcode,
    irn,
    ackno,
    ackdt
    FROM zsd_einv_data WHERE billingdocument = @ls_dbnote-accountingdocument AND
                                            companycode     = @ls_dbnote-companycode AND
                                            fiscalyear      = @ls_dbnote-fiscalyear
      INTO @DATA(w_einvvoice) .                         "#EC CI_NOORDER

    CLEAR : lv_qr_code , lv_irn_num   , lv_ack_no ,lv_ack_date .

    lv_qr_code  = w_einvvoice-signedqrcode.
    lv_irn_num  = w_einvvoice-irn.
    lv_ack_no   = w_einvvoice-ackno .
    lv_ack_date = w_einvvoice-ackdt+8(2) && '.' && w_einvvoice-ackdt+5(2) && '.' && w_einvvoice-ackdt+0(4).

    heading      = 'Debit Note' ##NO_TEXT.

    IF im_action = 'ficredit' ##NO_TEXT.

      heading     = 'Credit Note' ##NO_TEXT.

      IF ls_dbnote-accountingdocumenttype = 'DR'.
        heading     = 'Tax Invoice' ##NO_TEXT.
        sub_heading_new = '3. Interest @ 24% P.A. will be charged if payment is not received on due date' ##NO_TEXT.
      ELSEIF ls_dbnote-accountingdocumenttype = ''.
      ENDIF.

    ELSEIF im_action = 'fircm' ##NO_TEXT.
      heading     = 'Self Invoice' ##NO_TEXT.
      sub_heading_new  = 'Under section 31 of CGST Act 2017, read with rule 46 of CGST Rules 2017'.
    ELSEIF im_action = 'fitaxinv' ##NO_TEXT.
      heading     = 'Tax Invoice' ##NO_TEXT.
    ENDIF.


    for_sign  = 'DE DIAMOND ELECTRIC INDIA PVT. LTD.' ##NO_TEXT.
    ls_dbnote-suppl_name = 'DE DIAMOND ELECTRIC INDIA PRIVATE LIMITED' ##NO_TEXT.

    DATA(lv_xml) = |<Form>| &&
                   |<BillingDocumentNode>| &&
                   |<heading>{ heading }</heading>| &&
                   |<sub_heading_new>{ sub_heading_new  }</sub_heading_new>| &&
                   |<head_lut>{ head_lut }</head_lut>| &&
                   |<for_sign>{ for_sign }</for_sign>| &&
                   |<odte_text>{ gs_dbnote-revrs_yes_no }</odte_text>| &&
                   |<doc_curr>{ curr }</doc_curr>| &&

                   |<plant_code>{ ls_dbnote-suppl_code }</plant_code>| &&
                   |<plant_name>{ ls_dbnote-suppl_name }</plant_name>| &&
                   |<plant_address_l1>{ ls_dbnote-suppl_addr1 }</plant_address_l1>| &&
                   |<plant_address_l2>{ ls_dbnote-suppl_addr2 }</plant_address_l2>| &&
                   |<plant_address_l3>{ ls_dbnote-suppl_addr3 }</plant_address_l3>| &&
                   |<plant_cin>{ ls_dbnote-suppl_cin }</plant_cin>| &&
                   |<plant_gstin>{ ls_dbnote-suppl_gstin }</plant_gstin>| &&
                   |<plant_pan>{ ls_dbnote-suppl_gstin+2(10) }</plant_pan>| &&
                   |<plant_state_code>{ ls_dbnote-suppl_stat_code }</plant_state_code>| &&
                   |<plant_state_name></plant_state_name>| &&
                   |<plant_phone>{ ls_dbnote-suppl_phone }</plant_phone>| &&
                   |<plant_email>{ ls_dbnote-suppl_email }</plant_email>| &&

                   |<billto_code>{ ls_dbnote-billto_code }</billto_code>| &&
                   |<billto_name>{ ls_dbnote-billto_name }</billto_name>| &&
                   |<billto_address_l1>{ ls_dbnote-billto_addr1 }</billto_address_l1>| &&
                   |<billto_address_l2>{ ls_dbnote-billto_addr2 }</billto_address_l2>| &&
                   |<billto_address_l3>{ ls_dbnote-billto_addr3 }</billto_address_l3>| &&
                   |<billto_cin>{ ls_dbnote-billto_cin }</billto_cin>| &&
                   |<billto_gstin>{ ls_dbnote-billto_gstin }</billto_gstin>| &&
                   |<billto_pan>{ ls_dbnote-billto_gstin+2(10) }</billto_pan>| &&
                   |<billto_state_code>{ ls_dbnote-billto_stat_code }</billto_state_code>| &&
                   |<billto_state_name></billto_state_name>| &&
*                  |<billto_place_suply>{ ls_dbnote-sup }</billto_place_suply>| &&
                   |<billto_phone>{ ls_dbnote-billto_phone }</billto_phone>| &&
                   |<billto_email>{ ls_dbnote-billto_email }</billto_email>| &&

                   |<shipto_code>{ ls_dbnote-shipto_code }</shipto_code>| &&
                   |<shipto_name>{ ls_dbnote-shipto_name }</shipto_name>| &&
                   |<shipto_address_l1>{ ls_dbnote-shipto_addr1 }</shipto_address_l1>| &&
                   |<shipto_address_l2>{ ls_dbnote-shipto_addr2 }</shipto_address_l2>| &&
                   |<shipto_address_l3>{ ls_dbnote-shipto_addr3 }</shipto_address_l3>| &&
*                  |<shipto_cin>{ W_FINAL-PlantName }</shipto_cin>| &&
                   |<shipto_gstin>{ ls_dbnote-shipto_gstin }</shipto_gstin>| &&
                   |<shipto_pan>{ ls_dbnote-shipto_pan }</shipto_pan>| &&
                   |<shipto_state_code>{ ls_dbnote-shipto_stat_code }</shipto_state_code>| &&
                   |<shipto_state_name></shipto_state_name>| &&
*                  |<shipto_place_suply>{ w_final-we_city }</shipto_place_suply>| &&
                   |<shipto_phone>{ ls_dbnote-shipto_phone }</shipto_phone>| &&
                   |<shipto_email>{ ls_dbnote-shipto_email }</shipto_email>| &&

                   |<inv_no>{ ls_dbnote-inv_no }  </inv_no>| &&
                   |<inv_date>{ ls_dbnote-inv_date }</inv_date>| &&
                   |<inv_ref>{ ls_dbnote-inv_ref_no }</inv_ref>| &&
                   |<ref_doc_no>{ ls_dbnote-ref_doc_no }</ref_doc_no>| &&
                   |<inv_ref_date>{ gs_dbnote-inv_ref_date }</inv_ref_date>| &&
*                        |<exchange_rate>{ exc_rt }</exchange_rate>| &&
*                        |<currency>{ w_final-TransactionCurrency }</currency>| &&
*                        |<Exp_Inv_No>{ lv_exp_no }</Exp_Inv_No>| &&       """""""
                   |<IRN_num>{ lv_irn_num }</IRN_num>| &&
                   |<IRN_ack_No>{ lv_ack_no }</IRN_ack_No>| &&
                   |<irn_ack_date>{ lv_ack_date }</irn_ack_date>| &&
*                        |<irn_doc_type></irn_doc_type>| &&     """"""
*                        |<irn_category></irn_category>| &&     """"""
                        |<qrcode>{ lv_qr_code }</qrcode>| &&
*                        |<vcode>{ vcode }</vcode>| &&
*                        |<vplant>{ lv_cus_pl }</vplant>| &&
*                        |<pur_odr_no>{ w_final-PurchaseOrderByCustomer }</pur_odr_no>| &&
*                        |<pur_odr_date>{ lv_dt_po }</pur_odr_date>| &&
*                        |<Pay_term>{ w_final-CustomerPaymentTerms }:{ w_final-CustomerPaymentTermsName }</Pay_term>| &&  """"
                   |<Veh_no>{ ls_dbnote-veh_no }</Veh_no>| &&
                   |<Trans_mode>{ ls_dbnote-trnas_mode }</Trans_mode>| &&
*                        |<Ewaybill_no>{ lv_eway }</Ewaybill_no>| &&
*                        |<Ewaybill_date>{ lv_eway_dt }</Ewaybill_date>| &&

                   |<ItemData>| .

    LOOP AT ls_dbnote-gt_item INTO DATA(w_item) .

      srn = srn + 1 .
      lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                |<sno>{ srn }</sno>| &&

                    |<item_code>{ w_item-itemcode }</item_code>| &&
*                    |<item_cust_refno>{ lv_ref_sddoc }</item_cust_refno>| &&
                    |<item_desc>{ w_item-itemdesc }</item_desc>| &&
                    |<item_hsn_code>{ w_item-hsncode }</item_hsn_code>| &&
                    |<item_uom>{ w_item-uom }</item_uom>| &&
                    |<item_qty>{ w_item-itmqty }</item_qty>| &&
                    |<item_unit_rate>{ w_item-unit_rate }</item_unit_rate>| &&
                    |<item_amt_inr>{ w_item-amount }</item_amt_inr>| &&
                    |<item_discount>{ w_item-discount }</item_discount>| &&
                    |<item_taxable_amt>{ w_item-amount }</item_taxable_amt>| &&
                    |<item_sgst_rate>{ w_item-sgst_rate }</item_sgst_rate>| &&
                    |<item_sgst_amt>{ w_item-sgst_amt }</item_sgst_amt>| &&
                    |<item_cgst_amt>{ w_item-cgst_amt }</item_cgst_amt>| &&
                    |<item_cgst_rate>{ w_item-cgst_rate }</item_cgst_rate>| &&
                    |<item_igst_amt>{ w_item-igst_amt }</item_igst_amt>| &&
                    |<item_igst_rate>{ w_item-igst_rate }</item_igst_rate>| &&
                    |<item_curr>{ w_item-trans_curr }</item_curr>| &&
*                    |<item_amort_amt>{ w_item-item_amotization }</item_amort_amt>| &&

                |</ItemDataNode>|  .

    ENDLOOP .

    lv_xml = |{ lv_xml }{ lv_item }| &&
                       |</ItemData>| &&
                        |<total_amount_words>(INR) { ls_dbnote-tot_amt_words }</total_amount_words>| &&
                        |<gst_amt_words>(INR) { ls_dbnote-gst_amt_words }</gst_amt_words>| &&
                        |<remark_if_any>{ ls_dbnote-remark }</remark_if_any>| &&
*                        |<no_of_package>{ lv_no_pck }</no_of_package>| &&
*                        |<total_Weight>{ lv_qty }</total_Weight>| &&
*                        |<gross_Weight>{ lv_gross }</gross_Weight>| &&
*                        |<net_Weight>{ lv_net }</net_Weight>| &&

                         |<tot_qty></tot_qty>| &&  """ line item total quantity
                         |<total_amount>{ ls_dbnote-total_value }</total_amount>| &&
                         |<total_discount></total_discount>| &&

                        |<total_taxable_value>{ ls_dbnote-total_value }</total_taxable_value>| &&
                        |<total_cgst>{ ls_dbnote-sum_cgst_amt }</total_cgst>| &&
                        |<total_sgst>{ ls_dbnote-sum_sgst_amt }</total_sgst>| &&
                        |<total_igst>{ ls_dbnote-sum_igst_amt }</total_igst>| &&

                        |<total_igst1>{ ls_dbnote-sum_igst_amt1 }</total_igst1>| &&
                        |<total_sgst1>{ ls_dbnote-sum_sgst_amt1 }</total_sgst1>| &&
                        |<total_cgst1>{ ls_dbnote-sum_cgst_amt1 }</total_cgst1>| &&

                    ""   |<total_igst1>{ lv_tot_igst }</total_igst1>| &&
                        |<total_tcs>{ ls_dbnote-sum_tcs_amt }</total_tcs>| &&
                        |<total_other_chrg>{ ls_dbnote-sum_other_amt }</total_other_chrg>| &&
                        |<round_off>{ ls_dbnote-sum_rndf_amt }</round_off>| &&
                        |<grand_total>{ ls_dbnote-grand_total }</grand_total>| &&

                    |</BillingDocumentNode>| &&
                    |</Form>|.

    DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
    iv_xml_base64 = ls_data_xml_64.

  ENDMETHOD.


  METHOD prep_xml_payadv.

    DATA : heading      TYPE c LENGTH 100,
           sub_heading  TYPE c LENGTH 200,
           lv_xml_final TYPE string,
           lv_user_name TYPE string,
           lv_user_id   TYPE I_IAMBusinessUserLogonDetails-UserID.

    heading      = 'DE DIAMOND ELECTRIC INDIA PVT.LTD' ##NO_TEXT.
    sub_heading  = 'Payment Advice- ADV' ##NO_TEXT.

    READ TABLE it_payadv INTO DATA(ls_payadv) INDEX 1.

    CONDENSE ls_payadv-bank_acc_no.
    SHIFT ls_payadv-bank_acc_no LEFT DELETING LEADING '0'.
*    DATA(lv_acc_len) = strlen( ls_payadv-bank_acc_no ).
*    lv_acc_len = lv_acc_len - 5.
*    ls_payadv-bank_acc_no = ls_payadv-bank_acc_no+lv_acc_len(5).

    lv_user_id = sy-uname.
    SELECT SINGLE UserName FROM I_IAMBusinessUserLogonDetails
                  WHERE UserID = @lv_user_id
                  INTO @DATA(lv_user_detail).

    lv_user_name = lv_user_detail. "sy-uname

    DATA(lv_xml) =  |<Form>| &&
                    |<AccountDocumentNode>| &&
                    |<heading>{ heading }</heading>| &&
                    |<sub_heading>{ sub_heading }</sub_heading>| &&
                    |<suppl_cin>{ ls_payadv-suppl_cin }</suppl_cin>| &&
                    |<suppl_code>{ ls_payadv-suppl_code }</suppl_code>| &&
                    |<suppl_name>{ ls_payadv-suppl_name }</suppl_name>| &&
                    |<suppl_addrs1>{ ls_payadv-suppl_addr1 }</suppl_addrs1>| &&
                    |<suppl_addrs2>{ ls_payadv-suppl_addr2 }</suppl_addrs2>| &&
                    |<suppl_addrs3>{ ls_payadv-suppl_addr3 }</suppl_addrs3>| &&
                    |<suppl_addrs4>{ ls_payadv-suppl_addr4 }</suppl_addrs4>| &&
                    |<voucher_no>{ ls_payadv-voucher_no }</voucher_no>| &&
                    |<voucher_date>{ ls_payadv-voucher_date }</voucher_date>| &&
                    |<bank_name>{ ls_payadv-bank_name }</bank_name>| &&
                    |<bank_det1>{ ls_payadv-bank_det1 }</bank_det1>| &&
                    |<bank_det2>{ ls_payadv-bank_det2 }</bank_det2>| &&
                    |<cheque_no>{ ls_payadv-cheque_no }</cheque_no>| &&
                    |<cheque_date>{ ls_payadv-cheque_date }</cheque_date>| &&
                    |<po_num>{ ls_payadv-po_num }</po_num>| &&
                    |<chq_amt>{ ls_payadv-chq_amt }</chq_amt>| &&
                    |<amt_words>{ ls_payadv-tot_amt_words }</amt_words>| &&
                    |<narration>{ ls_payadv-narration }</narration>| &&
                    |<sum_bil_amt>{ ls_payadv-sum_bil_amt }</sum_bil_amt>| &&
                    |<sum_tds_amt>{ ls_payadv-sum_tds_amt }</sum_tds_amt>| &&
                    |<sum_debit_amt>{ ls_payadv-sum_debit_amt }</sum_debit_amt>| &&
                    |<sum_net_amt>{ ls_payadv-sum_net_amt }</sum_net_amt>| &&
                    |<header_curr>{ ls_payadv-trans_curr }</header_curr>| &&
                    |<user_name>{ lv_user_name }</user_name>| &&

                    |<bank_acc_no>{ ls_payadv-bank_acc_no }</bank_acc_no>| &&
                    |<bank_ifsc_code>{ ls_payadv-bank_ifsc_code }</bank_ifsc_code>| &&
                    |<payment_mode>{ ls_payadv-payment_mode }</payment_mode>| &&
                    |<bank_utr_no>{ ls_payadv-bank_utr_no }</bank_utr_no>| &&

                    |<ItemData>| .

    DATA : lv_item TYPE string .
    DATA : srn TYPE c LENGTH 3 .
    CLEAR : lv_item , srn .

    LOOP AT ls_payadv-gt_item INTO DATA(w_item) .

      srn = srn + 1 .

      lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                |<sr_num>{ srn }</sr_num>| &&
                |<doc_num>{ w_item-accountingdocument }</doc_num>| &&
                |<bill_num>{ w_item-bill_num }</bill_num>| &&
                |<bill_date>{ w_item-bill_date }</bill_date>| &&
                |<bill_amt>{ w_item-bill_amt }</bill_amt>| &&
                |<tds_amt>{ w_item-tds_amt }</tds_amt>| &&
                |<debit_note_no>{ w_item-debit_note_no }</debit_note_no>| &&
                |<debit_date>{ w_item-debit_date }</debit_date>| &&
                |<debit_amt>{ w_item-debit_amt }</debit_amt>| &&
                |<net_amt>{ w_item-net_amt }</net_amt>| &&
                |<dr_cr>{ w_item-dr_cr }</dr_cr>| &&
                |<item_curr>{ w_item-trans_curr }</item_curr>| &&
                |</ItemDataNode>|  .

    ENDLOOP.

    lv_xml = |{ lv_xml }{ lv_item }| &&
                       |</ItemData>| &&
                       |</AccountDocumentNode>| &&
                       |</Form>|.

    DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
    iv_xml_base64 = ls_data_xml_64.

  ENDMETHOD.


  METHOD prep_xml_voucher_print .

    sys_date = cl_abap_context_info=>get_system_date( ).
    sys_time = cl_abap_context_info=>get_system_time( ).
    sy_uname = cl_abap_context_info=>get_user_technical_name( ).

    CLEAR: gt_final.
    gt_final[] = it_final[].

    READ TABLE gt_final INTO gs_final INDEX 1.

    DATA(lv_xml) =  |<Form>| &&
                    |<AccountDocumentNode>| &&
                    |<heading>{ gs_final-heading }</heading>| &&
                    |<sub_heading>{ gs_final-sub_heading }</sub_heading>| &&
                    |<header_1>{ gs_final-header_1 }</header_1>| &&
                    |<header_2>{ gs_final-header_2 }</header_2>| &&
                    |<header_3>{ gs_final-header_3 }</header_3>| &&
                    |<accounting_doc>{ gs_final-accountingdocument }</accounting_doc>| &&
                    |<fiscal_year>{ gs_final-fiscalyear }</fiscal_year>| &&
                    |<comp_code>{ gs_final-companycode }</comp_code>| &&
                    |<comp_name>{ gs_final-comp_name }</comp_name>| &&
                    |<comp_adrs1>{ gs_final-comp_adrs1 }</comp_adrs1>| &&
                    |<comp_adrs2>{ gs_final-comp_adrs2 }</comp_adrs2>| &&
                    |<comp_adrs3>{ gs_final-comp_adrs3 }</comp_adrs3>| &&
                    |<plant_code>{ gs_final-plant_code }</plant_code>| &
                    |<plant_name>{ gs_final-plant_name }</plant_name>| &
                    |<plant_address_l1>{ gs_final-plant_address_l1 }</plant_address_l1>| &
                    |<plant_address_l2>{ gs_final-plant_address_l2 }</plant_address_l2>| &
                    |<plant_address_l3>{ gs_final-plant_address_l3 }</plant_address_l3>| &
                    |<vend_address>{ gs_final-vend_address }</vend_address>| &
                    |<voucher_no>{ gs_final-voucher_no }</voucher_no>| &&
                    |<voucher_date>{ gs_final-voucher_date }</voucher_date>| &&
                    |<doc_type>{ gs_final-doc_type }</doc_type>| &&
                    |<doc_type_desc>{ gs_final-doc_type_desc }</doc_type_desc>| &&
                    |<ref_num>{ gs_final-ref_num }</ref_num>| &&
                    |<posting_date>{ gs_final-posting_date }</posting_date>| &&
                    |<doc_date>{ gs_final-doc_date }</doc_date>| &&
                    |<currency>{ gs_final-currency }</currency>| &&
                    |<park_by>{ gs_final-park_by }</park_by>| &&
                    |<posted_by>{ gs_final-posted_by }</posted_by>| &&
                    |<amt_words>{ gs_final-amt_words }</amt_words>| &&
                    |<sum_cr_amt>{ gs_final-sum_cr_amt }</sum_cr_amt>| &&
                    |<sum_dr_amt>{ gs_final-sum_dr_amt }</sum_dr_amt>| &&
                    |<sum_item_qty>{ gs_final-sum_item_qty }</sum_item_qty>| &&
                    |<ItemData>|  ##NO_TEXT.

    DATA : lv_item TYPE string,
           srn     TYPE c LENGTH 3.

    CLEAR : lv_item , srn .

    LOOP AT gs_final-gt_item INTO DATA(ls_item).
      srn = srn + 1 .
      REPLACE ALL OCCURRENCES OF '&' IN ls_item-gl_desc WITH 'and'.
      REPLACE ALL OCCURRENCES OF '×' IN ls_item-gl_desc WITH ''.
      REPLACE ALL OCCURRENCES OF '±' IN ls_item-gl_desc WITH ''.
      REPLACE ALL OCCURRENCES OF '#' IN ls_item-gl_desc WITH ''.

      lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                |<sr_num>{ srn }</sr_num>| &&
                |<acc_doc>{ ls_item-accountingdocument }</acc_doc>| &&
                |<acc_doc_item>{ ls_item-acc_doc_item }</acc_doc_item>| &&
                |<bill_num>{ ls_item-bill_num }</bill_num>| &&
                |<posting_key>{ ls_item-posting_key }</posting_key>| &&
                |<gl_code>{ ls_item-gl_code }</gl_code>| &&
                |<gl_desc>{ ls_item-gl_desc }</gl_desc>| &&
                |<dr_amt>{ ls_item-dr_amt }</dr_amt>| &&
                |<cr_amt>{ ls_item-cr_amt }</cr_amt>| &&
                |<c_center>{ ls_item-c_center }</c_center>| &&
                |<plant>{ ls_item-plant }</plant>| &&
                |<assign_ref>{ ls_item-assign_ref }</assign_ref>| &&
                |<tax_code>{ ls_item-tax_code }</tax_code>| &&
                |<item_qty>{ ls_item-item_qty }</item_qty>| &&
                |<narration>{ ls_item-narration }</narration>| &&
                |</ItemDataNode>|  ##NO_TEXT .

      CLEAR: ls_item.
    ENDLOOP.

    lv_xml = |{ lv_xml }{ lv_item }| &&
                       |</ItemData>| &&
                       |</AccountDocumentNode>| &&
                       |</Form>| ##NO_TEXT .

    DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
    iv_xml_base64 = ls_data_xml_64.

  ENDMETHOD.
ENDCLASS.
