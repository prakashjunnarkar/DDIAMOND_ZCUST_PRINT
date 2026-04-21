CLASS YCL_MM_PROG DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA:
      gt_final TYPE TABLE OF zstr_schd_line_print,
      gs_final TYPE zstr_schd_line_print,
      lt_item  TYPE TABLE OF zstr_schd_line_item,
      ls_item  TYPE zstr_schd_line_item.

    DATA:
      sys_date     TYPE d,
      sys_time     TYPE t,
      sys_timezone TYPE timezone,
      sy_uname     TYPE c LENGTH 20.

    DATA:
      lv_char10  TYPE c LENGTH 10,
      lv_char120 TYPE c LENGTH 120.

    METHODS:
      get_sa_data
        IMPORTING
                  iv_ebeln        LIKE lv_char10
                  iv_action       LIKE lv_char10
        RETURNING VALUE(et_final) LIKE gt_final,

      prep_xml_schdl_print
        IMPORTING
                  it_final             LIKE gt_final
                  iv_action            LIKE lv_char10
        RETURNING VALUE(iv_xml_base64) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS YCL_MM_PROG IMPLEMENTATION.


  METHOD get_sa_data.

    sys_date = cl_abap_context_info=>get_system_date( ).
    sys_time = cl_abap_context_info=>get_system_time( ).
    sy_uname = cl_abap_context_info=>get_user_technical_name( ).

    SELECT * FROM ZI_Schedgagrmt_PO
             WHERE SchedulingAgreement = @iv_ebeln
             INTO TABLE @DATA(lt_sa).         "#EC CI_ALL_FIELDS_NEEDED

    IF sy-subrc EQ 0.

      SELECT * FROM I_SchdAgrSchdLnEnhcdAPI01
      WHERE SchedulingAgreement = @iv_ebeln
      INTO TABLE @DATA(lt_schedule). "#EC CI_ALL_FIELDS_NEEDED

      DATA(lt_hdr) = lt_sa[].
      SORT lt_hdr BY SchedulingAgreement.
      DELETE ADJACENT DUPLICATES FROM lt_hdr COMPARING SchedulingAgreement.

      READ TABLE lt_hdr INTO DATA(lcs_hdr) INDEX 1.

      SELECT SINGLE * FROM zi_plant_address
               WHERE plant = @lcs_hdr-Plant
               INTO @DATA(ls_plant_adrs). "#EC CI_ALL_FIELDS_NEEDED

      SELECT SINGLE * FROM ZI_SUPPLIER_ADDRESS
               WHERE Supplier = @lcs_hdr-Supplier
               INTO @DATA(ls_suppliert_adrs). "#EC CI_ALL_FIELDS_NEEDED

      SELECT SINGLE * FROM I_PurchasingGroup
               WHERE PurchasingGroup = @lcs_hdr-PurchasingGroup
               INTO @DATA(ls_pur_group). "#EC CI_ALL_FIELDS_NEEDED

      LOOP AT lt_hdr INTO DATA(ls_hdr).

        gs_final-schedulingagreement  = ls_hdr-SchedulingAgreement.

        gs_final-schdl_date        = ls_hdr-CreationDate+6(2) && '.' &&
                                     ls_hdr-CreationDate+4(2) && '.' &&
                                     ls_hdr-CreationDate+0(4).

        gs_final-plant_code        = ls_hdr-Plant.
        gs_final-plant_name        = ls_plant_adrs-PlantName.
        gs_final-plant_adrs1       = ls_plant_adrs-StreetPrefixName1 && ',' && ls_plant_adrs-StreetPrefixName2.
        gs_final-plant_adrs2       = ls_plant_adrs-StreetName &&  ',' && ls_plant_adrs-StreetSuffixName1.
        gs_final-plant_adrs3       = ls_plant_adrs-CityName &&  ','  && ls_plant_adrs-PostalCode .

        gs_final-header_1          = 'SCHEDULE AGREEMENT' ##NO_TEXT.
        gs_final-header_2          = ls_plant_adrs-PlantName. "'ELIN ELECTRONICS LTD, GHAZIABAD'.
        gs_final-header_3          = gs_final-plant_adrs1. "'GZB/ELIN/PUR/010/03 REV.11'.
        gs_final-header_4          = gs_final-plant_adrs2. "'Site No.1, C-142,143,144,144/1,144/2'.
        gs_final-header_5          = gs_final-plant_adrs3. "'C-158, B.S. Road, Industrial Area'.
        gs_final-header_6          = |Email: { ls_plant_adrs-EmailAddress } Phone: { ls_plant_adrs-PhoneAreaCodeSubscriberNumber }| ##NO_TEXT. "'Email: elingoa@gmail.com Phone: 6690934/38/26'.
        gs_final-page_no           = ''.
        gs_final-tot_page          = ''.
        gs_final-contact_person    = ls_pur_group-FaxNumber.
        gs_final-contact_phone     = ls_pur_group-PhoneNumber.
        gs_final-contact_email     = ls_pur_group-EmailAddress.
        gs_final-pay_terms         = ls_hdr-PaymentTermsName.
        gs_final-plant_adrs4       = ''.
        gs_final-plant_phone       = ''.
        gs_final-plant_email       = ''.
        gs_final-plant_gstin       = '30AAACE6449G1ZY' ##NO_TEXT.
        gs_final-plant_pan         = 'AAACE6449G' ##NO_TEXT.
        gs_final-plant_vat         = ''.
        gs_final-suppl_code        = ls_hdr-Supplier.
        gs_final-suppl_name        = ls_suppliert_adrs-SupplierName.
        gs_final-suppl_adrs1       = ls_suppliert_adrs-StreetPrefixName1 && ',' && ls_suppliert_adrs-StreetPrefixName2..
        gs_final-suppl_adrs2       = ls_suppliert_adrs-StreetName &&  ',' && ls_suppliert_adrs-StreetSuffixName1 &&  ',' && ls_suppliert_adrs-DistrictName.
        gs_final-suppl_adrs3       = ls_suppliert_adrs-CityName &&  ',' && ls_suppliert_adrs-PostalCode &&  ',' && ls_suppliert_adrs-Country.
        gs_final-suppl_adrs4       = ''.
        gs_final-suppl_phone       = ls_suppliert_adrs-PhoneNumber1.
        gs_final-suppl_email       = ls_suppliert_adrs-EmailAddress.
        gs_final-suppl_gstin       = ls_suppliert_adrs-TaxNumber3.
        gs_final-suppl_pan         = ls_suppliert_adrs-BusinessPartnerPanNumber.

        LOOP AT lt_sa INTO DATA(ls_sa) WHERE SchedulingAgreement = ls_hdr-SchedulingAgreement.

         READ TABLE lt_schedule INTO DATA(ls_schedule) with key
         schedulingagreement     = ls_sa-SchedulingAgreement
         schedulingagreementitem = ls_sa-SchedulingAgreementItem
         ScheduleLine            = ls_sa-ScheduleLine.

        if ls_schedule-ScheduleLineOpenQuantity gt 0.

          ls_item-schedulingagreement     = ls_sa-SchedulingAgreement.
          ls_item-schedulingagreementitem = ls_sa-SchedulingAgreementItem.
          ls_item-item_code               = ls_sa-Material.
          ls_item-item_name               = ls_sa-ProductDescription.
          ls_item-item_qty                = ls_schedule-ScheduleLineOpenQuantity. "ls_sa-ScheduleLineOrderQuantity.

          ls_item-delivery_date           =  ls_sa-ScheduleLineDeliveryDate+6(2) && '.' &&
                                             ls_sa-ScheduleLineDeliveryDate+4(2) && '.' &&
                                             ls_sa-ScheduleLineDeliveryDate+0(4).

          ls_item-net_value               = ls_sa-NetPriceAmount.

          ls_item-rate                    = ''.
          ls_item-cgst_amt                = ''.
          ls_item-sgst_amt                = ''.
          ls_item-igst_amt                = ''.
          ls_item-tax_value               = ''.
          ls_item-tot_val                 = ''.
          ls_item-unit                    = ''.
          APPEND ls_item TO lt_item.

          gs_final-sum_qty       = gs_final-sum_qty + ls_item-item_qty.
          gs_final-sum_netpr     = gs_final-sum_netpr + ls_item-net_value.

        ENDIF.

          CLEAR: ls_sa, ls_schedule.
        ENDLOOP.

        INSERT LINES OF lt_item INTO TABLE gs_final-sa_item.
        APPEND gs_final TO gt_final.

        CLEAR: ls_hdr.
      ENDLOOP.

    ENDIF.

  ENDMETHOD.


  METHOD prep_xml_schdl_print.

    sys_date = cl_abap_context_info=>get_system_date( ).
    sys_time = cl_abap_context_info=>get_system_time( ).
    sy_uname = cl_abap_context_info=>get_user_technical_name( ).

    CLEAR: gt_final.
    gt_final[] = it_final[].

    READ TABLE gt_final INTO gs_final INDEX 1.

    DATA(lv_xml) =  |<Form>| &&
                    |<ScheduleAgrementNode>| &&
                    |<header_1>{ gs_final-header_1 }</header_1>| &&
                    |<header_2>{ gs_final-header_2 }</header_2>| &&
                    |<header_3>{ gs_final-header_3 }</header_3>| &&
                    |<header_4>{ gs_final-header_4 }</header_4>| &&
                    |<header_5>{ gs_final-header_5 }</header_5>| &&
                    |<header_6>{ gs_final-header_6 }</header_6>| &&
                    |<schdl_agrno>{ gs_final-schedulingagreement }</schdl_agrno>| &&
                    |<schdl_date>{ gs_final-schdl_date }</schdl_date>| &&
                    |<page_no>{ gs_final-page_no }</page_no>| &&
                    |<tot_page>{ gs_final-tot_page }</tot_page>| &&
                    |<contact_person>{ gs_final-contact_person }</contact_person>| &&
                    |<contact_phone>{ gs_final-contact_phone }</contact_phone>| &&
                    |<contact_email>{ gs_final-contact_email }</contact_email>| &&
                    |<pay_terms>{ gs_final-pay_terms }</pay_terms>| &&
                    |<plant_code>{ gs_final-plant_code }</plant_code>| &&
                    |<plant_name>{ gs_final-plant_name }</plant_name>| &&
                    |<plant_adrs1>{ gs_final-plant_adrs1 }</plant_adrs1>| &&
                    |<plant_adrs2>{ gs_final-plant_adrs2 }</plant_adrs2>| &&
                    |<plant_adrs3>{ gs_final-plant_adrs3 }</plant_adrs3>| &&
                    |<plant_adrs4>{ gs_final-plant_adrs4 }</plant_adrs4>| &&
                    |<plant_phone>{ gs_final-plant_phone }</plant_phone>| &&
                    |<plant_email>{ gs_final-plant_email }</plant_email>| &&
                    |<plant_gstin>{ gs_final-plant_gstin }</plant_gstin>| &&
                    |<plant_pan>{ gs_final-plant_pan }</plant_pan>| &&
                    |<plant_vat>{ gs_final-plant_vat }</plant_vat>| &&
                    |<suppl_code>{ gs_final-suppl_code }</suppl_code>| &&
                    |<suppl_name>{ gs_final-suppl_name }</suppl_name>| &&
                    |<suppl_adrs1>{ gs_final-suppl_adrs1 }</suppl_adrs1>| &&
                    |<suppl_adrs2>{ gs_final-suppl_adrs2 }</suppl_adrs2>| &&
                    |<suppl_adrs3>{ gs_final-suppl_adrs3 }</suppl_adrs3>| &&
                    |<suppl_adrs4>{ gs_final-suppl_adrs4 }</suppl_adrs4>| &&
                    |<suppl_phone>{ gs_final-suppl_phone }</suppl_phone>| &&
                    |<suppl_email>{ gs_final-suppl_email }</suppl_email>| &&
                    |<suppl_gstin>{ gs_final-suppl_gstin }</suppl_gstin>| &&
                    |<suppl_pan>{ gs_final-suppl_pan }</suppl_pan>| &&
                    |<sum_qty>{ gs_final-sum_qty }</sum_qty>| &&
                    |<sum_netpr>{ gs_final-sum_netpr }</sum_netpr>| &&
                    |<ItemData>|  ##NO_TEXT.


    DATA : lv_item TYPE string,
           srn     TYPE c LENGTH 3.

    CLEAR : lv_item , srn .

    SORT gs_final-sa_item by delivery_date ASCENDING.
    LOOP AT gs_final-sa_item INTO DATA(ls_item).
      srn = srn + 1 .

      SHIFT ls_item-item_code LEFT DELETING LEADING '0'.
      lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                |<sl_num>{ srn }</sl_num>| &&
                |<item_code>{ ls_item-item_code }</item_code>| &&
                |<item_name>{ ls_item-item_name }</item_name>| &&
                |<item_qty>{ ls_item-item_qty }</item_qty>| &&
                |<delivery_date>{ ls_item-delivery_date }</delivery_date>| &&
                |<net_value>{ ls_item-net_value }</net_value>| &&
                |</ItemDataNode>|  ##NO_TEXT .

      CLEAR: ls_item.
    ENDLOOP.

    lv_xml = |{ lv_xml }{ lv_item }| &&
                       |</ItemData>| &&
                       |</ScheduleAgrementNode>| &&
                       |</Form>| ##NO_TEXT .

    DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
    iv_xml_base64 = ls_data_xml_64.

  ENDMETHOD.
ENDCLASS.
