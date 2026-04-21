CLASS zcl_http_invoice_print DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    DATA: xt_final        TYPE TABLE OF zi_sale_reg,
          ls_xml_base64   TYPE string,
          lv_access_token TYPE string.

    DATA: lv_vbeln      TYPE c LENGTH 10,
          lv_vbeln_n    TYPE c LENGTH 10,
          lv_pack_num   TYPE c LENGTH 10,
          rv_response   TYPE string,
          rv_resp_signd TYPE string,
          lv_action     TYPE c LENGTH 10,
          lv_prntval    TYPE c LENGTH 10.

    DATA: lo_client TYPE REF TO zcl_sd_custom_print,
          lo_ads    TYPE REF TO zcl_ads_service.

    INTERFACES if_http_service_extension .

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS ZCL_HTTP_INVOICE_PRINT IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.

    ""**Get input Data
    DATA(lt_input) = request->get_form_fields( ).

    READ TABLE lt_input INTO DATA(ls_action) WITH KEY name = 'actionname'.
    IF sy-subrc EQ 0.
      lv_action = ls_action-value.
    ENDIF.

    READ TABLE lt_input INTO DATA(ls_action1) WITH KEY name = 'radiovalue'.
    IF sy-subrc EQ 0.
      lv_prntval = ls_action1-value.
    ENDIF.

    READ TABLE lt_input INTO DATA(ls_input) WITH KEY name = 'billingdocument'.
    IF sy-subrc EQ 0.
      lv_vbeln = ls_input-value.
    ENDIF.

    lv_vbeln_n = lv_vbeln.
    lv_vbeln = |{ lv_vbeln ALPHA = IN }|.

    "********Creation of object**************
    CREATE OBJECT lo_client.
    CREATE OBJECT lo_ads.

    ""*****Calling Methods to get PDF code base64
    lv_access_token = lo_ads->get_ads_access_token(  ).

    IF lv_action = 'export'.

      lv_pack_num = lv_vbeln.
      SHIFT lv_pack_num LEFT DELETING LEADING '0'.
      xt_final      = lo_client->get_packing_data( im_pack = lv_pack_num  iv_action = lv_action ).

      IF xt_final[] IS NOT INITIAL.

        ls_xml_base64 = lo_client->prep_xml_pack_inv( it_final = xt_final[] iv_action = lv_action im_prntval = lv_prntval im_pack = lv_pack_num ).
        rv_response = lo_ads->get_ads_api_toget_base64(
          im_access_token  = lv_access_token
          im_template_name = 'ZSD_EXPORT_COMM_INV/ZSD_DDMND_EXP_COMM_INV'
          im_xml_base64    = ls_xml_base64 ).

        IF lv_prntval = 'All'.
          ls_xml_base64 = lo_client->prep_xml_pack_inv1( it_final = xt_final[] iv_action = lv_action im_prntval = lv_prntval im_pack = lv_pack_num ).
          rv_response = lo_ads->get_ads_api_toget_base64(
            im_access_token  = lv_access_token
            im_template_name = 'ZSD_EXPORT_COMM_INV_MULTI/ZSD_DDMND_EXP_COMM_INV_MULTI'
            im_xml_base64    = ls_xml_base64 ).
        ENDIF.

      ENDIF.

    ENDIF.


    IF lv_action = 'packls'.

      lv_pack_num = lv_vbeln.
      SHIFT lv_pack_num LEFT DELETING LEADING '0'.
      xt_final      = lo_client->get_packing_data( im_pack = lv_pack_num  iv_action = lv_action ).

      IF xt_final[] IS NOT INITIAL.
        ls_xml_base64 = lo_client->prep_xml_pack_inv( it_final = xt_final[] iv_action = lv_action im_prntval = lv_prntval im_pack = lv_pack_num ).
        rv_response   = lo_ads->get_ads_api_toget_base64(
        im_access_token  = lv_access_token
        im_template_name = 'ZSD_FORM_PACK/ZSD_DDMND_PACK_LIST'
        im_xml_base64    = ls_xml_base64 ).

        IF lv_prntval = 'All'.
          ls_xml_base64 = lo_client->prep_xml_pack_inv1( it_final = xt_final[] iv_action = lv_action im_prntval = lv_prntval im_pack = lv_pack_num ).
          rv_response = lo_ads->get_ads_api_toget_base64(
          im_access_token  = lv_access_token
          im_template_name = 'ZSD_FORM_PACK_MULTI/ZSD_DDMND_PACK_LIST_MULTI'
          im_xml_base64    = ls_xml_base64 ).

        ENDIF.
      ENDIF.

    ENDIF.

    IF lv_action = 'oeminv'.

      xt_final      = lo_client->get_billing_data( iv_vbeln = lv_vbeln  iv_action = lv_action ).

      IF xt_final[] IS NOT INITIAL.

        READ TABLE Xt_final INTO DATA(w_final) INDEX 1 .

        ls_xml_base64 = lo_client->prep_xml_tax_inv( it_final = xt_final[] iv_action = lv_action im_prntval = lv_prntval ).
        rv_response = lo_ads->get_ads_api_toget_base64(
          im_access_token  = lv_access_token
          im_template_name = 'ZSD_FORM_INVOICE/ZSD_DDMND_TAX_INVOICE'
          im_xml_base64    = ls_xml_base64 ).
        IF lv_prntval = 'All'.
          ls_xml_base64 = lo_client->prep_xml_tax_inv1( it_final = xt_final[] iv_action = lv_action im_prntval = lv_prntval ).
          rv_response = lo_ads->get_ads_api_toget_base64(
          im_access_token  = lv_access_token
          im_template_name = 'ZSD_FORM_INVOICE_MULTI/ZSD_DDMND_TAX_INVOICE_MULTI'
          im_xml_base64    = ls_xml_base64 ).

        ENDIF.

      ENDIF.

    ENDIF.

    IF lv_action = 'taxinv'.

      xt_final      = lo_client->get_billing_data( iv_vbeln = lv_vbeln  iv_action = lv_action ).

      IF xt_final[] IS NOT INITIAL.

        ls_xml_base64 = lo_client->prep_xml_tax_inv( it_final = xt_final[] iv_action = lv_action im_prntval = lv_prntval ).

        rv_response = lo_ads->get_ads_api_toget_base64(
          im_access_token  = lv_access_token
          im_template_name = 'ZSD_EXPORT_TAX_INVOICE/ZSD_DDMND_EXPORT_TAX_INVOICE'
          im_xml_base64    = ls_xml_base64 ).

        IF lv_prntval = 'All'.
          ls_xml_base64 = lo_client->prep_xml_tax_inv1( it_final = xt_final[] iv_action = lv_action im_prntval = lv_prntval ).
          rv_response = lo_ads->get_ads_api_toget_base64(
          im_access_token  = lv_access_token
          im_template_name = 'ZSD_EXPORT_TAX_INVOICE_MULTI/ZSD_DDMND_EXPORT_TAX_INV_MULTI'
          im_xml_base64    = ls_xml_base64 ).

        ENDIF.


      ENDIF.

    ENDIF.

    IF lv_action = 'dcnote'.

      xt_final      = lo_client->get_billing_data( iv_vbeln = lv_vbeln iv_action = lv_action ).

      IF xt_final[] IS NOT INITIAL.

        CLEAR: w_final.
        READ TABLE Xt_final INTO w_final INDEX 1 .

        ls_xml_base64 = lo_client->prep_xml_tax_inv( it_final = xt_final[] iv_action = lv_action im_prntval = lv_prntval ).
        rv_response = lo_ads->get_ads_api_toget_base64(
          im_access_token  = lv_access_token
          im_template_name = 'ZSD_FORM_DEBIT_CREDIT/ZSD_DDMND_DEBIT_CREDIT_NOTE'
          im_xml_base64    = ls_xml_base64 ).

        IF lv_prntval = 'All'.
          ls_xml_base64 = lo_client->prep_xml_tax_inv1( it_final = xt_final[] iv_action = lv_action im_prntval = lv_prntval ).
          rv_response = lo_ads->get_ads_api_toget_base64(
          im_access_token  = lv_access_token
          im_template_name = 'ZSD_FORM_DEBIT_CREDIT_MULTI/ZSD_DDMND_DEB_CRE_NOTE_MULTI'
          im_xml_base64    = ls_xml_base64 ).

        ENDIF.

      ENDIF.

    ENDIF.

    IF lv_action = 'dchlpr'.

      xt_final      = lo_client->get_billing_data( iv_vbeln = lv_vbeln  iv_action = lv_action ).

      IF xt_final[] IS NOT INITIAL.

        ls_xml_base64 = lo_client->prep_xml_tax_inv( it_final = xt_final[] iv_action = lv_action im_prntval = lv_prntval ).
        rv_response = lo_ads->get_ads_api_toget_base64(
          im_access_token  = lv_access_token
          im_template_name = 'ZSD_FORM_DEL_CHL/ZSD_DDMND_DEL_CHALLAN'
          im_xml_base64    = ls_xml_base64 ).

        IF lv_prntval = 'All'.
          ls_xml_base64 = lo_client->prep_xml_tax_inv1( it_final = xt_final[] iv_action = lv_action im_prntval = lv_prntval ).
          rv_response = lo_ads->get_ads_api_toget_base64(
          im_access_token  = lv_access_token
          im_template_name = 'ZSD_FORM_DEL_CHL_MULTI/ZSD_DDMND_DEL_CHALLAN_MULTI'
          im_xml_base64    = ls_xml_base64 ).

        ENDIF.


      ENDIF.

    ENDIF.

    ""**Setiing response/pdf in base64 format to UI5
    response->set_text(
      EXPORTING
        i_text = rv_response ).

  ENDMETHOD.
ENDCLASS.
