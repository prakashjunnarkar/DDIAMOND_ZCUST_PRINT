CLASS zcl_http_post_goods_movement DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_service_extension .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_HTTP_POST_GOODS_MOVEMENT IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.

    TYPES: BEGIN OF gty_item,
             ponum           TYPE C LENGTH 40,
             poitem          TYPE C LENGTH 40,
             ebeln           TYPE C LENGTH 40,
             ebelp           TYPE C LENGTH 40,
             matnr           TYPE C LENGTH 40,
             maktx           TYPE C LENGTH 40,
             docdate         TYPE C LENGTH 40,
             poqty           TYPE C LENGTH 40,
             uom             TYPE C LENGTH 40,
             netprice        TYPE C LENGTH 40,
             challnqty       TYPE C LENGTH 40,
             MIGOQty         TYPE C LENGTH 40,
             StorageLocation TYPE C LENGTH 40,
             StorageBin      TYPE C LENGTH 40,
             DelNoteqty      TYPE C LENGTH 40,
             mfgdate         TYPE c LENGTH 10,
           END OF gty_item.

    DATA: xt_item TYPE TABLE OF gty_item,
          xs_item TYPE gty_item.

    TYPES: BEGIN OF gty_hdr,
             gentryNum  TYPE C LENGTH 40,
             DocDate    TYPE C LENGTH 40,
             POSTDate   TYPE C LENGTH 40,
             HeaderText TYPE C LENGTH 40,
             InvoiceRef TYPE C LENGTH 40,
             BillOfLadd TYPE C LENGTH 40,
             geItem     LIKE xt_item,
           END OF gty_hdr.

    DATA: xt_data TYPE TABLE OF gty_hdr,
          xs_data TYPE gty_hdr.

    DATA:
      lv_action  TYPE C LENGTH 10,
      miw_string TYPE string,
      lo_migo    TYPE REF TO zcl_goods_movement_create,
      gt_header  TYPE TABLE OF zstr_migo_header,
      gs_header  TYPE zstr_migo_header,
      gt_item    TYPE TABLE OF zstr_migo_item,
      gs_item    TYPE zstr_migo_item,
      gt_serial  TYPE TABLE OF zstr_migo_serial,
      lv_gm_code TYPE C LENGTH 2.

    CREATE OBJECT lo_migo.

    ""**Get input Data
    DATA(lt_input) = request->get_form_fields( ).
    READ TABLE lt_input INTO DATA(ls_action) WITH KEY name = 'actionname'.
    IF sy-subrc EQ 0.
      lv_action = ls_action-value.
    ENDIF.

    "Get inbound data
    DATA(lv_request_body) = request->get_text( ).

    /ui2/cl_json=>deserialize(
                    EXPORTING json = lv_request_body
                       pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                       CHANGING data = xt_data
                       ).

    ""****Start: Validation for duplicate invoice no*************************"""""
    IF xt_data[] IS NOT INITIAL.

      DATA: lv_inv_no     TYPE zi_grn_detail-ReferenceDocument,
            lv_doc_date   TYPE d,
            lv_fis_year   TYPE zi_dc_note-FiscalYear,
            lv_doc_month(2)  TYPE N,
            lv_fis_oyear  TYPE zi_dc_note-FiscalYear,
            lv_po_item    TYPE zmm_ge_data-poitem,
            lv_doc_omonth(2)  TYPE N,
            lv_Supplier   TYPE zi_grn_detail-Supplier,
            lv_dup_bill   TYPE c.

              DATA:
                sys_date     TYPE d.

              sys_date = cl_abap_context_info=>get_system_date( ).


      READ TABLE xt_data INTO DATA(xs_data_new) INDEX 1.
      lv_inv_no = xs_data_new-invoiceref.

      lv_doc_date  = sys_date.
      lv_doc_month = lv_doc_date+4(2).
      lv_fis_year  = lv_doc_date+0(4).

      IF lv_doc_month LT 4. "( v_month = '01' OR v_month = '02' OR v_month = '03' ).
        lv_fis_year = lv_fis_year - 1.
      ENDIF.

      SELECT SINGLE lifnr FROM zmm_ge_data
                          WHERE gentry_num = @xs_data_new-gentrynum
                          INTO @lv_Supplier. "#EC WARNOK

      lv_Supplier = |{ lv_Supplier ALPHA = IN }| .

      SELECT * FROM zi_grn_detail
               WHERE ReferenceDocument = @lv_inv_no AND
                     GoodsMovementType IN ( '101', '102' ) AND
                     Supplier = @lv_Supplier
               INTO TABLE @DATA(gt_mdoc). "#EC CI_ALL_FIELDS_NEEDED

      LOOP AT gt_mdoc ASSIGNING FIELD-SYMBOL(<lfs_mdoc>).

        CLEAR: lv_fis_oyear, lv_doc_omonth.
        lv_doc_omonth = <lfs_mdoc>-PostingDate+4(2).
        lv_fis_oyear  = <lfs_mdoc>-PostingDate+0(4).
        IF lv_doc_omonth LT 4.
          lv_fis_oyear = lv_fis_oyear - 1.
        ENDIF.
        <lfs_mdoc>-MaterialDocumentYear = lv_fis_oyear.

      ENDLOOP.

      LOOP AT gt_mdoc INTO DATA(wa_mkpf) WHERE GoodsMovementType = '101'.

        READ TABLE gt_mdoc INTO DATA(wa_mkpf1)
                       WITH KEY ReversedMaterialDocument = <lfs_mdoc>-MaterialDocument
                                                   GoodsMovementType = '102'. "#EC CI_NOORDER
        IF sy-subrc = 0.
          CONTINUE.
        ELSE.
          IF wa_mkpf-MaterialDocumentYear = lv_fis_year.
            miw_string  =  'This Bill No. has already been posted' ##NO_TEXT.
            lv_dup_bill = abap_true.
            EXIT. "#EC CI_NOORDER
          ENDIF.
        ENDIF.

        CLEAR: wa_mkpf.
      ENDLOOP.

    ENDIF.
    ""****End: Validation for duplicate invoice no***************************"""""

    IF lv_dup_bill = abap_false.

      IF xt_data[] IS NOT INITIAL.

        READ TABLE xt_data INTO xs_data INDEX 1.

        CLEAR: gs_header.
        gs_header-genumber                       = xs_data-gentrynum.
        gs_header-documentdate                   = xs_data-docdate.
        gs_header-postingdate                    = xs_data-postdate.
        gs_header-materialdocumentheadertext     = xs_data-headertext.
        gs_header-referencedocument              = xs_data-invoiceref.
        gs_header-goodsmovementcode              = '01'.
        APPEND gs_header TO gt_header.

      SELECT SINGLE werks FROM zmm_ge_data
                          WHERE gentry_num = @xs_data_new-gentrynum
                          INTO @DATA(lv_werks). "#EC WARNOK

        LOOP AT xs_data-geitem INTO xs_item.

          gs_item-material                     = xs_item-matnr.
          gs_item-plant                        = lv_werks.
          gs_item-storagelocation              = xs_item-StorageLocation.
          gs_item-storagebin                   = xs_item-storagebin.

          if xs_item-ponum is NOT INITIAL.
          gs_item-goodsmovementtype            = '101'.
          else.
          gs_item-goodsmovementtype            = '501'.
          ENDIF.

          gs_item-purchaseorder                = xs_item-ponum.
          SHIFT xs_item-poitem LEFT DELETING LEADING space.
          lv_po_item = xs_item-poitem.
          gs_item-purchaseorderitem            = lv_po_item.
          gs_item-goodsmovementrefdoctype      = ''.
          gs_item-quantityinentryunit          = xs_item-MIGOQty. "challnqty.
          gs_item-delnoteqty                   = xs_item-delnoteqty.
          gs_item-mfgdate                      = xs_item-mfgdate.
          gs_item-storagebin                   = xs_item-storagebin.
          gs_item-vendor                       = lv_Supplier.
          gs_item-batch                        = ''.
          gs_item-issgorrcvgmaterial           = ''.
          gs_item-issgorrcvgbatch              = ''.
          gs_item-issuingorreceivingplant      = ''.
          gs_item-issuingorreceivingstorageloc = ''.
          APPEND gs_item TO gt_item.

        ENDLOOP.

        lv_gm_code = '01'.
        lo_migo->post_goods_mvt(
          EXPORTING
            im_header  = gt_header
            im_item    = gt_item
            im_serial  = gt_serial
            im_action  = lv_action
            im_gm_code = lv_gm_code
          RECEIVING
            es_result  = miw_string
        ).

      ENDIF.

      ""**Setting response for UI5
      response->set_text(
        EXPORTING
          i_text = miw_string ).

    ELSE.

      response->set_text(
        EXPORTING
          i_text = miw_string ).


    ENDIF.

  ENDMETHOD.
ENDCLASS.
