CLASS zcl_read_text DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA: lv_sysid   TYPE zsd_sysid-sysid,
          lv_obj_val TYPE zsd_sysid-objvalue,
          lv_sys_url TYPE zsd_sysid-objvalue.

    DATA:
      gt_text TYPE TABLE OF zstr_billing_text.
    DATA:
      lv_char10  TYPE c LENGTH 10,
      lv_char120 TYPE c LENGTH 120.

    METHODS:
      read_text_billing_header
        IMPORTING
                  iv_billnum     LIKE lv_char10
        RETURNING VALUE(xt_text) LIKE gt_text.

    METHODS:
      read_text_billing_item
        IMPORTING
                  im_billnum     LIKE lv_char10
                  im_billitem    TYPE zstr_billing_text-billingdocumentitem
        CHANGING
                  lv_api_pass    TYPE string OPTIONAL
        RETURNING VALUE(xt_text) LIKE gt_text.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS ZCL_READ_TEXT IMPLEMENTATION.


  METHOD read_text_billing_header.

    DATA: response TYPE string.

    "API endpoint for API sandbox
    DATA: lv_url1     TYPE string,
          lv_url2     TYPE string,
          lv_url3     TYPE string,
          lv_url      TYPE string,
          lv_api_pass TYPE string.

    SELECT SINGLE * FROM zsd_sysid
                    WHERE objcode = 'IRN' AND sysid = @sy-sysid
                    INTO @DATA(ls_sysid).

    IF sy-subrc EQ 0.
      lv_sysid = ls_sysid-sysid.
    ENDIF.

    SELECT SINGLE * FROM zsd_sysid
                    WHERE objcode = 'APIUSRPSS' AND sysid = @sy-sysid
                    INTO @DATA(ls_sysid_pass).

    IF sy-subrc EQ 0.
      lv_obj_val = ls_sysid_pass-objvalue.
    ENDIF.

    SELECT SINGLE * FROM zsd_sysid
                    WHERE objcode = 'SYSURL' AND sysid = @sy-sysid
                    INTO @DATA(ls_sys_url).

    IF sy-subrc EQ 0.
      lv_sys_url = ls_sys_url-objvalue.
      CONDENSE lv_sys_url.
    ENDIF.


    IF lv_sys_url IS NOT INITIAL.

      lv_url1     = lv_sys_url && '/sap/opu/odata/sap/API_BILLING_DOCUMENT_SRV/A_BillingDocument(%27'.
      lv_api_pass = lv_obj_val.

    ENDIF.

    lv_url2 = iv_billnum.
    lv_url3 = '%27)/to_Text?$top=50&$inlinecount=allpages'.
    lv_url = lv_url1 && lv_url2 && lv_url3.

    TRY.

        "create http destination by url; API endpoint for API sandbox
        DATA(lo_http_destination) = cl_http_destination_provider=>create_by_url( lv_url ).

        "create HTTP client by destination
        DATA(lo_web_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination ).

        "adding headers with API Key for API Sandbox
        DATA(lo_web_http_request) = lo_web_http_client->get_http_request( ).

        lo_web_http_request->set_authorization_basic( i_username = 'api_user'
                                              i_password = lv_api_pass ) ##NO_TEXT.

        lo_web_http_request->set_header_fields( VALUE #(
        (  name = 'APIKey'  value = 'auKKAVy7tpKvqcJq8JchjOflWWliK571'  )
        (  name = 'DataServiceVersion'  value = '2.0'  )
        (  name = 'Accept'  value = 'application/json'  )
         ) ) ##NO_TEXT .

        "set request method and execute request
        DATA(lo_web_http_response) = lo_web_http_client->execute( if_web_http_client=>get ).
        DATA(lv_response) = lo_web_http_response->get_text( ).


        ""***Start: Converting response in internal table*****************************
        DATA:
          lr_data     TYPE REF TO data.

        FIELD-SYMBOLS:
          <lt_table> TYPE STANDARD TABLE.

        /ui2/cl_json=>deserialize(
                EXPORTING json = lv_response
                   pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                   CHANGING data = lr_data
             ).

        ASSIGN lr_data->* TO FIELD-SYMBOL(<ls_data>).

        IF <ls_data> IS ASSIGNED.

          " Map the ADD_TEXT field
          ASSIGN COMPONENT 'D' OF STRUCTURE <ls_data> TO FIELD-SYMBOL(<ld_add>).
          ASSIGN <ld_add>->* TO FIELD-SYMBOL(<ld_add_value>).
          "ld_add_text = <ld_add_value>.

          " Map internal table
          ASSIGN COMPONENT 'RESULTS' OF STRUCTURE <ld_add_value> TO FIELD-SYMBOL(<lt_table_ref>).
          ASSIGN <lt_table_ref>->* TO <lt_table>.

          LOOP AT <lt_table> ASSIGNING FIELD-SYMBOL(<ls_line>).
            ASSIGN <ls_line>->* TO FIELD-SYMBOL(<ls_line_value>).

            ASSIGN COMPONENT 'BILLING_DOCUMENT'  OF STRUCTURE <ls_line_value> TO FIELD-SYMBOL(<ld_billdoc>).
            ASSIGN COMPONENT 'LANGUAGE' OF STRUCTURE <ls_line_value> TO FIELD-SYMBOL(<ld_lang>).
            ASSIGN COMPONENT 'LONG_TEXT' OF STRUCTURE <ls_line_value> TO FIELD-SYMBOL(<ld_long_txt>).
            ASSIGN COMPONENT 'LONG_TEXT_ID' OF STRUCTURE <ls_line_value> TO FIELD-SYMBOL(<ld_text_id>).

            ASSIGN <ld_billdoc>->* TO FIELD-SYMBOL(<ld_billdoc_value>).
            ASSIGN <ld_lang>->* TO FIELD-SYMBOL(<ld_lang_value>).
            ASSIGN <ld_long_txt>->* TO FIELD-SYMBOL(<ld_long_txt_value>).
            ASSIGN <ld_text_id>->* TO FIELD-SYMBOL(<ld_text_id_value>).

            INSERT VALUE #(
              billingdocument = <ld_billdoc_value>
              language        = <ld_lang_value>
              longtextid      = <ld_text_id_value>
              longtext        = <ld_long_txt_value>
            ) INTO TABLE xt_text.

          ENDLOOP.

        ENDIF.
        ""***End: Converting response in internal table*****************************

      CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error ##NO_HANDLER.
        "error handling
    ENDTRY.

  ENDMETHOD.


  METHOD read_text_billing_item.

    DATA: response TYPE string.

    "API endpoint for API sandbox
    DATA: lv_url1 TYPE string,
          lv_url2 TYPE string,
          lv_url3 TYPE string,
          lv_url  TYPE string.

    SELECT SINGLE * FROM zsd_sysid
                    WHERE objcode = 'APIUSRPSS' AND sysid = @sy-sysid
                    INTO @DATA(ls_sysid_pass).

    IF sy-subrc EQ 0.
      lv_obj_val = ls_sysid_pass-objvalue.
    ENDIF.

    SELECT SINGLE * FROM zsd_sysid
                    WHERE objcode = 'SYSURL' AND sysid = @sy-sysid
                    INTO @DATA(ls_sys_url).

    IF sy-subrc EQ 0.
      lv_sys_url = ls_sys_url-objvalue.
      CONDENSE lv_sys_url.
    ENDIF.

    IF lv_sysid = 'J8W' ##NO_TEXT.

      lv_url1     = lv_sys_url && '/sap/opu/odata/sap/API_BILLING_DOCUMENT_SRV/A_BillingDocumentItem(BillingDocument=%27' ##NO_TEXT.
      lv_api_pass = lv_obj_val. "'R7ADqslXWrzCQdCZsWwzWTElSKhBcnbbvird@HKH' ##NO_TEXT.

    ELSEIF lv_sysid = 'CCX' ##NO_TEXT.
      lv_url1     = lv_sys_url && '/sap/opu/odata/sap/API_BILLING_DOCUMENT_SRV/A_BillingDocumentItem(BillingDocument=%27' ##NO_TEXT.
      lv_api_pass = lv_obj_val. "'NyAxiKeYcJy2aAltcXs@FwcQyPZSqAEaHnNEwGRy' ##NO_TEXT.

    ELSEIF lv_sysid = 'CYK' ##NO_TEXT.

      lv_url1     = lv_sys_url && '/sap/opu/odata/sap/API_BILLING_DOCUMENT_SRV/A_BillingDocumentItem(BillingDocument=%27' ##NO_TEXT.
      lv_api_pass = lv_obj_val. "'FoPZYYtgChSbwhqUrmbZjetcE4oHeGDnAikSZ\XJ' ##NO_TEXT.

    ENDIF.

    lv_url2 = im_billnum && '%27,BillingDocumentItem=%27' && im_billitem.
    lv_url3 = '%27)/to_ItemText?$top=50&$inlinecount=allpages'.
    lv_url = lv_url1 && lv_url2 && lv_url3.

    TRY.

        "create http destination by url; API endpoint for API sandbox
        DATA(lo_http_destination) = cl_http_destination_provider=>create_by_url( lv_url ).

        "create HTTP client by destination
        DATA(lo_web_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination ).

        "adding headers with API Key for API Sandbox
        DATA(lo_web_http_request) = lo_web_http_client->get_http_request( ).

        lo_web_http_request->set_authorization_basic( i_username = 'api_user'
                                              i_password = lv_api_pass ).

        lo_web_http_request->set_header_fields( VALUE #(
        (  name = 'APIKey' value = 'auKKAVy7tpKvqcJq8JchjOflWWliK571' )
        (  name = 'DataServiceVersion' value = '2.0' )
        (  name = 'Accept' value = 'application/json' )
         ) ) ##NO_TEXT.

        "set request method and execute request
        DATA(lo_web_http_response) = lo_web_http_client->execute( if_web_http_client=>get ).
        DATA(lv_response) = lo_web_http_response->get_text( ).


        ""***Start: Converting response in internal table*****************************
        DATA:
          lr_data     TYPE REF TO data.

        FIELD-SYMBOLS:
          <lt_table> TYPE STANDARD TABLE.

        /ui2/cl_json=>deserialize(
                EXPORTING json = lv_response
                   pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                   CHANGING data = lr_data
             ).

        ASSIGN lr_data->* TO FIELD-SYMBOL(<ls_data>).

        " Map the ADD_TEXT field
        ASSIGN COMPONENT 'D' OF STRUCTURE <ls_data> TO FIELD-SYMBOL(<ld_add>).
        ASSIGN <ld_add>->* TO FIELD-SYMBOL(<ld_add_value>).
        "ld_add_text = <ld_add_value>.

        " Map internal table
        ASSIGN COMPONENT 'RESULTS' OF STRUCTURE <ld_add_value> TO FIELD-SYMBOL(<lt_table_ref>).
        ASSIGN <lt_table_ref>->* TO <lt_table>.

        LOOP AT <lt_table> ASSIGNING FIELD-SYMBOL(<ls_line>).
          ASSIGN <ls_line>->* TO FIELD-SYMBOL(<ls_line_value>).

          ASSIGN COMPONENT 'BILLING_DOCUMENT' OF STRUCTURE <ls_line_value> TO FIELD-SYMBOL(<ld_billdoc>).
          ASSIGN COMPONENT 'BILLING_DOCUMENT_ITEM' OF STRUCTURE <ls_line_value> TO FIELD-SYMBOL(<ld_billdocitem>).
          ASSIGN COMPONENT 'LANGUAGE' OF STRUCTURE <ls_line_value> TO FIELD-SYMBOL(<ld_lang>).
          ASSIGN COMPONENT 'LONG_TEXT' OF STRUCTURE <ls_line_value> TO FIELD-SYMBOL(<ld_long_txt>).
          ASSIGN COMPONENT 'LONG_TEXT_ID' OF STRUCTURE <ls_line_value> TO FIELD-SYMBOL(<ld_text_id>).

          ASSIGN <ld_billdoc>->* TO FIELD-SYMBOL(<ld_billdoc_value>).
          ASSIGN <ld_billdocitem>->* TO FIELD-SYMBOL(<ld_billdocitem_value>).
          ASSIGN <ld_lang>->* TO FIELD-SYMBOL(<ld_lang_value>).
          ASSIGN <ld_long_txt>->* TO FIELD-SYMBOL(<ld_long_txt_value>).
          ASSIGN <ld_text_id>->* TO FIELD-SYMBOL(<ld_text_id_value>).

          INSERT VALUE #(
            billingdocument = <ld_billdoc_value>
            billingdocumentitem = <ld_billdocitem_value>
            language        = <ld_lang_value>
            longtextid      = <ld_text_id_value>
            longtext        = <ld_long_txt_value>
          ) INTO TABLE xt_text.

        ENDLOOP.
        ""***End: Converting response in internal table*****************************

      CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error ##NO_HANDLER.
        "error handling
    ENDTRY.

  ENDMETHOD.
ENDCLASS.
