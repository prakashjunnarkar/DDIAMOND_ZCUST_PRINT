CLASS zcl_bom_detail DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA:
      xt_final TYPE TABLE OF zi_bom_report,
      gs_final TYPE zi_bom_report.

    METHODS:
      get_bom_data
        IMPORTING
                  im_input_str   TYPE string
        RETURNING VALUE(et_data) LIKE xt_final.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_BOM_DETAIL IMPLEMENTATION.


  METHOD get_bom_data.

    DATA:
      xt_final      TYPE TABLE OF zi_bom_report,
      xt_final_disp TYPE TABLE OF zi_bom_report,
      gs_final      TYPE zi_bom_report.

    DATA: lv_date         TYPE d,
          lv_explod_matnr TYPE C LENGTH 40.

    TYPES: BEGIN OF gty_mat,
             matnr_low TYPE C LENGTH 40,
           END OF gty_mat.

    TYPES: BEGIN OF gty_altbom,
             altbom_low TYPE C LENGTH 2,
           END OF gty_altbom.
    DATA:
      gt_alt TYPE TABLE OF gty_altbom,
      gs_alt TYPE gty_altbom,
      gt_mat TYPE TABLE OF gty_mat,
      gs_mat TYPE gty_mat.

    TYPES: BEGIN OF gty_input,
             matnr_high  TYPE C LENGTH 40,
             plant       TYPE C LENGTH 4,
             altbom_high TYPE C LENGTH 2,
             mat_low     LIKE gt_mat,
             alt_low     LIKE gt_alt,
           END OF gty_input.

    DATA:
      gt_input TYPE TABLE OF gty_input,
      gs_input TYPE gty_input.

    DATA : r_matnr  TYPE RANGE OF zi_bom_report-material,
           rw_matnr LIKE LINE OF  r_matnr,
           r_stlal  TYPE RANGE OF zi_bom_report-bomexplosionapplication,
           rw_stlal LIKE LINE OF r_stlal,
           lv_plant TYPE C LENGTH 4.

    /ui2/cl_json=>deserialize(
      EXPORTING json = im_input_str
         pretty_name = /ui2/cl_json=>pretty_mode-camel_case
         CHANGING data = gt_input
                                 ).

    IF gt_input[] IS NOT INITIAL.

      READ TABLE gt_input INTO gs_input INDEX 1.
      lv_plant = gs_input-plant.

      IF gs_input-matnr_high IS INITIAL.

        LOOP AT gs_input-mat_low INTO DATA(lss_matnr).

          rw_matnr-low     = lss_matnr-matnr_low.
          rw_matnr-high    = '' .
          rw_matnr-option  = 'EQ' .
          rw_matnr-sign    = 'I' .
          APPEND rw_matnr TO r_matnr.

          CLEAR: lss_matnr.
        ENDLOOP.

      ELSE.

        READ TABLE gs_input-mat_low INTO DATA(ls_matnr) INDEX 1.
        rw_matnr-low     = ls_matnr-matnr_low.
        rw_matnr-high    = gs_input-matnr_high.
        rw_matnr-option  = 'BT' .
        rw_matnr-sign    = 'I' .
        APPEND rw_matnr TO r_matnr.

      ENDIF.

      IF gs_input-altbom_high IS INITIAL.

        LOOP AT gs_input-alt_low INTO DATA(lss_alt).

          rw_stlal-low     = lss_alt-altbom_low.
          rw_stlal-high    = ''.
          rw_stlal-option  = 'EQ' .
          rw_stlal-sign    = 'I' .
          APPEND rw_stlal TO r_stlal.

          CLEAR: lss_alt.
        ENDLOOP.

      ELSE.

        READ TABLE gs_input-alt_low INTO DATA(ls_alt) INDEX 1.
        rw_stlal-low     = ls_alt-altbom_low.
        rw_stlal-high    = gs_input-altbom_high.
        rw_stlal-option  = 'BT' .
        rw_stlal-sign    = 'I' .
        APPEND rw_stlal TO r_stlal.

      ENDIF.

      DATA:
        sys_date     TYPE d.

      sys_date = cl_abap_context_info=>get_system_date( ).
      lv_date = sys_date.



      SELECT * FROM zi_bom_report( p_keydate = @lv_date )
               WHERE material IN @r_matnr AND
                     plant = @lv_plant AND
                     producttype EQ 'FERT'
               INTO TABLE @DATA(lt_bom_fert).

      IF lt_bom_fert[] IS NOT INITIAL.

        SELECT * FROM zi_bom_report( p_keydate = @lv_date )
                 INTO TABLE @DATA(lt_bom).

        READ TABLE lt_bom INTO DATA(ls_bom) INDEX 1. "#EC CI_NOORDER
        ls_bom-explod_matnr = ''.
        MODIFY lt_bom FROM ls_bom TRANSPORTING explod_matnr WHERE explod_matnr NE ''.

        DATA(lt_mat_fert) = lt_bom_fert[].
*     DELETE lt_mat_fert WHERE producttype NE 'FERT'.
        SORT lt_mat_fert BY material.
        DELETE ADJACENT DUPLICATES FROM lt_mat_fert COMPARING material.
*     DELETE lt_mat_fert WHERE material NE 'FGSTMT401100235'.

      ENDIF.

    ENDIF.

    "========================================================================"
    DATA: lv_index TYPE sy-tabix.
    LOOP AT lt_mat_fert INTO DATA(ls_mat_fert).

      CLEAR: xt_final.

      DATA(lt_mat_halb) = lt_bom[].
      DELETE lt_mat_halb WHERE material NE ls_mat_fert-material.
      SORT lt_mat_halb BY billofmaterialitemnumber.
      APPEND LINES OF lt_mat_halb TO xt_final.

      DELETE lt_mat_halb WHERE comp_producttype NE 'HALB'.

      LOOP AT lt_mat_halb INTO DATA(ls_mat_halb).
        lv_index = sy-tabix.

        DATA(lt_mat_halb_n) = lt_bom[].
        DELETE lt_mat_halb_n WHERE material NE ls_mat_halb-billofmaterialcomponent.
        SORT lt_mat_halb_n BY billofmaterialitemnumber.
        APPEND LINES OF lt_mat_halb_n TO xt_final.
        DELETE lt_mat_halb_n WHERE comp_producttype NE 'HALB'.

        IF lt_mat_halb_n[] IS NOT INITIAL.
          APPEND LINES OF lt_mat_halb_n TO lt_mat_halb.
        ENDIF.
        DELETE lt_mat_halb INDEX lv_index.
      ENDLOOP.

      IF xt_final[] IS NOT INITIAL.
        READ TABLE xt_final INTO DATA(ls_final) INDEX 1.
        ls_final-explod_matnr = ls_mat_fert-material.
        MODIFY xt_final FROM ls_final TRANSPORTING explod_matnr WHERE explod_matnr EQ ''.
        APPEND LINES OF xt_final TO xt_final_disp.
        CLEAR: xt_final.
      ENDIF.

    ENDLOOP.

    IF xt_final_disp[] IS NOT INITIAL.
      et_data[] = xt_final_disp[].
    ENDIF.

  ENDMETHOD.
ENDCLASS.
