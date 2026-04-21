CLASS zcl_http_pp_print DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_service_extension .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_HTTP_PP_PRINT IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.

    DATA: lo_client       TYPE REF TO zcl_custom_pp_print,
          miw_string      TYPE string,
          xt_final        TYPE TABLE OF zstr_insplot_print_hdr,
          xt_final_prod   TYPE TABLE OF zstr_pp_prod_hdr,
          xt_final_joblot TYPE TABLE OF zstr_pp_joblot_hdr,
          ls_xml_base64   TYPE string,
          lv_access_token TYPE string,
          lv_action       TYPE c LENGTH 10,
          lv_lotnum       TYPE zi_lot_print_data-InspectionLot,
          lv_pord         TYPE c LENGTH 12,
          lv_plant        TYPE c LENGTH 4,
          lo_ads          TYPE REF TO zcl_ads_service,
          rv_response     TYPE string,
          lv_selradio     TYPE c LENGTH 120,
          ls_sel_scr      TYPE zstr_lot_print_sel.

    ""**Get input Data
    DATA(lt_input) = request->get_form_fields( ).

    READ TABLE lt_input INTO DATA(ls_action) WITH KEY name = 'actionname'.
    IF sy-subrc EQ 0.
      lv_action = ls_action-value.
    ENDIF.

    READ TABLE lt_input INTO DATA(ls_input) WITH KEY name = 'inspectionlot'.
    IF sy-subrc EQ 0.
      lv_lotnum = ls_input-value.
    ENDIF.
    lv_lotnum = |{ lv_lotnum ALPHA = IN }| .

    CLEAR: ls_input.
    READ TABLE lt_input INTO ls_input WITH KEY name = 'productionodr'.
    IF sy-subrc EQ 0.
      lv_pord  = ls_input-value.
    ENDIF.
    lv_pord  = |{ lv_pord  ALPHA = IN }| .

    CLEAR: ls_input.
    READ TABLE lt_input INTO ls_input WITH KEY name = 'plant'.
    IF sy-subrc EQ 0.
      lv_pord  = ls_input-value.
    ENDIF.

    CLEAR: ls_input.
    READ TABLE lt_input INTO ls_input WITH KEY name = 'selectedradiobtn' ##NO_TEXT.
    IF sy-subrc EQ 0.

      lv_selradio = ls_input-value.
      CONDENSE lv_selradio.

      IF lv_selradio = 'New Development' ##NO_TEXT.
        ls_sel_scr-r_new_devlmnt = 'OK' ##NO_TEXT.
      ELSEIF lv_selradio = 'Receiving Inspection' ##NO_TEXT.
        ls_sel_scr-r_recvng_insp = 'OK' ##NO_TEXT.
      ELSEIF lv_selradio = 'Design Change' ##NO_TEXT.
        ls_sel_scr-r_design_chng = 'OK' ##NO_TEXT.
      ELSEIF lv_selradio = 'Tooling Change' ##NO_TEXT.
        ls_sel_scr-r_tooling_chng = 'OK' ##NO_TEXT.
      ENDIF.

    ENDIF.

    CLEAR: ls_input.
    READ TABLE lt_input INTO ls_input WITH KEY name = 'remark' ##NO_TEXT.
    IF sy-subrc EQ 0.
      ls_sel_scr-remark = ls_input-value.
    ENDIF.

    CREATE OBJECT lo_client.
    CREATE OBJECT lo_ads.

    lv_access_token = lo_ads->get_ads_access_token(  ).

    IF lv_action = 'qltyprint'.

      xt_final[]  = lo_client->get_insplot_data( im_lotnum = lv_lotnum im_sel_scr = ls_sel_scr ).

      ls_xml_base64 = lo_client->prep_xml_insplot_print( it_final = xt_final[] iv_action = lv_action ).

      rv_response = lo_ads->get_ads_api_toget_base64(
        im_access_token  = lv_access_token
        im_template_name = 'ZPP_FORM_INSPLOT/ZPP_OEL_INSPLOT_PRINT'
        im_xml_base64    = ls_xml_base64 ).

    ENDIF.

    IF lv_action = 'pordprint'.

      xt_final_prod[]  = lo_client->get_production_data( im_pord = lv_pord im_plant = lv_plant ).

      ls_xml_base64 = lo_client->prep_xml_prod_print( it_final = xt_final_prod[] iv_action = lv_action ).

      rv_response = lo_ads->get_ads_api_toget_base64(
        im_access_token  = lv_access_token
        im_template_name = 'ZPP_FORM_PRODUCTION_ORDER/ZPP_OEL_PRODUCTION_ORDER'
        im_xml_base64    = ls_xml_base64 ).

    ENDIF.

    IF lv_action = 'lotjbprint'.

      xt_final_joblot[]  = lo_client->get_joblot_data( im_pord = lv_pord im_plant = lv_plant ).

      ls_xml_base64 = lo_client->prep_xml_joblot_print( it_final = xt_final_joblot[] iv_action = lv_action ).

      rv_response = lo_ads->get_ads_api_toget_base64(
        im_access_token  = lv_access_token
        im_template_name = 'ZPP_FORM_LOT_JOB/ZPP_OEL_LOT_JOB'
        im_xml_base64    = ls_xml_base64 ).

    ENDIF.

    ""**Setiing response/pdf in base64 format to UI5
    response->set_text(
      EXPORTING
        i_text = rv_response ).

  ENDMETHOD.
ENDCLASS.
