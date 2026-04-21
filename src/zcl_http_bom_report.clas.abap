CLASS zcl_http_bom_report DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_service_extension .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_HTTP_BOM_REPORT IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.

    DATA: lo_client  TYPE REF TO zcl_bom_detail,
          miw_string TYPE string,
          xt_data    TYPE TABLE OF zi_bom_report,
          lv_input_str TYPE string.

    "Get inbound data
    DATA(lv_request_body) = request->get_text( ).
    lv_input_str = lv_request_body.

    CREATE OBJECT lo_client.
    xt_data[]  = lo_client->get_bom_data( im_input_str = lv_input_str ).

    DATA(json) = /ui2/cl_json=>serialize(
      data             = xt_data[]
      compress         = abap_true
      assoc_arrays     = abap_true
      assoc_arrays_opt = abap_true
      pretty_name      = /ui2/cl_json=>pretty_mode-camel_case
      ).

    miw_string = json .

    ""**Setting response/pdf in base64 format to UI5
    response->set_text(
      EXPORTING
        i_text = miw_string ).

  ENDMETHOD.
ENDCLASS.
