CLASS zcl_goods_movement_create DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA:
      gt_header TYPE TABLE OF zstr_migo_header,
      gt_item   TYPE TABLE OF zstr_migo_item,
      gt_serial TYPE TABLE OF zstr_migo_serial.

    DATA:
      lv_char10 TYPE c LENGTH 10,
      lv_char2  TYPE c LENGTH 2.

    METHODS:
      post_goods_mvt
        IMPORTING
                  im_header        LIKE gt_header
                  im_item          LIKE gt_item
                  im_serial        LIKE gt_serial
                  im_action        LIKE lv_char10
                  im_gm_code       LIKE lv_char2
        RETURNING VALUE(es_result) TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS ZCL_GOODS_MOVEMENT_CREATE IMPLEMENTATION.


  METHOD post_goods_mvt.

    DATA:
      lv_str_hdr       TYPE string,
      lv_str_itm       TYPE string,
      lv_str_othr1     TYPE string,
      lv_str_othr2     TYPE string,
      miw_string_final TYPE string,
      lv_doc_date      TYPE string,
      lv_post_date     TYPE string,
      lv_index         TYPE sy-tabix,
      lv_matnr         TYPE I_ProductStorage_2-Product,
      lv_mfg_date      TYPE string,
      lv_mfg_date_err  TYPE c,
      lv_doc_date1     TYPE c LENGTH 10,
      lv_post_date1    TYPE c LENGTH 10.


    DATA:
      sys_date     TYPE d,
      sys_time     TYPE t,
      sys_timezone TYPE timezone.

    sys_date = cl_abap_context_info=>get_system_date( ).
    sys_time = cl_abap_context_info=>get_system_time( ).


    IF im_item[] IS NOT INITIAL.

      READ TABLE im_header INTO DATA(ls_hdr) INDEX 1.

      "*lv_doc_date  = sys_date+0(4) && '-' && sys_date+4(2) && '-' && sys_date+6(2) && 'T00:00:00'.
      lv_doc_date  = ls_hdr-documentdate && 'T00:00:00'.
      lv_doc_date  = '"' && lv_doc_date && '",'.

      lv_post_date = ls_hdr-postingdate && 'T00:00:00'.
      lv_post_date  = '"' && lv_post_date && '",'.

      lv_str_hdr =  '{'
                && '"DocumentDate":' && lv_doc_date  "2023-08-31T00:00:00",'
                && '"PostingDate":'  && lv_post_date "2023-08-31T00:00:00",'
                && '"MaterialDocumentHeaderText":' && '"' && ls_hdr-genumber && '",'
                && '"ReferenceDocument":' && '"' && ls_hdr-referencedocument && '",'      "*GE7654321",'
                && '"GoodsMovementCode": "01",'
                && '"to_MaterialDocumentItem": {'
                && '"results": ['.

      lv_str_othr2 = ']'
                  && '}'
                  && '}'.


      DATA(lv_count) = lines( im_item ).
      LOOP AT im_item INTO DATA(ws_gmvt).

        lv_index = sy-tabix.

        IF lv_index = lv_count.
          lv_str_othr1 = '}'.
        ELSE.
          lv_str_othr1 = '},'.
        ENDIF.

        SHIFT ws_gmvt-material LEFT DELETING LEADING ''.
        lv_matnr = ws_gmvt-material.
        SELECT SINGLE product,
                      MinRemainingShelfLife
                      FROM I_ProductStorage_2
                      WHERE product = @lv_matnr
                      INTO @DATA(ls_sheflife).

        IF ls_sheflife-MinRemainingShelfLife NE 0.

          IF ws_gmvt-mfgdate IS NOT INITIAL.
            lv_mfg_date  = ws_gmvt-mfgdate && 'T00:00:00'.
            lv_mfg_date  = '"' && lv_mfg_date && '"'.
          ELSE.
            lv_mfg_date_err = abap_true.
          ENDIF.


          if ws_gmvt-goodsmovementtype ne '501'.

          lv_str_itm = lv_str_itm
                  && '{'
                  && '"Material":' && '"' && ws_gmvt-material && '",'
                  && '"Plant":' && '"' && ws_gmvt-plant && '",'
                  && '"StorageLocation":' && '"' && ws_gmvt-storagelocation && '",'
                  && '"GoodsMovementType":' && '"' && ws_gmvt-goodsmovementtype && '",'
                  && '"PurchaseOrder":' && '"' && ws_gmvt-purchaseorder && '",'
                  && '"PurchaseOrderItem":' && '"' && ws_gmvt-purchaseorderitem && '",'
                  && '"GoodsMovementRefDocType": "B",'
                  && '"EWMStorageBin":' && '"' && ws_gmvt-storagebin && '",'
*                 && '"EWMWarehouse": "1100",'
                  && '"QuantityInEntryUnit":' && '"' && ws_gmvt-quantityinentryunit && '",'
                  && '"ManufactureDate":' && lv_mfg_date
                  && lv_str_othr1.

          else.

          ENDIF.

        ELSE.

          if ws_gmvt-goodsmovementtype ne '501'.

          lv_str_itm = lv_str_itm
                  && '{'
                  && '"Material":' && '"' && ws_gmvt-material && '",'
                  && '"Plant":' && '"' && ws_gmvt-plant && '",'
                  && '"StorageLocation":' && '"' && ws_gmvt-storagelocation && '",'
                  && '"GoodsMovementType":' && '"' && ws_gmvt-goodsmovementtype && '",'
                  && '"PurchaseOrder":' && '"' && ws_gmvt-purchaseorder && '",'
                  && '"PurchaseOrderItem":' && '"' && ws_gmvt-purchaseorderitem && '",'
                  && '"GoodsMovementRefDocType": "B",'
                  && '"EWMStorageBin":' && '"' && ws_gmvt-storagebin && '",'
*                 && '"EWMWarehouse": "1100",'
                  && '"QuantityInEntryUnit":' && '"' && ws_gmvt-quantityinentryunit && '"'
                  && lv_str_othr1.

           else.

          lv_str_itm = lv_str_itm
                  && '{'
                  && '"Material":' && '"' && ws_gmvt-material && '",'
                  && '"Plant":' && '"' && ws_gmvt-plant && '",'
                  && '"StorageLocation":' && '"' && ws_gmvt-storagelocation && '",'
                  && '"GoodsMovementType":' && '"' && ws_gmvt-goodsmovementtype && '",'
                  && '"InventorySpecialStockType": "M",'
                  && '"Supplier":' && '"' && ws_gmvt-vendor && '",'
                  && '"EWMStorageBin":' && '"' && ws_gmvt-storagebin && '",'
                  && '"QuantityInEntryUnit":' && '"' && ws_gmvt-quantityinentryunit && '"'
                  && lv_str_othr1.

           ENDIF.

        ENDIF.

        CLEAR: ws_gmvt.
      ENDLOOP.

      miw_string_final = lv_str_hdr && lv_str_itm && lv_str_othr2.

      "API endpoint for API sandbox
      DATA: lv_url1     TYPE string,
            lv_url      TYPE string,
            lv_api_pass TYPE string,
            response    TYPE string,
            miw_string  TYPE string.

      DATA: lv_sysid   TYPE zsd_sysid-sysid,
            lv_obj_val TYPE zsd_sysid-objvalue,
            lv_sys_url TYPE zsd_sysid-objvalue.

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

        lv_url1     = lv_sys_url && '/sap/opu/odata/sap/API_MATERIAL_DOCUMENT_SRV/A_MaterialDocumentHeader'.
        lv_api_pass = lv_obj_val. "'aMdwlFpQwhxyvn6uAeTsWSuJ=HGUzJuhljBGEsFC'.

      ENDIF.

      TRY.

          "create http destination by url; API endpoint for API sandbox
          DATA(lo_http_destination) = cl_http_destination_provider=>create_by_url( lv_url1 ).

          "create HTTP client by destination
          DATA(lo_web_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination ).

          "adding headers with API Key for API Sandbox
          DATA(lo_web_http_request) = lo_web_http_client->get_http_request( ).

          lo_web_http_request->set_content_type( 'application/json; charset=utf-8' ) ##NO_TEXT.

          lo_web_http_request->set_authorization_basic( i_username = 'api_user'
                                                i_password = lv_api_pass ).

          lo_web_http_request->append_text(
            EXPORTING
              data = miw_string_final
          ).

          lo_web_http_request->set_header_fields( VALUE #(
          (  name = 'APIKey' value = 'auKKAVy7tpKvqcJq8JchjOflWWliK571' )
          (  name = 'DataServiceVersion' value = '2.0' )
          (  name = 'Accept' value = 'application/json' )
          (  name = 'x-csrf-token' value = 'fetch' )
           ) ) ##NO_TEXT.

          "set request method and execute request
          DATA(lo_web_http_response12) = lo_web_http_client->execute( if_web_http_client=>get ).
          DATA(lv_response_csrf) = lo_web_http_response12->get_header_field(
              i_name  = 'x-csrf-token'
          ).

          lo_web_http_request->set_header_fields( VALUE #(
          (  name = 'APIKey' value = 'auKKAVy7tpKvqcJq8JchjOflWWliK571' )
          (  name = 'DataServiceVersion' value = '2.0' )
          (  name = 'Accept' value = 'application/json' )
          (  name = 'x-csrf-token' value = lv_response_csrf )
           ) ) ##NO_TEXT.

*        CATCH cx_web_message_error.
          DATA(lo_web_http_response) = lo_web_http_client->execute( if_web_http_client=>post ).
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

          IF sy-subrc EQ 0.

            ASSIGN <ld_add>->* TO FIELD-SYMBOL(<ld_add_value>).
            ASSIGN COMPONENT 'MATERIAL_DOCUMENT' OF STRUCTURE <ld_add_value> TO FIELD-SYMBOL(<ld_mblnr>).
            ASSIGN COMPONENT 'MATERIAL_DOCUMENT_YEAR' OF STRUCTURE <ld_add_value> TO FIELD-SYMBOL(<ld_mjahr>).
            ASSIGN <ld_mblnr>->* TO FIELD-SYMBOL(<ld_mblnr_value>).
            ASSIGN <ld_mjahr>->* TO FIELD-SYMBOL(<ld_mjahr_value>).
            IF <ld_mblnr_value> IS NOT INITIAL.
              es_result = |Material Document { <ld_mblnr_value> } Year { <ld_mjahr_value> } Posted Successfully| ##NO_TEXT.

              SELECT * FROM zmm_ge_data
                       WHERE gentry_num = @ls_hdr-genumber
                       INTO TABLE @DATA(xt_ge).

              IF xt_ge[] IS NOT INITIAL.

                LOOP AT xt_ge ASSIGNING FIELD-SYMBOL(<lfs_ge>).
                  IF <lfs_ge> IS ASSIGNED.
                    READ TABLE im_item INTO DATA(lvs_item) WITH KEY
                                                material           = <lfs_ge>-matnr
                                                plant              = <lfs_ge>-werks
                                                purchaseorder      = <lfs_ge>-ponum
                                                purchaseorderitem  = <lfs_ge>-poitem.

                    SHIFT lvs_item-delnoteqty LEFT DELETING LEADING space.

                    <lfs_ge>-mblnr = <ld_mblnr_value>.
                    <lfs_ge>-mjahr = <ld_mjahr_value>.
                    <lfs_ge>-delnoteqty = lvs_item-delnoteqty.

                    CLEAR: lvs_item.
                  ENDIF.
                ENDLOOP.

                MODIFY zmm_ge_data FROM TABLE @xt_ge.
                COMMIT WORK.

              ENDIF.

            ENDIF.

          ELSE.

            ASSIGN COMPONENT 'ERROR' OF STRUCTURE <ls_data> TO FIELD-SYMBOL(<ld_add_err>).
            IF <ld_add_err> IS ASSIGNED.

              ASSIGN <ld_add_err>->* TO FIELD-SYMBOL(<ls_data_err>).
              ASSIGN COMPONENT 'INNERERROR' OF STRUCTURE <ls_data_err> TO FIELD-SYMBOL(<ld_add_irr>).

              ASSIGN <ld_add_irr>->* TO FIELD-SYMBOL(<ls_add_irr>).
              ASSIGN COMPONENT 'ERRORDETAILS' OF STRUCTURE <ls_add_irr> TO FIELD-SYMBOL(<ld_add_error>).

              ASSIGN <ld_add_error>->* TO FIELD-SYMBOL(<ls_add_error>).

              LOOP AT <ls_add_error> ASSIGNING FIELD-SYMBOL(<lfs_err>).
                IF <lfs_err> IS ASSIGNED.

                  ASSIGN <lfs_err>->* TO FIELD-SYMBOL(<lfs_err_new>).
                  ASSIGN COMPONENT 'MESSAGE' OF STRUCTURE <lfs_err_new> TO FIELD-SYMBOL(<ls_err_msg>).
                  ASSIGN <ls_err_msg>->* TO FIELD-SYMBOL(<ls_err_msg_val>).
                  es_result = <ls_err_msg_val>.
                  EXIT.

                ENDIF.
              ENDLOOP.

              IF lv_mfg_date_err = abap_true.
                es_result = |Manufacturing date required for material { lv_matnr }| ##NO_TEXT.
              ENDIF.

            ENDIF.

          ENDIF.
          ""***End: Converting response in internal table*****************************

        CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error ##NO_HANDLER.
          "error handling
      ENDTRY.

    ENDIF.

  ENDMETHOD.
ENDCLASS.
