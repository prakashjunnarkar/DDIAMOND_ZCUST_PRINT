CLASS zcl_ads_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS:

      get_ads_access_token
        RETURNING VALUE(iv_access_token) TYPE string,

      get_ads_api_toget_base64
        IMPORTING
                  im_access_token      TYPE string
                  im_template_name     TYPE string
                  im_xml_base64        TYPE string
        RETURNING VALUE(iv_pdf_base64) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_ADS_SERVICE IMPLEMENTATION.


  METHOD get_ads_access_token.

    DATA: url            TYPE string,
          lo_http_client TYPE REF TO if_web_http_client.

    CLEAR : url.
    url = 'https://subdediamond-j8z9y3mw.authentication.eu10.hana.ondemand.com/oauth/token' ##NO_TEXT.

    TRY.

        DATA(dest1) = cl_http_destination_provider=>create_by_url( url ).

      CATCH cx_http_dest_provider_error ##NO_HANDLER.

    ENDTRY.

    TRY.

        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( dest1 ).

      CATCH cx_web_http_client_error ##NO_HANDLER.

    ENDTRY.

    DATA(lo_request1) = lo_http_client->get_http_request( ).

    lo_request1->set_authorization_basic( i_username = 'sb-6f5b54d6-cf53-4f1e-9088-74f5441ffc86!b530111|ads-xsappname!b102452'
                                          i_password = 'daf73bd5-34e7-44e6-bdad-46b0d3f93ead$YllPZmg6L4E33A_BYjuTvxM2VuQTgUgmJHfXmbaPIXE=' ) ##NO_TEXT.

    lo_request1->set_content_type( 'application/x-www-form-urlencoded' ).

    lo_request1->set_form_field( EXPORTING i_name  = 'grant_type'
                                           i_value = 'client_credentials' ).

    TRY.

        DATA(lo_response1) = lo_http_client->execute( i_method = if_web_http_client=>post ).

      CATCH cx_web_http_client_error ##NO_HANDLER.

    ENDTRY.

    DATA(response_body1) = lo_response1->get_text( ).

    REPLACE ALL OCCURRENCES OF '{"access_token":"' IN response_body1 WITH '' .
    SPLIT response_body1 AT '","token_type' INTO DATA(v1) DATA(v2) .
    iv_access_token = v1 .

  ENDMETHOD.


  METHOD get_ads_api_toget_base64.

    TYPES :
      BEGIN OF struct,
        xdp_Template TYPE string,
        xml_Data     TYPE string,
        form_Type    TYPE string,
        form_Locale  TYPE string,
        tagged_Pdf   TYPE string,
        embed_Font   TYPE string,
      END OF struct.

    DATA: url            TYPE string,
          lo_http_client TYPE REF TO if_web_http_client.

    DATA: lr_data     TYPE REF TO data,
          rv_response TYPE string.

    FIELD-SYMBOLS:
      <data>                TYPE data,
      <field>               TYPE any,
      <pdf_based64_encoded> TYPE any.

    """********Start: Form/Print Processing*******************************
    CLEAR : url .
    url = 'https://adsrestapi-formsprocessing.cfapps.eu10.hana.ondemand.com/v1/adsRender/pdf?templateSource=storageName&TraceLevel=2' ##NO_TEXT.

    TRY.

        DATA(dest) = cl_http_destination_provider=>create_by_url( url ).

      CATCH cx_http_dest_provider_error ##NO_HANDLER.

    ENDTRY.

    TRY.

        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( dest ).

      CATCH cx_web_http_client_error ##NO_HANDLER.

    ENDTRY.

    DATA(lo_request) = lo_http_client->get_http_request( ).

    lo_request->set_authorization_bearer( im_access_token ).

    DATA(ls_body) = VALUE struct( xdp_Template = im_template_name
                                  xml_Data = im_xml_base64
                                  form_Type = 'print'
                                  form_Locale = 'de_DE'
                                  tagged_Pdf = '0'
                                  embed_font = '0' ).

    DATA(lv_json) = /ui2/cl_json=>serialize( data        = ls_body
                                             compress    = abap_true
                                             pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).

    lo_request->append_text( EXPORTING data = lv_json ).

    lo_request->set_content_type( 'application/json' ).

    TRY.
        DATA(lo_response) = lo_http_client->execute( i_method = if_web_http_client=>post ).

        DATA(lv_json_response) = lo_response->get_text( ).

        lr_data = /ui2/cl_json=>generate( json = lv_json_response ).

        IF lr_data IS BOUND.

          ASSIGN lr_data->* TO <data>.
          ASSIGN COMPONENT 'fileContent' OF STRUCTURE <data> TO <field>.

          IF sy-subrc EQ 0.
            ASSIGN <field>->* TO <pdf_based64_encoded>.

            rv_response = <pdf_based64_encoded>.

            DATA(len) = strlen( <pdf_based64_encoded> ).
            len = len - 2 .

            rv_response   = <pdf_based64_encoded>+0(len).
            iv_pdf_base64 = rv_response.

          ENDIF.
        ENDIF.

    CATCH cx_web_http_client_error ##NO_HANDLER.

    ENDTRY.
    """********End: Form/Print Processing*******************************
  ENDMETHOD.
ENDCLASS.
