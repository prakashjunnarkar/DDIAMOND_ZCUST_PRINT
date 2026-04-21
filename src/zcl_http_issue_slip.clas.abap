class ZCL_HTTP_ISSUE_SLIP definition
  public
  create public .

public section.

    DATA: ls_xml_base64   TYPE string,
          lv_access_token TYPE string.

    DATA: lv_rsnum TYPE C LENGTH 10,
          lv_rsdat TYPE ZI_ISSUE_SLIP-ReservationDate,
          lv_nrsdat TYPE C LENGTH 10,
          rv_response   TYPE string,
          rv_resp_signd TYPE string,
          lv_action     TYPE C LENGTH 10.

    DATA: lo_client TYPE REF TO zcl_mm_custom_print,
          lo_ads    TYPE REF TO zcl_ads_service.

  interfaces IF_HTTP_SERVICE_EXTENSION .
protected section.
private section.
ENDCLASS.



CLASS ZCL_HTTP_ISSUE_SLIP IMPLEMENTATION.


  method IF_HTTP_SERVICE_EXTENSION~HANDLE_REQUEST.

    DATA:
      xt_final TYPE TABLE OF zstr_issue_slip.

    ""**Get input Data
    DATA(lt_input) = request->get_form_fields( ).

    READ TABLE lt_input INTO DATA(ls_action) WITH KEY name = 'actionname'.
    IF sy-subrc EQ 0.
      lv_action = ls_action-value.
    ENDIF.

    READ TABLE lt_input INTO DATA(ls_input) WITH KEY name = 'rsnum'.
    IF sy-subrc EQ 0.
      lv_rsnum = ls_input-value.
    ENDIF.

    lv_rsnum = |{ lv_rsnum ALPHA = IN }| .

    CLEAR: ls_input.
    READ TABLE lt_input INTO ls_input WITH KEY name = 'rsdate'.
    IF sy-subrc EQ 0.
      lv_nrsdat = ls_input-value.
      lv_rsdat  = lv_nrsdat+0(4) && lv_nrsdat+5(2) && lv_nrsdat+8(2).
    ENDIF.

    CREATE OBJECT lo_client.
    CREATE OBJECT lo_ads.

    DATA:
      lv_resp_new TYPE string.

    ""*****Calling Methods to get PDF code base64
    lv_access_token = lo_ads->get_ads_access_token(  ).

    IF lv_action = 'reserv'.

      xt_final      = lo_client->get_resb_data( iv_rsnum = lv_rsnum iv_rsdat = lv_rsdat iv_action = lv_action ).

      ls_xml_base64 = lo_client->prep_xml_issue_slip_print( it_final = xt_final[] iv_action = lv_action ).

      rv_response = lo_ads->get_ads_api_toget_base64(
        im_access_token  = lv_access_token
        im_template_name = 'ZMM_FORM_ISSUE_SLIP/ZMM_DDMND_ISSUE_SLIP_PRINT'
        im_xml_base64    = ls_xml_base64 ).

   ENDIF.


    ""**Setiing response/pdf in base64 format to UI5
    response->set_text(
      EXPORTING
        i_text = rv_response ).

  endmethod.
ENDCLASS.
