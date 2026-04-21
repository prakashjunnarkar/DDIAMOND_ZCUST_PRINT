CLASS zcl_packing_list DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    DATA: gt_item  TYPE TABLE OF zstr_pack_item,
          gs_item  LIKE LINE OF gt_item,
          gt_pack  TYPE TABLE OF zstr_pack_data,
          gs_pack  TYPE zstr_pack_data,
          gt_final TYPE TABLE OF zsd_pack_data,
          gs_final TYPE zsd_pack_data.

    DATA : lv_char10 TYPE c LENGTH 10 .
    DATA : lv_char20 TYPE c LENGTH 20 .
    DATA : lv_char120 TYPE c LENGTH 120 .

    DATA:
      sys_date     TYPE d  , " VALUE cl_abap_context_info ,
      sys_time     TYPE t  , "  VALUE  cl_abap_context_info=>get_system_time( 8,0 ),
      sys_timezone TYPE timezone,
      sy_uname     TYPE c LENGTH 20.

    METHODS:
      get_delivery_data
        IMPORTING
                  im_vbeln1      LIKE lv_char10
                  im_vbeln2      LIKE lv_char10
        RETURNING VALUE(et_item) LIKE gt_item,

      save_data_get_packnum
        IMPORTING
                  xt_pack            LIKE gt_pack
                  im_action          LIKE lv_char10
        RETURNING VALUE(rv_pack_num) LIKE lv_char120,

      get_pack_change_data
        IMPORTING
                  im_packnum     LIKE lv_char10
        RETURNING VALUE(et_pack) LIKE gt_pack.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS ZCL_PACKING_LIST IMPLEMENTATION.


  METHOD get_delivery_data.

    DATA:
      r_vbeln   TYPE RANGE OF I_DeliveryDocumentItem-DeliveryDocument,
      wr_vbeln  LIKE LINE OF r_vbeln,
      lv_vbeln1 TYPE c LENGTH 10,
      lv_vbeln2 TYPE c LENGTH 10.


    sys_date = cl_abap_context_info=>get_system_date( ).
    sys_time = cl_abap_context_info=>get_system_time( ).
    sy_uname = cl_abap_context_info=>get_user_technical_name( ).

    lv_vbeln1 = im_vbeln1.
    lv_vbeln2 = im_vbeln2.

    IF lv_vbeln2 IS INITIAL.
      lv_vbeln2 = lv_vbeln1.
    ENDIF.

    wr_vbeln-low  = lv_vbeln1.
    wr_vbeln-high = lv_vbeln2.
    wr_vbeln-sign = 'I'.
    wr_vbeln-option = 'BT'.
    APPEND wr_vbeln TO r_vbeln.

*    SELECT * FROM zi_delivery_data WHERE DeliveryDocument IN @r_vbeln INTO TABLE @DATA(lt_delv).
*    DATA(xt_delv) = lt_delv[].
*
*    IF lt_delv[] IS NOT INITIAL.
*      LOOP AT lt_delv INTO DATA(ls_delv).
*        gs_item-vbeln        = ls_delv-DeliveryDocument.
*        gs_item-posnr        = ls_delv-DeliveryDocumentItem.
*        gs_item-matnr        = ls_delv-Material.
*        gs_item-kdmat        = ls_delv-MaterialByCustomer.
*        gs_item-lfimg        = ls_delv-ActualDeliveryQuantity.
*        gs_item-pallet_no    = ''.
*        gs_item-type_pkg     = ''.
*        gs_item-pkg_no       = ''.
*        gs_item-pkg_length   = ''.
*        gs_item-pkg_width    = ''.
*        gs_item-pkg_height   = ''.
*        gs_item-pkg_vol      = ls_delv-ItemVolume.
*        gs_item-uom          = ls_delv-BaseUnit.
*        APPEND gs_item TO gt_item.
*      ENDLOOP.
*    ENDIF.

    SELECT * FROM zi_sale_reg WHERE BillingDocument IN @r_vbeln INTO TABLE @DATA(lt_delv).
    DATA(xt_delv) = lt_delv[].

    IF lt_delv[] IS NOT INITIAL.
      LOOP AT lt_delv INTO DATA(ls_delv).

        gs_item-vbeln        = ls_delv-BillingDocument.         "ls_delv-DeliveryDocument.
        gs_item-posnr        = ls_delv-BillingDocumentItem.     "ls_delv-DeliveryDocumentItem.

        gs_item-matnr        = ls_delv-ProductOldID.            "ls_delv-Material., ls_delv-product.

        IF ls_delv-MaterialByCustomer IS NOT INITIAL.
          gs_item-kdmat        = ls_delv-MaterialByCustomer.      "ls_delv-MaterialByCustomer.
        ELSE.
          gs_item-kdmat        = ls_delv-Product.
        ENDIF.

*        SELECT SINGLE * FROM I_ProductText WHERE Product  = @gs_item-matnr AND
*                                                 Language = 'E'
*                                           INTO @DATA(ls_makt).

        gs_item-maktx        = ls_delv-BillingDocumentItemText. "ls_makt-ProductName.
        gs_item-lfimg        = ls_delv-BillingQuantity.         "ls_delv-ActualDeliveryQuantity.
        gs_item-pallet_no    = ''.
        gs_item-type_pkg     = ''.
        gs_item-pkg_no       = ''.
        gs_item-pkg_length   = ''.
        gs_item-pkg_width    = ''.
        gs_item-pkg_height   = ''.
        gs_item-pkg_vol      = ls_delv-NetWeight.
        gs_item-uom          = ls_delv-BaseUnit.    "ls_delv-BaseUnit.
        APPEND gs_item TO gt_item.
      ENDLOOP.
    ENDIF.

    SORT gt_item BY vbeln posnr.
    et_item[] = gt_item[].

  ENDMETHOD.


  METHOD get_pack_change_data.

    DATA:
      gt_final  TYPE TABLE OF zstr_pack_data,
      gs_final  TYPE zstr_pack_data,
      gs_item   TYPE zstr_pack_item,
      pack_item TYPE TABLE OF zstr_pack_item.

    SELECT * FROM zsd_pack_data WHERE pack_num = @im_packnum
             INTO TABLE @DATA(gt_pack).

    DATA(gt_pitem) = gt_pack[].
    SORT gt_pack BY pack_num.
    DELETE ADJACENT DUPLICATES FROM gt_pack COMPARING pack_num.

    LOOP AT gt_pack INTO DATA(gs_pack).

      MOVE-CORRESPONDING gs_pack TO gs_final.

      LOOP AT gt_pitem INTO DATA(gs_pitem) WHERE pack_num = gs_pack-pack_num.

        MOVE-CORRESPONDING gs_pitem TO gs_item.
        APPEND gs_item TO pack_item.

      ENDLOOP.

      INSERT LINES OF pack_item INTO TABLE gs_final-pack_item.
      APPEND gs_final TO et_pack.

    ENDLOOP.

  ENDMETHOD.


  METHOD save_data_get_packnum.

    DATA:
      lv_index TYPE sy-tabix.

    IF xt_pack[] IS NOT INITIAL.

      IF im_action = 'create'.

        TRY.

            CALL METHOD cl_numberrange_runtime=>number_get
              EXPORTING
                nr_range_nr = '01'
                object      = 'ZPACK_NUM'
              IMPORTING
                number      = DATA(pack_num)
                returncode  = DATA(rcode).
          CATCH cx_nr_object_not_found ##NO_HANDLER.
          CATCH cx_number_ranges ##NO_HANDLER.
        ENDTRY.

      ENDIF.

      sys_date = cl_abap_context_info=>get_system_date( ).
      sys_time = cl_abap_context_info=>get_system_time( ).
      sy_uname = cl_abap_context_info=>get_user_technical_name( ).

      LOOP AT xt_pack INTO DATA(xs_pack).
        MOVE-CORRESPONDING xs_pack TO gs_final.
        IF im_action = 'change'.
          pack_num = gs_final-pack_num.
        ENDIF.
        SHIFT pack_num LEFT DELETING LEADING '0'.
        gs_final-pack_num   = pack_num.
        gs_final-erdate   = sys_date . """ CL_ABAP_CONTEXT_INFO=>get_system_date( ) .
        gs_final-uzeit    = sys_time . """ CL_ABAP_CONTEXT_INFO=>get_system_time( ) .
        gs_final-uname    = sy-uname.
        LOOP AT xs_pack-pack_item INTO DATA(xs_pack_item).
          lv_index = lv_index + 1.
          MOVE-CORRESPONDING xs_pack_item TO gs_final.
          gs_final-pack_posnr = lv_index.
          APPEND gs_final TO gt_final.
        ENDLOOP.
      ENDLOOP.

      IF gt_final[] IS NOT INITIAL.

        IF im_action = 'create'.

          INSERT zsd_pack_data FROM TABLE @gt_final.
          IF sy-subrc EQ 0.
            CONCATENATE 'Packing number' pack_num 'generated successfully' INTO rv_pack_num SEPARATED BY space ##NO_TEXT.
          ENDIF.

        ELSEIF im_action = 'change'.

          MODIFY zsd_pack_data FROM TABLE @gt_final.
          IF sy-subrc EQ 0.
            CONCATENATE 'Packing number' pack_num 'updated successfully' INTO rv_pack_num SEPARATED BY space ##NO_TEXT.
          ENDIF.

        ENDIF.

      ENDIF.

    ENDIF.

  ENDMETHOD.
ENDCLASS.
