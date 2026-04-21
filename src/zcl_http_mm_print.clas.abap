class ZCL_HTTP_MM_PRINT definition
  public
  create public .

public section.

    DATA: xt_final        TYPE TABLE OF zstr_schd_line_print,
          ls_xml_base64   TYPE string,
          lv_access_token TYPE string.

    DATA: lv_ebeln      TYPE c LENGTH 10,
          lv_date       TYPE c LENGTH 10,
          rv_response   TYPE string,
          rv_resp_signd TYPE string,
          lv_action     TYPE c LENGTH 10.

    DATA: lo_client TYPE REF TO YCL_MM_PROG,
          lo_ads    TYPE REF TO zcl_ads_service.


  interfaces IF_HTTP_SERVICE_EXTENSION .

protected section.
private section.
ENDCLASS.



CLASS ZCL_HTTP_MM_PRINT IMPLEMENTATION.


  method IF_HTTP_SERVICE_EXTENSION~HANDLE_REQUEST.

    ""**Get input Data
    DATA(lt_input) = request->get_form_fields( ).

    READ TABLE lt_input INTO DATA(ls_action) WITH KEY name = 'actionname'.
    IF sy-subrc EQ 0.
      lv_action = ls_action-value.
    ENDIF.

    READ TABLE lt_input INTO DATA(ls_input) WITH KEY name = 'schedulingagreement'.
    IF sy-subrc EQ 0.
      lv_ebeln = ls_input-value.
    ENDIF.

    lv_ebeln = |{ lv_ebeln ALPHA = IN }| .

    CLEAR: ls_input.
    READ TABLE lt_input INTO ls_input WITH KEY name = 'schedulingagreementdate'.
    IF sy-subrc EQ 0.
      lv_date = ls_input-value.
    ENDIF.

    "********Creation of object**************
    CREATE OBJECT lo_client.
    CREATE OBJECT lo_ads.

    DATA:
      lv_resp_new TYPE string.

    ""*****Calling Methods to get PDF code base64
    lv_access_token = lo_ads->get_ads_access_token(  ).

    IF lv_action = 'schdlprint'.

      xt_final      = lo_client->get_sa_data( iv_ebeln = lv_ebeln iv_action = lv_action ).

      ls_xml_base64 = lo_client->prep_xml_schdl_print( it_final = xt_final[] iv_action = lv_action ).

        rv_response = lo_ads->get_ads_api_toget_base64(
        im_access_token  = lv_access_token
        im_template_name = 'ZMM_FORM_SCHDL/ZMM_MSVL_SASL_PRINT'
        im_xml_base64    = ls_xml_base64 ).

    ENDIF.

    ""**Setiing response/pdf in base64 format to UI5
    response->set_text(
      EXPORTING
        i_text = rv_response ).

  endmethod.
ENDCLASS.
