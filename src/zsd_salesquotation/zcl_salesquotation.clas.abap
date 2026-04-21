CLASS zcl_salesquotation DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    DATA: xt_final        TYPE TABLE OF zstr_sales_qu,
      ls_xml_base64   TYPE string,
      lv_access_token TYPE string.

    DATA: lv_vbeln      TYPE c LENGTH 10,
          lv_vbeln_n    TYPE c LENGTH 10,
          lv_pack_num   TYPE c LENGTH 10,
          rv_response   TYPE string,
          rv_resp_signd TYPE string,
          lv_action     TYPE c LENGTH 10,
          lv_prntval    TYPE c LENGTH 10,
          lv_date       type c length 10 .

    DATA: lo_client TYPE REF TO zcl_salesqu_xml.
    DATA: lo_ads    TYPE REF TO zcl_ads_service.

    data : gt_data type table of zstr_salesqu_item.

    INTERFACES if_http_service_extension .

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_SALESQUOTATION IMPLEMENTATION.


  METHOD  if_http_service_extension~handle_request.

    ""**Get input Data
    DATA(lt_input) = request->get_form_fields( ).

    READ TABLE lt_input INTO DATA(ls_action) WITH KEY name = 'actionname'.
    IF sy-subrc EQ 0.
      lv_action = ls_action-value.
    ENDIF.

    READ TABLE lt_input INTO DATA(ls_input_so) WITH KEY name = 'salesdocument'.
    IF sy-subrc EQ 0.
      lv_vbeln   = ls_input_so-value.
      lv_vbeln_n = lv_vbeln.
      lv_vbeln   = |{ lv_vbeln ALPHA = IN }| .
    ENDIF.

    CREATE OBJECT lo_client.
    CREATE OBJECT lo_ads.

    lv_access_token = lo_ads->get_ads_access_token(  ).

    IF lv_action = 'quotprnt'.

    xt_final      = lo_client->get_data( lv_vbeln = lv_vbeln ).

      ls_xml_base64 = lo_client->Generate_XML( lv_vbeln = lv_vbeln ).

      rv_response = lo_ads->get_ads_api_toget_base64(
          im_access_token  = lv_access_token
          im_template_name = 'ZSD_SALES_QUATATION/ZSD_SALES_QUATATION'
          im_xml_base64    = ls_xml_base64 ).

           ""**Setiing response/pdf in base64 format to UI5
    response->set_text(
      EXPORTING
        i_text = rv_response ).



    ENDIF.

  ENDMETHOD.
ENDCLASS.
