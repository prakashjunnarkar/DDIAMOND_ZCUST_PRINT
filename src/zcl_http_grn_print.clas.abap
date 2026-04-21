CLASS zcl_http_grn_print DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    DATA: xt_final        TYPE TABLE OF zi_sale_reg,
          ls_xml_base64   TYPE string,
          lv_access_token TYPE string.

    DATA: lv_mblnr      TYPE c LENGTH 10,
          lv_gjahr      TYPE zi_dc_note-FiscalYear,
          rv_response   TYPE string,
          rv_resp_signd TYPE string,
          lv_action     TYPE c LENGTH 10.

    DATA: lo_client TYPE REF TO zcl_mm_custom_print,
          lo_ads    TYPE REF TO zcl_ads_service.

    INTERFACES if_http_service_extension .

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS ZCL_HTTP_GRN_PRINT IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.

    DATA:
      xt_final TYPE TABLE OF zstr_grn_data.

    ""**Get input Data
    DATA(lt_input) = request->get_form_fields( ).

    READ TABLE lt_input INTO DATA(ls_action) WITH KEY name = 'actionname'.
    IF sy-subrc EQ 0.
      lv_action = ls_action-value.
    ENDIF.

    READ TABLE lt_input INTO DATA(ls_input) WITH KEY name = 'materialdocument'.
    IF sy-subrc EQ 0.
      lv_mblnr = ls_input-value.
    ENDIF.

    lv_mblnr = |{ lv_mblnr ALPHA = IN }| .

    CLEAR: ls_input.
    READ TABLE lt_input INTO ls_input WITH KEY name = 'grndate'.
    IF sy-subrc EQ 0.
      lv_gjahr = ls_input-value.
    ENDIF.

    "********Creation of object**************
    CREATE OBJECT lo_client.
    CREATE OBJECT lo_ads.

    DATA:
      lv_resp_new TYPE string.

    ""*****Calling Methods to get PDF code base64
    lv_access_token = lo_ads->get_ads_access_token(  ).

    IF lv_action = 'siplgrn'.

      xt_final      = lo_client->get_grn_data( iv_mblnr = lv_mblnr iv_gjahr = lv_gjahr iv_action = lv_action ).



      ls_xml_base64 = lo_client->prep_xml_grn_print( it_final = xt_final[] iv_action = lv_action ).

      rv_response = lo_ads->get_ads_api_toget_base64(
        im_access_token  = lv_access_token
        im_template_name = 'ZMM_FORM_GRN/ZMM_DDMND_GRN_PRINT'
        im_xml_base64    = ls_xml_base64 ).

    ENDIF.


    IF lv_action = 'rtpprint'.

      xt_final      = lo_client->get_grn_data( iv_mblnr = lv_mblnr iv_gjahr = lv_gjahr iv_action = lv_action ).



      ls_xml_base64 = lo_client->prep_xml_grn_print( it_final = xt_final[] iv_action = lv_action ).

      rv_response = lo_ads->get_ads_api_toget_base64(
        im_access_token  = lv_access_token
        im_template_name = 'ZMM_FORM_RTP/ZMM_DDMND_RTP_PRINT'
        im_xml_base64    = ls_xml_base64 ).

    ENDIF.

    IF lv_action = 'misprint'. "Material Issue Slip Print

      xt_final      = lo_client->get_grn_data( iv_mblnr = lv_mblnr iv_gjahr = lv_gjahr iv_action = lv_action ).
      ls_xml_base64 = lo_client->prep_xml_grn_print( it_final = xt_final[] iv_action = lv_action ).

      rv_response = lo_ads->get_ads_api_toget_base64(
        im_access_token  = lv_access_token
        im_template_name = 'ZMM_FORM_ISSUE_SLIP/ZMM_DDMND_ISSUE_SLIP_PRINT'
        im_xml_base64    = ls_xml_base64 ).

   ENDIF.

    ""**Setiing response/pdf in base64 format to UI5
    response->set_text(
      EXPORTING
        i_text = rv_response ).

  ENDMETHOD.
ENDCLASS.
