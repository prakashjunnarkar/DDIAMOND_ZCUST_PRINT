CLASS zcl_http_fi_debit_note DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    DATA: xt_dbnote       TYPE TABLE OF zstr_fi_debit_note,
          xt_final        TYPE TABLE OF zstr_voucher_print,
          ls_xml_base64   TYPE string,
          lv_access_token TYPE string.

    DATA: lv_belnr      TYPE C LENGTH 10,
          lv_gjahr      TYPE zstr_fi_debit_note-fiscalyear,
          lv_bukrs      TYPE C LENGTH 4,
          lv_action1    TYPE C LENGTH 10,
          rv_response   TYPE string,
          rv_resp_signd TYPE string,
          lv_action     TYPE C LENGTH 10.

    DATA: lo_client TYPE REF TO zcl_fi_custom_print,
          lo_ads    TYPE REF TO zcl_ads_service.

    INTERFACES if_http_service_extension .

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS ZCL_HTTP_FI_DEBIT_NOTE IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.

    DATA(lt_input) = request->get_form_fields( ).

    READ TABLE lt_input INTO DATA(ls_action) WITH KEY name = 'actionname'.
    IF sy-subrc EQ 0.
      lv_action1 = ls_action-value.
    ENDIF.

    READ TABLE lt_input INTO DATA(ls_input) WITH KEY name = 'accountingdocument'.
    IF sy-subrc EQ 0.
      lv_belnr = ls_input-value.
    ENDIF.
    lv_belnr = |{ lv_belnr ALPHA = IN }| .

    CLEAR: ls_input.
    READ TABLE lt_input INTO ls_input WITH KEY name = 'companycode'.
    IF sy-subrc EQ 0.
      lv_bukrs = ls_input-value.
    ENDIF.

    CLEAR: ls_input.
    READ TABLE lt_input INTO ls_input WITH KEY name = 'fiscalyear'.
    IF sy-subrc EQ 0.
      lv_gjahr = ls_input-value.
    ENDIF.

    CREATE OBJECT lo_client.
    CREATE OBJECT lo_ads.

    IF lv_action1 = 'fidebit'.

      lv_access_token = lo_ads->get_ads_access_token(  ).

      lo_client->get_fidebit_data(
        EXPORTING
          im_bukrs  = lv_bukrs
          im_belnr  = lv_belnr
          im_gjahr  = lv_gjahr
          im_action = lv_action1
        RECEIVING
          et_dbdata =  xt_dbnote
      ).

      ls_xml_base64 = lo_client->prep_xml_fidebit( it_dbnote = xt_dbnote[] im_action = lv_action1 ).

      rv_response = lo_ads->get_ads_api_toget_base64(
        im_access_token  = lv_access_token
        im_template_name = 'ZFI_FORM_DEBIT_NOTE/ZFI_DDMND_DEBIT_NOTE'
        im_xml_base64    = ls_xml_base64 ).

*""**Setiing response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = rv_response ).

    ENDIF.

    IF lv_action1 = 'payadv'.

      lv_access_token = lo_ads->get_ads_access_token(  ).

      lo_client->get_payadv_data(
        EXPORTING
          im_bukrs  = lv_bukrs
          im_belnr  = lv_belnr
          im_gjahr  = lv_gjahr
          im_action = lv_action1
        RECEIVING
          et_payadv =  xt_dbnote
      ).

      ls_xml_base64 = lo_client->prep_xml_payadv( it_payadv = xt_dbnote[] im_action = lv_action1 ).

      rv_response = lo_ads->get_ads_api_toget_base64(
        im_access_token  = lv_access_token
        im_template_name = 'ZFI_FORM_PAY_ADV/ZFI_DDMND_PAY_ADV'
        im_xml_base64    = ls_xml_base64 ).

*""**Setiing response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = rv_response ).

    ENDIF.

    IF lv_action1 = 'chqprnt'.

      lv_access_token = lo_ads->get_ads_access_token(  ).

      lo_client->get_chqprnt_data(
        EXPORTING
          im_bukrs  = lv_bukrs
          im_belnr  = lv_belnr
          im_gjahr  = lv_gjahr
          im_action = lv_action1
        RECEIVING
          et_chqprnt =  xt_dbnote
      ).

      ls_xml_base64 = lo_client->prep_xml_chqprnt( it_chqprnt = xt_dbnote[] im_action = lv_action1 ).

      rv_response = lo_ads->get_ads_api_toget_base64(
        im_access_token  = lv_access_token
        im_template_name = 'ZFI_FORM_CHQ_PRINT/ZFI_DDMND_CHQ_PRINT'
        im_xml_base64    = ls_xml_base64 ).

*""**Setiing response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = rv_response ).

    ENDIF.

    IF lv_action1 = 'ficredit'.

      lv_access_token = lo_ads->get_ads_access_token(  ).

      lo_client->get_fidebit_data(
        EXPORTING
          im_bukrs  = lv_bukrs
          im_belnr  = lv_belnr
          im_gjahr  = lv_gjahr
          im_action = lv_action1
        RECEIVING
          et_dbdata =  xt_dbnote
      ).

      ls_xml_base64 = lo_client->prep_xml_fidebit( it_dbnote = xt_dbnote[] im_action = lv_action1 ).

      rv_response = lo_ads->get_ads_api_toget_base64(
        im_access_token  = lv_access_token
        im_template_name = 'ZFI_FORM_CREDIT_NOTE/ZFI_DDMND_CREDIT_NOTE'
        im_xml_base64    = ls_xml_base64 ).

*""**Setiing response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = rv_response ).

    ENDIF.

    IF lv_action1 = 'fitaxinv'.

      lv_access_token = lo_ads->get_ads_access_token(  ).

      lo_client->get_fidebit_data(
        EXPORTING
          im_bukrs  = lv_bukrs
          im_belnr  = lv_belnr
          im_gjahr  = lv_gjahr
          im_action = lv_action1
        RECEIVING
          et_dbdata =  xt_dbnote
      ).

      ls_xml_base64 = lo_client->prep_xml_fidebit( it_dbnote = xt_dbnote[] im_action = lv_action1 ).

      rv_response = lo_ads->get_ads_api_toget_base64(
        im_access_token  = lv_access_token
        im_template_name = 'ZFI_FORM_TAX_INVOICE/ZFI_DDMND_TAX_INV'
        im_xml_base64    = ls_xml_base64 ).

*""**Setiing response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = rv_response ).

    ENDIF.

    IF lv_action1 = 'fircm'.

      lv_access_token = lo_ads->get_ads_access_token(  ).

      lo_client->get_fidebit_data(
        EXPORTING
          im_bukrs  = lv_bukrs
          im_belnr  = lv_belnr
          im_gjahr  = lv_gjahr
          im_action = lv_action1
        RECEIVING
          et_dbdata =  xt_dbnote
      ).

      ls_xml_base64 = lo_client->prep_xml_fidebit( it_dbnote = xt_dbnote[] im_action = lv_action1 ).

      rv_response = lo_ads->get_ads_api_toget_base64(
        im_access_token  = lv_access_token
        im_template_name = 'ZFI_FORM_RCM/ZFI_DDMND_RCM_INVOICE'
        im_xml_base64    = ls_xml_base64 ).

      ""**Setiing response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = rv_response ).

    ENDIF.

    IF lv_action1 = 'vchprint'.

        lv_access_token = lo_ads->get_ads_access_token(  ).

        lo_client->get_voucher_data(
        EXPORTING
          im_bukrs  = lv_bukrs
          im_belnr  = lv_belnr
          im_gjahr  = lv_gjahr
          im_action = lv_action
        RECEIVING
          et_final =  xt_final
      ).

      ls_xml_base64 = lo_client->prep_xml_voucher_print( it_final = xt_final[] iv_action = lv_action ).

        rv_response = lo_ads->get_ads_api_toget_base64(
        im_access_token  = lv_access_token
        im_template_name = 'ZFI_FORM_VOUCHER/ZFI_DDMND_VOUCHER_PRINT'
        im_xml_base64    = ls_xml_base64 ).

      ""**Setiing response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = rv_response ).

    ENDIF.

  ENDMETHOD.
ENDCLASS.
