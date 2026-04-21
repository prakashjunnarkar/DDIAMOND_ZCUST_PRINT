CLASS zcl_http_cust_ret DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_service_extension .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_HTTP_CUST_RET IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.

    DATA:
      gt_gedata TYPE TABLE OF zstr_cust_ret_hdr,
      gt_geitem TYPE TABLE OF zstr_cust_ret_itm,
      gs_geitem TYPE zstr_cust_ret_itm.


    DATA:
      lo_client TYPE REF TO zcl_cust_ret.

    DATA: lv_invno   TYPE c LENGTH 10,
          lv_kunnr   TYPE c LENGTH 10,
          lv_genum   TYPE c LENGTH 10,
          lv_action1 TYPE c LENGTH 10,
          lv_action2 TYPE c LENGTH 10.

    "Get inbound data
    DATA(lv_request_body) = request->get_text( ).

    ""**Get input Data
    DATA(lt_input) = request->get_form_fields( ).

    READ TABLE lt_input INTO DATA(ls_input) WITH KEY name = 'invoiceno'.
    IF sy-subrc EQ 0.
      lv_invno = ls_input-value.
    ENDIF.
    lv_invno = |{ lv_invno ALPHA = IN }| .

    READ TABLE lt_input INTO DATA(ls_date) WITH KEY name = 'customer'.
    IF sy-subrc EQ 0.
      lv_kunnr = ls_date-value.
    ENDIF.
    lv_kunnr = |{ lv_kunnr ALPHA = IN }| .

    READ TABLE lt_input INTO DATA(ls_action) WITH KEY name = 'actionname1'. "create
    IF sy-subrc EQ 0.
      lv_action1 = ls_action-value.
    ENDIF.

    CLEAR: ls_action.
    READ TABLE lt_input INTO ls_action WITH KEY name = 'actionname2'. "pof4help
    IF sy-subrc EQ 0.
      lv_action2 = ls_action-value.
    ENDIF.

    CLEAR: ls_action.
    READ TABLE lt_input INTO ls_action WITH KEY name = 'gateentryno'.
    IF sy-subrc EQ 0.
      lv_genum = ls_action-value.
    ENDIF.

    ""****Creating Object**********************
    CREATE OBJECT lo_client.

    IF lv_action1 = 'create' AND lv_action2 = 'getdata'.

      """"***Preparing Gate entry PO-F4help data
      DATA(gt_data) = lo_client->get_data(
        EXPORTING
          im_kunnr = lv_kunnr
          im_invno = lv_invno
      ).

      """***Converting data in to JSON & passing to front end
      DATA: miw_string TYPE string.
      CLEAR: miw_string.

      IF gt_data[] IS NOT INITIAL.

        DATA(json) = /ui2/cl_json=>serialize(
          data             = gt_data[]
          pretty_name      = /ui2/cl_json=>pretty_mode-none
        ).

        miw_string = json .

      ELSE.

        miw_string = 'No suitable data found !'  ##NO_TEXT.

      ENDIF.

      response->set_text(
        EXPORTING
          i_text = miw_string ).

    ENDIF.

    IF lv_action1 = 'create' AND lv_action2 = 'save'.

      "Get inbound data
      CLEAR: lv_request_body.
      lv_request_body = request->get_text( ).

      /ui2/cl_json=>deserialize(
                      EXPORTING json = lv_request_body
                         pretty_name = /ui2/cl_json=>pretty_mode-none
                         CHANGING data = gt_gedata
                   ).

      DATA(lv_gate_num) = lo_client->save_data_get_genum( im_action = lv_action1 xt_gedata = gt_gedata ).
      miw_string = lv_gate_num.

      ""**Setting response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = miw_string ).

    ENDIF.

  ENDMETHOD.
ENDCLASS.
