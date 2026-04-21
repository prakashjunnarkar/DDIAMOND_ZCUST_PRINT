CLASS ycl_sd_print DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA:
      gt_sodata    TYPE TABLE OF zstr_so_data.

    DATA:
      sys_date     TYPE d,
      sys_time     TYPE t,
      sys_timezone TYPE timezone,
      sy_uname     TYPE c LENGTH 20.

    DATA:
      lv_char10  TYPE c LENGTH 10,
      lv_char4   TYPE c LENGTH 4,
      lv_char120 TYPE c LENGTH 120.


    METHODS:
      get_sales_data
        IMPORTING
                  iv_vbeln        LIKE lv_char10
                  iv_action       LIKE lv_char10
        RETURNING VALUE(et_final) LIKE gt_sodata,

      prep_xml_so_prnt
        IMPORTING
                  it_final             LIKE gt_sodata
                  iv_action            LIKE lv_char10
                  im_prntval           LIKE lv_char10
        RETURNING VALUE(iv_xml_base64) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS YCL_SD_PRINT IMPLEMENTATION.


  METHOD get_sales_data.
    DATA: gt_sohdr     TYPE TABLE OF zstr_so_data,
          gs_sohdr     TYPE zstr_so_data,
          gt_item      TYPE TABLE OF zstr_so_item,
          gs_item      TYPE zstr_so_item,
          lv_grand_tot TYPE p LENGTH 16 DECIMALS 2,
          lv_sum_igst  TYPE p LENGTH 16 DECIMALS 2,
          lv_sum_qty   TYPE p LENGTH 16 DECIMALS 0,
          lv_itm_qty   TYPE p LENGTH 16 DECIMALS 0,
          lv_tot_amt   TYPE p LENGTH 16 DECIMALS 2.



    SELECT * FROM i_salesdocument
             WHERE salesdocument = @iv_vbeln
             INTO TABLE @DATA(lt_sohdr).

    IF lt_sohdr[] IS NOT INITIAL.

      SELECT * FROM i_salesdocumentitem
               WHERE salesdocument = @iv_vbeln
               INTO TABLE @DATA(lt_soitem).   "#EC CI_ALL_FIELDS_NEEDED

      SELECT * FROM i_salesdocitempricingelement
               WHERE salesdocument = @iv_vbeln
               INTO TABLE @DATA(lt_soitem_price). "#EC CI_ALL_FIELDS_NEEDED

      SELECT * FROM zi_so_partner
               WHERE salesdocument = @iv_vbeln
               INTO TABLE @DATA(lt_sopart).   "#EC CI_ALL_FIELDS_NEEDED

      IF lt_soitem[] IS NOT INITIAL.

        SELECT
        product,
        ProductType
        FROM i_product
                 FOR ALL ENTRIES IN @lt_soitem
                 WHERE product  = @lt_soitem-product
                 INTO TABLE @DATA(lt_product).     "#EC CI_NO_TRANSFORM

      ENDIF.

      SELECT * FROM i_salesdocumentscheduleline
               WHERE salesdocument = @iv_vbeln
               INTO TABLE @DATA(lt_schdl).    "#EC CI_ALL_FIELDS_NEEDED

    ENDIF.

    LOOP AT lt_sohdr INTO DATA(ls_sohdr).

      READ TABLE lt_soitem INTO DATA(ls_souitem_new) WITH KEY salesdocument = ls_sohdr-salesdocument.

      gs_sohdr-saleorder      = ls_sohdr-salesdocument.
      gs_sohdr-saleorderdate  = ls_sohdr-salesdocumentdate+6(2) && '.' && ls_sohdr-salesdocumentdate+4(2) && '.' && ls_sohdr-salesdocumentdate+0(4).
      gs_sohdr-saleordertype  = ls_sohdr-salesdocumenttype.

      """"" plant address       hardcode .....
      gs_sohdr-work_addrs = ''.
      gs_sohdr-exptr_code = '' .
      gs_sohdr-exptr_name   = 'DE DIAMOND ELECTRIC INDIA PVT.LTD' ##NO_TEXT.
      gs_sohdr-exptr_gstin = '' .
      gs_sohdr-exptr_pan   = '' .
      gs_sohdr-exptr_email = '' .
      gs_sohdr-exptr_phone = '' .

      gs_sohdr-exptr_addrs1 = 'Sector - 5, HSIIDC Growth Centre, Plot no. 38, Phase-II,' ##NO_TEXT.
      gs_sohdr-exptr_addrs2 = 'Industrial Model Twp, Bawal, Haryana 123501, India' ##NO_TEXT.
      gs_sohdr-exptr_addrs3 = '' .
      gs_sohdr-exptr_addrs4 = ''.

      """" factory address
      gs_sohdr-fact_addrs1 = '18 Old Anaj Mandi, Ferozepur Cantt. - 152001 Punjab ' ##NO_TEXT.
      gs_sohdr-fact_addrs2 = 'India' ##NO_TEXT.
      gs_sohdr-fact_addrs3 = '' .

      gs_sohdr-our_ref          = ls_sohdr-salesdocument.
      gs_sohdr-our_ref_date     = ls_sohdr-salesdocumentdate+6(2) && '.' && ls_sohdr-salesdocumentdate+4(2) && '.' && ls_sohdr-salesdocumentdate+0(4).
      gs_sohdr-cust_odr_ref     = ls_sohdr-purchaseorderbycustomer .
      gs_sohdr-cust_odr_date    = ls_sohdr-customerpurchaseorderdate+6(2) && '.' && ls_sohdr-customerpurchaseorderdate+4(2) && '.' && ls_sohdr-customerpurchaseorderdate+0(4).
      gs_sohdr-buyr_code        = ls_sohdr-soldtoparty .
      gs_sohdr-inco_term        = ls_sohdr-incotermsclassification.
      gs_sohdr-price_term       = ls_sohdr-incotermslocation1. "IncotermsClassification.
      gs_sohdr-amtount_curr     = ls_sohdr-transactioncurrency.

      SELECT SINGLE * FROM i_customerpaymenttermstext
                      WHERE customerpaymentterms = @ls_sohdr-customerpaymentterms
                        AND language = 'E'
                      INTO @DATA(ls_payterm_desc).

      gs_sohdr-pay_term   = ls_payterm_desc-customerpaymenttermsname.

      DATA : lv_shp_adr1 TYPE c LENGTH 100,
             lv_shp_adr2 TYPE c LENGTH 100,
             lv_shp_adr3 TYPE c LENGTH 100,
             lv_shp_adr4 TYPE c LENGTH 100.

      DATA : lv_sold_adr1 TYPE c LENGTH 100,
             lv_sold_adr2 TYPE c LENGTH 100,
             lv_sold_adr3 TYPE c LENGTH 100,
             lv_sold_adr4 TYPE c LENGTH 100.

      READ TABLE lt_sopart INTO DATA(ls_sopart) WITH KEY salesdocument = ls_sohdr-salesdocument.
      IF ls_sopart-we_street IS NOT INITIAL .
        IF lv_shp_adr1 IS NOT INITIAL   .
          lv_shp_adr1 = |{ lv_shp_adr1 } , { ls_sopart-we_street }, { ls_sopart-we_streetprefixname1 }, { ls_sopart-we_streetprefixname2 }, { ls_sopart-we_streetsuffixname1 }| .
        ELSE .
          lv_shp_adr1 = |{ ls_sopart-we_street }, { ls_sopart-we_streetprefixname1 }, { ls_sopart-we_streetprefixname2 }, { ls_sopart-we_streetsuffixname1 }| .
        ENDIF .
      ENDIF .

      IF ls_sopart-we_street1 IS NOT INITIAL .
        IF lv_shp_adr1 IS NOT INITIAL   .
          lv_shp_adr1 = |{ lv_shp_adr1 } , { ls_sopart-we_street1 }, { ls_sopart-we_streetprefixname1 }, { ls_sopart-we_streetprefixname2 }, { ls_sopart-we_streetsuffixname1 }| .
        ELSE .
          lv_shp_adr1 = |{ ls_sopart-we_street1 }, { ls_sopart-we_streetprefixname1 }, { ls_sopart-we_streetprefixname2 }, { ls_sopart-we_streetsuffixname1 }| .
        ENDIF .
      ENDIF .

      DATA(len) = strlen( lv_shp_adr1 ) .
      len = len - 40.
      IF strlen( lv_shp_adr1 ) GT 40 .
        lv_shp_adr2 = |{ lv_shp_adr1+40(len) },| .
        lv_shp_adr1 = lv_shp_adr1+0(40) .
      ENDIF .

      READ TABLE lt_sopart INTO DATA(ls_sopart_ag) WITH KEY salesdocument = ls_sohdr-salesdocument.
      IF ls_sopart_ag-ag_street IS NOT INITIAL .
        IF lv_sold_adr1 IS NOT INITIAL   .
          lv_sold_adr1 = |{ lv_sold_adr1 } , { ls_sopart_ag-ag_street }, { ls_sopart_ag-ag_streetprefixname1 }, { ls_sopart_ag-ag_streetprefixname2 }, { ls_sopart_ag-ag_streetsuffixname1 }| .
        ELSE .
          lv_sold_adr1 = |{ ls_sopart_ag-ag_street }, { ls_sopart_ag-ag_streetprefixname1 }, { ls_sopart_ag-ag_streetprefixname2 }, { ls_sopart_ag-ag_streetsuffixname1 }| .
        ENDIF .
      ENDIF .

      IF ls_sopart_ag-ag_street1 IS NOT INITIAL .
        IF lv_sold_adr1 IS NOT INITIAL   .
          lv_sold_adr1 = |{ lv_sold_adr1 } , { ls_sopart_ag-ag_street1 }, { ls_sopart_ag-ag_streetprefixname1 }, { ls_sopart_ag-ag_streetprefixname2 }, { ls_sopart_ag-ag_streetsuffixname1 }| .
        ELSE .
          lv_sold_adr1 = |{ ls_sopart_ag-ag_street1 }, { ls_sopart_ag-ag_streetprefixname1 }, { ls_sopart_ag-ag_streetprefixname2 }, { ls_sopart_ag-ag_streetsuffixname1 }| .
        ENDIF .
      ENDIF .

      DATA(len_ag) = strlen( lv_sold_adr1 ) .
      len_ag = len_ag - 40.
      IF strlen( lv_sold_adr1 ) GT 40 .
        lv_sold_adr2 = |{ lv_sold_adr1+40(len_ag) },| .
        lv_sold_adr1 = lv_sold_adr1+0(40) .
      ENDIF .

      SELECT SINGLE
        Country,
        Language,
        CountryName,
        CountryShortName
      FROM i_countrytext   WHERE country = @ls_sopart_ag-ag_country AND language = 'E'
      INTO @DATA(lv_cn_nm).                        "#EC CI_NO_TRANSFORM

      SELECT SINGLE
        Country,
        Language,
        Region,
        RegionName
      FROM i_regiontext  WHERE region = @ls_sopart_ag-ag_region AND language = 'E' AND country = @ls_sopart_ag-ag_country
      INTO @DATA(lv_st_name_ag).                   "#EC CI_NO_TRANSFORM

      lv_sold_adr3 = ls_sopart_ag-ag_city && '-' && ls_sopart_ag-ag_pin && ',' && lv_cn_nm-countryname.
      lv_sold_adr4 = lv_st_name_ag-regionname. "ls_sopart_ag-ag_region && '(' && lv_st_name_ag-RegionName && ')'.
      gs_sohdr-buyr_name        = ls_sopart_ag-ag_name.
      gs_sohdr-buyr_addrs1      = lv_sold_adr1.
      gs_sohdr-buyr_addrs2      = lv_sold_adr2.
      gs_sohdr-buyr_addrs3      = lv_sold_adr3.
      gs_sohdr-buyr_addrs4      = ''. "lv_sold_adr4.
      gs_sohdr-buyr_phone        = ''.
      gs_sohdr-buyr_state        = ''.
      gs_sohdr-buyr_state_code   = ''.

      SELECT SINGLE
        Country,
        Language,
        CountryName,
        CountryShortName
      FROM i_countrytext   WHERE country = @ls_sopart-we_country AND language = 'E'
      INTO @DATA(lv_cn_nm1).                       "#EC CI_NO_TRANSFORM

      SELECT SINGLE
        Country,
        Language,
        Region,
        RegionName
      FROM i_regiontext  WHERE region = @ls_sopart-we_region AND language = 'E' AND country = @ls_sopart-we_country
      INTO @DATA(lv_st_name_we1).                  "#EC CI_NO_TRANSFORM

      lv_shp_adr3 = ls_sopart-we_city && '-' && ls_sopart-we_pin && ',' && lv_cn_nm1-countryname.
      lv_shp_adr4 = lv_st_name_we1-regionname. "ls_sopart-we_region && '(' && lv_st_name_we1-RegionName && ')'.

      gs_sohdr-cnsinee_code     = ''.
      gs_sohdr-cnsinee_name     = ls_sopart-we_name.
      gs_sohdr-cnsinee_addrs1   = lv_shp_adr1.
      gs_sohdr-cnsinee_addrs2   = lv_shp_adr2.
      gs_sohdr-cnsinee_addrs3   = lv_shp_adr3.
      gs_sohdr-cnsinee_addrs4   = ''. "lv_shp_adr4.
      gs_sohdr-cnsinee_gstin     = ''.
      gs_sohdr-cnsinee_stat_name = ''.
      gs_sohdr-cnsinee_stat_code = ''.

      IF ls_sopart_ag-ag_code EQ ls_sopart-ship_to_party.
        gs_sohdr-cnsinee_name = 'Same as buyer' ##NO_TEXT.
        CLEAR: gs_sohdr-cnsinee_addrs1, gs_sohdr-cnsinee_addrs2, gs_sohdr-cnsinee_addrs3, gs_sohdr-cnsinee_addrs4.
      ENDIF.

      gs_sohdr-ship_mode        = ''.
      gs_sohdr-port_disch       = ''.
      gs_sohdr-port_delivry     = ''.
      gs_sohdr-pinst_box        = ''.
      gs_sohdr-pinst_stickr     = ''.
      gs_sohdr-pinst_make       = ''.
      gs_sohdr-made_in_india    = ''.
      gs_sohdr-making_inst      = ''.


      gs_sohdr-agent_from        = ''.
      gs_sohdr-tax_type          = ''.
      gs_sohdr-del_from_date     = ''.
      gs_sohdr-del_to_date       = ''.
      gs_sohdr-broker_name       = ''.
      gs_sohdr-bank_name         = ''.
      gs_sohdr-bank_branch       = ''.
      gs_sohdr-bank_acc          = ''.
      gs_sohdr-bank_ifsc         = ''.

      LOOP AT lt_soitem INTO DATA(ls_souitem) WHERE salesdocument = ls_sohdr-salesdocument.


        gs_item-saleorder       = ls_souitem-salesdocument.
        gs_item-saleitem        = ls_souitem-salesdocumentitem.
        gs_item-sr_num          = ls_souitem-salesdocumentitem.
        gs_item-byur_code       = ls_sohdr-SoldToParty.
        SHIFT gs_item-byur_code LEFT DELETING LEADING '0'.

        READ TABLE lt_product INTO DATA(ls_product) WITH KEY product = ls_souitem-product.
        gs_item-item_code       = ls_souitem-product. "ls_product-productoldid.
        SHIFT gs_item-item_code LEFT DELETING LEADING '0'.
        CLEAR: ls_product.

        gs_item-item_desc       = ls_souitem-salesdocumentitemtext .
        lv_itm_qty = ls_souitem-orderquantity.
        gs_item-item_qty        = lv_itm_qty.
        SHIFT gs_item-item_qty LEFT DELETING LEADING ''.
        lv_sum_qty = lv_sum_qty + ls_souitem-orderquantity.

        gs_item-item_uom        = ls_souitem-orderquantityunit.

        IF gs_item-item_uom = 'ST'.
          gs_item-item_uom = 'PC' ##NO_TEXT.
        ENDIF.

        READ TABLE lt_schdl INTO DATA(ls_schdl) WITH KEY salesdocument = ls_souitem-salesdocument
                                                         salesdocumentitem = ls_souitem-salesdocumentitem.

        gs_item-dispatch_date   = ls_schdl-deliverydate+6(2) && '.' && ls_schdl-deliverydate+4(2) && '.' && ls_schdl-deliverydate+0(4).

        READ TABLE lt_soitem_price INTO DATA(w_item_price)
         WITH KEY salesdocument = ls_sohdr-salesdocument
                  salesdocumentitem = ls_souitem-salesdocumentitem
                  conditiontype = 'PPR0'.

        IF sy-subrc = 0 .
          gs_item-price_usd_fob   = w_item_price-conditionratevalue / w_item_price-conditionquantity .
          gs_item-amt_usd_fob     = gs_item-price_usd_fob * ls_souitem-orderquantity .
          lv_tot_amt = lv_tot_amt + gs_item-amt_usd_fob.
        ENDIF .

        READ TABLE lt_soitem_price INTO w_item_price
        WITH KEY salesdocument = ls_sohdr-salesdocument
                 salesdocumentitem = ls_souitem-salesdocumentitem
                 conditiontype = 'ZDIS'.
        IF sy-subrc = 0 .
          gs_sohdr-disc_amt = gs_sohdr-disc_amt + w_item_price-conditionamount.
        ENDIF .

        READ TABLE lt_soitem_price INTO DATA(w_item_igst)
         WITH KEY salesdocument = ls_sohdr-salesdocument
                  salesdocumentitem = ls_souitem-salesdocumentitem
                  conditiontype = 'JOIG'.
        IF sy-subrc = 0 .
          IF w_item_igst-conditionratevalue EQ '0.100000000'.
            lv_sum_igst = lv_sum_igst + w_item_igst-conditionamount.
          ENDIF.
        ENDIF .

        lv_grand_tot = lv_grand_tot + ls_souitem-netamount .

        APPEND gs_item TO gt_item.
        CLEAR: ls_souitem , gs_item , w_item_price, w_item_igst.
      ENDLOOP.

      gs_sohdr-igst_amt = lv_sum_igst.
      gs_sohdr-sum_qty  = lv_sum_qty.

      gs_sohdr-grand_total      = lv_tot_amt + gs_sohdr-disc_amt + gs_sohdr-igst_amt.
      gs_sohdr-total_amt        = lv_tot_amt.
      gs_sohdr-disc_amt         = gs_sohdr-disc_amt .

      DATA : lv_grand_tot_word TYPE string,
             lv_gst_tot_word   TYPE string.

      DATA:
        lo_amt_words TYPE REF TO zcl_amt_words.

      CREATE OBJECT lo_amt_words.

      lv_grand_tot_word = gs_sohdr-grand_total. "lv_grand_tot.

      lo_amt_words->number_to_words_export(
       EXPORTING
         iv_num   = lv_grand_tot_word
       RECEIVING
         rv_words = DATA(grand_tot_amt_words)
     ).

      gs_sohdr-amt_words        = |{ gs_sohdr-amtount_curr } | && grand_tot_amt_words.

      INSERT LINES OF gt_item INTO TABLE gs_sohdr-xt_item.
      APPEND gs_sohdr TO gt_sohdr.
      CLEAR: ls_sohdr, ls_souitem_new.
    ENDLOOP.

    et_final[] = gt_sohdr[].
  ENDMETHOD.


  METHOD prep_xml_so_prnt.

    DATA : heading      TYPE c LENGTH 100,
           sub_heading  TYPE c LENGTH 200,
           lv_xml_final TYPE string.

    heading = 'SALE ORDER' ##NO_TEXT.

    READ TABLE it_final INTO DATA(ls_final) INDEX 1.
    SHIFT ls_final-sum_qty LEFT DELETING LEADING space.


    DATA(lv_xml) = |<Form>| &&
                   |<SalesDocumentNode>| &&
                   |<heading>{ heading }</heading>| &&
                   |<sub_heading>{ sub_heading }</sub_heading>| &&
                   |<work_addrs>{ ls_final-work_addrs }</work_addrs>| &&
                   |<exptr_code>{ ls_final-exptr_code }</exptr_code>| &&
                   |<exptr_name>{ ls_final-exptr_name }</exptr_name>| &&
                   |<exptr_addrs1>{ ls_final-exptr_addrs1 }</exptr_addrs1>| &&
                   |<exptr_addrs2>{ ls_final-exptr_addrs2 }</exptr_addrs2>| &&
                   |<exptr_addrs3>{ ls_final-exptr_addrs3 }</exptr_addrs3>| &&
                   |<exptr_addrs4>{ ls_final-exptr_addrs4 }</exptr_addrs4>| &&
                   |<exptr_gstin>{ ls_final-exptr_gstin }</exptr_gstin>| &&
                   |<exptr_pan>{ ls_final-exptr_pan }</exptr_pan>| &&
                   |<exptr_email>{ ls_final-exptr_email }</exptr_email>| &&
                   |<exptr_phone>{ ls_final-exptr_phone }</exptr_phone>| &&
                   |<fact_addrs1>{ ls_final-fact_addrs1 }</fact_addrs1>| &&
                   |<fact_addrs2>{ ls_final-fact_addrs2 }</fact_addrs2>| &&
                   |<fact_addrs3>{ ls_final-fact_addrs3 }</fact_addrs3>| &&
                   |<our_ref>{ ls_final-our_ref }</our_ref>| &&
                   |<our_ref_date>{ ls_final-our_ref_date }</our_ref_date>| &&
                   |<cust_odr_ref>{ ls_final-cust_odr_ref }</cust_odr_ref>| &&
                   |<cust_odr_date>{ ls_final-cust_odr_date }</cust_odr_date>| &&
                   |<buyr_code>{ ls_final-buyr_code }</buyr_code>| &&
                   |<buyr_name>{ ls_final-buyr_name }</buyr_name>| &&
                   |<buyr_addrs1>{ ls_final-buyr_addrs1 }</buyr_addrs1>| &&
                   |<buyr_addrs2>{ ls_final-buyr_addrs2 }</buyr_addrs2>| &&
                   |<buyr_addrs3>{ ls_final-buyr_addrs3 }</buyr_addrs3>| &&
                   |<buyr_addrs4>{ ls_final-buyr_addrs4 }</buyr_addrs4>| &&
                   |<buyr_phone>{ ls_final-buyr_phone }</buyr_phone>| &&
                   |<buyr_state>{ ls_final-buyr_state }</buyr_state>| &&
                   |<buyr_state_code>{ ls_final-buyr_state_code }</buyr_state_code>| &&
                   |<cnsinee_code>{ ls_final-cnsinee_code }</cnsinee_code>| &&
                   |<cnsinee_name>{ ls_final-cnsinee_name }</cnsinee_name>| &&
                   |<cnsinee_addrs1>{ ls_final-cnsinee_addrs1 }</cnsinee_addrs1>| &&
                   |<cnsinee_addrs2>{ ls_final-cnsinee_addrs2 }</cnsinee_addrs2>| &&
                   |<cnsinee_addrs3>{ ls_final-cnsinee_addrs3 }</cnsinee_addrs3>| &&
                   |<cnsinee_addrs4>{ ls_final-cnsinee_addrs4 }</cnsinee_addrs4>| &&
                   |<cnsinee_gstin>{ ls_final-cnsinee_gstin }</cnsinee_gstin>| &&
                   |<cnsinee_stat_name>{ ls_final-cnsinee_stat_name }</cnsinee_stat_name>| &&
                   |<cnsinee_stat_code>{ ls_final-cnsinee_stat_code }</cnsinee_stat_code>| &&
                   |<agent_from>{ ls_final-agent_from }</agent_from>| &&
                   |<tax_type>{ ls_final-tax_type }</tax_type>| &&
                   |<del_from_date>{ ls_final-del_from_date }</del_from_date>| &&
                   |<del_to_date>{ ls_final-del_to_date }</del_to_date>| &&
                   |<broker_name>{ ls_final-broker_name }</broker_name>| &&
                   |<bank_name>{ ls_final-bank_name }</bank_name>| &&
                   |<bank_branch>{ ls_final-bank_branch }</bank_branch>| &&
                   |<bank_acc>{ ls_final-bank_acc }</bank_acc>| &&
                   |<bank_ifsc>{ ls_final-bank_ifsc }</bank_ifsc>| &&
                   |<price_term>{ ls_final-price_term }</price_term>| &&
                   |<pay_term>{ ls_final-pay_term }</pay_term>| &&
                   |<inco_term>{ ls_final-inco_term }</inco_term>| &&
                   |<amount_curr>{ ls_final-amtount_curr }</amount_curr>| &&
                   |<ship_mode>{ ls_final-ship_mode }</ship_mode>| &&
                   |<port_disch>{ ls_final-port_disch }</port_disch>| &&
                   |<port_delivry>{ ls_final-port_delivry }</port_delivry>| &&
                   |<total_amt>{ ls_final-total_amt }</total_amt>| &&
                   |<disc_amt>{ ls_final-disc_amt }</disc_amt>| &&
                   |<amt_words>{ ls_final-amt_words }</amt_words>| &&
                   |<igst_amt>{ ls_final-igst_amt }</igst_amt>| &&
                   |<sum_qty>{ ls_final-sum_qty }</sum_qty>| &&
                   |<grand_total>{ ls_final-grand_total }</grand_total>| &&
                   |<pinst_box>{ ls_final-pinst_box }</pinst_box>| &&
                   |<pinst_stickr>{ ls_final-pinst_stickr }</pinst_stickr>| &&
                   |<pinst_make>{ ls_final-pinst_make }</pinst_make>| &&
                   |<made_in_india>{ ls_final-made_in_india }</made_in_india>| &&
                   |<making_inst>{ ls_final-making_inst }</making_inst>| &&
                   |<ItemData>| .

    DATA : lv_item TYPE string .
    DATA : srn TYPE c LENGTH 10.
    CLEAR : lv_item , srn .

    LOOP AT ls_final-xt_item INTO DATA(ls_item).

      srn = ls_item-sr_num. "srn + 1 .
      SHIFT srn LEFT DELETING LEADING '0'.



      lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                |<sr_num>{ srn }</sr_num>| &&
                |<saleorder>{ ls_item-saleorder }</saleorder>| &&
                |<saleitem>{ ls_item-saleitem }</saleitem> | &&
                |<byur_code>{ ls_item-byur_code }</byur_code>| &&
                |<item_code>{ ls_item-item_code }</item_code>| &&
                |<item_desc>{ ls_item-item_desc }</item_desc>| &&
                |<item_qty>{ ls_item-item_qty }</item_qty>| &&
                |<item_uom>{ ls_item-item_uom }</item_uom>| &&
                |<dispatch_date>{ ls_item-dispatch_date }</dispatch_date>| &&
                |<price_usd_fob>{ ls_item-price_usd_fob }</price_usd_fob>| &&
                |<amt_usd_fob>{ ls_item-amt_usd_fob }</amt_usd_fob>| &&
                |</ItemDataNode>|  .

    ENDLOOP.


  lv_xml = |{ lv_xml }{ lv_item }| &&
                     |</ItemData>| &&
                     |</SalesDocumentNode>| &&
                     |</Form>|.

  DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
  iv_xml_base64 = ls_data_xml_64.

ENDMETHOD.
ENDCLASS.
