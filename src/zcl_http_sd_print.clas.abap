class ZCL_HTTP_SD_PRINT definition
  public
  create public .

public section.
    DATA:
      xt_final_so     TYPE TABLE OF zstr_so_data,
      ls_xml_base64   TYPE string,
      lv_access_token TYPE string.

    DATA: lv_vbeln    TYPE c LENGTH 10,
          lv_vbeln_n  TYPE c LENGTH 10,
          lv_plant    TYPE c LENGTH 4,
          lv_date1    TYPE c LENGTH 10,
          lv_date     TYPE d,
          rv_response TYPE string,
          lv_action   TYPE c LENGTH 10,
          lv_prntval  TYPE c LENGTH 10.

    DATA: lo_client TYPE REF TO ycl_sd_print,
          lo_ads    TYPE REF TO zcl_ads_service.

  interfaces IF_HTTP_SERVICE_EXTENSION .
protected section.
private section.
ENDCLASS.



CLASS ZCL_HTTP_SD_PRINT IMPLEMENTATION.


  method IF_HTTP_SERVICE_EXTENSION~HANDLE_REQUEST.

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

    "********Creation of object**************
    CREATE OBJECT lo_client.
    CREATE OBJECT lo_ads.

    DATA:
      lv_resp_new TYPE string.

    ""*****Calling Methods to get PDF code base64
    lv_access_token = lo_ads->get_ads_access_token(  ).

    IF lv_action = 'soprnt'. "Sales order Print

      xt_final_so      = lo_client->get_sales_data( iv_vbeln = lv_vbeln  iv_action = lv_action ).

      IF xt_final_so[] IS NOT INITIAL.

        ls_xml_base64 = lo_client->prep_xml_so_prnt( it_final = xt_final_so[] iv_action = lv_action im_prntval = lv_prntval ).
        rv_response = lo_ads->get_ads_api_toget_base64(
          im_access_token  = lv_access_token
          im_template_name = 'ZSD_FORM_SO_PRINT/ZSD_DDMND_SO_PRINT'
          im_xml_base64    = ls_xml_base64 ).

      ENDIF.

    ENDIF.

    ""**Setiing response/pdf in base64 format to UI5
    response->set_text(
      EXPORTING
        i_text = rv_response ).


  endmethod.
ENDCLASS.
