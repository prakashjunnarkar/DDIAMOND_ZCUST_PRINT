CLASS zcl_mm_po_print DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA:
      sys_date     TYPE d,
      sys_time     TYPE t,
      sys_timezone TYPE timezone,
      sy_uname     TYPE c LENGTH 20.

    DATA:
      lv_char10  TYPE c LENGTH 10,
      lv_char120 TYPE c LENGTH 120.

    DATA:
      lv_char15         TYPE c LENGTH 15,
      total_gst         TYPE string,
      total_gst_words   TYPE string,
      grand_total       TYPE string,
      grand_total_words TYPE string,
      item_cgst         TYPE string,
      item_sgst         TYPE string,
      item_igst         TYPE string,
      charge_per        TYPE p LENGTH 16 DECIMALS 2.

    DATA:
      gt_final TYPE TABLE OF zstr_mm_po_print_hdr,
      gs_final TYPE zstr_mm_po_print_hdr,
      lt_item  TYPE TABLE OF zstr_mm_po_print_itm,
      ls_item  TYPE zstr_mm_po_print_itm.

*    data:
*      it_po_hdr type table of

    DATA: lo_amt_words   TYPE REF TO zcl_amt_words.

    METHODS:
      get_po_data
        IMPORTING
                  im_action       LIKE lv_char15
                  im_ponum        TYPE zi_po_print_data-purchaseorder
                  im_podate       TYPE zi_po_print_data-purchaseorderdate
                  im_poplant      TYPE zi_po_print_data-plant
        RETURNING VALUE(et_final) LIKE gt_final,

      prep_xml_po_print
        IMPORTING
                  it_final             LIKE gt_final
                  im_action            LIKE lv_char15
        RETURNING VALUE(iv_xml_base64) TYPE string,

      get_rgpout_data
        IMPORTING
                  im_action       LIKE lv_char15
                  im_rgpoutnum    TYPE zi_rgp_out_report-rgpoutnum
                  im_rgpoutdate   TYPE zi_rgp_out_report-rgpoutcreationdate
                  im_plant        TYPE zi_rgp_out_report-werks
        RETURNING VALUE(et_final) LIKE gt_final,


      get_nrgp_data
        IMPORTING
                  im_action       LIKE lv_char15
                  im_nrgpnum      TYPE zi_nrgp_report-nrgpnum
                  im_nrgpdate     TYPE zi_nrgp_report-nrgpcreationdate
                  im_plant        TYPE zi_nrgp_report-werks
        RETURNING VALUE(et_final) LIKE gt_final,
      prep_xml_rgpout_print
        IMPORTING
                  it_final             LIKE gt_final
                  im_action            LIKE lv_char15
        RETURNING VALUE(iv_xml_base64) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_mm_po_print IMPLEMENTATION.


  METHOD get_po_data.

    sys_date = cl_abap_context_info=>get_system_date( ).
    sys_time = cl_abap_context_info=>get_system_time( ).
    sy_uname = cl_abap_context_info=>get_user_technical_name( ).

    SELECT * FROM zi_po_data WHERE purchaseorder     EQ @im_ponum
                             AND   purchaseorderdate EQ @im_podate
                             AND   plant             EQ @im_poplant
                             INTO TABLE @DATA(it_po_data).

    IF it_po_data IS NOT INITIAL.

      READ TABLE it_po_data INTO DATA(wa_po_hdr) INDEX 1. "#EC CI_NOORDER

      SELECT SINGLE * FROM zi_plant_address WHERE plant EQ @wa_po_hdr-plant  INTO @DATA(wa_plant_address). "#EC CI_ALL_FIELDS_NEEDED
      SELECT SINGLE * FROM zi_supplier_address WHERE supplier EQ @wa_po_hdr-supplier  INTO @DATA(wa_supplier_adr). "#EC CI_ALL_FIELDS_NEEDED

      """**Preparing Header Data
      gs_final-plant_name     = ''.
      gs_final-plant_adr1     = ''.
      gs_final-plant_adr2     = ''.
      gs_final-plant_gstin    = ''.
      gs_final-po_type        = ''.
      gs_final-purchase_order = wa_po_hdr-purchaseorder.
      gs_final-po_date        = wa_po_hdr-purchaseorderdate.
      gs_final-amd_no         = ''.
      gs_final-amd_date       = ''.
      gs_final-currency       = wa_po_hdr-documentcurrency.
      gs_final-po_ref_no      = wa_po_hdr-referencedeliveryaddressid.
      gs_final-vend_code      = wa_supplier_adr-supplier.
      gs_final-vend_name      = wa_supplier_adr-supplierfullname.
      gs_final-vend_adr1      = wa_supplier_adr-streetsuffixname1.
      gs_final-vend_adr2      = wa_supplier_adr-streetprefixname2.
      gs_final-vend_adr3      = wa_supplier_adr-streetprefixname2.
      gs_final-vend_gstin     = wa_supplier_adr-taxnumber3.
      gs_final-vend_pan       = ''.
      gs_final-vend_mail      = wa_supplier_adr-emailaddress.
      gs_final-vend_mob       = wa_supplier_adr-phonenumber1.
      gs_final-billto_name    = wa_plant_address-plantname.
      gs_final-billto_adr1    = wa_plant_address-streetsuffixname1.
      gs_final-billto_adr2    = wa_plant_address-streetprefixname1.
      gs_final-billto_state   = wa_plant_address-regionname.
      gs_final-billto_mob     = ''.
      gs_final-billto_gst     = ''.
      gs_final-billto_pan     = ''.
      gs_final-billto_cin     = ''.
      gs_final-delvto_name    = wa_plant_address-plantname.
      gs_final-delvto_adr1    = wa_plant_address-streetsuffixname1.
      gs_final-delvto_adr2    = wa_plant_address-streetprefixname1.
      gs_final-delvto_state   = wa_plant_address-regionname.
      gs_final-delvto_mob     = ''.
      gs_final-delvto_gst     = ''.
      gs_final-delvto_pan     = ''.
      gs_final-payment_terms  = wa_po_hdr-paymentterms.
      gs_final-freight        = ''.
      gs_final-insurance      = ''.
      gs_final-delivery_term  = ''.
      gs_final-tot_qty        = ''.
      gs_final-subtotal       = wa_po_hdr-subtotal1amount.
      gs_final-tot_cgst       = ''.
      gs_final-tot_sgst       = ''.
      gs_final-tot_igst       = ''.
      gs_final-freight_chrg   = ''.
      gs_final-packing_chrg   = ''.
      gs_final-other_chrg     = ''.
      gs_final-insurance_chrg = ''.
      gs_final-grand_total    = wa_po_hdr-subtotal6amount.
      gs_final-grand_tot_word = ''.
      gs_final-remarks        = ''.


      """**Preparing Item Data
      LOOP AT it_po_data INTO DATA(wa_po_itm).

        ls_item-purchase_order = wa_po_itm-purchaseorder.
        ls_item-purchase_item  = wa_po_itm-purchaseorderitem.
        ls_item-sl_no          = ''.
        ls_item-item_code      = wa_po_itm-material.
        ls_item-item_name      = wa_po_itm-productdescription.
        ls_item-item_hsn       = ''.
        ls_item-item_unit      = wa_po_itm-baseunit.
        ls_item-item_qty       = wa_po_itm-orderquantity.
        ls_item-item_rate      = ''.
        ls_item-disc_amt       = ''.
        ls_item-cgst_amt       = ''.
        ls_item-sgst_amt       = ''.
        ls_item-igst_amt       = ''.
        ls_item-net_val        = wa_po_itm-netamount.
        APPEND ls_item TO lt_item.

      ENDLOOP.
    ENDIF.

    """**Combining Header & Item
    INSERT LINES OF lt_item INTO TABLE gs_final-gt_item.
    APPEND gs_final TO gt_final.
    et_final[] = gt_final[].

  ENDMETHOD.


  METHOD get_nrgp_data.

    sys_date = cl_abap_context_info=>get_system_date( ).
    sys_time = cl_abap_context_info=>get_system_time( ).
    sy_uname = cl_abap_context_info=>get_user_technical_name( ).


    SELECT * FROM zmm_nrgp_data WHERE nrgp_num    EQ @im_nrgpnum
                             AND   nrgp_creationdate EQ @im_nrgpdate
                             AND   werks             EQ @im_plant
                             AND   nrgpdeleted = ''
                             INTO TABLE @DATA(it_po_data).

    IF it_po_data IS NOT INITIAL.

      SELECT
      taxcode,
      cgstrate,
      sgstrate,
      igstrate
      FROM ze_tax_gst_prcnt
      FOR ALL ENTRIES IN @it_po_data
      WHERE taxcode = @it_po_data-taxcode
      INTO TABLE @DATA(it_gst_rate).               "#EC CI_NO_TRANSFORM

    ENDIF.

    IF it_po_data IS NOT INITIAL.

      READ TABLE it_po_data INTO DATA(wa_po_hdr) INDEX 1. "#EC CI_NOORDER

      DATA: lv_lifnr TYPE i_supplier-supplier.
      lv_lifnr = |{ wa_po_hdr-lifnr ALPHA = IN }|.
      wa_po_hdr-lifnr = lv_lifnr.


      SELECT SINGLE * FROM zi_plant_address WHERE plant EQ @wa_po_hdr-werks  INTO @DATA(wa_plant_address). "#EC CI_ALL_FIELDS_NEEDED

      SELECT SINGLE * FROM zi_supplier_address WHERE supplier EQ @wa_po_hdr-lifnr  INTO @DATA(wa_supplier_adr). "#EC CI_ALL_FIELDS_NEEDED

      SELECT
        purchaseorder,
        purchaseorderitem,
        pricingdocument,
        pricingdocumentitem,
        pricingprocedurestep,
        pricingprocedurecounter,
        conditionapplication,
        conditiontype,
        conditionamount,
        conditionquantity,
        conditioncalculationtype,
        conditionratevalue
      FROM i_purorditmpricingelementapi01 WHERE purchaseorder EQ @wa_po_hdr-prnum
                                                   INTO TABLE @DATA(it_charges). "#EC CI_NO_TRANSFORM

      gs_final-purchase_order = wa_po_hdr-nrgp_num.
      gs_final-po_date        = wa_po_hdr-nrgp_creationdate+6(2) && '.' && wa_po_hdr-nrgp_creationdate+4(2) && '.'
                                && wa_po_hdr-nrgp_creationdate+0(4).

    ENDIF.

    gs_final-plant = wa_po_hdr-werks.

    DATA(billtoname) = |{ wa_plant_address-addresseefullname } { wa_plant_address-housenumber } { wa_plant_address-streetname } { wa_plant_address-cityname }  { wa_plant_address-regionname } { wa_plant_address-postalcode }|.

    gs_final-billto_name    = billtoname.
    gs_final-billto_adr1    = wa_plant_address-streetsuffixname1.
    gs_final-billto_adr2    = wa_plant_address-streetprefixname1.
    gs_final-billto_state   = wa_plant_address-regionname.
    gs_final-billto_mob     = ''.
    gs_final-billto_gst     = '06AACCD6342B1Z6'.
    gs_final-billto_pan     = 'AACCD6342B'.
    gs_final-billto_cin     = ''.
    gs_final-delvto_name    = gs_final-billto_name.
    gs_final-delvto_adr1    = wa_plant_address-streetname.
    gs_final-delvto_adr2    = wa_plant_address-streetprefixname1.
    gs_final-delvto_state   = wa_plant_address-region.
    gs_final-delvto_mob     = ''.
    gs_final-delvto_gst     = '06AACCD6342B1Z6' .
    gs_final-delvto_pan     = 'AACCD6342B'.


    gs_final-amd_no         = ''.
    gs_final-amd_date       = ''.
    gs_final-currency       = wa_po_hdr-currcy.

    SELECT SINGLE supplier FROM i_purchaseorderpartnerapi01 WHERE purchaseorder EQ @wa_po_hdr-prnum
    INTO @DATA(supplier_code).
*      SELECT SINGLE suppliername FROM i_supplier WHERE supplier EQ @supplier_code INTO @gs_final-broker_name.

    IF wa_po_hdr-lifnr IS NOT INITIAL.
      SHIFT wa_supplier_adr-supplier LEFT DELETING LEADING '0'.
      gs_final-vend_code      = wa_supplier_adr-supplier.
      gs_final-vend_name      = wa_supplier_adr-suppliername.
      gs_final-vend_adr1      = wa_supplier_adr-streetname.
      gs_final-vend_adr2      = wa_supplier_adr-districtname.
      gs_final-vend_adr3      = wa_supplier_adr-region && '-' && wa_supplier_adr-postalcode.
      gs_final-vend_gstin     = wa_supplier_adr-taxnumber3.
      gs_final-vend_pan       = wa_supplier_adr-businesspartnerpannumber.
      gs_final-vend_mail      = wa_supplier_adr-emailaddress.
      gs_final-vend_mob       = wa_supplier_adr-phonenumber1.
    ENDIF.
**
**
    CONCATENATE  gs_final-vend_name cl_abap_char_utilities=>newline gs_final-vend_adr1 ',' gs_final-vend_adr2 ','
                 gs_final-vend_adr3 INTO DATA(lv_ven) .

    gs_final-vend_name = lv_ven .

    gs_final-tot_cgst       = ''.
    gs_final-tot_sgst       = ''.
    gs_final-tot_igst       = ''.
    gs_final-remarks        = wa_po_hdr-remarks.

    DATA:
      lv_cgst_rate TYPE p LENGTH 13 DECIMALS 2,
      lv_sgst_rate TYPE p LENGTH 13 DECIMALS 2,
      lv_igst_rate TYPE p LENGTH 13 DECIMALS 2,
      lv_cgst_sum  TYPE p LENGTH 16 DECIMALS 2,
      lv_sgst_sum  TYPE p LENGTH 16 DECIMALS 2,
      lv_igst_sum  TYPE p LENGTH 16 DECIMALS 2.

    DATA: split0 TYPE c LENGTH 10,
          split1 TYPE c LENGTH 10,
          split2 TYPE c LENGTH 10.

    SELECT FROM i_purchaseorderitemnotetp_2
                               FIELDS plainlongtext , purchaseorder , purchaseorderitem
                               FOR ALL ENTRIES IN @it_po_data
                               WHERE purchaseorder = @it_po_data-prnum
                               AND purchaseorderitem = @it_po_data-pritem  INTO TABLE @DATA(it_text).

    """**Preparing Item Data
    IF im_action = 'rgpoutprint' OR im_action = 'nrgpprint'.
      SORT it_po_data BY prnum pritem.
      LOOP AT it_po_data INTO DATA(wa_po_itm).

        READ TABLE it_gst_rate INTO DATA(ls_gst_rate) WITH KEY taxcode = wa_po_itm-taxcode.
        IF sy-subrc EQ 0.

          IF ls_gst_rate-cgstrate IS NOT INITIAL.
            CONDENSE ls_gst_rate-cgstrate.
            lv_cgst_rate = ls_gst_rate-cgstrate.
          ENDIF.

          IF ls_gst_rate-sgstrate IS NOT INITIAL.
            CONDENSE ls_gst_rate-sgstrate.
            lv_sgst_rate = ls_gst_rate-sgstrate.
          ENDIF.

          IF ls_gst_rate-igstrate IS NOT INITIAL.
            CONDENSE ls_gst_rate-igstrate.
            lv_igst_rate = ls_gst_rate-igstrate.
          ENDIF.

        ENDIF.

        ls_item-purchase_order = wa_po_itm-prnum.
        ls_item-purchase_item  = wa_po_itm-pritem.
        ls_item-item_hsn = wa_po_itm-hsncode.
        ls_item-sl_no          = ''.
        ls_item-item_code = wa_po_itm-matnr .
        ls_item-item_name = wa_po_itm-maktx .
        ls_item-exp_date = wa_po_itm-exp_returndate .
*        ls_item-net_val = wa_po_itm-grossvalue .
*        ls_item-item_rate = wa_po_itm-netprice .
*
        SHIFT ls_item-item_code LEFT DELETING LEADING '0'.
*        ls_item-item_name      = wa_po_itm-maktx .

        READ TABLE it_text INTO DATA(wa_text) WITH KEY purchaseorder = wa_po_itm-prnum
                                                       purchaseorderitem = wa_po_itm-pritem.
        IF sy-subrc = 0 .
          CONCATENATE  ls_item-item_name cl_abap_char_utilities=>newline 'Note : ' wa_text-plainlongtext INTO ls_item-item_name.
        ENDIF.

*          ls_item-item_brand     = wa_po_itm-matnr.

        IF wa_po_itm-uom  = 'ST'.
          ls_item-item_unit    = 'PC'.
        ELSE.
          ls_item-item_unit    = wa_po_itm-uom.
        ENDIF.
        ls_item-item_qty       = wa_po_itm-prqty.
        ls_item-item_rate      = wa_po_itm-netprice.
        gs_final-tot_qty       = gs_final-tot_qty + wa_po_itm-prqty.

        ls_item-cgst_per       = lv_cgst_rate.
        ls_item-sgst_per       = lv_sgst_rate.
        ls_item-igst_per       = lv_igst_rate.

        ls_item-cgst_amt       = ( wa_po_itm-netprice * lv_cgst_rate ) / 100.
        ls_item-sgst_amt       = ( wa_po_itm-netprice * lv_sgst_rate ) / 100.
        ls_item-igst_amt       = ( wa_po_itm-netprice * lv_igst_rate ) / 100.

        lv_cgst_sum   = lv_cgst_sum + ( wa_po_itm-netprice * lv_cgst_rate ) / 100.
        lv_sgst_sum   = lv_sgst_sum + ( wa_po_itm-netprice * lv_sgst_rate ) / 100.
        lv_igst_sum   = lv_igst_sum + ( wa_po_itm-netprice * lv_igst_rate ) / 100.

        gs_final-subtotal      = gs_final-subtotal + wa_po_itm-netprice.
        APPEND ls_item TO lt_item.
        CLEAR : wa_po_itm,ls_item, ls_gst_rate, lv_cgst_rate, lv_sgst_rate,
                lv_igst_rate.
        " wa_charges,
      ENDLOOP.

    ENDIF.

*      gs_final-cgst_rate = lv_cgst_rate && '%'.
*      gs_final-sgst_rate = lv_sgst_rate && '%'.
*      gs_final-igst_rate = lv_igst_rate && '%'.
*      CONDENSE : gs_final-cgst_rate, gs_final-sgst_rate, gs_final-igst_rate.

    gs_final-tot_cgst       = lv_cgst_sum.
    gs_final-tot_sgst       = lv_sgst_sum.
    gs_final-tot_igst       = lv_igst_sum.

    gs_final-tot_gst = gs_final-tot_cgst  + gs_final-tot_sgst  + gs_final-tot_igst ##TYPE.

    gs_final-grand_total = gs_final-subtotal + gs_final-tot_cgst + gs_final-tot_sgst + gs_final-tot_igst.
***
***      ENDIF.

    grand_total = gs_final-grand_total.
    CREATE OBJECT lo_amt_words.
    grand_total_words = lo_amt_words->number_to_words( iv_num = grand_total ).
    REPLACE ALL OCCURRENCES OF 'Rupees' IN grand_total_words WITH space ##NO_TEXT.
    CONCATENATE 'Rupees' grand_total_words INTO gs_final-grand_tot_word SEPARATED BY space ##NO_TEXT.
    CONDENSE gs_final-grand_tot_word.



    total_gst = gs_final-tot_gst.
    total_gst_words = lo_amt_words->number_to_words( iv_num = total_gst ).
    REPLACE ALL OCCURRENCES OF 'Rupees' IN total_gst_words WITH space ##NO_TEXT.
    CONCATENATE 'Rupees' total_gst_words INTO gs_final-tot_gst_word SEPARATED BY space ##NO_TEXT.
    CONDENSE gs_final-tot_gst_word.

*
    IF gs_final-currency = 'INR'.  "replace Currecy

*      REPLACE ALL OCCURRENCES OF 'Rupees' IN grand_total_words WITH space ##NO_TEXT.


    ELSEIF gs_final-currency = 'USD'.

      REPLACE ALL OCCURRENCES OF 'Rupees' IN gs_final-grand_tot_word WITH 'USD' ##NO_TEXT.
      REPLACE ALL OCCURRENCES OF 'Paisa' IN gs_final-grand_tot_word WITH 'Cents' ##NO_TEXT.

      REPLACE ALL OCCURRENCES OF 'Rupees' IN gs_final-tot_gst_word WITH 'Cents' ##NO_TEXT.
      REPLACE ALL OCCURRENCES OF 'Paisa' IN gs_final-tot_gst_word WITH 'Cents' ##NO_TEXT.




    ELSEIF gs_final-currency = 'CNY'.

      REPLACE ALL OCCURRENCES OF 'Rupees' IN gs_final-grand_tot_word WITH 'CNY' ##NO_TEXT.
      REPLACE ALL OCCURRENCES OF 'Paisa' IN gs_final-grand_tot_word WITH 'Fens' ##NO_TEXT.


      REPLACE ALL OCCURRENCES OF 'Rupees' IN gs_final-tot_gst_word WITH 'CNY' ##NO_TEXT.
      REPLACE ALL OCCURRENCES OF 'Paisa' IN gs_final-tot_gst_word WITH 'Fens' ##NO_TEXT.


    ENDIF.
*
*    ENDIF.

    """**Combining Header & Item
    INSERT LINES OF lt_item INTO TABLE gs_final-gt_item.
    APPEND gs_final TO gt_final.
    et_final[] = gt_final[].   "12.02.2026

  ENDMETHOD.


  METHOD get_rgpout_data.

    sys_date = cl_abap_context_info=>get_system_date( ).
    sys_time = cl_abap_context_info=>get_system_time( ).
    sy_uname = cl_abap_context_info=>get_user_technical_name( ).


    SELECT * FROM zmm_rgp_data WHERE rgpout_num     EQ @im_rgpoutnum
                             AND   rgpout_creationdate EQ @im_rgpoutdate
                             AND   werks             EQ @im_plant
                             AND rgpoutdeleted = ''
                             AND rgpin_num = ''
                             AND rgpindeleted = ''
                             INTO TABLE @DATA(it_po_data).

    IF it_po_data IS NOT INITIAL.

      SELECT
      taxcode,
      cgstrate,
      sgstrate,
      igstrate
      FROM ze_tax_gst_prcnt
      FOR ALL ENTRIES IN @it_po_data
      WHERE taxcode = @it_po_data-taxcode
      INTO TABLE @DATA(it_gst_rate).               "#EC CI_NO_TRANSFORM

    ENDIF.

    IF it_po_data IS NOT INITIAL.

      READ TABLE it_po_data INTO DATA(wa_po_hdr) INDEX 1. "#EC CI_NOORDER

      DATA: lv_lifnr TYPE i_supplier-supplier.
      lv_lifnr = |{ wa_po_hdr-lifnr ALPHA = IN }|.
      wa_po_hdr-lifnr = lv_lifnr.


      SELECT SINGLE * FROM zi_plant_address WHERE plant EQ @wa_po_hdr-werks  INTO @DATA(wa_plant_address). "#EC CI_ALL_FIELDS_NEEDED

      SELECT SINGLE * FROM zi_supplier_address WHERE supplier EQ @wa_po_hdr-lifnr  INTO @DATA(wa_supplier_adr). "#EC CI_ALL_FIELDS_NEEDED

      SELECT
        purchaseorder,
        purchaseorderitem,
        pricingdocument,
        pricingdocumentitem,
        pricingprocedurestep,
        pricingprocedurecounter,
        conditionapplication,
        conditiontype,
        conditionamount,
        conditionquantity,
        conditioncalculationtype,
        conditionratevalue
      FROM i_purorditmpricingelementapi01 WHERE purchaseorder EQ @wa_po_hdr-prnum
                                                   INTO TABLE @DATA(it_charges). "#EC CI_NO_TRANSFORM

      DATA(it_charges_pdy) = it_charges[].
      DELETE it_charges_pdy WHERE conditionratevalue IS INITIAL.

      IF im_action = 'rgpoutprint'.
        gs_final-purchase_order = wa_po_hdr-rgpout_num.
        gs_final-po_date        = wa_po_hdr-rgpout_creationdate+6(2) && '.' && wa_po_hdr-rgpout_creationdate+4(2) && '.'
                                  && wa_po_hdr-rgpout_creationdate+0(4).
      ELSEIF im_action = 'nrgpprint'.
        gs_final-purchase_order = wa_po_hdr-rgpin_num.
        gs_final-po_date        = wa_po_hdr-rgpin_creationdate+6(2) && '.' && wa_po_hdr-rgpin_creationdate+4(2) && '.'
                                  && wa_po_hdr-rgpin_creationdate+0(4).
      ENDIF.

      """""""""Prepare adress for Previous and current plant & logo

      DATA : logo TYPE string.

      gs_final-plant = wa_po_hdr-werks.

      DATA(billtoname) = |{ wa_plant_address-addresseefullname } { wa_plant_address-housenumber } { wa_plant_address-streetname } { wa_plant_address-cityname }  { wa_plant_address-regionname } { wa_plant_address-postalcode }|.

      gs_final-billto_name    = billtoname.
      gs_final-billto_adr1    = wa_plant_address-streetsuffixname1.
      gs_final-billto_adr2    = wa_plant_address-streetprefixname1.
      gs_final-billto_state   = wa_plant_address-regionname.
      gs_final-billto_mob     = ''.
      gs_final-billto_gst     = '06AACCD6342B1Z6'.
      gs_final-billto_pan     = 'AACCD6342B'.
      gs_final-billto_cin     = ''.
      gs_final-delvto_name    = gs_final-billto_name.
      gs_final-delvto_adr1    = wa_plant_address-streetname.
      gs_final-delvto_adr2    = wa_plant_address-streetprefixname1.
      gs_final-delvto_state   = wa_plant_address-region.
      gs_final-delvto_mob     = ''.
      gs_final-delvto_gst     = '06AACCD6342B1Z6' .
      gs_final-delvto_pan     = 'AACCD6342B'.

      gs_final-amd_no         = ''.
      gs_final-amd_date       = ''.
      gs_final-currency       = wa_po_hdr-currcy.

      SELECT SINGLE supplier FROM i_purchaseorderpartnerapi01 WHERE purchaseorder EQ @wa_po_hdr-prnum
      INTO @DATA(supplier_code).
*      SELECT SINGLE suppliername FROM i_supplier WHERE supplier EQ @supplier_code INTO @gs_final-broker_name.

      IF wa_po_hdr-lifnr IS NOT INITIAL.
        SHIFT wa_supplier_adr-supplier LEFT DELETING LEADING '0'.
        gs_final-vend_code      = wa_supplier_adr-supplier.
        gs_final-vend_name      = wa_supplier_adr-suppliername.
        gs_final-vend_adr1      = wa_supplier_adr-streetname.
        gs_final-vend_adr2      = wa_supplier_adr-districtname.
        gs_final-vend_adr3      = wa_supplier_adr-region && '-' && wa_supplier_adr-postalcode.
        gs_final-vend_gstin     = wa_supplier_adr-taxnumber3.
        gs_final-vend_pan       = wa_supplier_adr-businesspartnerpannumber.
        gs_final-vend_mail      = wa_supplier_adr-emailaddress.
        gs_final-vend_mob       = wa_supplier_adr-phonenumber1.
      ENDIF.


      gs_final-tot_cgst       = ''.
      gs_final-tot_sgst       = ''.
      gs_final-tot_igst       = ''.
      gs_final-remarks        = wa_po_hdr-remarks.


      DATA:
        lv_cgst_rate TYPE p LENGTH 13 DECIMALS 2,
        lv_sgst_rate TYPE p LENGTH 13 DECIMALS 2,
        lv_igst_rate TYPE p LENGTH 13 DECIMALS 2,
        lv_cgst_sum  TYPE p LENGTH 16 DECIMALS 2,
        lv_sgst_sum  TYPE p LENGTH 16 DECIMALS 2,
        lv_igst_sum  TYPE p LENGTH 16 DECIMALS 2.

      DATA: split0 TYPE c LENGTH 10,
            split1 TYPE c LENGTH 10,
            split2 TYPE c LENGTH 10.
**
**
      SELECT FROM i_purchaseorderitemnotetp_2
                                 FIELDS plainlongtext , purchaseorder , purchaseorderitem
                                 FOR ALL ENTRIES IN @it_po_data
                                 WHERE purchaseorder = @it_po_data-prnum
                                 AND purchaseorderitem = @it_po_data-pritem  INTO TABLE @DATA(it_text).

      """**Preparing Item Data
      IF im_action = 'rgpoutprint'.
        SORT it_po_data BY prnum pritem.
        LOOP AT it_po_data INTO DATA(wa_po_itm).

          READ TABLE it_gst_rate INTO DATA(ls_gst_rate) WITH KEY taxcode = wa_po_itm-taxcode.
          IF sy-subrc EQ 0.

            IF ls_gst_rate-cgstrate IS NOT INITIAL.
              CONDENSE ls_gst_rate-cgstrate.
              lv_cgst_rate = ls_gst_rate-cgstrate.
            ENDIF.

            IF ls_gst_rate-sgstrate IS NOT INITIAL.
              CONDENSE ls_gst_rate-sgstrate.
              lv_sgst_rate = ls_gst_rate-sgstrate.
            ENDIF.
**
            IF ls_gst_rate-igstrate IS NOT INITIAL.
              CONDENSE ls_gst_rate-igstrate.
              lv_igst_rate = ls_gst_rate-igstrate.
            ENDIF.

          ENDIF.

          ls_item-purchase_order = wa_po_itm-prnum.
          ls_item-purchase_item  = wa_po_itm-pritem.
          ls_item-item_hsn = wa_po_itm-hsncode.
          ls_item-sl_no          = ''.
          ls_item-item_code = wa_po_itm-matnr .
          ls_item-item_name = wa_po_itm-maktx .
          ls_item-net_val = wa_po_itm-grossvalue .
          ls_item-item_rate = wa_po_itm-netprice .
          ls_item-exp_date = wa_po_itm-exp_returndate .

          SHIFT ls_item-item_code LEFT DELETING LEADING '0'.
          ls_item-item_name      = wa_po_itm-maktx .

          READ TABLE it_text INTO DATA(wa_text) WITH KEY purchaseorder = wa_po_itm-prnum
                                                         purchaseorderitem = wa_po_itm-pritem.
          IF sy-subrc = 0 .
            CONCATENATE  ls_item-item_name cl_abap_char_utilities=>newline 'Note : ' wa_text-plainlongtext INTO ls_item-item_name.
          ENDIF.

*          ls_item-item_brand     = wa_po_itm-matnr.

          IF wa_po_itm-uom  = 'ST'.
            ls_item-item_unit    = 'PC'.
          ELSE.
            ls_item-item_unit    = wa_po_itm-uom.
          ENDIF.
          ls_item-item_qty       = wa_po_itm-prqty.
          ls_item-item_rate      = wa_po_itm-netprice.
          gs_final-tot_qty       = gs_final-tot_qty + wa_po_itm-prqty.

*

          ls_item-cgst_per       = lv_cgst_rate.
          ls_item-sgst_per       = lv_sgst_rate.
          ls_item-igst_per       = lv_igst_rate.

          ls_item-cgst_amt       = ( wa_po_itm-netprice * lv_cgst_rate ) / 100.
          ls_item-sgst_amt       = ( wa_po_itm-netprice * lv_sgst_rate ) / 100.
          ls_item-igst_amt       = ( wa_po_itm-netprice * lv_igst_rate ) / 100.

          lv_cgst_sum   = lv_cgst_sum + ( wa_po_itm-netprice * lv_cgst_rate ) / 100.
          lv_sgst_sum   = lv_sgst_sum + ( wa_po_itm-netprice * lv_sgst_rate ) / 100.
          lv_igst_sum   = lv_igst_sum + ( wa_po_itm-netprice * lv_igst_rate ) / 100.

          gs_final-subtotal      = gs_final-subtotal + wa_po_itm-netprice.
          APPEND ls_item TO lt_item.
          CLEAR : wa_po_itm,  ls_item, ls_gst_rate, lv_cgst_rate, lv_sgst_rate,
                  lv_igst_rate.
        ENDLOOP.
*
      ENDIF.

*      gs_final-cgst_rate = lv_cgst_rate && '%'.
*      gs_final-sgst_rate = lv_sgst_rate && '%'.
*      gs_final-igst_rate = lv_igst_rate && '%'.
*      CONDENSE : gs_final-cgst_rate, gs_final-sgst_rate, gs_final-igst_rate.

      gs_final-tot_cgst       = lv_cgst_sum.
      gs_final-tot_sgst       = lv_sgst_sum.
      gs_final-tot_igst       = lv_igst_sum.

      gs_final-tot_cgst       = lv_cgst_sum.
      gs_final-tot_sgst       = lv_sgst_sum.
      gs_final-tot_igst       = lv_igst_sum.

      gs_final-tot_gst = gs_final-tot_cgst  + gs_final-tot_sgst  + gs_final-tot_igst ##TYPE.

      gs_final-grand_total = gs_final-subtotal + gs_final-tot_cgst + gs_final-tot_sgst + gs_final-tot_igst.
***
***      ENDIF.

      grand_total = gs_final-grand_total.
      CREATE OBJECT lo_amt_words.
      grand_total_words = lo_amt_words->number_to_words( iv_num = grand_total ).
      REPLACE ALL OCCURRENCES OF 'Rupees' IN grand_total_words WITH space ##NO_TEXT.
      CONCATENATE 'Rupees' grand_total_words INTO gs_final-grand_tot_word SEPARATED BY space ##NO_TEXT.
      CONDENSE gs_final-grand_tot_word.

      total_gst = gs_final-tot_gst.
      total_gst_words = lo_amt_words->number_to_words( iv_num = total_gst ).
      REPLACE ALL OCCURRENCES OF 'Rupees' IN total_gst_words WITH space ##NO_TEXT.
      CONCATENATE 'Rupees' total_gst_words INTO gs_final-tot_gst_word SEPARATED BY space ##NO_TEXT.
      CONDENSE gs_final-tot_gst_word.

*
*
      IF gs_final-currency = 'INR'.  "replace Currecy

      ELSEIF gs_final-currency = 'USD'.

        REPLACE ALL OCCURRENCES OF 'Rupees' IN gs_final-grand_tot_word WITH 'USD' ##NO_TEXT.
        REPLACE ALL OCCURRENCES OF 'Paisa' IN gs_final-grand_tot_word WITH 'Cents' ##NO_TEXT.

        REPLACE ALL OCCURRENCES OF 'Rupees' IN gs_final-tot_gst_word WITH 'Cents' ##NO_TEXT.
        REPLACE ALL OCCURRENCES OF 'Paisa' IN gs_final-tot_gst_word WITH 'Cents' ##NO_TEXT.




      ELSEIF gs_final-currency = 'CNY'.

        REPLACE ALL OCCURRENCES OF 'Rupees' IN gs_final-grand_tot_word WITH 'CNY' ##NO_TEXT.
        REPLACE ALL OCCURRENCES OF 'Paisa' IN gs_final-grand_tot_word WITH 'Fens' ##NO_TEXT.


        REPLACE ALL OCCURRENCES OF 'Rupees' IN gs_final-tot_gst_word WITH 'CNY' ##NO_TEXT.
        REPLACE ALL OCCURRENCES OF 'Paisa' IN gs_final-tot_gst_word WITH 'Fens' ##NO_TEXT.


      ENDIF.
*
    ENDIF.

    """**Combining Header & Item
    INSERT LINES OF lt_item INTO TABLE gs_final-gt_item.
    APPEND gs_final TO gt_final.
    et_final[] = gt_final[].  "12.02.2026


  ENDMETHOD.


  METHOD prep_xml_rgpout_print.

    DATA : heading      TYPE c LENGTH 100,
           sub_heading  TYPE c LENGTH 200,
           draft        TYPE string,
           lv_xml_final TYPE string,
           logo         TYPE string.

    READ TABLE it_final INTO DATA(ls_final) INDEX 1.
    SHIFT ls_final-purchase_order LEFT DELETING LEADING ''.

    IF im_action = 'poprint'.
      heading = 'Purchase Order' ##NO_TEXT.

    ELSEIF im_action = 'saprint'.
      heading = 'Scheduling Agreement' ##NO_TEXT.

    ELSEIF im_action = 'rgpoutprint'.
      heading = 'RGPOUT' ##NO_TEXT.

    ELSEIF im_action = 'nrgpprint'.
      heading = 'NRGP' ##NO_TEXT.
    ENDIF.

    DATA : lv_footertext TYPE string .
    DATA : lv_footertext1 TYPE string .
    DATA : lv_finaltext TYPE string .

    CONCATENATE lv_footertext  lv_footertext1 INTO lv_finaltext .


    DATA : lv_name TYPE string .

    DATA(lv_xml) =  |<Form>| &&
                    |<PurchaseOrderNode>| &&
*                    |<logo>{ ls_final-logo }</logo>| &&
                    |<header_1>{ heading }</header_1>| &&
                    |<header_2>{ ls_final-plant_name }</header_2>| &&
                    |<header_3>{ ls_final-plant_adr1 }</header_3>| &&
                    |<header_4>{ ls_final-plant_adr2 }</header_4>| &&
*                    |<header_5>{ ls_final-plant_adr3 }</header_5>| &&
                    |<ft>{ lv_finaltext }</ft>| &&
                    |<formername>{ lv_name }</formername>| &&
                    |<draft>{ draft }</draft>| &&
                    |<plant>{ ls_final-plant }</plant>| &&
                    |<gstin>{ ls_final-plant_gstin }</gstin>| &&
*                    |<plant_pan>{ ls_final-plant_pan }</plant_pan>| &&
                    |<po_type>{ ls_final-po_type }</po_type>| &&
                    |<po_no>{ ls_final-purchase_order }</po_no>| &&
                    |<po_date>{ ls_final-po_date }</po_date>| &&
                    |<amd_no>{ ls_final-amd_no }</amd_no>| &&
                    |<amd_date>{ ls_final-amd_date }</amd_date>| &&
                    |<currency>{ ls_final-currency }</currency>| &&
                    |<po_ref_no>{ ls_final-po_ref_no }</po_ref_no>| &&
                    |<ven_code>{ ls_final-vend_code }</ven_code>| &&
                    |<ven_name>{ ls_final-vend_name }</ven_name>| &&
                    |<ven_adrs1>{ ls_final-vend_adr1 }</ven_adrs1>| &&
                    |<ven_adrs2>{ ls_final-vend_adr2 }</ven_adrs2>| &&
                    |<ven_adrs3>{ ls_final-vend_adr3 }</ven_adrs3>| &&
                    |<ven_gstin>{ ls_final-vend_gstin }</ven_gstin>| &&
                    |<ven_pan>{ ls_final-vend_pan }</ven_pan>| &&
                    |<ven_mail>{ ls_final-vend_mail }</ven_mail>| &&
                    |<ven_mob>{ ls_final-vend_mob }</ven_mob>| &&
                    |<bill_to_name>{ ls_final-billto_name }</bill_to_name>| &&
                    |<bill_to_adrs1>{ ls_final-billto_adr1 }</bill_to_adrs1>| &&
                    |<bill_to_adrs2>{ ls_final-billto_adr2 }</bill_to_adrs2>| &&
                    |<bill_to_state_code>{ ls_final-billto_state }</bill_to_state_code>| &&
                    |<bill_to_mob>{ ls_final-billto_mob }</bill_to_mob>| &&
                    |<bill_to_gst>{ ls_final-billto_gst }</bill_to_gst>| &&
                    |<bill_to_pan>{ ls_final-billto_pan }</bill_to_pan>| &&
                    |<bill_to_cin>{ ls_final-billto_cin }</bill_to_cin>| &&
*                    |<bill_to_endate>{ ls_final-billto_enddate }</bill_to_endate>| &&
                    |<del_to_name>{ ls_final-delvto_name }</del_to_name>| &&
                    |<del_to_adrs1>{ ls_final-delvto_adr1 }</del_to_adrs1>| &&
                    |<del_to_adrs2>{ ls_final-delvto_adr2 }</del_to_adrs2>| &&
                    |<del_to_state_code>{ ls_final-delvto_state }</del_to_state_code>| &&
                    |<del_to_mob>{ ls_final-delvto_mob }</del_to_mob>| &&
                    |<del_to_gst>{ ls_final-delvto_gst }</del_to_gst>| &&
                    |<del_to_pan>{ ls_final-delvto_pan }</del_to_pan>| &&
                    |<subtotal>{ ls_final-subtotal }</subtotal>| &&
                    |<total_cgst_amt>{ ls_final-tot_cgst }</total_cgst_amt>| &&
                    |<total_sgst_amt>{ ls_final-tot_sgst }</total_sgst_amt>| &&
                    |<total_igst_amt>{ ls_final-tot_igst }</total_igst_amt>| &&
                    |<grand_total>{ ls_final-grand_total }</grand_total>| &&
                    |<grand_total_words>{ ls_final-grand_tot_word }</grand_total_words>| &&
                    |<total_gst_words>{ ls_final-tot_gst_word }</total_gst_words>| &&
                    |<remarks>{ ls_final-remarks }</remarks>| &&
                    |<notes>{ ls_final-remarks }</notes>| &&
                    |<ItemData>|  ##NO_TEXT.

    DATA : lv_item TYPE string .
    DATA : item_desc TYPE string.
    DATA : srn TYPE c LENGTH 3 .
    CLEAR : lv_item , srn .

    LOOP AT ls_final-gt_item INTO DATA(ls_item).


      CLEAR : item_cgst, item_sgst, item_igst.
      item_cgst = ls_item-cgst_per && '%' && cl_abap_char_utilities=>newline && ls_item-cgst_amt.
      item_sgst = ls_item-sgst_per && '%' && cl_abap_char_utilities=>newline && ls_item-sgst_amt.
      item_igst = ls_item-igst_per && '%' && cl_abap_char_utilities=>newline && ls_item-igst_amt.

      CLEAR item_desc.

      srn = srn + 1 .
      lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                |<sl_num>{ srn }</sl_num>| &&
                |<item_code>{ ls_item-item_code }</item_code>| &&
                |<item_name>{ ls_item-item_name }</item_name>| &&
                |<item_hsn>{ ls_item-item_hsn }</item_hsn>| &&
                |<item_unit>{ ls_item-item_unit }</item_unit>| &&
                |<item_qty>{ ls_item-item_qty }</item_qty>| &&
                |<item_rate>{ ls_item-item_rate }</item_rate>| &&
                |<disc_amt>{ ls_item-disc_amt }</disc_amt>| &&
                |<disc_del_dt>{ ls_item-exp_date }</disc_del_dt>| &&
                |<cgst_amt>{ item_cgst }</cgst_amt>| &&
                |<sgst_amt>{ item_sgst }</sgst_amt>| &&
                |<igst_amt>{ item_igst }</igst_amt>| &&
                |<net_value>{ ls_item-net_val }</net_value>| &&
                |</ItemDataNode>|  ##NO_TEXT .

    ENDLOOP.


    lv_xml = |{ lv_xml }{ lv_item }| &&
                       |</ItemData>| &&
                       |</PurchaseOrderNode>| &&
                       |</Form>| ##NO_TEXT .

    CLEAR : lv_name ,lv_footertext , lv_footertext1 , lv_finaltext ." pt19.

    REPLACE ALL OCCURRENCES OF 'Ω'  IN lv_xml WITH 'OHM'.
    REPLACE ALL OCCURRENCES OF 'µF' IN lv_xml WITH 'microfarad'.
    REPLACE ALL OCCURRENCES OF '±'  IN lv_xml WITH 'Tolerance'.
    REPLACE ALL OCCURRENCES OF '℃'  IN lv_xml WITH 'Degree Celsius'.
    REPLACE ALL OCCURRENCES OF '~'  IN lv_xml WITH 'Range'.
    REPLACE ALL OCCURRENCES OF '*'  IN lv_xml WITH 'Multiplication'.
    REPLACE ALL OCCURRENCES OF 'Ф'  IN lv_xml WITH 'Diameter'.
    REPLACE ALL OCCURRENCES OF '&' IN lv_xml WITH 'and' .
    REPLACE ALL OCCURRENCES OF '₹' IN lv_xml WITH 'INR'.
    REPLACE ALL OCCURRENCES OF '€' IN lv_xml WITH 'EUR'.
    REPLACE ALL OCCURRENCES OF '©' IN lv_xml WITH '(C)'.
    REPLACE ALL OCCURRENCES OF '®' IN lv_xml WITH '(R)'.
    REPLACE ALL OCCURRENCES OF '°' IN lv_xml WITH 'DEG'.
    REPLACE ALL OCCURRENCES OF '–' IN lv_xml WITH '-'.
    REPLACE ALL OCCURRENCES OF '—' IN lv_xml WITH '-'.
    REPLACE ALL OCCURRENCES OF '…' IN lv_xml WITH '...'.
    REPLACE ALL OCCURRENCES OF 'Ф' IN lv_xml WITH 'Dia'.
    REPLACE ALL OCCURRENCES OF '$' IN lv_xml WITH 'USD'.
    REPLACE ALL OCCURRENCES OF '×' IN lv_xml WITH 'X'.
    REPLACE ALL OCCURRENCES OF '÷' IN lv_xml WITH '/'.

    REPLACE ALL OCCURRENCES OF '\' IN lv_xml WITH '/'.
    REPLACE ALL OCCURRENCES OF '|' IN lv_xml WITH '-'.
*
    REPLACE ALL OCCURRENCES OF '¿' IN lv_xml WITH '?'.
    REPLACE ALL OCCURRENCES OF '€' IN lv_xml WITH 'EUR'.
    REPLACE ALL OCCURRENCES OF '£' IN lv_xml WITH 'GBP'.
    REPLACE ALL OCCURRENCES OF '™' IN lv_xml WITH 'TM'.
**        REPLACE ALL OCCURRENCES OF '+' IN lv_xml WITH 'Tolerance'.
    REPLACE ALL OCCURRENCES OF '-+-' IN lv_xml WITH 'Tolerance'.
    REPLACE ALL OCCURRENCES OF '-±' IN lv_xml WITH 'Tolerance'.
    REPLACE ALL OCCURRENCES OF '/°C' IN lv_xml WITH 'Degree Celsius'.

    DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
    CONDENSE lv_xml.
    iv_xml_base64 = ls_data_xml_64.  "12.02.2026

  ENDMETHOD.


  METHOD prep_xml_po_print.

    DATA : heading      TYPE c LENGTH 100,
           sub_heading  TYPE c LENGTH 200,
           lv_xml_final TYPE string.

    READ TABLE it_final INTO DATA(ls_final) INDEX 1.
    SHIFT ls_final-purchase_order LEFT DELETING LEADING ''.
    heading = 'Purchase Order' ##NO_TEXT.

    DATA(lv_xml) =  |<Form>| &&
                    |<PurchaseOrderNode>| &&
                    |<header_1>{ heading }</header_1>| &&
                    |<header_2>{ ls_final-plant_name }</header_2>| &&
                    |<header_3>{ ls_final-plant_adr1 }</header_3>| &&
                    |<header_4>{ ls_final-plant_adr2 }</header_4>| &&
                    |<gstin>{ ls_final-plant_gstin }</gstin>| &&
                    |<po_type>{ ls_final-po_type }</po_type>| &&
                    |<po_no>{ ls_final-purchase_order }</po_no>| &&
                    |<po_date>{ ls_final-po_date }</po_date>| &&
                    |<amd_no>{ ls_final-amd_no }</amd_no>| &&
                    |<amd_date>{ ls_final-amd_date }</amd_date>| &&
                    |<currency>{ ls_final-currency }</currency>| &&
                    |<po_ref_no>{ ls_final-po_ref_no }</po_ref_no>| &&
                    |<ven_code>{ ls_final-vend_code }</ven_code>| &&
                    |<ven_name>{ ls_final-vend_name }</ven_name>| &&
                    |<ven_adrs1>{ ls_final-vend_adr1 }</ven_adrs1>| &&
                    |<ven_adrs2>{ ls_final-vend_adr2 }</ven_adrs2>| &&
                    |<ven_adrs3>{ ls_final-vend_adr3 }</ven_adrs3>| &&
                    |<ven_gstin>{ ls_final-vend_gstin }</ven_gstin>| &&
                    |<ven_pan>{ ls_final-vend_pan }</ven_pan>| &&
                    |<ven_mail>{ ls_final-vend_mail }</ven_mail>| &&
                    |<ven_mob>{ ls_final-vend_mob }</ven_mob>| &&
                    |<bill_to_name>{ ls_final-billto_name }</bill_to_name>| &&
                    |<bill_to_adrs1>{ ls_final-billto_adr1 }</bill_to_adrs1>| &&
                    |<bill_to_adrs2>{ ls_final-billto_adr2 }</bill_to_adrs2>| &&
                    |<bill_to_state_code>{ ls_final-billto_state }</bill_to_state_code>| &&
                    |<bill_to_mob>{ ls_final-billto_mob }</bill_to_mob>| &&
                    |<bill_to_gst>{ ls_final-billto_gst }</bill_to_gst>| &&
                    |<bill_to_pan>{ ls_final-billto_pan }</bill_to_pan>| &&
                    |<bill_to_cin>{ ls_final-billto_cin }</bill_to_cin>| &&
                    |<del_to_name>{ ls_final-delvto_name }</del_to_name>| &&
                    |<del_to_adrs1>{ ls_final-delvto_adr1 }</del_to_adrs1>| &&
                    |<del_to_adrs2>{ ls_final-delvto_adr2 }</del_to_adrs2>| &&
                    |<del_to_state_code>{ ls_final-delvto_state }</del_to_state_code>| &&
                    |<del_to_mob>{ ls_final-delvto_mob }</del_to_mob>| &&
                    |<del_to_gst>{ ls_final-delvto_gst }</del_to_gst>| &&
                    |<del_to_pan>{ ls_final-delvto_pan }</del_to_pan>| &&
                    |<payment_terms>{ ls_final-payment_terms }</payment_terms>| &&
                    |<freight>{ ls_final-freight }</freight>| &&
                    |<insurance>{ ls_final-insurance }</insurance>| &&
                    |<delivery_terms>{ ls_final-delivery_term }</delivery_terms>| &&
                    |<total_qty>{ ls_final-tot_qty }</total_qty>| &&
                    |<subtotal>{ ls_final-subtotal }</subtotal>| &&
                    |<total_cgst_amt>{ ls_final-tot_cgst }</total_cgst_amt>| &&
                    |<total_sgst_amt>{ ls_final-tot_sgst }</total_sgst_amt>| &&
                    |<total_igst_amt>{ ls_final-tot_igst }</total_igst_amt>| &&
                    |<freight_charges>{ ls_final-freight_chrg }</freight_charges>| &&
                    |<packing_charges>{ ls_final-packing_chrg }</packing_charges>| &&
                    |<other_charges>{ ls_final-other_chrg }</other_charges>| &&
                    |<insurance_charges>{ ls_final-insurance_chrg }</insurance_charges>| &&
                    |<grand_total>{ ls_final-grand_total }</grand_total>| &&
                    |<grand_total_words>{ ls_final-grand_tot_word }</grand_total_words>| &&
                    |<remarks>{ ls_final-remarks }</remarks>| &&
                    |<ItemData>|  ##NO_TEXT.

    DATA : lv_item TYPE string .
    DATA : srn TYPE c LENGTH 3 .
    CLEAR : lv_item , srn .

    LOOP AT ls_final-gt_item INTO DATA(ls_item).

      srn = srn + 1 .
      lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                |<sl_num>{ srn }</sl_num>| &&
                |<item_code>{ ls_item-item_code }</item_code>| &&
                |<item_name>{ ls_item-item_name }</item_name>| &&
                |<item_hsn>{ ls_item-item_hsn }</item_hsn>| &&
                |<item_unit>{ ls_item-item_unit }</item_unit>| &&
                |<item_qty>{ ls_item-item_qty }</item_qty>| &&
                |<item_rate>{ ls_item-item_rate }</item_rate>| &&
                |<disc_amt>{ ls_item-disc_amt }</disc_amt>| &&
                |<cgst_amt>{ ls_item-cgst_amt }</cgst_amt>| &&
                |<sgst_amt>{ ls_item-sgst_amt }</sgst_amt>| &&
                |<igst_amt>{ ls_item-igst_amt }</igst_amt>| &&
                |<net_value>{ ls_item-net_val }</net_value>| &&
                |</ItemDataNode>|  ##NO_TEXT .

    ENDLOOP.

    lv_xml = |{ lv_xml }{ lv_item }| &&
                       |</ItemData>| &&
                       |</PurchaseOrderNode>| &&
                       |</Form>| ##NO_TEXT .

    DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
    iv_xml_base64 = ls_data_xml_64.

  ENDMETHOD.
ENDCLASS.
