class ZCL_HTTP_GATE_ENTRY definition
  public
  create public .

public section.

  interfaces IF_HTTP_SERVICE_EXTENSION .
protected section.
private section.
ENDCLASS.



CLASS ZCL_HTTP_GATE_ENTRY IMPLEMENTATION.


  method IF_HTTP_SERVICE_EXTENSION~HANDLE_REQUEST.

    DATA:
      gs_data     TYPE zstr_ge_po_f4_data,
      gt_gedata   TYPE TABLE OF zstr_ge_data,
      gt_geitem   TYPE TABLE OF zstr_ge_item,
      gs_geitem   TYPE zstr_ge_item.

    DATA:
      lo_client TYPE REF TO zcl_ge_process.

    DATA: lv_werks   TYPE C LENGTH 4,
          lv_lifnr   TYPE C LENGTH 10,
          lv_genum   TYPE C LENGTH 10,
          lv_action1 TYPE C LENGTH 10,
          lv_action2 TYPE C LENGTH 10.

    "Get inbound data
    DATA(lv_request_body) = request->get_text( ).

    ""**Get input Data
    DATA(lt_input) = request->get_form_fields( ).

    READ TABLE lt_input INTO DATA(ls_input) WITH KEY name = 'plant'.
    IF sy-subrc EQ 0.
      lv_werks = ls_input-value.
    ENDIF.

    READ TABLE lt_input INTO DATA(ls_date) WITH KEY name = 'vendor'.
    IF sy-subrc EQ 0.
      lv_lifnr = ls_date-value.
    ENDIF.
    lv_lifnr = |{ lv_lifnr ALPHA = IN }| .

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
    "lv_genum = |{ lv_genum ALPHA = IN }| .

    ""****Creating Object**********************
    CREATE OBJECT lo_client.

    IF lv_action1 = 'create' AND lv_action2 = 'pof4help'.

      """"***Preparing Gate entry PO-F4help data
      DATA(gt_data) = lo_client->get_po_f4_data(
        EXPORTING
          iv_lifnr = lv_lifnr
          iv_werks = lv_werks
      ).

      """***Converting data in to JSON & passing to front end
      DATA: miw_string TYPE string.
      CLEAR: miw_string.

      DATA(json) = /ui2/cl_json=>serialize(
        data             = gt_data[]
        compress         = abap_true
        assoc_arrays     = abap_true
        assoc_arrays_opt = abap_true
        pretty_name      = /ui2/cl_json=>pretty_mode-camel_case
      ).

      miw_string = json .

      response->set_text(
        EXPORTING
          i_text = miw_string ).

    ENDIF.

    IF lv_action1 = 'create' AND lv_action2 = 'save'.

      "Get inbound data
      clear: lv_request_body.
      lv_request_body = request->get_text( ).

      /ui2/cl_json=>deserialize(
                      EXPORTING json = lv_request_body
                         pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                         CHANGING data = gt_gedata
                   ).

      DATA(lv_gate_num) = lo_client->save_data_get_genum( im_action = lv_action1 xt_gedata = gt_gedata ).
      miw_string = lv_gate_num.

      ""**Setting response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = miw_string ).

    ENDIF.

    IF lv_action1 = 'change' AND lv_action2 = 'getdata'.

    DATA(gt_final) = lo_client->get_ge_change_data(
      EXPORTING
        iv_genum = lv_genum
    ).

    clear: json.
    json = /ui2/cl_json=>serialize(
      data             = gt_final[]
      compress         = abap_true
      assoc_arrays     = abap_true
     assoc_arrays_opt = abap_true
      pretty_name      = /ui2/cl_json=>pretty_mode-camel_case
      ).

      miw_string = json.

      ""**Setting response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = miw_string ).


    ENDIF.

    IF lv_action1 = 'change' AND lv_action2 = 'save'.

      "Get inbound data
      lv_request_body = request->get_text( ).

      /ui2/cl_json=>deserialize(
                      EXPORTING json = lv_request_body
                         pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                         CHANGING data = gt_gedata
                   ).

      lv_gate_num = lo_client->save_data_get_genum( im_action = lv_action1 xt_gedata = gt_gedata ).
      miw_string = lv_gate_num.

      ""**Setting response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = miw_string ).

    ENDIF.

    IF lv_action1 = 'delete' AND lv_action2 = 'save'.

      "Get inbound data
      lv_request_body = request->get_text( ).

      /ui2/cl_json=>deserialize(
                      EXPORTING json = lv_request_body
                         pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                         CHANGING data = gt_gedata
                   ).

      lv_gate_num = lo_client->delete_data_genum( im_action = lv_action1 xt_gedata = gt_gedata ).
      miw_string = lv_gate_num.

      ""**Setting response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = miw_string ).

    ENDIF.

  endmethod.
ENDCLASS.
