CLASS zcl_http_rgp_process DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_service_extension .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_HTTP_RGP_PROCESS IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.
    DATA:
      gs_data   TYPE zstr_rgp_pr_f4_data,
      gt_gedata TYPE TABLE OF zstr_RGP_data,
      gt_geitem TYPE TABLE OF zstr_RGP_item,
      gs_geitem TYPE zstr_RGP_item.

    DATA:
      lo_client TYPE REF TO zcl_rgp_process.

    DATA: lv_werks     TYPE c LENGTH 4,
          lv_lifnr     TYPE c LENGTH 10,
          lv_rgpoutnum TYPE c LENGTH 10,
          lv_nrgpnum TYPE c LENGTH 10,
          lv_rgpinnum  TYPE c LENGTH 10,
          lv_action1   TYPE c LENGTH 15,
          lv_action2   TYPE c LENGTH 10.

    "Get inbound data
    DATA(lv_request_body) = request->get_text( ).

    ""**Get input Data
    DATA(lt_input) = request->get_form_fields( ).

    READ TABLE lt_input INTO DATA(ls_input) WITH KEY name = 'plant'.
    IF sy-subrc EQ 0.
      lv_werks = ls_input-value.
    ENDIF.

*    READ TABLE lt_input INTO DATA(ls_date) WITH KEY name = 'vendor'.
*    IF sy-subrc EQ 0.
*      lv_lifnr = ls_date-value.
*    ENDIF.
*    lv_lifnr = |{ lv_lifnr ALPHA = IN }| .

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
    READ TABLE lt_input INTO ls_action WITH KEY name = 'rgpoutnum'.
    IF sy-subrc EQ 0.
      lv_rgpoutnum = ls_action-value.
    ENDIF.

    CLEAR: ls_action.
    READ TABLE lt_input INTO ls_action WITH KEY name = 'rgpinnum'.
    IF sy-subrc EQ 0.
      lv_rgpinnum = ls_action-value.
    ENDIF.

    CLEAR: ls_action.
    READ TABLE lt_input INTO ls_action WITH KEY name = 'nrgpnum'.
    IF sy-subrc EQ 0.
      lv_nrgpnum = ls_action-value.
    ENDIF.
    "lv_genum = |{ lv_genum ALPHA = IN }| .

    ""****Creating Object**********************
    CREATE OBJECT lo_client.

    IF lv_action1 = 'creatergpout' AND lv_action2 = 'prf4help'.

      """"***Preparing Gate entry PO-F4help data
      DATA(gt_data) = lo_client->get_pr_f4_data(
        EXPORTING
**          iv_lifnr = lv_lifnr
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

    IF lv_action1 = 'creatergpout' AND lv_action2 = 'save'.

      "Get inbound data
      CLEAR: lv_request_body.
      lv_request_body = request->get_text( ).

      /ui2/cl_json=>deserialize(
                      EXPORTING json = lv_request_body
                         pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                         CHANGING data = gt_gedata
                   ).

      DATA(lv_rgp_num) = lo_client->save_data_get_rgpoutnum( im_action = lv_action1 xt_gedata = gt_gedata ).
      miw_string = lv_rgp_num.

      ""**Setting response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = miw_string ).

    ENDIF.

    IF lv_action1 = 'changergpout' AND lv_action2 = 'getdata'.

      DATA(gt_final) = lo_client->get_rgpout_change_data(
        EXPORTING
          iv_rgpoutnum = lv_rgpoutnum
      ).

      CLEAR: json.
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

    IF lv_action1 = 'changergpout' AND lv_action2 = 'save'.

      "Get inbound data
      lv_request_body = request->get_text( ).

      /ui2/cl_json=>deserialize(
                      EXPORTING json = lv_request_body
                         pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                         CHANGING data = gt_gedata
                   ).

      lv_rgp_num = lo_client->save_data_get_rgpoutnum( im_action = lv_action1 xt_gedata = gt_gedata ).
      miw_string = lv_rgp_num.

      ""**Setting response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = miw_string ).

    ENDIF.

    IF lv_action1 = 'deletergpout' AND lv_action2 = 'save'.

      "Get inbound data
      lv_request_body = request->get_text( ).

      /ui2/cl_json=>deserialize(
                      EXPORTING json = lv_request_body
                         pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                         CHANGING data = gt_gedata
                   ).

      lv_rgp_num = lo_client->delete_data_rgpoutnum( im_action = lv_action1 xt_gedata = gt_gedata ).
      miw_string = lv_rgp_num.

      ""**Setting response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = miw_string ).

    ENDIF.


    IF lv_action1 = 'creatergpin' AND lv_action2 = 'getdata'.

      gt_final = lo_client->get_rgpin_create_data(
        EXPORTING
         iv_rgpoutnum = lv_rgpoutnum
      ).

      CLEAR: json.
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

    IF lv_action1 = 'creatergpin' AND lv_action2 = 'save'.

      "Get inbound data
      CLEAR: lv_request_body.
      lv_request_body = request->get_text( ).

      /ui2/cl_json=>deserialize(
                      EXPORTING json = lv_request_body
                         pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                         CHANGING data = gt_gedata
                   ).

      DATA(lv_rgpin_num) = lo_client->save_data_get_rgpoutnum( im_action = lv_action1 xt_gedata = gt_gedata ).
      miw_string = lv_rgpin_num.

      ""**Setting response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = miw_string ).

    ENDIF.

    IF lv_action1 = 'changergpin' AND lv_action2 = 'getdata'.

      gt_final = lo_client->get_rgpin_change_data(
        EXPORTING
          iv_rgpinnum = lv_rgpinnum
      ).

      CLEAR: json.
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

    IF lv_action1 = 'changergpin' AND lv_action2 = 'save'.

      "Get inbound data
      lv_request_body = request->get_text( ).

      /ui2/cl_json=>deserialize(
                      EXPORTING json = lv_request_body
                         pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                         CHANGING data = gt_gedata
                   ).

      lv_rgp_num = lo_client->save_data_get_rgpoutnum( im_action = lv_action1 xt_gedata = gt_gedata ).
      miw_string = lv_rgp_num.

      ""**Setting response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = miw_string ).

    ENDIF.

    IF lv_action1 = 'deletergpin' AND lv_action2 = 'save'.

      "Get inbound data
      lv_request_body = request->get_text( ).

      /ui2/cl_json=>deserialize(
                      EXPORTING json = lv_request_body
                         pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                         CHANGING data = gt_gedata
                   ).

      lv_rgp_num = lo_client->delete_data_rgpoutnum( im_action = lv_action1 xt_gedata = gt_gedata ).
      miw_string = lv_rgp_num.

      ""**Setting response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = miw_string ).

    ENDIF.

    IF lv_action1 = 'createnrgp' AND lv_action2 = 'nrgpf4help'.

      """"***Preparing Gate entry PO-F4help data
      gt_data = lo_client->get_nrgp_f4_data(
        EXPORTING
**          iv_lifnr = lv_lifnr
          iv_werks = lv_werks
      ).

      """***Converting data in to JSON & passing to front end

      CLEAR: miw_string.

      json = /ui2/cl_json=>serialize(
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

    IF lv_action1 = 'createnrgp' AND lv_action2 = 'save'.

      "Get inbound data
      CLEAR: lv_request_body.
      lv_request_body = request->get_text( ).

      /ui2/cl_json=>deserialize(
                      EXPORTING json = lv_request_body
                         pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                         CHANGING data = gt_gedata
                   ).

      data(lv_nrgp_num) = lo_client->save_data_get_rgpoutnum( im_action = lv_action1 xt_gedata = gt_gedata ).
      miw_string = lv_nrgp_num.

      ""**Setting response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = miw_string ).

    ENDIF.

    IF lv_action1 = 'changenrgp' AND lv_action2 = 'getdata'.

      gt_final = lo_client->get_nrgp_change_data(
         EXPORTING
         iv_nrgpnum   = lv_nrgpnum
       ).

      CLEAR: json.
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

    IF lv_action1 = 'changenrgp' AND lv_action2 = 'save'.

      "Get inbound data
      lv_request_body = request->get_text( ).

      /ui2/cl_json=>deserialize(
                      EXPORTING json = lv_request_body
                         pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                         CHANGING data = gt_gedata
                   ).

      lv_nrgp_num = lo_client->save_data_get_rgpoutnum( im_action = lv_action1 xt_gedata = gt_gedata ).
      miw_string = lv_nrgp_num.

      ""**Setting response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = miw_string ).

    ENDIF.

    IF lv_action1 = 'deletenrgp' AND lv_action2 = 'save'.

      "Get inbound data
      lv_request_body = request->get_text( ).

      /ui2/cl_json=>deserialize(
                      EXPORTING json = lv_request_body
                         pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                         CHANGING data = gt_gedata
                   ).

      lv_rgp_num = lo_client->delete_data_rgpoutnum( im_action = lv_action1 xt_gedata = gt_gedata ).
      miw_string = lv_rgp_num.

      ""**Setting response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = miw_string ).

    ENDIF.
  ENDMETHOD.
ENDCLASS.
