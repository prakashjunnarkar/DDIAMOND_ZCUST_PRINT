CLASS zcl_http_po_print DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA: lo_client       TYPE REF TO zcl_mm_po_print,
          miw_string      TYPE string,
          ls_xml_base64   TYPE string,
          lv_access_token TYPE string,
          lv_action       TYPE c LENGTH 15,
          lo_ads          TYPE REF TO zcl_ads_service,
          rv_response     TYPE string,
          lv_ponum        TYPE zi_po_print_data-purchaseorder,
          lv_podate       TYPE zi_po_print_data-purchaseorderdate,
          lv_poplant      TYPE zi_po_print_data-plant,
          lv_podate1      TYPE c LENGTH 10.

    DATA:
      xt_final TYPE TABLE OF zstr_mm_po_print_hdr,
      lt_item  TYPE TABLE OF zstr_mm_po_print_itm,
      ls_item  TYPE zstr_mm_po_print_itm.

    INTERFACES if_http_service_extension .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_HTTP_PO_PRINT IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.

    ""**Get input Data
    DATA(lt_input) = request->get_form_fields( ).

    READ TABLE lt_input INTO DATA(ls_action) WITH KEY name = 'actionname'.
    IF sy-subrc EQ 0.
      lv_action = ls_action-value.
    ENDIF.


    IF lv_action = 'poprint'.
      READ TABLE lt_input INTO DATA(ls_input) WITH KEY name = 'podocument'.
      IF sy-subrc EQ 0.
        lv_ponum = ls_input-value.
      ENDIF.
      lv_ponum = |{ lv_ponum ALPHA = IN }| .

    ELSEIF lv_action = 'rgpoutprint'.
      CLEAR: lv_ponum.
      READ TABLE lt_input INTO ls_input WITH KEY name = 'rgpoutnum'.
      IF sy-subrc EQ 0.
        lv_ponum = ls_input-value.
      ENDIF.
      lv_ponum = |{ lv_ponum ALPHA = IN }| .

    ELSEIF lv_action = 'nrgpprint'.
      CLEAR: lv_ponum.
      READ TABLE lt_input INTO ls_input WITH KEY name = 'nrgpnum'.
      IF sy-subrc EQ 0.
        lv_ponum = ls_input-value.
      ENDIF.
      lv_ponum = |{ lv_ponum ALPHA = IN }| .
    ENDIF.

    IF lv_action = 'poprint'.
      CLEAR: ls_input.
      READ TABLE lt_input INTO ls_input WITH KEY name = 'purchaseorderdate'.
      IF sy-subrc EQ 0.
        lv_podate1 = ls_input-value.
        lv_podate  = lv_podate1+0(4) && lv_podate1+5(2) && lv_podate1+8(2).
      ENDIF.

    ELSEIF lv_action = 'rgpoutprint'.
      CLEAR: ls_input.
      READ TABLE lt_input INTO ls_input WITH KEY name = 'rgpoutdate'.
      IF sy-subrc EQ 0.
        lv_podate1 = ls_input-value.
        lv_podate  = lv_podate1+0(4) && lv_podate1+5(2) && lv_podate1+8(2).
      ENDIF.

    ELSEIF lv_action = 'nrgpprint'.
      CLEAR: ls_input.
      READ TABLE lt_input INTO ls_input WITH KEY name = 'nrgpdate'.
      IF sy-subrc EQ 0.
        lv_podate1 = ls_input-value.
        lv_podate  = lv_podate1+0(4) && lv_podate1+5(2) && lv_podate1+8(2).
      ENDIF.

    ENDIF.

    CLEAR: ls_input.
    READ TABLE lt_input INTO ls_input WITH KEY name = 'plant'.
    IF sy-subrc EQ 0.
      lv_poplant = ls_input-value.
    ENDIF.

    CREATE OBJECT lo_client.
    CREATE OBJECT lo_ads.

    lv_access_token = lo_ads->get_ads_access_token(  ).

    IF lv_action = 'poprint'.

      xt_final[]  = lo_client->get_po_data(
                      im_action  = lv_action
                      im_ponum   = lv_ponum
                      im_podate  = lv_podate
                      im_poplant = lv_poplant
                    ).

      ls_xml_base64 = lo_client->prep_xml_po_print( it_final = xt_final[] im_action = lv_action ).

      rv_response = lo_ads->get_ads_api_toget_base64(
        im_access_token  = lv_access_token
        im_template_name = 'ZMM_FORM_PO_PRINT/ZMM_PO_PRINT'
        im_xml_base64    = ls_xml_base64 ).
    ENDIF.

    IF lv_action = 'rgpoutprint'.

      xt_final[]  = lo_client->get_rgpout_data(
                      im_action      = lv_action
                      im_rgpoutnum   = lv_ponum
                      im_rgpoutdate  = lv_podate
                      im_plant       = lv_poplant
                    ).

      ls_xml_base64 = lo_client->prep_xml_rgpout_print( it_final = xt_final[] im_action = lv_action ).

***      SELECT SINGLE Purchaseordertype FROM I_PurchaseorderAPI01 WHERE purchaseorder = @lv_ponum INTO @DATA(po_type).


      rv_response = lo_ads->get_ads_api_toget_base64(
      im_access_token  = lv_access_token
      im_template_name = 'ZMM_FORM_RGPOUT_PRINT/ZMM_RGPOUT_PRINT'
*        im_template_name = 'ZMM_FORM_PO_PRINT_DRAFT/ZMM_PO_PRINT_DRAFT'
      im_xml_base64    = ls_xml_base64 ).
    ENDIF.

    IF lv_action = 'nrgpprint'.

      xt_final[]  = lo_client->get_nrgp_data(
                      im_action      = lv_action
                      im_nrgpnum     = lv_ponum
                      im_nrgpdate    = lv_podate
                      im_plant       = lv_poplant
                    ).

      ls_xml_base64 = lo_client->prep_xml_rgpout_print( it_final = xt_final[] im_action = lv_action ).
      rv_response = lo_ads->get_ads_api_toget_base64(
      im_access_token  = lv_access_token
      im_template_name = 'ZMM_FORM_NRGP_PRINT/ZMM_NRGP_PRINT'
      im_xml_base64    = ls_xml_base64 ).
    ENDIF.
    ""**Setiing response/pdf in base64 format to UI5
    response->set_text(
      EXPORTING
        i_text = rv_response ).

  ENDMETHOD.
ENDCLASS.
