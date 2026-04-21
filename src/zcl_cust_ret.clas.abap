CLASS zcl_cust_ret DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA:
      lv_char10  TYPE c LENGTH 10,
      lv_char120 TYPE c LENGTH 120,
      lv_char4   TYPE c LENGTH 4.

    DATA:
      xt_final TYPE TABLE OF zstr_cust_ret_hdr,
      xs_final TYPE zstr_cust_ret_hdr,
      xt_item  TYPE TABLE OF zstr_cust_ret_itm,
      xs_item  TYPE zstr_cust_ret_itm,
      gt_final TYPE TABLE OF zmm_cust_ret,
      gs_final TYPE zmm_cust_ret.

    METHODS:
      get_data
        IMPORTING
                  im_kunnr       LIKE lv_char10
                  im_invno       LIKE lv_char10
        RETURNING VALUE(et_data) LIKE xt_final,

      save_data_get_genum
        IMPORTING
                  xt_gedata        LIKE xt_final
                  im_action        LIKE lv_char10
        RETURNING VALUE(rv_ge_num) LIKE lv_char120.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS ZCL_CUST_RET IMPLEMENTATION.


  METHOD get_data.

    DATA:
      r_vbeln  TYPE RANGE OF zi_sale_reg-BillingDocument,
      rs_vbeln LIKE LINE OF r_vbeln.

    rs_vbeln-low    = im_invno.
    rs_vbeln-high   = im_invno.
    rs_vbeln-option = 'BT'.
    rs_vbeln-sign   = 'I'.
    APPEND rs_vbeln TO r_vbeln.

*    SELECT
*    CompanyCode,
*    BillingDocument,
*    BillingDocumentItem,
*    Plant,
*    bill_to_party,
*    re_name,
*    BillingDocumentDate,
*    product,
*    BillingDocumentItemText,
*    BillingQuantity,
*    BillingQuantityUnit
*    FROM zi_sale_reg
*    WHERE BillingDocument IN @r_vbeln
*    INTO TABLE @DATA(lt_reg).

    SELECT
    SalesDocument,
    SalesDocumentItem,
    SoldToParty,
    Plant,
    Material,
    Product,
    MaterialByCustomer,
    SalesDocumentItemText,
    OrderQuantity,
    OrderQuantityUnit,
    NetAmount,
    TransactionCurrency,
    NetPriceAmount
    FROM i_salesdocumentitem
    WHERE SalesDocument IN @r_vbeln
    INTO TABLE @DATA(lt_reg).

    IF lt_reg[] IS NOT INITIAL.

*      SELECT
*      gentry_num,
*      gentry_year,
*      billingdocument,
*      billingdocumentitem
*      FROM zmm_cust_ret
*      FOR ALL ENTRIES IN @lt_reg
*      WHERE billingdocument     = @lt_reg-billingdocument AND
*            billingdocumentitem = @lt_reg-BillingDocumentItem
*      INTO TABLE @DATA(lt_cut_ret).
*
*      DATA(lt_reg_itm) = lt_reg[] .
*      SORT lt_reg BY BillingDocument.
*      DELETE ADJACENT DUPLICATES FROM lt_reg COMPARING BillingDocument.

      SELECT
      gentry_num,
      gentry_year,
      billingdocument,
      billingdocumentitem
      FROM zmm_cust_ret
      FOR ALL ENTRIES IN @lt_reg
      WHERE billingdocument     = @lt_reg-SalesDocument AND
            billingdocumentitem = @lt_reg-SalesDocumentItem
      INTO TABLE @DATA(lt_cut_ret). "#EC CI_NO_TRANSFORM

      DATA(lt_reg_itm) = lt_reg[] .
      SORT lt_reg BY SalesDocument.
      DELETE ADJACENT DUPLICATES FROM lt_reg COMPARING SalesDocument.

    ENDIF.

    LOOP AT lt_reg INTO DATA(ls_reg).

      xs_final-billingdocument     = ls_reg-SalesDocument. "ls_reg-BillingDocument.
      xs_final-plant               = ls_reg-Plant.
      xs_final-customer            = ls_reg-SoldToParty. "ls_reg-bill_to_party.
      xs_final-transmode           = ''.
      xs_final-invoiceno           = ls_reg-SalesDocument. "ls_reg-BillingDocument.
      xs_final-refinvoiceno        = ''.
      xs_final-ewaybillno          = ''.
      xs_final-vehno               = ''.
      xs_final-driverno            = ''.
      xs_final-transporter         = ''.
      xs_final-challandate         = ''.
      xs_final-createdon           = ''.
      xs_final-createdtime         = ''.
      xs_final-check_rc            = ''.
      xs_final-check_pollt         = ''.
      xs_final-check_tripal        = ''.
      xs_final-check_insur         = ''.
      xs_final-check_dl            = ''.

      LOOP AT lt_reg_itm INTO DATA(ls_reg_itm).

*        READ TABLE lt_cut_ret INTO DATA(lw_cut_ret) WITH KEY billingdocument     = ls_reg-BillingDocument
*                                                             BillingDocumentItem = ls_reg_itm-BillingDocumentItem.

        READ TABLE lt_cut_ret INTO DATA(lw_cut_ret) WITH KEY billingdocument     = ls_reg-SalesDocument
                                                             BillingDocumentItem = ls_reg_itm-SalesDocument.

        IF sy-subrc NE 0.

          xs_item-billingdocument      = ls_reg-SalesDocument. "ls_reg-BillingDocument.
          xs_item-billingdocumentitem  = ls_reg_itm-SalesDocumentItem. "ls_reg_itm-BillingDocumentItem.
          xs_item-plant                = ls_reg_itm-Plant.
          xs_item-itemno               = ls_reg_itm-SalesDocumentItem. "ls_reg_itm-BillingDocumentItem.
          xs_item-itemcode             = ls_reg_itm-product.
          xs_item-itemdesc             = ls_reg-SalesDocumentItemText. "ls_reg_itm-BillingDocumentItemText.
          xs_item-orderqty             = ls_reg-OrderQuantity. "ls_reg_itm-BillingQuantity.
          xs_item-deliveredqty         = ls_reg-OrderQuantity. "ls_reg_itm-BillingQuantity.
          xs_item-uom                  = ls_reg-OrderQuantityUnit. "ls_reg_itm-BillingQuantityUnit.
          APPEND xs_item TO xt_item.

        ENDIF.

        CLEAR: ls_reg_itm.
      ENDLOOP.

      CLEAR: ls_reg.
    ENDLOOP.

    IF xt_item[] IS NOT INITIAL.
      INSERT LINES OF xt_item INTO TABLE xs_final-gt_item.
      APPEND xs_final TO et_data.
    ENDIF.

*    xs_final-billingdocument     = im_invno.
*    xs_final-plant               = '1101'.
*    xs_final-customer            = '400001'.
*    xs_final-transmode           = ''.
*    xs_final-invoiceno           = im_invno.
*    xs_final-vehno               = ''.
*    xs_final-driverno            = ''.
*    xs_final-transporter         = ''.
*    xs_final-challandate         = ''.
*    xs_final-createdon           = ''.
*    xs_final-createdtime         = ''.
*    xs_final-check_rc            = 'true'.
*    xs_final-check_pollt         = ''.
*    xs_final-check_tripal        = ''.
*    xs_final-check_insur         = ''.
*    xs_final-check_dl            = ''.
*
*
*    xs_item-billingdocument      = im_invno.
*    xs_item-billingdocumentitem  = '0010'.
*    xs_item-plant                = '1101'.
*    xs_item-itemno               = '0010'.
*    xs_item-itemcode             = 'MAT12345'.
*    xs_item-itemdesc             = 'Test Material' ##NO_TEXT.
*    xs_item-orderqty             = '10'.
*    xs_item-deliveredqty         = '5'.
*    xs_item-uom                  = 'EA'.
*    APPEND xs_item TO xt_item.
*
*    xs_item-billingdocument      = im_invno.
*    xs_item-billingdocumentitem  = '0020'.
*    xs_item-plant                = '1101'.
*    xs_item-itemno               = '0020'.
*    xs_item-itemcode             = 'MAT900001'.
*    xs_item-itemdesc             = 'Test Material-2' ##NO_TEXT.
*    xs_item-orderqty             = '50'.
*    xs_item-deliveredqty         = '30'.
*    xs_item-uom                  = 'PC'.
*    APPEND xs_item TO xt_item.

*    INSERT LINES OF xt_item INTO TABLE xs_final-gt_item.
*    APPEND xs_final TO et_data.


  ENDMETHOD.


  METHOD save_data_get_genum.

    DATA:
      sys_date     TYPE d,
      sys_time     TYPE t,
      sys_timezone TYPE timezone,
      sys_uname    TYPE c LENGTH 20.

    DATA: lv_doc_date     TYPE d,
          lv_fis_year     TYPE zi_dc_note-FiscalYear,
          lv_doc_month(2) TYPE n.

    sys_date  = cl_abap_context_info=>get_system_date( ).
    sys_time  = cl_abap_context_info=>get_system_time( ).
    sys_uname = cl_abap_context_info=>get_user_technical_name( ).

    lv_doc_date  = sys_date.
    lv_doc_month = lv_doc_date+4(2).
    lv_fis_year  = lv_doc_date+0(4).

    IF lv_doc_month LT 4.
      lv_fis_year = lv_fis_year - 1.
    ENDIF.

    IF xt_gedata[] IS NOT INITIAL.

      READ TABLE xt_gedata INTO DATA(xs_gedata_new) INDEX 1.

      IF im_action = 'create'.

        TRY.

            IF xs_gedata_new-plant = '1001'.

              CALL METHOD cl_numberrange_runtime=>number_get
                EXPORTING
                  nr_range_nr = '01'
                  object      = 'ZGATE_NUM'
                IMPORTING
                  number      = DATA(ge_num)
                  returncode  = DATA(rcode).

            ELSEIF xs_gedata_new-plant = '1002'.

              CALL METHOD cl_numberrange_runtime=>number_get
                EXPORTING
                  nr_range_nr = '02'
                  object      = 'ZGATE_NUM'
                IMPORTING
                  number      = ge_num
                  returncode  = rcode.

            ENDIF.

          CATCH cx_nr_object_not_found ##NO_HANDLER.

          CATCH cx_number_ranges ##NO_HANDLER.

        ENDTRY.

      ENDIF.

      LOOP AT xt_gedata INTO DATA(xs_gedata).

        MOVE-CORRESPONDING xs_gedata TO gs_final.
        IF im_action = 'change'.
          ge_num = gs_final-gentry_num.
        ENDIF.

        SHIFT ge_num LEFT DELETING LEADING '0'.
        gs_final-gentry_num   = ge_num.
        gs_final-gentry_year  = lv_fis_year.
        gs_final-created_on   = sys_date.
        gs_final-created_time = sys_time.

        LOOP AT xs_gedata-gt_item INTO DATA(xs_ge_item).
          MOVE-CORRESPONDING xs_ge_item TO gs_final.
          "gs_final-ponum  = xs_ge_item-ebeln.
          "gs_final-poitem = xs_ge_item-ebelp.
          APPEND gs_final TO gt_final.
        ENDLOOP.

      ENDLOOP.

      IF gt_final[] IS NOT INITIAL.

        IF im_action = 'create'.

          INSERT zmm_cust_ret FROM TABLE @gt_final.
          IF sy-subrc EQ 0.
            CONCATENATE 'Gate entry number' ge_num 'generated successfully' INTO rv_ge_num SEPARATED BY space ##NO_TEXT.
          ENDIF.

        ELSEIF im_action = 'change'.

          DATA:
            lv_index TYPE sy-tabix.

          SELECT * FROM zmm_cust_ret
                   WHERE gentry_num = @gs_final-gentry_num AND gedeleted = @abap_false
                   INTO TABLE @DATA(lt_ge_data). "#EC CI_ALL_FIELDS_NEEDED

        ENDIF.

      ENDIF.
    ENDIF.

  ENDMETHOD.
ENDCLASS.
