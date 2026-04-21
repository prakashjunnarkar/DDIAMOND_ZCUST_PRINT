CLASS zcl_http_sticker_print DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA: lo_client       TYPE REF TO zcl_mm_po_print,
          miw_string      TYPE string,
          ls_xml_base64   TYPE string,
          lv_access_token TYPE string,
          lv_action       TYPE c LENGTH 10,
          lv_action1      TYPE c LENGTH 10,
          lv_action2      TYPE c LENGTH 10,
          lo_ads          TYPE REF TO zcl_ads_service,
          rv_response     TYPE string,
          lv_ponum        TYPE zi_po_print_data-purchaseorder,
          lv_podate       TYPE zi_po_print_data-purchaseorderdate,
          lv_poplant      TYPE zi_po_print_data-plant,
          lv_podate1      TYPE c LENGTH 10,
          lv_vbeln        TYPE c LENGTH 10,
          lv_item         TYPE c LENGTH 5.



    INTERFACES if_http_service_extension .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_HTTP_STICKER_PRINT IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.

    ""**Get input Data
    DATA(lt_input) = request->get_form_fields( ).

    READ TABLE lt_input INTO DATA(ls_action) WITH KEY name = 'actionname'.
    IF sy-subrc EQ 0.
      lv_action = ls_action-value.
    ENDIF.

    READ TABLE lt_input INTO DATA(ls_action1) WITH KEY name = 'materialdocument'.
    IF sy-subrc EQ 0.
      lv_action1 = ls_action1-value.
    ENDIF.

    READ TABLE lt_input INTO DATA(ls_action2) WITH KEY name = 'materialdocumentitem'.
    IF sy-subrc EQ 0.
      lv_action2 = ls_action2-value.
    ENDIF.

    lv_vbeln = |{ lv_action1 ALPHA = IN }| .
    lv_item = |{ lv_action2 ALPHA = IN }| .


    """"""""""Fetching Data

    SELECT SINGLE FROM I_MaterialDocumentItem_2 AS a LEFT JOIN I_ProductDescription AS b  ON a~Material = b~product
    left join i_supplier as c on a~Supplier = c~Supplier
    FIELDS a~Supplier , a~MaterialDocument , a~MaterialDocumentItem , a~Material , a~batch , a~DocumentDate ,
    b~ProductDescription , c~SupplierName , a~QuantityInBaseUnit
    WHERE a~MaterialDocument = @lv_vbeln AND MaterialDocumentItem = @lv_item
    INTO @DATA(lv_data) .

    data : qty type string .
    qty = lv_data-QuantityInBaseUnit.



    DATA qr TYPE c LENGTH 250 .

    CONCATENATE 'Part No : ' lv_data-Material INTO qr .
    CONCATENATE qr cl_abap_char_utilities=>newline INTO qr .

    CONCATENATE qr 'Part Name : ' lv_data-ProductDescription INTO qr .
    CONCATENATE qr cl_abap_char_utilities=>newline INTO qr .

    CONCATENATE  qr 'Batch : ' lv_data-Batch INTO qr .
    CONCATENATE qr cl_abap_char_utilities=>newline INTO qr .

    CONCATENATE  qr 'Arrival date : ' lv_data-DocumentDate INTO qr .
    CONCATENATE qr cl_abap_char_utilities=>newline INTO qr .

    CONCATENATE qr 'Suppier : ' lv_data-supplier INTO qr .
*    CONCATENATE qr cl_abap_char_utilities=>newline into qr .
*
*     CONCATENATE qr 'Quantity : ' qty INTO qr .
*    CONCATENATE qr cl_abap_char_utilities=>newline into qr .





    """""""""""""""""""""""""""""""""""""""""""""
    """""""Generate Xml

    DATA(lv_xml) = |<Form>| &&
                 |<Header>| &&
                      |<partno>{ lv_data-Material }</partno>| &&
                      |<partname>{ lv_data-ProductDescription }</partname>| &&
                      |<batch>{ lv_data-Batch }</batch>| &&
                      |<arrivaldate>{ lv_data-DocumentDate }</arrivaldate>| &&
                      |<supplier>{ lv_data-suppliername }</supplier>| &&
                      |<qr>{ qr }</qr>| &&
                      |<temp1>{ lv_data-QuantityInBaseUnit }</temp1>| &&
                      |<temp2>{ '' }</temp2>| &&
                      |<temp3>{ '' }</temp3>| &&
                      |</Header>| &&
                      |</Form>| .


    CLEAR : lv_data , qr , qty.

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""

    DATA: lo_ads    TYPE REF TO zcl_ads_service.
    CREATE OBJECT lo_ads.


    DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
*    iv_xml_base64 = ls_data_xml_64.

    lv_access_token = lo_ads->get_ads_access_token(  ).

    rv_response = lo_ads->get_ads_api_toget_base64(
        im_access_token  = lv_access_token
        im_template_name = 'ZMM_STICKER_PRINT/ZMM_STICKER_PRINT'
        im_xml_base64    = ls_data_xml_64 ).

    ""**Setiing response/pdf in base64 format to UI5
    response->set_text(
      EXPORTING
        i_text = rv_response ).


  ENDMETHOD.
ENDCLASS.
