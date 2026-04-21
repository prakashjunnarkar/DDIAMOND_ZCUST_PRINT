CLASS zcl_http_mm_sticker_print DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA:
      ls_xml_base64   TYPE string,
      lv_access_token TYPE string.

    DATA: lv_mblnr      TYPE c LENGTH 10,
          lv_gjahr      TYPE c LENGTH 4,
          lv_docitm     TYPE c LENGTH 4,
          rv_response   TYPE string,
          rv_resp_final TYPE string,
          rv_resp_signd TYPE string,
          lv_action     TYPE c LENGTH 20.

    DATA: lo_client TYPE REF TO zcl_mm_sticker,
          lo_ads    TYPE REF TO zcl_ads_service.

    INTERFACES if_http_service_extension .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_HTTP_MM_STICKER_PRINT IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.

    TYPES: BEGIN OF lty_base64,
             base64_str TYPE string,
           END OF lty_base64.

    DATA:
      lt_base64 TYPE TABLE OF lty_base64,
      ls_base64 TYPE lty_base64.

    DATA:
      xt_final TYPE TABLE OF zstr_sticker_print,
      gt_final TYPE TABLE OF zstr_sticker_print.

    ""**Get input Data
    DATA(lt_input) = request->get_form_fields( ).

    READ TABLE lt_input INTO DATA(ls_action) WITH KEY name = 'actionname'.
    IF sy-subrc EQ 0.
      lv_action = ls_action-value.
    ENDIF.

    READ TABLE lt_input INTO DATA(ls_input) WITH KEY name = 'materialdocument'.
    IF sy-subrc EQ 0.
      lv_mblnr = ls_input-value.
    ENDIF.

    lv_mblnr = |{ lv_mblnr ALPHA = IN }| .

    CLEAR: ls_input.
    READ TABLE lt_input INTO ls_input WITH KEY name = 'materialdocumentitem'.
    IF sy-subrc EQ 0.
      lv_docitm = ls_input-value.
    ENDIF.

    CLEAR: ls_input.
    READ TABLE lt_input INTO ls_input WITH KEY name = 'materialdocumentyear'.
    IF sy-subrc EQ 0.
      lv_gjahr = ls_input-value.
    ENDIF.

    "********Creation of object**************
    CREATE OBJECT lo_client.
    CREATE OBJECT lo_ads.

    DATA:
      lv_resp_new   TYPE string.

    IF lv_action = 'getdata' OR lv_action = 'issuedata'.

      xt_final      = lo_client->get_grn_data(
                        iv_mblnr  = lv_mblnr
                        iv_gjahr  = lv_gjahr
                        iv_docitm = lv_docitm
                        iv_action = lv_action ).

      DATA(lv_json_data) = /ui2/cl_json=>serialize(
        data             = xt_final[]
        pretty_name      = /ui2/cl_json=>pretty_mode-camel_case
        ).

      ""**Setiing response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = lv_json_data ).

    ENDIF.

    IF lv_action = 'inwardprint' OR lv_action = 'issueprint'.

      DATA:
        lv_stkr_qty TYPE zi_grn_detail-QuantityInEntryUnit,
        lv_tot_qty  TYPE i,
        lv_count1   TYPE i,
        lv_count2   TYPE i,
        lv_index    TYPE sy-tabix.

      xt_final      = lo_client->get_grn_data(
                        iv_mblnr  = lv_mblnr
                        iv_gjahr  = lv_gjahr
                        iv_docitm = lv_docitm
                        iv_action = lv_action ).


      IF xt_final[] IS NOT INITIAL.

        DELETE xt_final WHERE materialdocumentitem NE lv_docitm.
        READ TABLE xt_final INTO DATA(xs_final) INDEX 1.
        CONDENSE xs_final-entryqty.

        lv_stkr_qty = xs_final-entryqty.
        lv_tot_qty  = xs_final-entryqty.

        CONDENSE xs_final-stickerqty.
        lv_count1 = xs_final-stickerqty.
        lv_count2 = xs_final-stickerqty.

        IF lv_count1 GT 2.
          lv_count1 = lv_count1 - 2.
        else.
          lv_count1 = 0.
        ENDIF.

        DO xs_final-stickerqty TIMES.
          lv_index = lv_index + 1.

          IF lv_stkr_qty > xs_final-onebox_qty.
            xs_final-boxqty = |{ xs_final-onebox_qty } / { lv_tot_qty }|.
            lv_stkr_qty = lv_stkr_qty - xs_final-onebox_qty.
          ELSE.
            xs_final-onebox_qty = lv_stkr_qty.
            xs_final-boxqty = |{ xs_final-onebox_qty } / { lv_tot_qty }|.
          ENDIF.

          IF lv_index EQ 1 OR lv_index = lv_count2.
            APPEND xs_final TO gt_final.
          ENDIF.

        ENDDO.

      ENDIF.

      lv_access_token = lo_ads->get_ads_access_token(  ).

      LOOP AT gt_final INTO DATA(gs_final).

        CLEAR: ls_xml_base64, rv_response.
        ls_xml_base64 = lo_client->prep_xml_sticker_print( im_final = gs_final iv_action = lv_action ).

        IF lv_action = 'inwardprint'.

          rv_response = lo_ads->get_ads_api_toget_base64(
            im_access_token  = lv_access_token
            im_template_name = 'ZMM_STICKER_PRINT/ZMM_STRL_STICKER_PRNT'
            im_xml_base64    = ls_xml_base64 ).

        ELSEIF lv_action = 'issueprint'.

          rv_response = lo_ads->get_ads_api_toget_base64(
            im_access_token  = lv_access_token
            im_template_name = 'ZMM_STICKER_ISSUE/ZMM_STRL_STICKER_ISSUE'
            im_xml_base64    = ls_xml_base64 ).

        ENDIF.

        CLEAR: ls_base64.
        ls_base64-base64_str = rv_response.
        APPEND ls_base64 TO lt_base64.

        IF sy-tabix = 1.
          DO lv_count1 TIMES.
            CLEAR: ls_base64.
            ls_base64-base64_str = rv_response.
            APPEND ls_base64 TO lt_base64.
          ENDDO.
        ENDIF.

        CLEAR: gs_final.
      ENDLOOP.

      DATA(lv_json) = /ui2/cl_json=>serialize(
        data             = lt_base64[]
        compress         = abap_true
        assoc_arrays     = abap_true
        assoc_arrays_opt = abap_true
        pretty_name      = /ui2/cl_json=>pretty_mode-camel_case
        ).

      rv_resp_final = lv_json .

      ""**Setiing response/pdf in base64 format to UI5
      response->set_text(
        EXPORTING
          i_text = rv_resp_final ).


    ENDIF.



  ENDMETHOD.
ENDCLASS.
