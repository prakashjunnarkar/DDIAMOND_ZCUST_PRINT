CLASS zcl_ge_process DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA:
      xt_final TYPE TABLE OF zstr_ge_po_f4_data,
      xt_data  TYPE TABLE OF zstr_ge_data,
      gt_final TYPE TABLE OF zmm_ge_data,
      gs_final TYPE zmm_ge_data.

    DATA:
      lv_char10  TYPE c LENGTH 10,
      lv_char120 TYPE c LENGTH 120,
      lv_char4   TYPE c LENGTH 4.

    METHODS:
      get_po_f4_data
        IMPORTING
                  iv_lifnr       LIKE lv_char10
                  iv_werks       LIKE lv_char4
        RETURNING VALUE(et_data) LIKE xt_final,

      get_ge_change_data
        IMPORTING
                  iv_genum       LIKE lv_char10
        RETURNING VALUE(et_data) LIKE xt_data,

      save_data_get_genum
        IMPORTING
                  xt_gedata        LIKE xt_data
                  im_action        LIKE lv_char10
        RETURNING VALUE(rv_ge_num) LIKE lv_char120,

      delete_data_genum
        IMPORTING
                  xt_gedata        LIKE xt_data
                  im_action        LIKE lv_char10
        RETURNING VALUE(rv_ge_num) LIKE lv_char120.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS ZCL_GE_PROCESS IMPLEMENTATION.


  METHOD delete_data_genum.
    IF im_action = 'delete'.
      READ TABLE xt_gedata INTO DATA(xs_gedata) INDEX 1.

      IF xs_gedata-gentry_num IS NOT INITIAL.

        UPDATE zmm_ge_data SET gedeleted = @abap_true
                           WHERE gentry_num = @xs_gedata-gentry_num.
        IF sy-subrc EQ 0.
          COMMIT WORK.
          rv_ge_num = |Gate entry number - | && xs_gedata-gentry_num && | deleted successfully| ##NO_TEXT.
        ENDIF.

      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD get_ge_change_data.

    DATA:
      gs_change   TYPE zstr_ge_data,
      gt_item     TYPE TABLE OF zstr_ge_item,
      gs_item     TYPE zstr_ge_item,
      lv_open_qty TYPE p DECIMALS 2,
      lv_val_neg  TYPE c LENGTH 20.

    SELECT * FROM zmm_ge_data WHERE gentry_num = @iv_genum AND gedeleted = @abap_false
             INTO TABLE @DATA(gt_gedata).

    DATA(gt_pitem) = gt_gedata[].
    SORT gt_gedata BY gentry_num.
    DELETE ADJACENT DUPLICATES FROM gt_gedata COMPARING gentry_num.

    LOOP AT gt_gedata INTO DATA(gs_gedata).

      MOVE-CORRESPONDING gs_gedata TO gs_change.

      IF gs_change-check_rc EQ 'X'.
        gs_change-check_rc = 'true'.
      ENDIF.

      IF gs_change-check_pollt EQ 'X'.
        gs_change-check_pollt = 'true'.
      ENDIF.

      IF gs_change-check_tripal EQ 'X'.
        gs_change-check_tripal = 'true'.
      ENDIF.

      IF gs_change-check_insur EQ 'X'.
        gs_change-check_insur = 'true'.
      ENDIF.

      IF gs_change-check_dl EQ 'X'.
        gs_change-check_dl = 'true'.
      ENDIF.


      LOOP AT gt_pitem INTO DATA(gs_pitem) WHERE gentry_num = gs_gedata-gentry_num.

        MOVE-CORRESPONDING gs_pitem TO gs_item.

        SELECT SINGLE
               ponum,
               poitem,
               SUM( challnqty ) AS challnqty
               FROM zmm_ge_data
               WHERE ponum = @gs_pitem-ponum AND poitem = @gs_pitem-poitem
                   AND gedeleted = @abap_false
               GROUP BY ponum, poitem
               INTO @DATA(ls_ge).                           "#EC WARNOK

        lv_open_qty = gs_pitem-poqty.
        lv_open_qty = lv_open_qty - ls_ge-challnqty.
        lv_val_neg  = lv_open_qty.
        CONDENSE lv_val_neg.
        IF lv_val_neg CA '-'.
          lv_open_qty = 0.
        ENDIF.

        gs_item-openqty = lv_open_qty.
        gs_item-ebeln   = gs_item-ponum.
        gs_item-ebelp   = gs_item-poitem.
        APPEND gs_item TO gt_item.

        CLEAR: lv_open_qty, ls_ge.
      ENDLOOP.

      SORT gt_item BY ebeln ebelp.
      INSERT LINES OF gt_item INTO TABLE gs_change-ge_item.
      APPEND gs_change TO et_data.

    ENDLOOP.


  ENDMETHOD.


  METHOD get_po_f4_data.

    DATA:
      gt_data     TYPE TABLE OF zstr_ge_po_f4_data,
      gs_data     TYPE zstr_ge_po_f4_data,
      lv_open_qty TYPE p DECIMALS 2,
      gv_werks    TYPE c LENGTH 4,
      gv_lifnr    TYPE c LENGTH 10.

    gv_werks = iv_werks.
    gv_lifnr = iv_lifnr.
*      gv_werks = '1001'.
*      gv_lifnr = 'VDC00085'.

    SELECT * FROM zi_po_data WHERE Supplier = @gv_lifnr AND
                                      Plant = @gv_werks "AND
                                      "PurchasingProcessingStatus = '05'
                                  INTO TABLE @DATA(lt_po).

    SELECT * FROM ZI_Schedgagrmt_PO WHERE Supplier = @gv_lifnr
                                  AND Plant = @gv_werks
                                  INTO TABLE @DATA(lt_po_schd).

    IF lt_po[] IS NOT INITIAL.

      SELECT
      PurchaseOrder,
      PurchaseOrderItem,
      GoodsMovementType,
      Quantity
      FROM zi_po_hist FOR ALL ENTRIES IN @lt_po
      WHERE PurchaseOrder = @lt_po-PurchaseOrder AND PurchaseOrderItem = @lt_po-PurchaseOrderItem
      INTO TABLE @DATA(lt_hist).                   "#EC CI_NO_TRANSFORM

    ENDIF.

*    IF lt_po[] IS NOT INITIAL.

    LOOP AT lt_po INTO DATA(ls_po).




      READ TABLE lt_hist INTO DATA(ls_hist_201) WITH KEY PurchaseOrder     = ls_po-PurchaseOrder
                                                         PurchaseOrderItem = ls_po-PurchaseOrderItem
                                                         GoodsMovementType = '101'.

      READ TABLE lt_hist INTO DATA(ls_hist_202) WITH KEY PurchaseOrder     = ls_po-PurchaseOrder
                                                         PurchaseOrderItem = ls_po-PurchaseOrderItem
                                                         GoodsMovementType = '102'.

      SELECT SINGLE
             ponum,
             poitem,
             SUM( challnqty ) AS challnqty
             FROM zmm_ge_data
             WHERE ponum = @ls_po-PurchaseOrder AND poitem = @ls_po-PurchaseOrderItem
                 AND gedeleted = @abap_false
             GROUP BY ponum, poitem
             INTO @DATA(ls_ge).                             "#EC WARNOK

      lv_open_qty = ls_po-OrderQuantity. "- ( ls_hist_201-Quantity - ls_hist_202-Quantity ).
      lv_open_qty = lv_open_qty - ls_ge-challnqty.

      IF lv_open_qty GT 0.

        CLEAR: gs_data.
        gs_data-ebeln    =  ls_po-PurchaseOrder.
        gs_data-ebelp    =  ls_po-PurchaseOrderItem.
        gs_data-matnr    =  ls_po-Material.
        gs_data-maktx    =  ls_po-ProductDescription.
        gs_data-doc_date =  ls_po-PurchaseOrderDate.
        gs_data-poqty    =  ls_po-OrderQuantity.
        gs_data-opqty    =  lv_open_qty.
        gs_data-uom      =  ls_po-BaseUnit.
        gs_data-overtol  =  ls_po-OverdelivTolrtdLmtRatioInPct.
        gs_data-netprice =  ls_po-NetPriceAmount.
        gs_data-currency =  ls_po-OrderPriceUnit.
        gs_data-per      =  ''.

        SELECT SINGLE FROM i_purchaseorderitemapi01     "Add By VishalTyagi On 20May2025
    FIELDS DocumentCurrency WHERE PurchaseOrder = @ls_po-PurchaseOrder AND
    PurchaseOrderItem = @ls_po-PurchaseOrderItem INTO @gs_data-documentcurrency.

        APPEND gs_data TO gt_data.

      ENDIF.

      CLEAR: ls_po,  ls_hist_201, ls_hist_202, lv_open_qty, ls_ge.
    ENDLOOP.

    """***Data for scheduling agreement "5500000077
    DATA(ct_po_schd) = lt_po_schd[].

    DATA:
       lv_days15 TYPE d.

    DATA:
      sys_date     TYPE d,
      sys_time     TYPE t,
      sys_timezone TYPE timezone,
      sys_uname    TYPE c LENGTH 20.

    IF lt_po_schd[] IS NOT INITIAL.

      SORT lt_po_schd BY SchedulingAgreement SchedulingAgreementItem.
      DELETE ADJACENT DUPLICATES FROM lt_po_schd COMPARING SchedulingAgreement SchedulingAgreementItem.

      sys_date  = cl_abap_context_info=>get_system_date( ).
      sys_time  = cl_abap_context_info=>get_system_time( ).
      sys_uname = cl_abap_context_info=>get_user_technical_name( ).

      lv_days15 = sys_date + 15.

      LOOP AT lt_po_schd INTO DATA(ls_po_schd).

        CLEAR: ls_po_schd-TargetQuantity.
        LOOP AT ct_po_schd INTO DATA(cs_po_schd) WHERE SchedulingAgreement = ls_po_schd-SchedulingAgreement AND
                                                       SchedulingAgreementItem = ls_po_schd-SchedulingAgreementItem AND
                                                       ScheduleLineDeliveryDate LE lv_days15.

          ls_po_schd-TargetQuantity = ls_po_schd-TargetQuantity + cs_po_schd-ScheduleLineOrderQuantity.

          CLEAR: cs_po_schd.
        ENDLOOP.

        SELECT SINGLE
               ponum,
               poitem,
               SUM( challnqty ) AS challnqty
               FROM zmm_ge_data
               WHERE ponum = @ls_po_schd-SchedulingAgreement AND poitem = @ls_po_schd-SchedulingAgreementItem
                   AND gedeleted = @abap_false
               GROUP BY ponum, poitem
               INTO @ls_ge.                             "#EC CI_NOORDER


        lv_open_qty = ls_po_schd-TargetQuantity.
        lv_open_qty = lv_open_qty - ls_ge-challnqty.

        IF lv_open_qty GT 0.

          CLEAR: gs_data.
          gs_data-ebeln    = ls_po_schd-SchedulingAgreement.
          gs_data-ebelp    = ls_po_schd-SchedulingAgreementItem.
          gs_data-matnr    = ls_po_schd-Material.
          gs_data-maktx    = ls_po_schd-ProductDescription.
          gs_data-doc_date = ls_po_schd-ScheduleLineDeliveryDate.
          gs_data-poqty    = ls_po_schd-TargetQuantity.
          gs_data-opqty    = lv_open_qty.
          gs_data-uom      = ls_po_schd-OrderQuantityUnit.
          gs_data-overtol  = ls_po_schd-OverdelivTolrtdLmtRatioInPct.
          gs_data-netprice = ls_po_schd-NetPriceAmount.
          gs_data-currency = ls_po_schd-OrderPriceUnit.
          gs_data-per      = ''.
          gs_data-hsncode          = ls_po_schd-ConsumptionTaxCtrlCode.
          gs_data-poitemcategory   = ls_po_schd-PurchasingDocumentCategory.
          APPEND gs_data TO gt_data.

        ENDIF.

        CLEAR: ls_ge, ls_po_schd.
      ENDLOOP.
    ENDIF.

    SORT gt_data BY ebeln ebelp.
    et_data[] = gt_data[].

*    ENDIF.

  ENDMETHOD.


  METHOD save_data_get_genum.
    DATA:
      lv_billnum TYPE zmm_ge_data-billnum,
      lv_dupbill TYPE c.

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

    IF xt_gedata[] IS NOT INITIAL.

      lv_doc_date  = sys_date.
      lv_doc_month = lv_doc_date+4(2).
      lv_fis_year  = lv_doc_date+0(4).

      IF lv_doc_month LT 4. "( v_month = '01' OR v_month = '02' OR v_month = '03' ).
        lv_fis_year = lv_fis_year - 1.
      ENDIF.

      READ TABLE xt_gedata INTO DATA(xs_gedata_new) INDEX 1.
      lv_billnum = xs_gedata_new-billnum.

      IF lv_billnum IS NOT INITIAL.

        SELECT * FROM zmm_ge_data WHERE billnum     = @lv_billnum AND
                                        lifnr       = @xs_gedata_new-lifnr AND
                                        gentry_year = @lv_fis_year AND
                                        gedeleted   = @abap_false
                                        INTO TABLE @DATA(bt_data).

        IF bt_data[] IS NOT INITIAL.
          lv_dupbill = abap_true.
        ENDIF.

      ENDIF.

      IF lv_dupbill EQ abap_true AND im_action = 'create'.
        CONCATENATE 'Gate entry already posted against bill number' lv_billnum INTO rv_ge_num SEPARATED BY space ##NO_TEXT.
      ELSE.

        IF im_action = 'create'.

          TRY.

              IF xs_gedata_new-werks = '1002'.

                CALL METHOD cl_numberrange_runtime=>number_get
                  EXPORTING
                    nr_range_nr = '01'
                    object      = 'ZGATE_NUM'
                  IMPORTING
                    number      = DATA(ge_num)
                    returncode  = DATA(rcode).

              ELSEIF xs_gedata_new-werks = '1001'.

                CALL METHOD cl_numberrange_runtime=>number_get
                  EXPORTING
                    nr_range_nr = '03'
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
          gs_final-gentry_num  = ge_num.
          gs_final-gentry_year = lv_fis_year. "sys_date+0(4).
          gs_final-erdat       = sys_date.
          gs_final-uzeit       = sys_time.
          gs_final-uname       = sys_uname.
          gs_final-created_on   = sys_date.
          gs_final-created_time = sys_time.
          gs_final-out_date     = sys_date.
          gs_final-out_time     = sys_time.

          LOOP AT xs_gedata-ge_item INTO DATA(xs_ge_item).
            MOVE-CORRESPONDING xs_ge_item TO gs_final.
            gs_final-ponum  = xs_ge_item-ebeln.
            gs_final-poitem = xs_ge_item-ebelp.
            APPEND gs_final TO gt_final.
          ENDLOOP.

        ENDLOOP.

        IF gt_final[] IS NOT INITIAL.

          IF im_action = 'create'.

            INSERT zmm_ge_data FROM TABLE @gt_final.
            IF sy-subrc EQ 0.
              CONCATENATE 'Gate entry number' ge_num 'generated successfully' INTO rv_ge_num SEPARATED BY space ##NO_TEXT.
            ENDIF.

          ELSEIF im_action = 'change'.

            DATA:
              lv_index TYPE sy-tabix.

            SELECT * FROM zmm_ge_data
                     WHERE gentry_num = @gs_final-gentry_num AND gedeleted = @abap_false AND mblnr NE ''
                     INTO TABLE @DATA(lt_ge_data). "#EC CI_NO_TRANSFORM "#EC CI_ALL_FIELDS_NEEDED

            IF lt_ge_data[] IS NOT INITIAL.

              SELECT
        MaterialDocument,
        MaterialDocumentYear,
        DocumentDate,
        PostingDate,
        MaterialDocumentHeaderText,
        DeliveryDocument,
        ReferenceDocument,
        BillOfLading,
        Plant,
        MaterialDocumentItem,
        GoodsMovementType,
        Supplier,
        PurchaseOrder,
        PurchaseOrderItem,
        Material,
        EntryUnit,
        QuantityInEntryUnit,
        TotalGoodsMvtAmtInCCCrcy,
        InventorySpecialStockType,
        InventoryStockType,
        ReversedMaterialDocument,
        ReversedMaterialDocumentItem,
        ReversedMaterialDocumentYear,
        Batch,
        GoodsMovementIsCancelled,
        GoodsRecipientName,
        UnloadingPointName,
        IsAutomaticallyCreated,
        ManufacturingOrder,
        Reservation,
        ReservationItem,
        StorageLocation,
        StorageBin,
        IssgOrRcvgBatch,
        IssuingOrReceivingStorageLoc,
        EWMStorageBin,
        PurchaseOrderDate,
        OrderQuantity,
        NetPriceAmount,
        QuantityInDeliveryQtyUnit,
        SupplierName,
        Country,
        AddressID,
        InspectionLot,
        InspLotQtyToBlocked,
        InspLotQtyToFree,
        MatlDocLatestPostgDate,
        InspectionLotType,
        inspectionLotUsageDecidedBy,
        inspectionLotUsageDecidedOn,
        StreetPrefixName1,
        StreetPrefixName2,
        StreetName,
        StreetSuffixName1,
        DistrictName,
        CityName,
        PostalCode,
        AddressRepresentationCode,
        AddressPersonID,
        Region,
        supll_email,
        ProductDescription
              FROM zi_grn_detail
                       FOR ALL ENTRIES IN @lt_ge_data
                       WHERE ReversedMaterialDocument = @lt_ge_data-mblnr AND
                             GoodsMovementType = '102'
                       INTO TABLE @DATA(gt_mdoc).  "#EC CI_NO_TRANSFORM

              LOOP AT lt_ge_data INTO DATA(ls_ge_data).
                lv_index = sy-tabix.

                READ TABLE gt_mdoc INTO DATA(wa_mkpf1)
                               WITH KEY ReversedMaterialDocument = ls_ge_data-mblnr
                                               GoodsMovementType = '102'.
                IF sy-subrc EQ 0.
                  DELETE lt_ge_data INDEX lv_index.
                ENDIF.

                CLEAR: ls_ge_data.
              ENDLOOP.

            ENDIF.

            IF lt_ge_data[] IS INITIAL.

              MODIFY zmm_ge_data FROM TABLE @gt_final.
              IF sy-subrc EQ 0.
                CONCATENATE 'Gate entry number' ge_num 'updated successfully' INTO rv_ge_num SEPARATED BY space ##NO_TEXT.
              ENDIF.

            ELSE.

              CONCATENATE 'Changes not allowed, MIGO alreday posted against gate entry' ge_num INTO rv_ge_num SEPARATED BY space ##NO_TEXT.

            ENDIF.

          ENDIF.

        ENDIF.

      ENDIF.

    ENDIF.

  ENDMETHOD.
ENDCLASS.
