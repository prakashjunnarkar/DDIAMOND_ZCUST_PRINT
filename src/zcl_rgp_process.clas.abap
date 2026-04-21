CLASS zcl_rgp_process DEFINITION
  PUBLIC  FINAL  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA:
      xt_final  TYPE TABLE OF zstr_rgp_pr_f4_data,
      xt_data   TYPE TABLE OF zstr_rgp_data,
      gt_final  TYPE TABLE OF zmm_rgp_data,
      gt_final1 TYPE TABLE OF zmm_nrgp_data,
      gs_final  TYPE zmm_rgp_data,
      gs_final1 TYPE zmm_nrgp_data.

    DATA:
      lv_char10  TYPE c LENGTH 10,
      lv_char120 TYPE c LENGTH 120,
      lv_char4   TYPE c LENGTH 4,
      lv_char15  TYPE c LENGTH 15,
      lv_char1   TYPE c LENGTH 1.

    DATA:
      sys_date     TYPE d,
      sys_time     TYPE t,
      sys_timezone TYPE timezone,
      sys_uname    TYPE c LENGTH 20.

    METHODS:
      get_pr_f4_data
        IMPORTING
                  iv_werks       LIKE lv_char4
        RETURNING VALUE(et_data) LIKE xt_final,

      get_nrgp_f4_data
        IMPORTING
                  iv_werks       LIKE lv_char4
        RETURNING VALUE(et_data) LIKE xt_final,


      get_rgpout_change_data
        IMPORTING
                  iv_rgpoutnum   LIKE lv_char10
        EXPORTING ev_msg_type    TYPE char1_run_type
                  ev_msg_text    TYPE string
        RETURNING VALUE(et_data) LIKE xt_data,

      get_rgpin_create_data
        IMPORTING
                  iv_rgpoutnum   LIKE lv_char10
        EXPORTING ev_msg_type    TYPE char1_run_type
                  ev_msg_text    TYPE string
        RETURNING VALUE(et_data) LIKE xt_data,

      get_rgpin_change_data
        IMPORTING
                  iv_rgpinnum    LIKE lv_char10
        EXPORTING ev_msg_type    TYPE char1_run_type
                  ev_msg_text    TYPE string
        RETURNING VALUE(et_data) LIKE xt_data,

      get_nrgp_change_data
        IMPORTING
                  iv_nrgpnum     LIKE lv_char10
        EXPORTING ev_msg_type    TYPE char1_run_type
                  ev_msg_text    TYPE string
        RETURNING VALUE(et_data) LIKE xt_data,

      save_data_get_rgpoutnum
        IMPORTING
                  xt_gedata         LIKE xt_data
                  im_action         LIKE lv_char15
        RETURNING VALUE(rv_rgp_num) LIKE lv_char120,
*        RAISING cx_abap_message_runtimed,  "added by neelam

      delete_data_rgpoutnum
        IMPORTING
                  xt_gedata         LIKE xt_data
                  im_action         LIKE lv_char15
        RETURNING VALUE(rv_rgp_num) LIKE lv_char120.

  PROTECTED SECTION.
  PRIVATE SECTION.

**    METHODS:
**      close_pr_line
**        IMPORTING
**          iv_prnum  TYPE banfn    " Change from CSEQUENCE to banfn (CHAR 10)
**          iv_pritem TYPE bnfpo.   " Change from CSEQUENCE to bnfpo (NUMC 5)

**  METHOD close_pr_line.
**    " Identify the record using Key fields, but only list the 'Closed' flag for update
**    MODIFY ENTITIES OF I_PurchaseRequisitionTP
**      ENTITY PurchaseRequisitionItem
**        UPDATE FIELDS ( IsClosed ) " ONLY include the field to change
**        WITH VALUE #( (
**            PurchaseRequisition     = iv_prnum    " Part of the Key (Address)
**            PurchaseRequisitionItem = iv_pritem   " Part of the Key (Address)
**            IsClosed = abap_true " The actual change
**        ) )
**      FAILED   DATA(ls_failed)
**      REPORTED DATA(ls_reported).
**
**    " If there are no failures, commit the changes
**    IF ls_failed IS INITIAL.
**      COMMIT ENTITIES.
**    ELSE.
**      " Optional: Log the error from ls_reported if the PR fails to close
**    ENDIF.
**  ENDMETHOD.

ENDCLASS.



CLASS ZCL_RGP_PROCESS IMPLEMENTATION.


  METHOD get_rgpin_change_data.

    DATA:
      gs_change  TYPE zstr_rgp_data,
      gt_item    TYPE TABLE OF zstr_rgp_item,
      gs_item    TYPE zstr_rgp_item,
      lv_bal_qty TYPE p DECIMALS 2,
      lv_val_neg TYPE c LENGTH 20.

    sys_date  = cl_abap_context_info=>get_system_date( ).
    sys_time  = cl_abap_context_info=>get_system_time( ).
    sys_uname = cl_abap_context_info=>get_user_technical_name( ).

    CLEAR: et_data.

    SELECT * FROM zmm_rgp_data WHERE rgpin_num = @iv_rgpinnum AND rgpindeleted = @abap_false
          INTO TABLE @DATA(gt_gedata).

    IF gt_gedata IS INITIAL.
      CLEAR gs_change.
      gs_change-msg_type = 'E'.
      gs_change-msg_text = |This is not a RGP IN no { iv_rgpinnum }|.
      APPEND gs_change TO et_data.
      RETURN.
    ENDIF.


***    DELETE FROM zmm_rgp_data WHERE rgpout_num = '1600000060'.
    DATA(gt_pitem) = gt_gedata[].
    DELETE gt_pitem WHERE rgpin_num IS INITIAL.

    SORT gt_gedata BY rgpin_num.
    DELETE ADJACENT DUPLICATES FROM gt_gedata COMPARING rgpin_num.

    LOOP AT gt_gedata INTO DATA(gs_gedata).
      IF gs_gedata-rinvechout = 'X'.
        CLEAR gs_change.
        gs_change-msg_type = 'E'.
        gs_change-msg_text = |Vehicle is already out against this RGP No { iv_rgpinnum }|.
        APPEND gs_change TO et_data.
        RETURN.
      ENDIF.

      IF gs_gedata-shortclose = 'X'.
        CLEAR gs_change.
        gs_change-msg_type = 'E'.
        gs_change-msg_text = | Already short closure against this RGP No { iv_rgpinnum }|.
        APPEND gs_change TO et_data.
        RETURN.
      ENDIF.

      CLEAR: gs_change, gt_item.
      MOVE-CORRESPONDING gs_gedata TO gs_change.

      IF gs_change-rinvechout EQ 'X'.
        gs_change-rinvechout = 'true'.
      ENDIF.

      LOOP AT gt_pitem INTO DATA(gs_pitem) WHERE rgpin_num = gs_gedata-rgpin_num.
        SELECT SINGLE
                 prnum,
                 pritem,
                 SUM( recqty ) AS recqty
                 FROM zmm_rgp_data
                 WHERE prnum = @gs_pitem-prnum AND pritem = @gs_pitem-pritem
                     AND rgpindeleted = @abap_false
                 GROUP BY prnum, pritem
                 INTO @DATA(ls_recqty).                     "#EC WARNOK

        CLEAR: gs_item.
        MOVE-CORRESPONDING gs_pitem TO gs_item.

        lv_bal_qty = gs_pitem-prqty -
                   COND #( WHEN sy-subrc = 0 THEN ls_recqty-recqty ELSE 0 ).

        IF lv_bal_qty < 0.
          lv_bal_qty = 0.
        ENDIF.

        gs_item-balqty = lv_bal_qty.
        APPEND gs_item TO gt_item.


      ENDLOOP.

      SORT gt_item BY prnum pritem.
      INSERT LINES OF gt_item INTO TABLE gs_change-rgp_item.

      gs_change-created_on = gs_gedata-created_on.    "added by neelam
      gs_change-created_time = gs_gedata-created_time."added by neelam
      gs_change-changed_on = sys_date.                "added by neelam
      gs_change-changed_time = sys_time.              "added by neelam
      gs_change-ringross_wgt = gs_gedata-ringross_wgt.              "added by neelam
      gs_change-rintare_wgt = gs_gedata-rintare_wgt.
      .              "added by neelam
      gs_change-rinnet_wgt = gs_gedata-rinnet_wgt.              "added by neelam
      gs_change-invno = gs_gedata-invno.              "added by neelam
      gs_change-invdt = gs_gedata-invdt.              "added by neelam


      APPEND gs_change TO et_data.

    ENDLOOP.

  ENDMETHOD.


  METHOD delete_data_rgpoutnum.

    READ TABLE xt_gedata INTO DATA(ls) INDEX 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    CASE im_action.
      WHEN 'deletergpout'.
        UPDATE zmm_rgp_data SET rgpoutdeleted = @abap_true
          WHERE rgpout_num = @ls-rgpout_num.
        rv_rgp_num = |RGP OUT { ls-rgpout_num } deleted successfully|.

      WHEN 'deletergpin'.
        UPDATE zmm_rgp_data SET rgpindeleted = @abap_true
          WHERE rgpin_num = @ls-rgpin_num.
        rv_rgp_num = |RGP IN { ls-rgpin_num } deleted successfully|.

      WHEN 'deletenrgp'.
        UPDATE zmm_nrgp_data SET nrgpdeleted = @abap_true
          WHERE nrgp_num = @ls-nrgp_num.
        rv_rgp_num = |NRGP { ls-nrgp_num } deleted successfully|.
    ENDCASE.

    COMMIT WORK.

  ENDMETHOD.


  METHOD get_nrgp_change_data.

    DATA:
      gs_change  TYPE zstr_rgp_data,
      gt_item    TYPE TABLE OF zstr_rgp_item,
      gs_item    TYPE zstr_rgp_item,
      lv_bal_qty TYPE p DECIMALS 2,
      lv_val_neg TYPE c LENGTH 20.

    sys_date  = cl_abap_context_info=>get_system_date( ).
    sys_time  = cl_abap_context_info=>get_system_time( ).
    sys_uname = cl_abap_context_info=>get_user_technical_name( ).

    SELECT * FROM zmm_nrgp_data WHERE nrgp_num = @iv_nrgpnum AND nrgpdeleted = @abap_false
             INTO TABLE @DATA(gt_gedata).

    IF gt_gedata IS INITIAL.
      CLEAR gs_change.
      gs_change-msg_type = 'E'.
      gs_change-msg_text = |No data found for RGP No { iv_nrgpnum }|.
      APPEND gs_change TO et_data.
      RETURN.
    ENDIF.

    DATA(gt_pitem) = gt_gedata[].
    SORT gt_gedata BY nrgp_num.
    SORT gt_pitem BY prnum pritem.
    DELETE ADJACENT DUPLICATES FROM gt_gedata COMPARING nrgp_num.
*    DELETE gt_pitem WHERE prnum = ''.

    LOOP AT gt_gedata INTO DATA(gs_gedata).

      IF gs_gedata-vechout EQ 'X'.
        CLEAR gs_change.
        gs_change-msg_type = 'E'.
        gs_change-msg_text = |Vehicle is already out against this RGP No { iv_nrgpnum }|.
        APPEND gs_change TO et_data.
        RETURN.
      ENDIF.

      MOVE-CORRESPONDING gs_gedata TO gs_change.

      IF gs_change-vechout EQ 'X'.
        gs_change-vechout = 'true'.
      ENDIF.

      LOOP AT gt_pitem INTO DATA(gs_pitem) WHERE nrgp_num = gs_gedata-nrgp_num.

        MOVE-CORRESPONDING gs_pitem TO gs_item.

        gs_item-prnum   = gs_item-prnum.
        gs_item-pritem   = gs_item-pritem.
        APPEND gs_item TO gt_item.
      ENDLOOP.

      SORT gt_item BY prnum pritem.
      INSERT LINES OF gt_item INTO TABLE gs_change-rgp_item.

      gs_change-created_on = gs_gedata-created_on.    "added by neelam
      gs_change-created_time = gs_gedata-created_time."added by neelam
      gs_change-changed_on = sys_date.                "added by neelam
      gs_change-changed_time = sys_time.              "added by neelam

      APPEND gs_change TO et_data.

    ENDLOOP.

  ENDMETHOD.


  METHOD get_nrgp_f4_data.

    DATA:
      gt_data    TYPE TABLE OF zstr_rgp_pr_f4_data,
      gs_data    TYPE zstr_rgp_pr_f4_data,
      lv_bal_qty TYPE p DECIMALS 2,
      gv_werks   TYPE c LENGTH 4,
      gv_lifnr   TYPE c LENGTH 10.

    gv_werks = iv_werks.

    SELECT * FROM zi_pr_data WHERE plant = @gv_werks
                                  INTO TABLE @DATA(lt_po).

    IF lt_po IS NOT INITIAL.
      SELECT * FROM zmm_nrgp_data
      FOR ALL ENTRIES IN @lt_po WHERE prnum = @lt_po-purchaserequisition
      AND pritem = @lt_po-purchaserequisitionitem
       AND nrgpdeleted = @abap_false
      INTO TABLE @DATA(lt_nrgp).
    ENDIF.
    IF lt_nrgp IS NOT INITIAL.
      LOOP AT lt_nrgp INTO DATA(ls_nrgp) .
        DELETE lt_po WHERE purchaserequisition = ls_nrgp-prnum AND purchaserequisitionitem = ls_nrgp-pritem.
      ENDLOOP.
    ENDIF.

    LOOP AT lt_po INTO DATA(ls_po).
      CLEAR: gs_data.
      gs_data-prnum    =  ls_po-purchaserequisition.
      gs_data-pritem    =  ls_po-purchaserequisitionitem.
      gs_data-matnr    =  ls_po-material.

      IF ls_po-material IS NOT INITIAL.
        gs_data-maktx    =  ls_po-productdescription.
      ENDIF.
      gs_data-prqty    =  ls_po-requestedquantity.
      gs_data-netprice = ls_po-purchaserequisitionprice.
      gs_data-uom      = COND #( WHEN ls_po-baseunit = 'ST' THEN 'PC' ELSE ls_po-baseunit ).
      gs_data-grossvalue  =  ls_po-requestedquantity * ls_po-purchaserequisitionprice.
      gs_data-taxcode = ls_po-taxcode.
      gs_data-hsncode = ls_po-consumptiontaxctrlcode.

      APPEND gs_data TO gt_data.
      CLEAR:ls_po.

    ENDLOOP.

    DATA:
       lv_days15 TYPE d.

    DATA:
      sys_date     TYPE d,
      sys_time     TYPE t,
      sys_timezone TYPE timezone,
      sys_uname    TYPE c LENGTH 20.

    sys_date  = cl_abap_context_info=>get_system_date( ).
    sys_time  = cl_abap_context_info=>get_system_time( ).
    sys_uname = cl_abap_context_info=>get_user_technical_name( ).

    lv_days15 = sys_date + 15.

    SORT gt_data BY prnum pritem.
    et_data[] = gt_data[].


  ENDMETHOD.


  METHOD get_pr_f4_data.

    DATA:
      gt_data    TYPE TABLE OF zstr_rgp_pr_f4_data,
      gs_data    TYPE zstr_rgp_pr_f4_data,
      lv_bal_qty TYPE p DECIMALS 2,
      gv_werks   TYPE c LENGTH 4,
      gv_lifnr   TYPE c LENGTH 10.

    DATA: lt_pr   TYPE STANDARD TABLE OF zi_pr_data,
          lt_used TYPE HASHED TABLE OF zmm_rgp_data
                  WITH UNIQUE KEY prnum pritem.


    gv_werks = iv_werks.

    SELECT * FROM zi_pr_data WHERE plant = @gv_werks
                                  INTO TABLE @DATA(lt_po).

    IF lt_po IS NOT INITIAL.
      SELECT * FROM zmm_rgp_data
      FOR ALL ENTRIES IN @lt_po WHERE prnum = @lt_po-purchaserequisition
                                  AND pritem = @lt_po-purchaserequisitionitem
                                  AND rgpoutdeleted = @abap_false
                                  AND rgpin_num = ''
      INTO TABLE @DATA(lt_rgpout).
    ELSE.
      RETURN.
    ENDIF.

    IF lt_rgpout IS NOT INITIAL.
      LOOP AT lt_rgpout INTO DATA(ls_rgpout) .
        DELETE lt_po WHERE purchaserequisition = ls_rgpout-prnum
                       AND purchaserequisitionitem = ls_rgpout-pritem.
      ENDLOOP.
    ENDIF.

    LOOP AT lt_po INTO DATA(ls_po).

      SELECT SINGLE
          prnum,
          pritem,
          SUM( recqty ) AS recqty
          FROM zmm_rgp_data
          WHERE prnum = @ls_po-purchaserequisition AND pritem = @ls_po-purchaserequisitionitem
              AND rgpoutdeleted = @abap_false
          GROUP BY prnum, pritem
          INTO @DATA(ls_recqty).                            "#EC WARNOK

      lv_bal_qty = ls_po-requestedquantity.
      lv_bal_qty = lv_bal_qty - ls_recqty-recqty.

      IF lv_bal_qty GT 0.
        CLEAR: gs_data.
        gs_data-prnum    =  ls_po-purchaserequisition.
        gs_data-pritem    =  ls_po-purchaserequisitionitem.
        gs_data-matnr    =  ls_po-material.

        IF ls_po-material IS NOT INITIAL.
          gs_data-maktx    =  ls_po-productdescription.
        ENDIF.
        gs_data-prqty    =  ls_po-requestedquantity.
        gs_data-balqty   = lv_bal_qty.
        gs_data-netprice = ls_po-purchaserequisitionprice.
        gs_data-uom      = COND #( WHEN ls_po-baseunit = 'ST' THEN 'PC' ELSE ls_po-baseunit ).
        gs_data-grossvalue  =  ls_po-requestedquantity * ls_po-purchaserequisitionprice.
        gs_data-taxcode = ls_po-taxcode.
        gs_data-hsncode = ls_po-consumptiontaxctrlcode.

        APPEND gs_data TO gt_data.
      ENDIF.
      CLEAR:ls_po.

    ENDLOOP.

    DATA:
       lv_days15 TYPE d.

    sys_date  = cl_abap_context_info=>get_system_date( ).
    sys_time  = cl_abap_context_info=>get_system_time( ).
    sys_uname = cl_abap_context_info=>get_user_technical_name( ).

    lv_days15 = sys_date + 15.

    SORT gt_data BY prnum pritem.
    et_data[] = gt_data[].


  ENDMETHOD.


  METHOD get_rgpin_create_data.

    DATA:
      gs_change  TYPE zstr_rgp_data,
      gt_item    TYPE TABLE OF zstr_rgp_item,
      gs_item    TYPE zstr_rgp_item,
      lv_bal_qty TYPE p DECIMALS 2,
      lv_val_neg TYPE c LENGTH 20.

    sys_date  = cl_abap_context_info=>get_system_date( ).
    sys_time  = cl_abap_context_info=>get_system_time( ).
    sys_uname = cl_abap_context_info=>get_user_technical_name( ).

    CLEAR: et_data.

    SELECT * FROM zmm_rgp_data WHERE rgpout_num = @iv_rgpoutnum AND rgpindeleted = @abap_false
     AND vechout = 'X' INTO TABLE @DATA(gt_gedata).

    IF gt_gedata IS INITIAL.
      CLEAR gs_change.
      gs_change-msg_type = 'E'.
      gs_change-msg_text = |This is not a RGP IN no { iv_rgpoutnum }|.
      APPEND gs_change TO et_data.
      RETURN.
    ENDIF.


***    DELETE FROM zmm_rgp_data WHERE rgpout_num = '1600000060'.
    DATA(gt_pitem) = gt_gedata[].
    DELETE gt_pitem WHERE rgpout_num IS INITIAL.

    SORT gt_gedata BY rgpout_num.
    DELETE ADJACENT DUPLICATES FROM gt_gedata COMPARING rgpout_num.

    LOOP AT gt_gedata INTO DATA(gs_gedata).

      CLEAR: gs_change, gt_item.
      MOVE-CORRESPONDING gs_gedata TO gs_change.

      IF gs_change-rinvechout EQ 'X'.
        gs_change-rinvechout = 'true'.
      ENDIF.

      LOOP AT gt_pitem INTO DATA(gs_pitem) WHERE rgpout_num = gs_gedata-rgpout_num.
        SELECT SINGLE
                 prnum,
                 pritem,
                 SUM( recqty ) AS recqty
                 FROM zmm_rgp_data
                 WHERE prnum = @gs_pitem-prnum AND pritem = @gs_pitem-pritem
                     AND rgpindeleted = @abap_false
                 GROUP BY prnum, pritem
                 INTO @DATA(ls_recqty).                     "#EC WARNOK

        CLEAR: gs_item.
        MOVE-CORRESPONDING gs_pitem TO gs_item.

        lv_bal_qty = gs_pitem-prqty -
                   COND #( WHEN sy-subrc = 0 THEN ls_recqty-recqty ELSE 0 ).

        IF lv_bal_qty < 0.
          lv_bal_qty = 0.
        ENDIF.

        IF lv_bal_qty > 0.
          gs_item-balqty = lv_bal_qty.
          APPEND gs_item TO gt_item.
        ELSE.
          CLEAR gs_item.
          gs_change-msg_type = 'E'.
          gs_change-msg_text = |No data exist { iv_rgpoutnum }|.
          APPEND gs_item TO gt_item.
          RETURN.
        ENDIF.

      ENDLOOP.

      SORT gt_item BY prnum pritem.
      INSERT LINES OF gt_item INTO TABLE gs_change-rgp_item.

      gs_change-created_on = gs_gedata-created_on.    "added by neelam
      gs_change-created_time = gs_gedata-created_time."added by neelam
      gs_change-changed_on = sys_date.                "added by neelam
      gs_change-changed_time = sys_time.              "added by neelam
      gs_change-ringross_wgt = gs_gedata-ringross_wgt.              "added by neelam
      gs_change-rintare_wgt = gs_gedata-rintare_wgt.
      .              "added by neelam
      gs_change-rinnet_wgt = gs_gedata-rinnet_wgt.              "added by neelam
      gs_change-invno = gs_gedata-invno.              "added by neelam
      gs_change-invdt = gs_gedata-invdt.              "added by neelam


      APPEND gs_change TO et_data.

    ENDLOOP.

  ENDMETHOD.


  METHOD get_rgpout_change_data.

    DATA:
      gs_change  TYPE zstr_rgp_data,
      gt_item    TYPE TABLE OF zstr_rgp_item,
      gs_item    TYPE zstr_rgp_item,
      lv_bal_qty TYPE p DECIMALS 2,
      lv_val_neg TYPE c LENGTH 20.

    sys_date  = cl_abap_context_info=>get_system_date( ).
    sys_time  = cl_abap_context_info=>get_system_time( ).
    sys_uname = cl_abap_context_info=>get_user_technical_name( ).

    SELECT * FROM zmm_rgp_data WHERE rgpout_num = @iv_rgpoutnum AND rgpoutdeleted = @abap_false
    AND rgpin_num = ''
             INTO TABLE @DATA(gt_gedata).

    IF gt_gedata IS INITIAL.
      CLEAR gs_change.
      gs_change-msg_type = 'E'.
      gs_change-msg_text = |No data found for RGP No { iv_rgpoutnum }|.
      APPEND gs_change TO et_data.
      RETURN.
    ENDIF.

    DATA(gt_pitem) = gt_gedata[].
    SORT gt_gedata BY rgpout_num.
    SORT gt_pitem BY prnum pritem.
    DELETE ADJACENT DUPLICATES FROM gt_gedata COMPARING rgpout_num.
    DELETE ADJACENT DUPLICATES FROM gt_pitem COMPARING prnum pritem.

    LOOP AT gt_gedata INTO DATA(gs_gedata).

      IF gs_gedata-vechout EQ 'X'.
        CLEAR gs_change.
        gs_change-msg_type = 'E'.
        gs_change-msg_text = |Vehicle is already out against this Gateout no { iv_rgpoutnum }|.
        APPEND gs_change TO et_data.
        RETURN.
      ENDIF.

      MOVE-CORRESPONDING gs_gedata TO gs_change.

      IF gs_change-vechout EQ 'X'.
        gs_change-vechout = 'true'.
      ENDIF.

      LOOP AT gt_pitem INTO DATA(gs_pitem) WHERE rgpout_num = gs_gedata-rgpout_num.

        MOVE-CORRESPONDING gs_pitem TO gs_item.

        gs_item-prnum   = gs_item-prnum.
        gs_item-pritem   = gs_item-pritem.
        APPEND gs_item TO gt_item.
      ENDLOOP.

      SORT gt_item BY prnum pritem.
      INSERT LINES OF gt_item INTO TABLE gs_change-rgp_item.

      gs_change-created_on = gs_gedata-created_on.    "added by neelam
      gs_change-created_time = gs_gedata-created_time."added by neelam
      gs_change-changed_on = sys_date.                "added by neelam
      gs_change-changed_time = sys_time.              "added by neelam

      APPEND gs_change TO et_data.

    ENDLOOP.

  ENDMETHOD.


  METHOD save_data_get_rgpoutnum.
    DATA:
      lv_billnum TYPE zmm_rgp_data-billnum,
      lv_dupbill TYPE c.

    DATA: lv_doc_date     TYPE d,
          lv_fis_year     TYPE zi_dc_note-fiscalyear,
          lv_doc_month(2) TYPE n.

    sys_date  = cl_abap_context_info=>get_system_date( ).
    sys_time  = cl_abap_context_info=>get_system_time( ).
    sys_uname = cl_abap_context_info=>get_user_technical_name( ).

***    DELETE FROM zmm_rgp_data WHERE rgpoutdeleted = ''.

    IF xt_gedata[] IS NOT INITIAL.

      lv_doc_date  = sys_date.
      lv_doc_month = lv_doc_date+4(2).
      lv_fis_year  = lv_doc_date+0(4).

      IF lv_doc_month LT 4. "( v_month = '01' OR v_month = '02' OR v_month = '03' ).
        lv_fis_year = lv_fis_year - 1.
      ENDIF.

      READ TABLE xt_gedata INTO DATA(xs_gedata_new) INDEX 1.

      IF im_action = 'creatergpout'.

        TRY.

            CALL METHOD cl_numberrange_runtime=>number_get
              EXPORTING
                nr_range_nr = '40'
                object      = 'ZRGPOUT_NM'
              IMPORTING
                number      = DATA(rgp_num)
                returncode  = DATA(rcode).

*            IF xs_gedata_new-werks = '1101'.
*
*              CALL METHOD cl_numberrange_runtime=>number_get
*                EXPORTING
*                  nr_range_nr = '14'
*                  object      = 'ZRGPOUT_NM'
*                IMPORTING
*                  number      = DATA(rgp_num)
*                  returncode  = DATA(rcode).
*
*            ELSEIF xs_gedata_new-werks = '1102'.
*
*              CALL METHOD cl_numberrange_runtime=>number_get
*                EXPORTING
*                  nr_range_nr = '15'
*                  object      = 'ZRGPOUT_NM'
*                IMPORTING
*                  number      = rgp_num
*                  returncode  = rcode.
*
*            ELSEIF xs_gedata_new-werks = '1201'.
*
*              CALL METHOD cl_numberrange_runtime=>number_get
*                EXPORTING
*                  nr_range_nr = '16'
*                  object      = 'ZRGPOUT_NM'
*                IMPORTING
*                  number      = rgp_num
*                  returncode  = rcode.
*
*            ENDIF.

          CATCH cx_nr_object_not_found ##NO_HANDLER.
          CATCH cx_number_ranges ##NO_HANDLER.
        ENDTRY.

      ELSEIF im_action = 'creatergpin'.

        TRY.

            CALL METHOD cl_numberrange_runtime=>number_get
              EXPORTING
                nr_range_nr = '30'
                object      = 'ZRGPIN_NUM'
              IMPORTING
                number      = DATA(rgpin_num)
                returncode  = rcode.

*            IF xs_gedata_new-werks = '1101'.
*
*              CALL METHOD cl_numberrange_runtime=>number_get
*                EXPORTING
*                  nr_range_nr = '17'
*                  object      = 'ZRGPIN_NUM'
*                IMPORTING
*                  number      = DATA(rgpin_num)
*                  returncode  = rcode.
*
*            ELSEIF xs_gedata_new-werks = '1102'.
*
*              CALL METHOD cl_numberrange_runtime=>number_get
*                EXPORTING
*                  nr_range_nr = '18'
*                  object      = 'ZRGPIN_NUM'
*                IMPORTING
*                  number      = rgpin_num
*                  returncode  = rcode.
*
*            ELSEIF xs_gedata_new-werks = '1201'.
*
*              CALL METHOD cl_numberrange_runtime=>number_get
*                EXPORTING
*                  nr_range_nr = '19'
*                  object      = 'ZRGPIN_NUM'
*                IMPORTING
*                  number      = rgpin_num
*                  returncode  = rcode.
*
*            ENDIF.

          CATCH cx_nr_object_not_found ##NO_HANDLER.
          CATCH cx_number_ranges ##NO_HANDLER.
        ENDTRY.
      ELSEIF im_action = 'createnrgp'.

        TRY.

            CALL METHOD cl_numberrange_runtime=>number_get
              EXPORTING
                nr_range_nr = '50'
                object      = 'ZNRGP_NUM'
              IMPORTING
                number      = DATA(nrgp_num)
                returncode  = rcode.


*            IF xs_gedata_new-werks = '1101'.
*
*              CALL METHOD cl_numberrange_runtime=>number_get
*                EXPORTING
*                  nr_range_nr = '20'
*                  object      = 'ZNRGP_NUM'
*                IMPORTING
*                  number      = DATA(nrgp_num)
*                  returncode  = rcode.
*
*            ELSEIF xs_gedata_new-werks = '1102'.
*
*              CALL METHOD cl_numberrange_runtime=>number_get
*                EXPORTING
*                  nr_range_nr = '21'
*                  object      = 'ZNRGP_NUM'
*                IMPORTING
*                  number      = nrgp_num
*                  returncode  = rcode.
*
*            ELSEIF xs_gedata_new-werks = '1201'.
*
*              CALL METHOD cl_numberrange_runtime=>number_get
*                EXPORTING
*                  nr_range_nr = '22'
*                  object      = 'ZNRGP_NUM'
*                IMPORTING
*                  number      = NRGP_num
*                  returncode  = rcode.
*
*            ENDIF.

          CATCH cx_nr_object_not_found ##NO_HANDLER.
          CATCH cx_number_ranges ##NO_HANDLER.
        ENDTRY.
      ENDIF.

      LOOP AT xt_gedata INTO DATA(xs_gedata).

        MOVE-CORRESPONDING xs_gedata TO gs_final.

        IF im_action = 'changergpout'.
          rgp_num = gs_final-rgpout_num.
        ENDIF.
        SHIFT rgp_num LEFT DELETING LEADING '0'.

        gs_final-lifnr        = gs_final-lifnr.
        gs_final-vendor_name  = gs_final-vendor_name.
        gs_final-werks        = gs_final-werks.

        IF im_action = 'creatergpout' OR im_action = 'changergpout'.

          IF im_action = 'creatergpout'.
            gs_final-rgpout_num   = rgp_num.
          ELSEIF im_action = 'changergpout'.
            gs_final-rgpout_num = gs_final-rgpout_num .
            gs_final-shortclose = gs_final-shortclose. "added shortclosure
          ENDIF.
          gs_final-rgpout_year          = lv_fis_year. "sys_date+0(4).
          gs_final-gross_wgt            = gs_final-gross_wgt.
          gs_final-tare_wgt             = gs_final-tare_wgt.
          gs_final-net_wgt              = gs_final-net_wgt.
          gs_final-tot_val              = gs_final-tot_val.
          gs_final-grand_tot            = gs_final-grand_tot.
          gs_final-driver_num           = gs_final-driver_num.
          gs_final-driver_name          = gs_final-driver_name.
          gs_final-purpose              = gs_final-purpose.
          gs_final-rgpout_creationdate  = sys_date.
          gs_final-requestedby          = gs_final-requestedby.
          gs_final-through              = gs_final-through.
          gs_final-remarks              = gs_final-remarks.
          gs_final-vehiout_date         = gs_final-vehiout_date.
          gs_final-vehiout_time         =  gs_final-vehiout_time.
          gs_final-vechnum              = gs_final-vechnum.
          gs_final-exp_returndate       = gs_final-exp_returndate.
          gs_final-address              = gs_final-address.
          gs_final-state                = gs_final-state.
          gs_final-city                 = gs_final-city.
          gs_final-gstin                = gs_final-gstin.
**          gs_final-erdat        = sys_date.
          gs_final-pan                  = gs_final-pan.
          gs_final-contact              = gs_final-contact.
          gs_final-created_on           = sys_date.
          gs_final-created_time         = sys_time.
          gs_final-changed_on           = sys_date.
          gs_final-changed_time         = sys_time.
        ELSEIF im_action = 'creatergpin' OR im_action = 'changergpin'.

          IF im_action = 'changergpin'.
            rgpin_num = gs_final-rgpin_num.
          ENDIF.
          SHIFT rgpin_num LEFT DELETING LEADING '0'.

          gs_final-rgpout_num      = gs_final-rgpout_num.
          gs_final-rgpin_year      = lv_fis_year. "sys_date+0(4).

          SELECT SINGLE rgpout_creationdate FROM zmm_rgp_data
                     WHERE rgpout_num = @gs_final-rgpout_num AND rgpoutdeleted = @abap_false
                     INTO @gs_final-rgpout_creationdate. "#EC CI_ALL_FIELDS_NEEDED

          SHIFT rgpin_num LEFT DELETING LEADING '0'.
          IF im_action = 'creatergpin'.
            gs_final-rgpin_num       = rgpin_num.
          ELSEIF im_action = 'changergpin'.
            gs_final-rgpin_num  = gs_final-rgpin_num .
          ENDIF.
          gs_final-rgpin_creationdate  =  gs_final-rgpin_creationdate.
          gs_final-ringross_wgt    = gs_final-ringross_wgt.
          gs_final-rintare_wgt     = gs_final-rintare_wgt.
          gs_final-rinnet_wgt      = gs_final-rinnet_wgt.
          gs_final-rindriver_num   = gs_final-rindriver_num.
          gs_final-rindriver_name  = gs_final-rindriver_name.
          gs_final-rinpurpose      = gs_final-rinpurpose.
          gs_final-rinrequestedby  = gs_final-rinrequestedby.
          gs_final-rinthrough      = gs_final-rinthrough.
          gs_final-rinremarks      = gs_final-rinremarks.
          gs_final-rgpin_date      = gs_final-rgpin_date.
          gs_final-rgpin_time      = gs_final-rgpin_time .
          gs_final-rinvechnum      = gs_final-rinvechnum.
          gs_final-rinvechout      = gs_final-rinvechout.
          gs_final-invno      = gs_final-invno.
          gs_final-invdt      = gs_final-invdt.
        ENDIF.

        LOOP AT xs_gedata-rgp_item INTO DATA(xs_rgp_item).
          MOVE-CORRESPONDING xs_rgp_item TO gs_final.
          gs_final-prnum  = xs_rgp_item-prnum.
          gs_final-pritem = xs_rgp_item-pritem.

          IF im_action = 'creatergpin' OR im_action = 'changergpin'.
            gs_final-balqty = xs_rgp_item-prqty - xs_rgp_item-recqty.
          ENDIF.

          APPEND gs_final TO gt_final.
        ENDLOOP.

      ENDLOOP.

      IF im_action = 'createnrgp' OR im_action = 'changenrgp'.
        CLEAR: xs_gedata,xs_rgp_item.

        LOOP AT xt_gedata INTO xs_gedata.

          MOVE-CORRESPONDING xs_gedata TO gs_final1.

          IF im_action = 'changenrgp'.
            nrgp_num = gs_final1-nrgp_num.
          ENDIF.

          gs_final1-lifnr        = gs_final1-lifnr.
          gs_final1-vendor_name  = gs_final1-vendor_name.
          gs_final1-werks        = gs_final1-werks.

          SHIFT nrgp_num LEFT DELETING LEADING '0'.
          gs_final1-nrgp_num             = nrgp_num.
          gs_final1-nrgp_year            = lv_fis_year. "sys_date+0(4).
          gs_final1-gross_wgt            = gs_final1-gross_wgt.
          gs_final1-tare_wgt             = gs_final1-tare_wgt.
          gs_final1-net_wgt              = gs_final1-net_wgt.
          gs_final1-tot_val              = gs_final1-tot_val.
          gs_final1-grand_tot            = gs_final1-grand_tot.
          gs_final1-driver_num           = gs_final1-driver_num.
          gs_final1-driver_name          = gs_final1-driver_name.
          gs_final1-purpose              = gs_final1-purpose.
          gs_final1-nrgp_creationdate    = sys_date.
          gs_final1-requestedby          = gs_final1-requestedby.
          gs_final1-through              = gs_final1-through.
          gs_final1-remarks              = gs_final1-remarks.
          gs_final1-vehiout_date         = gs_final1-vehiout_date.
          gs_final1-vehiout_time         =  gs_final1-vehiout_time.
          gs_final1-vechnum              = gs_final1-vechnum.
          gs_final1-exp_returndate       = gs_final1-exp_returndate.
          gs_final-address               = gs_final-address.
          gs_final-state                 = gs_final-state.
          gs_final-city                  = gs_final-city.
          gs_final-gstin                 = gs_final-gstin.
**          gs_final-erdat        = sys_date.
          gs_final-pan                   = gs_final-pan.
          gs_final-contact               = gs_final-contact.
**          gs_final1-erdat        = sys_date.
          gs_final1-uzeit                 = sys_time.
          gs_final1-uname                 = sys_uname.
          gs_final1-created_on            = sys_date.
          gs_final1-created_time          = sys_time.
          gs_final1-changed_on            = sys_date.
          gs_final1-changed_time          = sys_time.

          LOOP AT xs_gedata-rgp_item INTO xs_rgp_item.
            MOVE-CORRESPONDING xs_rgp_item TO gs_final1.
            gs_final1-prnum  = xs_rgp_item-prnum.
            gs_final1-pritem = xs_rgp_item-pritem.

            APPEND gs_final1 TO gt_final1.
          ENDLOOP.

        ENDLOOP.
      ENDIF.

      IF gt_final1[] IS NOT INITIAL.
        IF im_action = 'createnrgp'.
          INSERT zmm_nrgp_data FROM TABLE @gt_final1.
          IF sy-subrc EQ 0.

            CONCATENATE 'NRGP OUT number' nrgp_num 'generated successfully' INTO rv_rgp_num SEPARATED BY space ##NO_TEXT.
          ENDIF.

        ELSEIF im_action = 'changenrgp'.

          DATA:
            lv_index TYPE sy-tabix.

          DELETE FROM zmm_nrgp_data WHERE nrgp_num = ''.
          SELECT * FROM zmm_nrgp_data
                   WHERE nrgp_num = @gs_final1-nrgp_num AND nrgpdeleted = @abap_false AND mblnr NE ''
                   INTO TABLE @DATA(lt_nrgp_data). "#EC CI_ALL_FIELDS_NEEDED

          IF lt_nrgp_data[] IS INITIAL.
            MODIFY zmm_nrgp_data FROM TABLE @gt_final1.
            IF sy-subrc EQ 0.
              CONCATENATE 'NRGP number' nrgp_num 'updated successfully' INTO rv_rgp_num SEPARATED BY space ##NO_TEXT.
            ENDIF.
****              ENDIF.

          ENDIF.
        ENDIF.

      ELSEIF gt_final[] IS NOT INITIAL.

        IF im_action = 'creatergpout'.


          INSERT zmm_rgp_data FROM TABLE @gt_final.
          IF sy-subrc EQ 0.
            CONCATENATE 'RGP OUT number' rgp_num 'generated successfully' INTO rv_rgp_num SEPARATED BY space ##NO_TEXT.
          ENDIF.

        ELSEIF im_action = 'changergpout'.


          DELETE FROM zmm_rgp_data WHERE rgpout_num = ''.
          " --- START OF AUTO CLOSE LOGIC ---
**          LOOP AT gt_final INTO DATA(ls_nrgp_close).
**            " If it's Non-Returnable, we assume the PR is consumed immediately
**            IF ls_nrgp_close-prnum IS NOT INITIAL.
**              me->close_pr_line(
**              iv_prnum   = ls_nrgp_close-prnum
**              iv_pritem  = ls_nrgp_close-pritem
**              ).
**            ENDIF.
**          ENDLOOP.

          SELECT * FROM zmm_rgp_data
                   WHERE rgpout_num = @gs_final-rgpout_num AND rgpoutdeleted = @abap_false AND mblnr NE ''
                   INTO TABLE @DATA(lt_ge_data). "#EC CI_ALL_FIELDS_NEEDED

          IF lt_ge_data[] IS INITIAL.

            MODIFY zmm_rgp_data FROM TABLE @gt_final.
            IF sy-subrc EQ 0.
              CONCATENATE 'RGP OUT number' rgp_num 'updated successfully' INTO rv_rgp_num SEPARATED BY space ##NO_TEXT.
            ENDIF.
****              ENDIF.

          ENDIF.
        ENDIF.
        IF im_action = 'creatergpin'.

          INSERT zmm_rgp_data FROM TABLE @gt_final.
          IF sy-subrc EQ 0.
            CONCATENATE 'RGP IN number' rgpin_num 'generated successfully' INTO rv_rgp_num SEPARATED BY space ##NO_TEXT.
          ENDIF.

        ELSEIF im_action = 'changergpin'.
          DELETE FROM zmm_rgp_data WHERE rgpin_num = ''.
          SELECT * FROM zmm_rgp_data
                   WHERE rgpin_num = @gs_final-rgpin_num AND rgpindeleted = @abap_false AND mblnr NE ''
                   INTO TABLE @lt_ge_data.    "#EC CI_ALL_FIELDS_NEEDED

          IF lt_ge_data[] IS INITIAL.

            MODIFY zmm_rgp_data FROM TABLE @gt_final.
            IF sy-subrc EQ 0.
              CONCATENATE 'RGP in number' rgpin_num 'updated successfully' INTO rv_rgp_num SEPARATED BY space ##NO_TEXT.
            ENDIF.
*****              ENDIF.
          ENDIF.
        ENDIF.

      ELSEIF gt_final[] IS INITIAL AND im_action = 'changergpout'.

        CLEAR: xs_gedata, xs_rgp_item.

        " Prepare the header data for the check
        READ TABLE xt_gedata INTO xs_gedata INDEX 1.
        IF sy-subrc <> 0. RETURN. ENDIF.
        MOVE-CORRESPONDING xs_gedata TO gs_final.

        " 1. Select ONLY existing records for this RGP Number
        SELECT * FROM zmm_rgp_data
          WHERE rgpout_num = @gs_final-rgpout_num
          INTO TABLE @DATA(lt_existing_rgp).

        IF sy-subrc = 0.
          " 2. Check if any record is already short-closed to prevent duplicate work
          IF line_exists( lt_existing_rgp[ shortclose = 'X' ] ).
            rv_rgp_num = |RGP OUT number { gs_final-rgpout_num } already shortclosed|.
            RETURN.
          ENDIF.

          " 3. Loop through existing records to update status and trigger PR closure
          LOOP AT lt_existing_rgp ASSIGNING FIELD-SYMBOL(<fs_rgp>).
            <fs_rgp>-shortclose   = 'X'.
            <fs_rgp>-changed_on   = sys_date.
            <fs_rgp>-changed_time = sys_time.

          ENDLOOP.

          " 5. Use UPDATE instead of MODIFY to ensure NO new rows are created
          " This only updates rows where the primary key already exists
          UPDATE zmm_rgp_data FROM TABLE @lt_existing_rgp.

          IF sy-subrc = 0.
            rv_rgp_num = |RGP OUT number { gs_final-rgpout_num } shortclosed successfully|.
          ENDIF.

**        ELSE.
**          " No existing record found for this RGP Number
**          rv_rgp_num = |Error: RGP OUT { gs_final-rgpout_num } does not exist|.
        ENDIF.

      ENDIF.


    ENDIF.

  ENDMETHOD.
ENDCLASS.
