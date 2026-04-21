CLASS zcl_salesqu_xml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    DATA:
        gt_sodata    TYPE TABLE OF zstr_sales_qu.
    DATA : wa_final TYPE zstr_sales_qu .

    DATA : lo_text           TYPE REF TO zcl_read_text.
    DATA :  gt_item_text      TYPE TABLE OF zstr_billing_text.

    DATA:
      sys_date     TYPE d,
      sys_time     TYPE t,
      sys_timezone TYPE timezone,
      sy_uname     TYPE c LENGTH 20.

    DATA:
      lv_char10  TYPE c LENGTH 10,
      lv_char4   TYPE c LENGTH 4,
      lv_char120 TYPE c LENGTH 120.
*      zchar10 type c length 10 .

    METHODS : Generate_XML
      IMPORTING
                lv_vbeln             TYPE  zchar10_de

      RETURNING VALUE(iv_xml_base64) TYPE string.

    METHODS : Get_data
      IMPORTING
                lv_vbeln        TYPE zchar10_de

      RETURNING VALUE(it_final) LIKE gt_sodata.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_SALESQU_XML IMPLEMENTATION.


  METHOD Generate_XML.

    DATA : lv_xml TYPE String .
    DATA : lv_Supplier TYPE c LENGTH 50 .
    DATA : lv_supplier_adress TYPE c LENGTH 150 .
    DATA : lv_supplier_gst TYPE c LENGTH 20 .
    DATA : lv_supplier_phone TYPE c LENGTH 20 .
    DATA : lv_plant TYPE c LENGTH 4 .

    DATA : it_final TYPE TABLE OF  zstr_sales_qu.
    DATA : wa_final TYPE   zstr_sales_qu.




    lv_Supplier = 'DE DIAMOND ELECTRIC INDIA PVT. LTD'.

    SELECT SINGLE FROM i_salesquotationitem
    FIELDS plant
    WHERE SalesQuotation = @lv_vbeln
    INTO @lv_plant.

    IF lv_plant = '1001'.
      lv_supplier_adress = 'PLOT NO. 38, SECTOR-5, HSIIDC GROWTH CENTER, PHASE-II, Bawal, Rewari, Haryana - 123501' .
      lv_supplier_gst = '06AACCD6342B1Z6' .
      lv_supplier_phone = '9053029816'.
    ELSEIF lv_plant = '1002'.
      lv_supplier_adress = 'Plot no 116-A, CRAFT MOLD INDIA PVT LTD, 2nd Main Road, Sidco Industrial Estate Thirumazhisai, Tiruvallur, Chennai, Tamil Nadu - 600124'.
      lv_supplier_gst = '33AACCD6342B1Z9' .
      lv_supplier_phone = '9053029817'.
    ELSEIF lv_plant = '1003'.
      lv_supplier_adress = 'Khasra No. 22//12/2/2,13/14,17/1,18,19/1/2,22/2/1,22/2/3, Hankyu Hanshin Express India Pvt Ltd, Khentawas, Farrukhnagar, Gurugram, Haryana - 122506 '.
      lv_supplier_gst = '06AACCD6342B1Z6' .
      lv_supplier_phone = '9053029817'.
    ELSEIF lv_plant = '1004'.
      lv_supplier_adress = 'SURVEY NO. 21, 3T INDUSTRIAL SOLUTIONS PVT LTD Warehouse, STATE HIGHWAY 7, Jalisana, TA Mandal, Ahemdabad, Gujarat - 382120'.
      lv_supplier_gst = '24AACCD6342B1Z8' .
      lv_supplier_phone = '9053029817'.
    ELSEIF lv_plant = '1005'.
      lv_supplier_adress = '5/2/8, INDOSPACE INDUSTRIAL PARK, Munimadugu, Sri Sathyasai, Andhra Pradesh - 515164'.
      lv_supplier_gst = '37AACCD6342B1Z1' .
      lv_supplier_phone = '9053029817'.
    ELSEIF lv_plant = '1006'.
      lv_supplier_adress = 'No.2/977, Bommandapalli main road, Kothakondapalli Panchayat, Hosur - 635109'.
      lv_supplier_gst = '33AACCD6342B1Z9' .
      lv_supplier_phone = '9053029817'.
    ELSEIF lv_plant = '1007'.
      lv_supplier_adress = 'Plot No- SP 2 8 & 9, NIC, Majra-Kath, Japanese Investment Zone, Neemrana, Alwar, Rajasthan -  301705'.
      lv_supplier_gst = '' .
      lv_supplier_phone = '9053029817'.
    ENDIF.


    SELECT SINGLE FROM i_salesquotationpartner WITH PRIVILEGED ACCESS
    FIELDS customer , FullName , ContactPerson , vatregistration ,
         InternationalMobilePhoneNumber , EmailAddress , AddressID
    WHERE SalesQuotation = @lv_vbeln
    INTO  @DATA(wa_customer).

    IF wa_customer-AddressID IS NOT INITIAL.
      SELECT SINGLE FROM I_Address_2 WITH PRIVILEGED ACCESS
      FIELDS StreetName , cityName , PostalCode , Region
      WHERE AddressID = @wa_customer-AddressID
      INTO @DATA(wa_customer_address).
    ENDIF.

    DATA : cus_adr TYPE string .

    CONCATENATE wa_customer_address-StreetName
                wa_customer_address-CityName wa_customer_address-PostalCode
                wa_customer_address-Region INTO cus_adr SEPARATED BY ','.



    SELECT FROM i_salesquotationitem AS a LEFT JOIN I_SalesQuotation AS b
    ON a~SalesQuotation = b~SalesQuotation
    FIELDS material , BaseUnit , b~TotalNetAmount , a~OrderQuantity , a~SalesQuotationItemText,
    a~SalesQuotation , a~SalesQuotationItem , a~yy1_itemcost1_sdi , yy1_itemcost2_sdi , yy1_itemcost3_sdi ,
    yy1_itemcost4_sdi , yy1_itemcost5_sdi , yy1_itemcost6_sdi  , yy1_itemcost7_sdi , yy1_itemcost8_sdi , yy1_itemcost9_sdi ,
    materialbycustomer , a~NetPriceAmount , a~NetAmount
    WHERE a~SalesQuotation = @lv_vbeln
    INTO TABLE @DATA(it_tab).

    IF it_tab IS NOT INITIAL.
      SELECT FROM i_salesquotationitemprcgelmnt
      FIELDS ConditionAmount , ConditionType , SalesQuotation , SalesQuotationItem
      FOR ALL ENTRIES IN @it_tab WHERE SalesQuotation = @it_tab-SalesQuotation
       AND SalesQuotationItem = @it_tab-SalesQuotationItem AND ConditionType IN
        ( 'JOIG' , 'JOSG' , 'JOIG' , 'JOUG' )
       INTO TABLE @DATA(it_tax).  "#EC CI_NO_TRANSFORM
    ENDIF.


*    SELECT SINGLE  FROM I_SalesQuotation
*    FIELDS SalesQuotationApprovalReason , CreatedByUser , CustomerPaymentTerms , RequestedDeliveryDate ,
*     IncotermsClassification , PurchaseOrderByCustomer , BINDINGPERIODVALIDITYENDDATe , salesquotationdate
*     WHERE SalesQuotation = @lv_vbeln
*    INTO @DATA(wa_salesquation).

    SELECT SINGLE  FROM I_SalesQuotation
    FIELDS SoldToParty , YY1_CustomerContactPer_SDH , SalesQuotationApprovalReason , CreatedByUser ,
    CustomerPaymentTerms , IncotermsClassification  , RequestedDeliveryDate , yy1_deincontactpersonn_sdh,
    YY1_Email_SDH , yy1_contactnumber_sdh , YY1_ContactNumber1_SDH  , YY1_Email1_SDH , PurchaseOrderByCustomer ,
     YY1_Note1_SDH , yy1_note2150max_sdh ,yy1_note3150max_sdh , YY1_Note5100max_SDH , YY1_Note6100max_SDH ,YY1_Note8100max_SDH , YY1_Note9100max_SDH ,
    YY1_Note10100max_SDH , salesquotationdate , BINDINGPERIODVALIDITYENDDATe
    WHERE SalesQuotation = @lv_vbeln
    INTO @DATA(wa_salesquation).

    IF wa_salesquation-SoldToParty IS NOT INITIAL.

    SELECT single from I_Customer
    FIELDS TaxNumber3 WHERE Customer = @wa_salesquation-SoldToParty
    into @data(gst).

    ENDIF.


    wa_customer-contactperson = wa_salesquation-YY1_CustomerContactPer_SDH. "YY1_ContactPersonName_SDH. "vt

    IF wa_salesquation-SalesQuotationApprovalReason IS NOT INITIAL.
      SELECT SINGLE
       FROM Zi_user
       WITH PRIVILEGED ACCESS
       FIELDS UserDescription
       WHERE UserID = @wa_salesquation-SalesQuotationApprovalReason
       INTO  @DATA(lv_username).
    ENDIF.

    IF wa_salesquation-CreatedByUser IS NOT INITIAL.
      SELECT SINGLE
        FROM Zi_user
        WITH PRIVILEGED ACCESS
        FIELDS UserDescription
        WHERE UserID = @wa_salesquation-CreatedByUser
        INTO  @DATA(lv_username1).
    ENDIF.

    if wa_salesquation-CustomerPaymentTerms is not INITIAL.
       SELECT single from I_PaymentTermsText
       FIELDS PaymentTermsName
       where PaymentTerms = @wa_salesquation-CustomerPaymentTerms
       into @data(lv_pterms).
    endif.

    DATA : lv_sq TYPE c LENGTH 10 .
    DATA : lv_it TYPE c LENGTH 6 .

    DATA : lv_total TYPE p DECIMALS 2 .
    DATA : lv_tax TYPE p DECIMALS 2 .
    DATA : lv_gtotal TYPE p DECIMALS 2 .

    LOOP AT it_tab INTO DATA(waa).
      lv_total += waa-NetAmount.
    ENDLOOP.

    LOOP AT it_tax INTO DATA(wa_taxx).
      lv_tax += wa_taxx-ConditionAmount.
    ENDLOOP.

    lv_gtotal = lv_tax + lv_total.


    lv_xml = |<Form>| &&
               |<Header>| &&
                    |<QuatationNo>{ lv_vbeln }</QuatationNo>| &&
                    |<PaymentTerms>{ lv_pterms }</PaymentTerms>| &&
                    |<DeliveryTerms>{ wa_salesquation-IncotermsClassification }</DeliveryTerms>| &&
                    |<DelDate>{ wa_salesquation-RequestedDeliveryDate }</DelDate>| &&

                    |<Supplier>{ lv_supplier }</Supplier>| &&
                    |<SupplierAdress>{ lv_supplier_adress }</SupplierAdress>| &&
                    |<SupplierTel>{ lv_supplier_phone }</SupplierTel>| &&
                    |<SupplierGst>{ lv_supplier_gst }</SupplierGst>| &&
                    |<SupplierPersonName>{ wa_salesquation-yy1_deincontactpersonn_sdh }</SupplierPersonName>| &&
                    |<SupplierPersonEmail>{ wa_salesquation-YY1_Email_SDH }</SupplierPersonEmail>| &&
                    |<SupplierPersonPhone>{ wa_salesquation-yy1_contactnumber_sdh }</SupplierPersonPhone>| &&

                    |<CustomerCode>{ wa_customer-FullName }</CustomerCode>| &&
                    |<CustomerName>{ cus_adr }</CustomerName>| &&
                    |<CustomerGST>{ gst }</CustomerGST>| &&
                    |<CustomerContactPerson>{ wa_salesquation-YY1_CustomerContactPer_SDH }</CustomerContactPerson>| &&
                    |<CustomerPhone>{ wa_salesquation-YY1_ContactNumber1_SDH }</CustomerPhone>| &&
                    |<CustomerEmail>{ wa_salesquation-YY1_Email1_SDH }</CustomerEmail>| &&
                    |<Customerreff>{ wa_salesquation-PurchaseOrderByCustomer }</Customerreff>| &&

                    |<Approved>{ lv_username }</Approved>| &&
                    |<Checked>{ '' }</Checked>| &&
                    |<Written>{ lv_username1 }</Written>| &&

                     |<t1>{ wa_salesquation-YY1_Note1_SDH }</t1>| &&
                     |<t2>{ wa_salesquation-yy1_note2150max_sdh }</t2>| &&
                     |<t3>{ wa_salesquation-yy1_note3150max_sdh }</t3>| &&
                     |<t4>{ wa_salesquation-YY1_Note5100max_SDH }</t4>| &&
                     |<t5>{ wa_salesquation-YY1_Note6100max_SDH }</t5>| &&
                     |<t6>{ wa_salesquation-YY1_Note8100max_SDH }</t6>| &&
                     |<t7>{ wa_salesquation-YY1_Note9100max_SDH }</t7>| &&
                     |<t8>{ wa_salesquation-YY1_Note10100max_SDH }</t8>| &&
                     |<t9>{ '' }</t9>| &&
                    |<Temp1>{ wa_salesquation-BINDINGPERIODVALIDITYENDDATe }</Temp1>| &&   " Extra field
                    |<Temp2>{ wa_salesquation-salesquotationdate }</Temp2>| &&
                    |<Temp3>{ lv_total }</Temp3>| &&
                    |<tax>{ lv_tax }</tax>| &&
                    |<tax1>{ '' }</tax1>| &&
                    |<gtotal>{ lv_gtotal }</gtotal>| &&
               |</Header>| &&
       |<footer>| &&
          |<PartsCost>{ '' }</PartsCost>| &&
          |<SubmaterialCost>{ '' }</SubmaterialCost>| &&
          |<AssemblingCost>{ '' }</AssemblingCost>| &&
          |<PackTransportCost>{ '' }</PackTransportCost>| &&
          |<AdmistrationCost>{ '' }</AdmistrationCost>| &&
          |<TTL>{ '' }</TTL>| &&
          |<AdmistrationTooling>{ '' }</AdmistrationTooling>| &&
          |<TTLAdmistrationCost>{ '' }</TTLAdmistrationCost>| &&
       |</footer>| &&

       |<ITEMS>| .
*    LOOP AT it_final INTO wa_final.

    DATA : lv_var TYPE string .
    DATA : partcost TYPE string.
    DATA : submaterial TYPE string.
    DATA : packingandtrasnportingcost TYPE string.
    DATA : assembling TYPE string.
    DATA : adminstrationcostandprofit  TYPE string.
    DATA : ttl_withoutgst_inr TYPE string.
    DATA : amoritisationcostoftooling TYPE string.
    DATA : ttl_without_gst_inr_amoritisat TYPE string.
    DATA : remarks4 TYPE string .
    DATA : remarks5 TYPE string .
    DATA : total TYPE string.
    DATA : lv_tot TYPE p DECIMALS 2.

    DATA : unit_qty TYPE p DECIMALS 2 .


    LOOP AT it_tab INTO DATA(wa_tab).

      CLEAR : lv_var .

      lv_sq   = wa_tab-SalesQuotation .
      lv_it   = wa_tab-SalesQuotationItem .


      SHIFT lv_sq LEFT DELETING LEADING '0'.
      SHIFT lv_it LEFT DELETING LEADING '0'.

*
*
*      SELECT SINGLE FROM zsalesqu_tax
*         FIELDS *
*         WHERE zvbeln = @lv_sq AND zposnr = @lv_it
*         INTO @DATA(wa_tax).
*
*      partcost = wa_tax-partscost.
*      submaterial = wa_tax-submaterialcost.
*      assembling = wa_tax-assemblingcost.
*      packingandtrasnportingcost = wa_tax-packingandtrasnportingcost.
*      adminstrationcostandprofit = wa_tax-adminstrationcostandprofit.
*      ttl_withoutgst_inr = wa_tax-ttl_withoutgst_inr.
*      amoritisationcostoftooling = wa_tax-amoritisationcostoftooling.
*      ttl_without_gst_inr_amoritisat = wa_tax-ttl_without_gst_inr_amoritisat.
*      remarks4 = wa_tax-remarks4.
*
*
*      IF wa_tax-remarks4 > 0.
*        CONCATENATE wa_tax-remarks2 remarks4 INTO remarks4 SEPARATED BY ' : '.
*      ENDIF.
*
*      remarks5 = wa_tax-remarks5.
*
*      IF wa_tax-remarks5 > 0 .
*        CONCATENATE wa_tax-remarks3 remarks5 INTO remarks5 SEPARATED BY ' : ' .
*      ENDIF.
*
*
*      lv_tot = wa_tax-partscost +  wa_tax-submaterialcost + wa_tax-assemblingcost + wa_tax-packingandtrasnportingcost
*              + wa_tax-adminstrationcostandprofit + wa_tax-ttl_withoutgst_inr + wa_tax-amoritisationcostoftooling +
*                wa_tax-ttl_without_gst_inr_amoritisat + wa_tax-remarks4 + wa_tax-remarks4.
*
*      total = lv_tot.
*
*      CLEAR unit_qty .
*      unit_qty = wa_tab-TotalNetAmount / wa_tab-OrderQuantity .
*
*
*      CONCATENATE ' Parts Cost : ' partcost INTO lv_var SEPARATED BY ' '.
*      CONCATENATE lv_var cl_abap_char_utilities=>newline INTO lv_var.
*
*      CONCATENATE lv_var 'Submaterial Cost : '  submaterial INTO lv_var SEPARATED BY ' '.
*      CONCATENATE lv_var cl_abap_char_utilities=>newline INTO lv_var.
*
*      CONCATENATE lv_var 'Assembling Cost TTL : ' assembling INTO lv_var SEPARATED BY ''.
*      CONCATENATE lv_var cl_abap_char_utilities=>newline INTO lv_var.
*
*      CONCATENATE lv_var 'Packaging and transportation cost : ' packingandtrasnportingcost INTO lv_var SEPARATED BY ''.
*      CONCATENATE lv_var cl_abap_char_utilities=>newline INTO lv_var.
*
*      CONCATENATE lv_var 'Administration cost and Profit  : ' adminstrationcostandprofit INTO lv_var SEPARATED BY ''.
*      CONCATENATE lv_var cl_abap_char_utilities=>newline INTO lv_var.
*
*      CONCATENATE lv_var 'TTL (Without GST) in INR  : ' ttl_withoutgst_inr INTO lv_var SEPARATED BY ''.
*      CONCATENATE lv_var cl_abap_char_utilities=>newline INTO lv_var.
*
*      CONCATENATE lv_var 'Amoritisation cost of tooling' amoritisationcostoftooling  INTO lv_var SEPARATED BY ''.
*      CONCATENATE lv_var cl_abap_char_utilities=>newline INTO lv_var.
*
*      CONCATENATE lv_var 'TTL (Without GST) in INR with amortisation cost' ttl_without_gst_inr_amoritisat INTO lv_var SEPARATED BY ''.
*      CONCATENATE lv_var cl_abap_char_utilities=>newline INTO lv_var.
*
*      IF remarks4 is NOT INITIAL.
*        CONCATENATE lv_var  remarks4 INTO lv_var SEPARATED BY ' '.
*        CONCATENATE lv_var cl_abap_char_utilities=>newline INTO lv_var.
*      ENDIF.
*
*      IF remarks5 is NOT INITIAL.
*        CONCATENATE lv_var  remarks5 INTO lv_var SEPARATED BY ' '.
*        CONCATENATE lv_var cl_abap_char_utilities=>newline INTO lv_var.
*      ENDIF.
*
*      CONCATENATE lv_var 'Total  ' total INTO lv_var SEPARATED BY ' '.
*      CONCATENATE lv_var cl_abap_char_utilities=>newline INTO lv_var.
*
*CONDENSE lv_var .
      IF wa_tab-yy1_itemcost1_sdi IS NOT INITIAL.
        CONCATENATE lv_var wa_tab-yy1_itemcost1_sdi INTO lv_var .
      ENDIF.

*      CONDENSE lv_var.

      IF wa_tab-yy1_itemcost2_sdi IS NOT INITIAL.
        CONCATENATE lv_var cl_abap_char_utilities=>newline INTO lv_var.
        CONCATENATE lv_var wa_tab-yy1_itemcost2_sdi INTO lv_var .
      ENDIF.
*      CONDENSE lv_var.

      IF wa_tab-yy1_itemcost3_sdi IS NOT INITIAL.
        CONCATENATE lv_var cl_abap_char_utilities=>newline INTO lv_var.
        CONCATENATE lv_var wa_tab-yy1_itemcost3_sdi INTO lv_var .
      ENDIF.

      IF wa_tab-yy1_itemcost4_sdi IS NOT INITIAL.
        CONCATENATE lv_var cl_abap_char_utilities=>newline INTO lv_var.
        CONCATENATE lv_var wa_tab-yy1_itemcost4_sdi INTO lv_var .
      ENDIF.

      IF wa_tab-yy1_itemcost5_sdi IS NOT INITIAL.
        CONCATENATE lv_var cl_abap_char_utilities=>newline INTO lv_var.
        CONCATENATE lv_var wa_tab-yy1_itemcost5_sdi INTO lv_var .
      ENDIF.

      IF wa_tab-yy1_itemcost6_sdi IS NOT INITIAL.
        CONCATENATE lv_var cl_abap_char_utilities=>newline INTO lv_var.
        CONCATENATE lv_var wa_tab-yy1_itemcost6_sdi INTO lv_var .
      ENDIF.

      IF wa_tab-yy1_itemcost7_sdi IS NOT INITIAL.
        CONCATENATE lv_var cl_abap_char_utilities=>newline INTO lv_var.
        CONCATENATE lv_var wa_tab-yy1_itemcost7_sdi INTO lv_var .
      ENDIF.

      IF wa_tab-yy1_itemcost8_sdi IS NOT INITIAL.
        CONCATENATE lv_var cl_abap_char_utilities=>newline INTO lv_var.
        CONCATENATE lv_var wa_tab-yy1_itemcost8_sdi INTO lv_var .
      ENDIF.

      IF wa_tab-yy1_itemcost9_sdi IS NOT INITIAL.
        CONCATENATE lv_var cl_abap_char_utilities=>newline INTO lv_var.
        CONCATENATE lv_var wa_tab-yy1_itemcost9_sdi INTO lv_var .
      ENDIF.

*      CONDENSE lv_var NO-GAPS.


      DATA(lv_xml2) = |<Line_Item>| &&
      |<Sq>{ wa_tab-SalesQuotationItem }</Sq>| &&
      |<Item>{ wa_tab-SalesQuotationItem }</Item>| &&
      |<DEINPartNo>{ wa_tab-Material }</DEINPartNo>| &&
      |<CustPartNo>{ wa_tab-materialbycustomer  }</CustPartNo>| &&
      |<Description>{ wa_tab-SalesQuotationItemText }</Description>| &&
      |<Qty>{ wa_tab-OrderQuantity }</Qty>| &&
      |<UnitPrice>{ wa_tab-NetPriceAmount }</UnitPrice>| &&
      |<Amount>{ wa_tab-NetAmount }</Amount>|  &&

       |<PartsCosts>{ lv_var }</PartsCosts>| &&
       |<submaterialcost>{ '' }</submaterialcost>| && "wa_tax-submaterialcost
       |<assemblingcost>{ '' }</assemblingcost>| &&   "wa_tax-assemblingcost
       |<packingandtrasnportingcost>{ '' }</packingandtrasnportingcost>| &&  "wa_tax-packingandtrasnportingcost
       |<adminstrationcostandprofit>{ '' }</adminstrationcostandprofit>| &&  "wa_tax-packingandtrasnportingcost
       |<ttl_withoutgst_inr>{ '' }</ttl_withoutgst_inr>| &&  "wa_tax-ttl_withoutgst_inr
       |<amoritisationcostoftooling>{ '' }</amoritisationcostoftooling>| && "wa_tax-amoritisationcostoftooling
       |<ttl_without_gst_inr_amoritisat>{ '' }</ttl_without_gst_inr_amoritisat>| && "wa_tax-ttl_without_gst_inr_amoritisat
       |<Remarks1>{ '' }</Remarks1>| &&
       |<Remarks2>{ '' }</Remarks2>| &&
       |<Remarks3>{ '' }</Remarks3>| &&
       |<Remarks4>{ '' }</Remarks4>| &&
       |<Remarks5>{ '' }</Remarks5>| &&
       |<total_item>{ '' }</total_item>|  .


      CONCATENATE lv_xml lv_xml2 '</Line_Item>' INTO lv_xml.
      CLEAR : lv_sq , lv_it.
      CLEAR :   lv_var.
      CLEAR : lv_var , partcost , submaterial , packingandtrasnportingcost , assembling , adminstrationcostandprofit ,
        ttl_withoutgst_inr ,amoritisationcostoftooling , ttl_without_gst_inr_amoritisat ,total , lv_tot , remarks4 , remarks5 .

*    ENDLOOP.
    ENDLOOP.

    CONCATENATE lv_xml '</ITEMS>' '</Form>' INTO lv_xml.

    REPLACE ALL OCCURRENCES OF '&' IN lv_xml WITH 'and' .


*      |</Form>| .

    DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
    iv_xml_base64 = ls_data_xml_64.



  ENDMETHOD.


  METHOD get_data .

    DATA : gt_header TYPE TABLE OF zstr_sales_qu.
    DATA : gs_header TYPE zstr_sales_qu.

    DATA : gt_item TYPE TABLE OF zstr_salesqu_item .
    DATA  : gs_item TYPE zstr_salesqu_item.

    SELECT  FROM i_salesquotation  AS a
    FIELDS a~SalesQuotation
      WHERE a~SalesQuotation = @lv_vbeln
       INTO TABLE @DATA(it_head).

    SELECT SINGLE FROM i_salesquotationitem
     FIELDS plant
     WHERE SalesQuotation = @lv_vbeln
     INTO @DATA(lv_plant).

    SELECT FROM i_salesquotationitem AS a LEFT JOIN I_SalesQuotation AS b
 ON a~SalesQuotation = b~SalesQuotation
 FIELDS material , BaseUnit , b~TotalNetAmount , a~OrderQuantity , a~SalesQuotationItemText ,
 a~SalesQuotation , a~SalesQuotationItem
 WHERE a~SalesQuotation = @lv_vbeln
 INTO TABLE @DATA(it_item).

    SELECT SINGLE FROM i_salesquotationpartner WITH PRIVILEGED ACCESS
   FIELDS customer , FullName , ContactPerson , vatregistration ,
        InternationalMobilePhoneNumber , EmailAddress , AddressID
   WHERE SalesQuotation = @lv_vbeln
   INTO  @DATA(wa_customer).


* if it_item is not INITIAL.
* Select from zsd_sq_tax
* FIELDS *
* FOR ALL ENTRIES IN @it_item
* where zvbeln = @it_item-SalesQuotation and zposnr = @it_item-SalesQuotationItem
* into table @data(it_tax).
* endif.




    CREATE OBJECT lo_text.

    lo_text->read_text_billing_item(
             EXPORTING
               im_billnum  = lv_vbeln
               im_billitem = 10
             RECEIVING
               xt_text     = gt_item_text
           ).





    LOOP AT it_head INTO DATA(wa_head).

      gs_header-qt_no = wa_head-SalesQuotation.
      gs_header-customer = wa_customer-Customer.
      gs_header-cust_name = wa_customer-FullName.
      gs_header-c_person_name = wa_customer-VATRegistration.
      gs_header-c_email = wa_customer-EmailAddress.
      gs_header-c_phone = wa_customer-InternationalMobilePhoneNumber.


      IF lv_plant = '1001'.
        gs_header-supplier_adress = 'PLOT NO. 38, SECTOR-5, HSIIDC GROWTH CENTER, PHASE-II, Bawal, Rewari, Haryana - 123501' .
        gs_header-supplier_gst = '06AACCD6342B1Z6' .
        gs_header-supplier_phone = '9053029816'.
      ELSEIF lv_plant = '1002'.
        gs_header-supplier_adress = 'Plot no 116-A, CRAFT MOLD INDIA PVT LTD, 2nd Main Road, Sidco Industrial Estate Thirumazhisai, Tiruvallur, Chennai, Tamil Nadu - 600124'.
        gs_header-supplier_gst = '33AACCD6342B1Z9' .
        gs_header-supplier_phone = '9053029817'.
      ELSEIF lv_plant = '1003'.
        gs_header-supplier_adress = 'Khasra No. 22//12/2/2,13/14,17/1,18,19/1/2,22/2/1,22/2/3, Hankyu Hanshin Express India Pvt Ltd, Khentawas, Farrukhnagar, Gurugram, Haryana - 122506 '.
        gs_header-supplier_gst = '06AACCD6342B1Z6' .
        gs_header-supplier_phone = '9053029817'.
      ELSEIF lv_plant = '1004'.
        gs_header-supplier_adress = 'SURVEY NO. 21, 3T INDUSTRIAL SOLUTIONS PVT LTD Warehouse, STATE HIGHWAY 7, Jalisana, TA Mandal, Ahemdabad, Gujarat - 382120'.
        gs_header-supplier_gst = '24AACCD6342B1Z8' .
        gs_header-supplier_phone = '9053029817'.
      ELSEIF lv_plant = '1005'.
        gs_header-supplier_adress = '5/2/8, INDOSPACE INDUSTRIAL PARK, Munimadugu, Sri Sathyasai, Andhra Pradesh - 515164'.
        gs_header-supplier_gst = '37AACCD6342B1Z1' .
        gs_header-supplier_phone = '9053029817'.
      ELSEIF lv_plant = '1006'.
        gs_header-supplier_adress = 'No.2/977, Bommandapalli main road, Kothakondapalli Panchayat, Hosur - 635109'.
        gs_header-supplier_gst = '33AACCD6342B1Z9' .
        gs_header-supplier_phone = '9053029817'.
      ELSEIF lv_plant = '1007'.
        gs_header-supplier_adress = 'Plot No- SP 2 8 & 9, NIC, Majra-Kath, Japanese Investment Zone, Neemrana, Alwar, Rajasthan -  301705'.
        gs_header-supplier_gst = '' .
        gs_header-supplier_phone = '9053029817'.
      ENDIF.

      DATA : lv_sq TYPE c LENGTH 10 .
      DATA : lv_it TYPE c LENGTH 6 .

      LOOP AT it_item INTO DATA(wa_item).


        lv_sq   = |{ wa_item-SalesQuotation ALPHA = IN }| .
        lv_it   = |{ wa_item-SalesQuotationitem ALPHA = IN }| .


        SELECT SINGLE FROM zsalesqu_tax
        FIELDS *
        WHERE zvbeln = @lv_sq AND zposnr = @lv_it
        INTO @DATA(wa_tax).

        IF wa_tax IS NOT INITIAL.

          gs_item-partscost = wa_tax-partscost.
          gs_item-submaterialcost = wa_tax-submaterialcost.
          gs_item-assemblingcost = wa_tax-assemblingcost.
          gs_item-packingandtrasnportingcost = wa_tax-packingandtrasnportingcost.
          gs_item-adminstrationcostandprofit = wa_tax-adminstrationcostandprofit.
          gs_item-ttl_withoutgst_inr = wa_tax-ttl_withoutgst_inr.
          gs_item-amoritisationcostoftooling = wa_tax-amoritisationcostoftooling.
          gs_item-ttl_without_gst_inr_amoritisat = wa_tax-ttl_without_gst_inr_amoritisat.
          gs_item-remarks1 = wa_tax-remarks1.
          gs_item-remarks2 = wa_tax-remarks2.
          gs_item-remarks3 = wa_tax-remarks3.
          gs_item-remarks4 = wa_tax-remarks4.
          gs_item-remarks5 = wa_tax-remarks5.


        ENDIF.

        gs_item-quantity = wa_item-OrderQuantity.
        gs_item-amount = wa_item-TotalNetAmount.
        gs_item-deinpartno = wa_item-Material.
        gs_item-description = wa_item-SalesQuotationItemText.

        APPEND gs_item TO gt_item.
        CLEAR wa_tax.
        CLEAR : lv_sq , lv_it.

      ENDLOOP.

      INSERT LINES OF gt_item INTO TABLE gs_header-xt_item.
      APPEND gs_header TO gt_header.



    ENDLOOP.


    it_final[] =  gt_header .


  ENDMETHOD.
ENDCLASS.
