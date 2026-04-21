CLASS zcl_mm_sticker DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    DATA:
      gt_final  TYPE TABLE OF zstr_sticker_print,
      gs_final  TYPE zstr_sticker_print,
      lv_char10 TYPE c LENGTH 10,
      lv_char20 TYPE c LENGTH 20,
      lv_char4  TYPE c LENGTH 4.

    METHODS:
      get_grn_data
        IMPORTING
                  iv_mblnr        LIKE lv_char10
                  iv_gjahr        LIKE lv_char4
                  iv_docitm       LIKE lv_char4
                  iv_action       LIKE lv_char20
        RETURNING VALUE(et_final) LIKE gt_final,

      prep_xml_sticker_print
        IMPORTING
                  im_final             LIKE gs_final
                  iv_action            LIKE lv_char20
        RETURNING VALUE(iv_xml_base64) TYPE string.


  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_MM_STICKER IMPLEMENTATION.


  METHOD get_grn_data.

*    DATA:
*      lv_bar_code  TYPE string,
*      lv_pstd_qty  TYPE zi_grn_detail-QuantityInEntryUnit,
*      lv_pstd_qtyc TYPE c LENGTH 20.
*
*    IF ( iv_action = 'getdata' or iv_action = 'inwardprint' ).
*
*      SELECT * FROM zi_grn_detail
*               WHERE MaterialDocument     = @iv_mblnr AND
*                     MaterialDocumentYear = @iv_gjahr AND
*                     GoodsMovementIsCancelled = '' AND
*                     GoodsMovementType = '101'
*               INTO TABLE @DATA(lt_grn).      "#EC CI_ALL_FIELDS_NEEDED
*
*    ELSEIF ( iv_action = 'issuedata' or iv_action = 'issueprint' ).
*
*      SELECT * FROM zi_grn_detail
*               WHERE MaterialDocument     = @iv_mblnr AND
*                     MaterialDocumentYear = @iv_gjahr AND
*                     GoodsMovementIsCancelled = '' AND
*                     IsAutomaticallyCreated   = '' AND
*                     GoodsMovementType in ( '311', '201', '411' )
*               INTO TABLE @lt_grn.      "#EC CI_ALL_FIELDS_NEEDED #EC CI_FAE_LINES_ENSURED
*
*    if lt_grn[] is NOT INITIAL.
*
*      SELECT * FROM zi_grn_detail
*               FOR ALL ENTRIES IN @lt_grn
*               WHERE Batch = @lt_grn-Batch AND
*                     GoodsMovementIsCancelled = '' AND
*                     GoodsMovementType = '101'
*               INTO TABLE @DATA(lt_grn_101). "#EC CI_ALL_FIELDS_NEEDED #EC CI_FAE_LINES_ENSURED
*
*    endif.
*
*    ENDIF.
*
*    SORT lt_grn BY MaterialDocument MaterialDocumentYear MaterialDocumentItem.
*    DELETE ADJACENT DUPLICATES FROM lt_grn COMPARING MaterialDocument MaterialDocumentYear MaterialDocumentItem.
*
*    IF lt_grn[] IS NOT INITIAL.
*
*      SELECT * FROM zmm_pack_std
*               FOR ALL ENTRIES IN @lt_grn
*               WHERE Supplier = @lt_grn-Supplier AND
*                     material = @lt_grn-Material
*               INTO TABLE @DATA(lt_pstd).
*
*      LOOP AT lt_grn INTO DATA(ls_grn).
*
*        gs_final-materialdocument     = ls_grn-MaterialDocument.
*        gs_final-materialdocumentyear = ls_grn-MaterialDocumentYear.
*        gs_final-materialdocumentitem = ls_grn-MaterialDocumentItem.
*        gs_final-stickernumber        = 1.
*        gs_final-plant                = ls_grn-Plant.
*        gs_final-supplier             = ls_grn-Supplier.
*        gs_final-entryunit            = ls_grn-EntryUnit.
*        gs_final-entryqty             = ls_grn-QuantityInEntryUnit.
*        gs_final-suppliername         = ls_grn-SupplierName.
*        gs_final-invoiceno            = ls_grn-ReferenceDocument.
*        gs_final-recdate              = ls_grn-PostingDate+6(2) && '.' && ls_grn-PostingDate+4(2) && '.' && ls_grn-PostingDate+0(4).
*        gs_final-batch                = ls_grn-Batch.
*        gs_final-partcode             = ls_grn-Material.
*        gs_final-partname             = ls_grn-ProductDescription.
*
*        READ TABLE lt_pstd INTO DATA(ls_pstd) WITH KEY Supplier = ls_grn-Supplier
*                                                       Material = ls_grn-Material.
*
*        IF sy-subrc EQ 0.
*          gs_final-onebox_qty = ls_pstd-qtyinbox.
*          lv_pstd_qty  = ls_grn-QuantityInEntryUnit / ls_pstd-qtyinbox.
*          lv_pstd_qtyc = lv_pstd_qty.
*          CONDENSE lv_pstd_qtyc.
*          SPLIT lv_pstd_qtyc AT '.' INTO DATA(lv_part1) DATA(lv_part2).
*          IF lv_part2 NE 0.
*            lv_part1 = lv_part1 + 1.
*          ENDIF.
*          lv_pstd_qty = lv_part1.
*        ENDIF.
*
*        gs_final-stickerqty           = lv_pstd_qty.
*
*        if iv_action = 'issuedata' or iv_action = 'issueprint'.
*         READ TABLE lt_grn_101 INTO DATA(ls_grn_101) with key Batch = ls_grn-Batch.
*
*         gs_final-invoiceno    = ls_grn_101-ReferenceDocument.
*         gs_final-supplier     = ls_grn_101-Supplier.
*         gs_final-suppliername = ls_grn_101-SupplierName.
*         gs_final-recdate      = ls_grn_101-PostingDate+6(2) && '.' && ls_grn_101-PostingDate+4(2) && '.' && ls_grn_101-PostingDate+0(4).
*         gs_final-issuedate    = ls_grn-PostingDate+6(2) && '.' && ls_grn-PostingDate+4(2) && '.' && ls_grn-PostingDate+0(4).
*         gs_final-onebox_qty   = 1. "gs_final-entryqty.
*         gs_final-stickerqty   = 1. "gs_final-entryqty.
*
*        ENDIF.
*
*        lv_bar_code = ls_grn-Batch.
**         && '|' &&
**                      ls_grn-Material && '|' &&
**                      ls_grn-ReferenceDocument && '|' &&
**                      gs_final-recdate.
*
*        gs_final-barcode              = lv_bar_code.
*        gs_final-barcodestr           = lv_bar_code.
*
*        APPEND gs_final TO et_final.
*
*        CLEAR: ls_grn, ls_pstd, ls_grn_101.
*      ENDLOOP.
*
*    ENDIF.

  ENDMETHOD.


  METHOD  prep_xml_sticker_print.

    DATA : heading      TYPE c LENGTH 100,
           sub_heading  TYPE c LENGTH 200,
           lv_xml_final TYPE string,
           lv_xml_fina  TYPE string.

    DATA(lv_xml) =  |<Form>| &&
                    |<MaterialDocumentNode>| &&
                    |<document_num>{ im_final-materialdocument }</document_num>| &&
                    |<vendor_code>{ im_final-supplier }</vendor_code>| &&
                    |<vendor_name>{ im_final-suppliername }</vendor_name>| &&
                    |<inv_num>{ im_final-invoiceno }</inv_num>| &&
                    |<rec_date>{ im_final-recdate }</rec_date>| &&
                    |<issue_date>{ im_final-issuedate }</issue_date>| &&
                    |<part_code>{ im_final-partcode }</part_code>| &&
                    |<part_name>{ im_final-partname }</part_name>| &&
                    |<label_qty>{ im_final-boxqty }</label_qty>| &&
                    |<batch>{ im_final-batch }</batch>| &&
                    |<qr_string>{ im_final-barcodestr }</qr_string>| &&
                    |<qr_code>{ im_final-barcode }</qr_code>| &&
                    |<ItemData>| .

    DATA : lv_item TYPE string .

    lv_item = |{ lv_item }| && |<ItemDataNode>| &&
              |<heading>{ 'Test' }</heading>| &&
              |<sub_heading>{ 'Test' }</sub_heading>| &&
              |<RECPT_NO>{ 'Test' }</RECPT_NO> | &&
              |</ItemDataNode>|  ##NO_TEXT.

    lv_xml = |{ lv_xml }{ lv_item }| &&
                       |</ItemData>| &&
                       |</MaterialDocumentNode>| &&
                       |</Form>|.

    DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
    iv_xml_base64 = ls_data_xml_64.

  ENDMETHOD.
ENDCLASS.
