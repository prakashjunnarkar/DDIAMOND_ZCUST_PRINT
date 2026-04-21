    CLASS zcl_sd_custom_print DEFINITION
      PUBLIC
      FINAL
      CREATE PUBLIC .

      PUBLIC SECTION.
        DATA:
          gt_final  TYPE TABLE OF zi_sale_reg,
          lv_char10 TYPE c LENGTH 10.

        METHODS:
          get_billing_data
            IMPORTING
                      iv_vbeln        LIKE lv_char10
                      iv_action       LIKE lv_char10
            RETURNING VALUE(et_final) LIKE gt_final,

          prep_xml_tax_inv
            IMPORTING
                      it_final             LIKE gt_final
                      iv_action            LIKE lv_char10
                      im_prntval           LIKE lv_char10
            RETURNING VALUE(iv_xml_base64) TYPE string,

          "BOC by Neelam on 22.06.2025

          prep_xml_tax_inv1
            IMPORTING
                      it_final             LIKE gt_final
                      iv_action            LIKE lv_char10
                      im_prntval           LIKE lv_char10
            RETURNING VALUE(iv_xml_base64) TYPE string,
          "EOC by Neelam on 22.06.2025

          get_packing_data
            IMPORTING
                      im_pack         LIKE lv_char10
                      iv_action       LIKE lv_char10
            RETURNING VALUE(et_final) LIKE gt_final,

          prep_xml_pack_inv
            IMPORTING
                      it_final             LIKE gt_final
                      iv_action            LIKE lv_char10
                      im_prntval           LIKE lv_char10
                      im_pack              LIKE lv_char10
            RETURNING VALUE(iv_xml_base64) TYPE string,

          "BOC by Neelam on 01.07.2025
          prep_xml_pack_inv1
            IMPORTING
                      it_final             LIKE gt_final
                      iv_action            LIKE lv_char10
                      im_prntval           LIKE lv_char10
                      im_pack              LIKE lv_char10
            RETURNING VALUE(iv_xml_base64) TYPE string.
        "EOC by Neelam on 01.07.2025

      PROTECTED SECTION.
      PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_SD_CUSTOM_PRINT IMPLEMENTATION.


      METHOD get_billing_data.

        """*****************Start: Fetch & Prepare Data******************************

        DATA : lv_billtype TYPE RANGE OF zi_sale_reg-billingdocumenttype,
               wa_billtype LIKE LINE OF  lv_billtype,
               lv_distchnl TYPE RANGE OF zi_sale_reg-distributionchannel,
               wa_distchnl LIKE LINE  OF lv_distchnl.


        SELECT * FROM zi_sale_reg  WHERE billingdocument = @iv_vbeln
                                    AND billingdocumenttype IN @lv_billtype
                                    AND distributionchannel IN @lv_distchnl
                                        INTO TABLE @DATA(it_final) .

        IF it_final IS NOT INITIAL.

          et_final[] = it_final[].

        ENDIF.

        """*****************End: Fetch & Prepare Data********************************

      ENDMETHOD.


      METHOD get_packing_data.

        """*****************Start: Fetch & Prepare Data******************************


        SELECT * FROM zsd_pack_data WHERE pack_num = @im_pack ORDER BY PRIMARY KEY
         INTO @DATA(wa_pack_data1)
         UP TO 1 ROWS .                       "#EC CI_ALL_FIELDS_NEEDED
        ENDSELECT.

        SELECT * FROM zi_sale_reg
        WHERE billingdocument    = @wa_pack_data1-vbeln AND
              "BillingDocumentType = 'F2' AND
              bill_to_party NE '' AND
              billingdocumentiscancelled = ''
        INTO TABLE @DATA(it_final) .          "#EC CI_ALL_FIELDS_NEEDED


        et_final[] = it_final[].

        """*****************End: Fetch & Prepare Data********************************

      ENDMETHOD.


      METHOD prep_xml_pack_inv.

        DATA:
          lv_plant_addrs1 TYPE string,
          lv_plant_addrs2 TYPE string,
          lv_plant_addrs3 TYPE string,
          lv_plant_cin    TYPE string,
          lv_plant_iec    TYPE string.

        DATA: lv_vbeln_n  TYPE c LENGTH 10. "char10 .

        DATA:
*          tot_amt   TYPE p LENGTH 16 DECIMALS 2,
*          tot_dis   TYPE p LENGTH 16 DECIMALS 2,
          tot_oth       TYPE p LENGTH 16 DECIMALS 2,
          grand_tot     TYPE p LENGTH 16 DECIMALS 2,
          lv_unit_price TYPE p LENGTH 16 DECIMALS 2,
          lv_tot_qty    TYPE p LENGTH 16 DECIMALS 2,
          lv_po_numbers TYPE string,
          lv_lut_num    TYPE c LENGTH 40,
          lv_bank1      TYPE c LENGTH 100,
          lv_bank2      TYPE c LENGTH 100,
          lv_bank3      TYPE c LENGTH 100,
          lv_bank4      TYPE c LENGTH 100.

        IF it_final[] IS NOT INITIAL.

          LOOP AT it_final INTO DATA(wa_final).

            IF sy-tabix = 1.
              lv_po_numbers = lv_po_numbers && wa_final-purchaseorderbycustomer.
            ELSE.
              lv_po_numbers = lv_po_numbers && '/' && wa_final-purchaseorderbycustomer.
            ENDIF.

            CLEAR: wa_final.
          ENDLOOP.

          READ TABLE it_final INTO DATA(w_final) INDEX 1 .
          lv_vbeln_n = w_final-billingdocument.
          lv_vbeln_n = |{ lv_vbeln_n ALPHA = IN }| .
          """    SHIFT lv_vbeln_n LEFT DELETING LEADING '0'.

          SELECT * FROM zsd_pack_data WHERE pack_num = @im_pack
                   INTO TABLE @DATA(lt_pack).

          SELECT SINGLE * FROM zsd_pack_data WHERE pack_num =  @im_pack INTO @DATA(wa_pack_data). "#EC WARNOK

          REPLACE ALL OCCURRENCES OF '&' IN  w_final-re_name WITH '' .
          REPLACE ALL OCCURRENCES OF '&' IN  w_final-we_name WITH '' .

          DATA : odte_text TYPE c LENGTH 20 , """"original duplicate triplicate ....
                 tot_qty   TYPE p LENGTH 16 DECIMALS 2,
                 tot_amt   TYPE p LENGTH 16 DECIMALS 2,
                 tot_dis   TYPE p LENGTH 16 DECIMALS 2.

          IF im_prntval = 'Original' ##NO_TEXT.
            "odte_text = odte_text = |White-Original            Pink-Duplicate          Yellow-Triplicate|  ##NO_TEXT.
            odte_text = 'Original' ##NO_TEXT.
          ELSEIF im_prntval = 'Duplicate' ##NO_TEXT.
            odte_text = 'Duplicate' ##NO_TEXT.
          ELSEIF im_prntval = 'Triplicate' ##NO_TEXT.
            odte_text = 'Triplicate'  ##NO_TEXT.
          ELSEIF im_prntval = 'Extra' ##NO_TEXT.
            odte_text = 'Extra Copy' ##NO_TEXT.
          ENDIF.

          DATA : heading     TYPE c LENGTH 100,
                 sub_heading TYPE c LENGTH 100,
                 for_sign    TYPE c LENGTH 100.


          IF iv_action = 'export'  ##NO_TEXT.
            heading = 'EXPORT INVOICE' ##NO_TEXT.
          ELSEIF iv_action = 'packls'  ##NO_TEXT.
            heading = 'PACKING LIST' ##NO_TEXT.
          ENDIF .


          for_sign  = 'DE DIAMOND ELECTRIC INDIA PVT. LTD.' ##NO_TEXT.

          DATA : lv_bill_adr1 TYPE c LENGTH 100 .
          DATA : lv_bill_adr2 TYPE c LENGTH 100 .
          DATA : lv_bill_adr3 TYPE c LENGTH 100.

          DATA : lv_shp_adr1 TYPE c LENGTH 100.
          DATA : lv_shp_adr2 TYPE c LENGTH 100.
          DATA : lv_shp_adr3 TYPE c LENGTH 100.

          DATA : lv_sp_adr1 TYPE c LENGTH 100,
                 lv_sp_adr2 TYPE c LENGTH 100,
                 lv_sp_adr3 TYPE c LENGTH 100,
                 lv_es_adr1 TYPE c LENGTH 100,
                 lv_es_adr2 TYPE c LENGTH 100,
                 lv_es_adr3 TYPE c LENGTH 100.

          """"""" bill address set """"""""
          IF w_final-re_house_no IS NOT INITIAL .
            lv_bill_adr1 = |{ w_final-re_house_no }| .
          ENDIF .

          IF w_final-re_street IS NOT INITIAL .
            IF lv_bill_adr1 IS NOT INITIAL   .
              lv_bill_adr1 = |{ lv_bill_adr1 } , { w_final-re_street }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
            ELSE .
              lv_bill_adr1 = |{ w_final-re_street }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
            ENDIF .
          ENDIF .

          IF w_final-re_street1 IS NOT INITIAL .
            IF lv_bill_adr1 IS NOT INITIAL   .
              lv_bill_adr1 = |{ lv_bill_adr1 }, { w_final-re_street1 }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
            ELSE .
              lv_bill_adr1 = |{ w_final-re_street1 }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
            ENDIF .
          ENDIF .

          DATA(len) = strlen( lv_bill_adr1 ) .
          len = len - 40.
          IF strlen( lv_bill_adr1 ) GT 40 .
            lv_bill_adr2 = |{ lv_bill_adr1+40(len) },| .
            lv_bill_adr1 = lv_bill_adr1+0(40) .
          ENDIF .
          """"""" eoc bill address set """"""""


          """"""" ship address set """"""""
          IF w_final-we_house_no IS NOT INITIAL .
            lv_shp_adr1 = |{ w_final-we_house_no }| .
          ENDIF .

          IF w_final-we_street IS NOT INITIAL .
            IF lv_shp_adr1 IS NOT INITIAL   .
              lv_shp_adr1 = |{ lv_shp_adr1 } , { w_final-we_street }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
            ELSE .
              lv_shp_adr1 = |{ w_final-we_street }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
            ENDIF .
          ENDIF .

          IF w_final-we_street1 IS NOT INITIAL .
            IF lv_shp_adr1 IS NOT INITIAL   .
              lv_shp_adr1 = |{ lv_shp_adr1 } , { w_final-we_street1 }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
            ELSE .
              lv_shp_adr1 = |{ w_final-we_street1 }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
            ENDIF .
          ENDIF .

          len = strlen( lv_shp_adr1 ) .
          len = len - 40.
          IF strlen( lv_shp_adr1 ) GT 40 .
            lv_shp_adr2 = |{ lv_shp_adr1+40(len) },| .
            lv_shp_adr1 = lv_shp_adr1+0(40) .
          ENDIF .

*          """"""" sp address set """"""""
          IF w_final-sp_house_no IS NOT INITIAL .
            lv_sp_adr1 = |{ w_final-sp_house_no }| .
          ENDIF .

          IF w_final-sp_street IS NOT INITIAL .
            IF lv_sp_adr1 IS NOT INITIAL   .
              lv_sp_adr1 = |{ lv_sp_adr1 } , { w_final-sp_street }| .
            ELSE .
              lv_sp_adr1 = |{ w_final-sp_street }| .
            ENDIF .
          ENDIF .

          IF w_final-sp_street1 IS NOT INITIAL .
            IF lv_sp_adr1 IS NOT INITIAL   .
              lv_sp_adr1 = |{ lv_sp_adr1 } , { w_final-sp_street1 }| .
            ELSE .
              lv_sp_adr1 = |{ w_final-sp_street1 }| .
            ENDIF .
          ENDIF .

          len = strlen( lv_sp_adr1 ) .
          IF len GT 40 .
            lv_sp_adr2 = |{ lv_sp_adr1+40(len) },| .
            lv_sp_adr1 = lv_sp_adr1+0(40) .
          ENDIF .

*          """"""" ES address set """"""""
*          IF w_final-es_house_no IS NOT INITIAL .
*            lv_es_adr1 = |{ w_final-es_house_no }| .
*          ENDIF .
*
*          IF w_final-es_street IS NOT INITIAL .
*            IF lv_es_adr1 IS NOT INITIAL   .
*              lv_es_adr1 = |{ lv_es_adr1 } , { w_final-es_street }| .
*            ELSE .
*              lv_es_adr1 = |{ w_final-es_street }| .
*            ENDIF .
*          ENDIF .
*
*          IF w_final-es_street1 IS NOT INITIAL .
*            IF lv_es_adr1 IS NOT INITIAL   .
*              lv_es_adr1 = |{ lv_es_adr1 } , { w_final-es_street1 }| .
*            ELSE .
*              lv_es_adr1 = |{ w_final-es_street1 }| .
*            ENDIF .
*          ENDIF .

          len = strlen( lv_es_adr1 ) .
          IF len GT 40 .
            lv_es_adr2 = |{ lv_es_adr1+40(len) },| .
            lv_es_adr1 = lv_es_adr1+0(40) .
          ENDIF .

          ""****Start:Logic to read text of Billing Header************
          DATA:
            lo_text           TYPE REF TO zcl_read_text,
            gt_text           TYPE TABLE OF zstr_billing_text,
            gt_item_text      TYPE TABLE OF zstr_billing_text,
            lo_amt_words      TYPE REF TO zcl_amt_words,
            lv_grand_tot_word TYPE string.

          DATA:
            inst_hsn_code    TYPE string,
            inst_sbno        TYPE string,
            inst_sb_date     TYPE string,
            inst_rcno        TYPE string,
            trans_mode       TYPE string,
            inst_date_accpt  TYPE string,
            inst_delv_date   TYPE string,
            inst_transipment TYPE string,
            inst_no_orginl   TYPE string,
            inst_frt_amt     TYPE string,
            inst_frt_pay_at  TYPE string,
            inst_destination TYPE string,
            inst_particular  TYPE string,
            inst_collect     TYPE string.

          CREATE OBJECT lo_text.
          CREATE OBJECT lo_amt_words.

          ""****End:Logic to read text of Billing Header************

          lo_text->read_text_billing_header(
             EXPORTING
               iv_billnum = lv_vbeln_n
             RECEIVING
               xt_text    = gt_text "This will contain all text IDs data of given billing document
           ).


          DATA : lv_vessel     TYPE c LENGTH 100,
                 lv_plant_name TYPE c LENGTH 100.
          DATA : lv_no_pck TYPE c LENGTH 100.

          DATA : lv_gross TYPE c LENGTH 100.

          DATA : lv_other_ref TYPE c LENGTH 100.
          CLEAR : lv_vessel , lv_no_pck , lv_gross .
          READ TABLE gt_text INTO DATA(w_text) WITH KEY longtextid = 'Z004' .
          IF sy-subrc = 0 .
            lv_vessel = w_text-longtext .
          ENDIF .

          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z011' .
          IF sy-subrc = 0 .
            lv_gross = w_text-longtext .
          ENDIF .

          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'TX05' .
          IF sy-subrc = 0 .
            lv_other_ref = w_text-longtext .
          ENDIF .

          """***For Shipping Instruction****************
          CLEAR: w_text.
          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z005' .
          IF sy-subrc = 0 .
            inst_sbno = w_text-longtext .
          ENDIF .

          CLEAR: w_text.
          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z006' .
          IF sy-subrc = 0 .
            inst_rcno = w_text-longtext .
          ENDIF .

          CLEAR: w_text.
          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z013' .
          IF sy-subrc = 0 .
            inst_no_orginl = w_text-longtext .
          ENDIF .

          CLEAR: w_text.
          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z014' .
          IF sy-subrc = 0 .
            inst_particular = w_text-longtext .
          ENDIF .

          CLEAR: w_text.
          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z015' .
          IF sy-subrc = 0 .
            inst_date_accpt = w_text-longtext .
          ENDIF .

          CLEAR: w_text.
          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z002' .
          IF sy-subrc = 0 .
            trans_mode = w_text-longtext .
          ENDIF .
          """***For Shipping Instruction****************

          ""   CLEAR : w_final , wa_pack_data , for_sign , sub_heading , heading , odte_text .
          "  FREE : it_final .

          DATA:
             lv_bill_date TYPE c LENGTH 10.

          lv_bill_date = w_final-billingdocumentdate+6(2) && '.' && w_final-billingdocumentdate+4(2) && '.' && w_final-billingdocumentdate+0(4).
          wa_pack_data-iec = ''.
          w_final-phoneareacodesubscribernumber = '+91-129-2275001' ##NO_TEXT.
          wa_pack_data-country_org = 'India' ##NO_TEXT.
          wa_pack_data-country_of_fdest = w_final-re_country.

          ""*****Start: Item XML*****************************************************
          DATA : lv_item      TYPE string,
                 lv_pallet_no TYPE string,
                 srn          TYPE c LENGTH 3,
                 lv_anp_part  TYPE string.

          IF w_final-item_igstrate EQ 0.

            sub_heading = '(Supply meant for Export Under Bond or Letter of Undertaking Without Payment of Integrated Tax)' ##NO_TEXT.

            SELECT SINGLE * FROM zsd_sysid
                            WHERE objcode = 'LUTNO' AND sysid = @sy-sysid
                            INTO @DATA(ls_sysid_pass).

            IF sy-subrc EQ 0.
              lv_lut_num = ls_sysid_pass-objvalue.
            ENDIF.

          ELSE.
            sub_heading = '(Supply meant for Export Under Bond or Letter of Undertaking With Payment of Integrated Tax)' ##NO_TEXT.
          ENDIF.

          IF iv_action = 'export'  ##NO_TEXT.

            DATA(xt_pack) = lt_pack[].
            SORT lt_pack BY vbeln posnr.
            DELETE ADJACENT DUPLICATES FROM lt_pack COMPARING vbeln posnr.

            LOOP AT lt_pack ASSIGNING FIELD-SYMBOL(<lfs_pack>).

              IF <lfs_pack> IS ASSIGNED.
                CLEAR: <lfs_pack>-qty_in_pcs, <lfs_pack>-pkg_vol, <lfs_pack>-pkg_length.
                LOOP AT xt_pack INTO DATA(xs_pack) WHERE vbeln = <lfs_pack>-vbeln AND posnr = <lfs_pack>-posnr.
                  "<lfs_pack>-qty_in_pcs = <lfs_pack>-qty_in_pcs + xs_pack-qty_in_pcs.
                  <lfs_pack>-pkg_vol    = <lfs_pack>-pkg_vol + xs_pack-pkg_vol.
                  <lfs_pack>-pkg_length = <lfs_pack>-pkg_length + xs_pack-pkg_length.
                  CLEAR: xs_pack.
                ENDLOOP.

                READ TABLE it_final INTO DATA(xw_final) WITH KEY billingdocument = <lfs_pack>-vbeln billingdocumentitem = <lfs_pack>-posnr.
                IF sy-subrc EQ 0.
                  <lfs_pack>-qty_in_pcs = xw_final-billingquantity.
                ENDIF.

              ENDIF.

            ENDLOOP.

          ENDIF.

          IF iv_action = 'packls'.
            SORT lt_pack BY pallet_no.
          ENDIF.

          CLEAR : lv_item , srn .
          CLEAR: tot_amt, tot_dis, tot_oth, grand_tot.
          LOOP AT lt_pack INTO DATA(w_pack) .

            READ TABLE it_final INTO DATA(w_item) WITH KEY
                                billingdocument     = w_pack-vbeln billingdocumentitem = w_pack-posnr.
            "DeliveryDocumentItem = w_pack-posnr.

            CLEAR: gt_item_text.
            lo_text->read_text_billing_item(
              EXPORTING
                im_billnum  = w_item-billingdocument
                im_billitem = w_item-billingdocumentitem
              RECEIVING
                xt_text     = gt_item_text
            ).

            IF gt_item_text[] IS NOT INITIAL.
              READ TABLE gt_item_text INTO DATA(gs_item_text) INDEX 1.
            ENDIF.

            srn = srn + 1 .
            lv_pallet_no =  |{ w_item-purchaseorderbycustomer } / { w_item-customerpurchaseorderdate+6(2) }.{ w_item-customerpurchaseorderdate+4(2) }.{ w_item-customerpurchaseorderdate+0(4) } / { gs_item_text-longtext }| .

            lv_tot_qty    =  w_pack-qty_in_pcs * w_pack-type_pkg.

            IF iv_action = 'export'.
              wa_pack_data-total_pcs      = wa_pack_data-total_pcs + w_pack-qty_in_pcs.
            ELSE.
              wa_pack_data-total_pcs      = wa_pack_data-total_pcs + lv_tot_qty.
            ENDIF.

            wa_pack_data-tot_net_wgt    = wa_pack_data-tot_net_wgt + w_pack-pkg_vol.
            wa_pack_data-tot_gross_wgt  = wa_pack_data-tot_gross_wgt +  w_pack-pkg_length.




            lv_anp_part  = w_item-materialbycustomer. "w_pack-matnr. "w_item-ProductOldID.
            IF w_pack-kdmat IS INITIAL.
              w_pack-kdmat = lv_anp_part.
            ENDIF.
            """""""""""""""""""""""""""""""""""
            SELECT SINGLE * FROM zi_regiontext  WHERE region = @w_final-region AND language = 'E' AND country = @w_final-country
             INTO @DATA(lv_st_nm1).           "#EC CI_ALL_FIELDS_NEEDED

            SELECT SINGLE * FROM zi_regiontext  WHERE region = @w_final-re_region AND language = 'E' AND country = @w_final-re_country
            INTO @DATA(lv_st_name_re1).       "#EC CI_ALL_FIELDS_NEEDED

            SELECT SINGLE * FROM zi_regiontext  WHERE region = @w_final-we_region AND language = 'E' AND country = @w_final-we_country
            INTO @DATA(lv_st_name_we1).       "#EC CI_ALL_FIELDS_NEEDED


            SELECT SINGLE * FROM zi_countrytext   WHERE country = @w_final-country AND language = 'E'
            INTO @DATA(lv_cn_nm1).            "#EC CI_ALL_FIELDS_NEEDED

            SELECT SINGLE * FROM zi_countrytext   WHERE country = @w_final-re_country AND language = 'E'
            INTO @DATA(lv_cn_name_re1).       "#EC CI_ALL_FIELDS_NEEDED

            SELECT SINGLE * FROM zi_countrytext   WHERE country = @w_final-we_country AND language = 'E'
            INTO @DATA(lv_cn_name_we1).       "#EC CI_ALL_FIELDS_NEEDED

            SELECT SINGLE * FROM zi_countrytext   WHERE country = @wa_pack_data-country_of_fdest
             AND language = 'E'  INTO @DATA(lv_cn_name_fdes). "#EC CI_ALL_FIELDS_NEEDED

            REPLACE ALL OCCURRENCES OF '&' IN  w_item-materialbycustomer WITH '' .
            REPLACE ALL OCCURRENCES OF '&' IN  lv_anp_part WITH '' .
            REPLACE ALL OCCURRENCES OF '&' IN  w_item-billingdocumentitemtext WITH '' .

            IF w_item-conditionquantity IS NOT INITIAL .
              lv_unit_price = w_item-item_unitprice / w_item-conditionquantity.
            ELSE.
              lv_unit_price = w_item-item_unitprice.
            ENDIF.

            "w_item-item_unitprice = w_item-item_unitprice / w_item-ConditionQuantity.
            w_item-item_totalamount = w_item-billingquantity * lv_unit_price. "w_item-item_unitprice.

            tot_amt = tot_amt + w_item-item_totalamount.
            tot_dis = tot_dis + w_item-item_discountamount.
            tot_oth = tot_oth + w_item-item_freight + w_item-item_othercharge.

            lv_item = |{ lv_item }| && |<ItemDataNode>| &&

                      |<cust_pono> { lv_pallet_no }</cust_pono>| &&
                      |<pallet_no>{ w_pack-pallet_no }</pallet_no>| &&
                      |<pkgs_from_to>{ w_pack-pkg_no }</pkgs_from_to>| &&
                      |<buyer_code>{ w_pack-kdmat }</buyer_code>| &&
                      |<anp_part>{ lv_anp_part }</anp_part>| &&
                      |<item_code>{ lv_anp_part }</item_code>| &&
                      |<item_desc>{  w_item-billingdocumentitemtext }</item_desc>| &&
                      |<hsn_code>{  w_item-hsn }</hsn_code>| &&
                      |<qty>{ w_item-billingquantity }</qty>| &&
                      |<uom>{ w_item-baseunit }</uom>| &&
                      |<qty_pcs>{ w_pack-qty_in_pcs }</qty_pcs>| &&
                      |<net_wgt>{ w_pack-pkg_vol }</net_wgt>| &&
                      |<gross_wgt>{ w_pack-pkg_length }</gross_wgt>| &&
                      |<rate>{ lv_unit_price }</rate>| &&
                      |<amount>{ w_item-item_totalamount }</amount>| &&
                      |<no_of_pkg>{ w_pack-type_pkg }</no_of_pkg>| &&
                      |<tot_qty>{ lv_tot_qty }</tot_qty>| &&
                      |<box_size>{ w_pack-box_size }</box_size>| &&
*                    |<item_code>{ w_item-MaterialDescriptionByCustomer }</item_code>| &&
                      |</ItemDataNode>|  .

          ENDLOOP .

          IF iv_action = 'shpinst'.

            heading = 'SLI'.

            inst_delv_date     = ''.
            inst_transipment   = ''.
            inst_frt_amt       = ''.
            inst_frt_pay_at    = ''.
            inst_destination   = ''.

            IF w_final-incotermsclassification = 'FOB' OR w_final-incotermsclassification = 'FCA'.
              inst_collect       = 'FREIGHT COLLECT' ##NO_TEXT.
            ELSE.
              inst_collect       = 'IHC COLLECT' ##NO_TEXT.
            ENDIF.

            DATA(lt_inst) = it_final[].
            SORT lt_inst BY hsn.
            DELETE ADJACENT DUPLICATES FROM lt_inst COMPARING hsn.

            LOOP AT lt_inst INTO DATA(ls_inst).
              inst_hsn_code  = inst_hsn_code && ls_inst-hsn.
            ENDLOOP.

            CLEAR: lv_item.
            lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                      |<cust_pono> { lv_pallet_no }</cust_pono>| &&
                      |</ItemDataNode>|  .

          ENDIF.

          grand_tot = tot_amt - tot_dis + tot_oth.
          lv_grand_tot_word  = grand_tot.
          lo_amt_words->number_to_words_export(
           EXPORTING
             iv_num   = lv_grand_tot_word
           RECEIVING
             rv_words = DATA(grand_tot_amt_words)
         ).

          IF w_final-transactioncurrency EQ 'USD'.

          ELSEIF w_final-transactioncurrency EQ 'EUR'.
            REPLACE ALL OCCURRENCES OF 'Dollars' IN grand_tot_amt_words WITH 'Euro' ##NO_TEXT.
          ENDIF.

          DATA : lv_declaration1 TYPE string .
          CLEAR: w_text.
          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z016' .
          IF sy-subrc = 0 .
            lv_declaration1 = w_text-longtext .
          ENDIF .

          ""*****End: Item XML*****************************************************
          CLEAR : odte_text .
          ""*****Start: Header XML*****************************************************
*          w_final-plantname = 'DE DIAMOND ELECTRIC INDIA PVT. LTD' ##NO_TEXT.
          lv_plant_name     = 'DE DIAMOND ELECTRIC INDIA PVT. LTD' ##NO_TEXT.
          w_final-phoneareacodesubscribernumber = '9053029817' ##NO_TEXT.
          wa_pack_data-ad_code = ''.
          lv_vessel = wa_pack_data-vessel.

          REPLACE ALL OCCURRENCES OF '&' IN w_final-incotermslocation1 WITH ''.


          lv_plant_addrs1  = 'Sector - 5, HSIIDC Growth Centre, Plot no. 38' ##NO_TEXT.
          lv_plant_addrs2  = 'Phase-II, Industrial Model Twp, Bawal' ##NO_TEXT.
          lv_plant_addrs3  = 'Haryana 123501' ##NO_TEXT. "-121003, HR-India
          lv_plant_cin     = 'U31908HR2007FTC039788' ##NO_TEXT.
          lv_plant_iec     = '0507048172' ##NO_TEXT.

          lv_bank1 = 'MUFG Bank Limited' ##NO_TEXT.
          lv_bank2 = '10 Ground floor Commercial Plot No.09, RIICO, Japanese Zone,' ##NO_TEXT.
          lv_bank3 = 'Neemrana, Alwar, Rajasthan-301705 India' ##NO_TEXT.

          DATA(lv_xml) = |<Form>| &&
                         |<BillingDocumentNode>| &&
                         |<heading>{ heading }</heading>| &&
                         |<sub_heading>{ sub_heading }</sub_heading>| &&
                         |<for_sign>{ for_sign }</for_sign>| &&
                         |<odte_text>{ odte_text }</odte_text>| &&


                          |<plant_code>{ w_final-plant }</plant_code>| &&
                          |<plant_name>{ lv_plant_name }</plant_name>| &&
                          |<plant_address_l1>{ lv_plant_addrs1 }</plant_address_l1>| &&
                          |<plant_address_l2>{ lv_plant_addrs2 }</plant_address_l2>| &&
                          |<plant_address_l3>{ lv_plant_addrs3 }</plant_address_l3>| &&
                          |<plant_cin>{ lv_plant_cin }</plant_cin>| &&
                          |<plant_gstin>{ w_final-plant_gstin }</plant_gstin>| &&
                          |<plant_pan>{ w_final-plant_gstin+2(10) }</plant_pan>| &&
                          |<plant_state_code>{ w_final-region }</plant_state_code>| &&
                          |<plant_state_name>{ w_final-plantname }</plant_state_name>| &&
                          |<plant_phone>{ w_final-phoneareacodesubscribernumber }</plant_phone>| &&
                          |<plant_email>{ w_final-plant_email }</plant_email>| &&

                          |<consignee_code>{ w_final-ship_to_party }</consignee_code>| &&
                          |<consignee_name>{ w_final-we_name }</consignee_name>| &&
                          |<consignee_address_l1>{ lv_shp_adr1 }</consignee_address_l1>| &&
                          |<consignee_address_l2>{ lv_shp_adr2 }</consignee_address_l2>| &&
                          |<consignee_address_l3>{ w_final-we_pin } ({ lv_cn_name_we1-countryname })</consignee_address_l3>| &&
                          |<consignee_cin>{ w_final-plantname }</consignee_cin>| &&
                          |<consignee_gstin>{ w_final-we_tax }</consignee_gstin>| &&
                          |<consignee_pan>{ w_final-we_pan }</consignee_pan>| &&
                          |<consignee_state_code>{ w_final-we_region } ({ lv_st_name_we1-regionname })</consignee_state_code>| &&
                          |<consignee_state_name>{ w_final-we_city }</consignee_state_name>| &&
                          |<consignee_place_suply>{ w_final-we_region }</consignee_place_suply>| &&
                          |<consignee_phone>{ w_final-we_phone4 }</consignee_phone>| &&
                          |<consignee_email>{ w_final-we_email }</consignee_email>| &&


                          |<shipto_code>{ w_final-sp_code }</shipto_code>| &&
                          |<shipto_name>{ w_final-sp_name }</shipto_name>| &&
                          |<shipto_addrs1>{ lv_sp_adr1 }</shipto_addrs1>| &&
                          |<shipto_addrs2>{ lv_sp_adr2 }</shipto_addrs2>| &&
                          |<shipto_addrs3>{ w_final-sp_pin }</shipto_addrs3>| &&

*                          |<secnd_ntfy_code>{ w_final-es_code }</secnd_ntfy_code>| &&
*                          |<secnd_ntfy_name>{ w_final-es_name }</secnd_ntfy_name>| &&
*                          |<secnd_ntfy_addrs1>{ lv_es_adr1 }</secnd_ntfy_addrs1>| &&
*                          |<secnd_ntfy_addrs2>{ lv_es_adr2 }</secnd_ntfy_addrs2>| &&
*                          |<secnd_ntfy_addrs3>{ w_final-es_pin }</secnd_ntfy_addrs3>| &&


                          |<buyer_code>{ w_final-bill_to_party }</buyer_code>| &&
                          |<buyer_name>{ w_final-re_name }</buyer_name>| &&
                          |<buyer_address_l1>{ lv_bill_adr1 }</buyer_address_l1>| &&
                          |<buyer_address_l2>{ lv_bill_adr2 }</buyer_address_l2>| &&
                          |<buyer_address_l3>{ w_final-re_pin } ({ lv_cn_name_re1-countryname })</buyer_address_l3>| &&
                          |<buyer_cin></buyer_cin>| &&   """ { w_final-PlantName }
                          |<buyer_gstin>{ w_final-re_tax }</buyer_gstin>| &&
                          |<buyer_pan>{ w_final-re_pan }</buyer_pan>| &&
                          |<buyer_state_code>{ w_final-re_region } ({ lv_st_name_re1-regionname })</buyer_state_code>| &&
                          |<buyer_state_name>{ w_final-re_city }</buyer_state_name>| &&
                          |<buyer_place_suply>{ w_final-re_region }</buyer_place_suply>| &&
                          |<buyer_phone>{ w_final-re_phone4 }</buyer_phone>| &&
                          |<buyer_email>{ w_final-re_email }</buyer_email>| &&

                          |<inv_no>{ w_final-documentreferenceid }</inv_no>| &&
                          |<inv_date>{ lv_bill_date }</inv_date>| &&

                          |<iec_num>{ lv_plant_iec }</iec_num>| &&
                          |<pan_num>{ wa_pack_data-ex_pan }</pan_num>| &&
                          |<ad_code>{ wa_pack_data-ad_code }</ad_code>| &&
                          |<pre_carig_by>{ wa_pack_data-pre_carig_by }</pre_carig_by>| &&
                          |<vessel>{ lv_vessel }</vessel>| &&
                          |<port_of_discg>{ wa_pack_data-port_of_discg }</port_of_discg>| &&
                          |<mark_no_of_cont>{ wa_pack_data-mark_no_of_cont }</mark_no_of_cont>| &&
                          |<pre_carrier>{ wa_pack_data-pre_carrier }</pre_carrier>| &&
                          |<port_of_load>{ wa_pack_data-port_of_load }</port_of_load>| &&
                          |<final_dest>{ wa_pack_data-final_dest }</final_dest>| &&
                          |<country_org>{ wa_pack_data-country_org }</country_org>| &&
                          |<country_of_fdest>{ lv_cn_name_fdes-countryname }</country_of_fdest>| &&

                          |<pay_term>{ w_final-incotermslocation1 } ({ w_final-incotermsclassification })</pay_term>| &&
                          |<payment>{ w_final-customerpaymenttermsname }</payment>| &&

                          |<des_of_goods>{ 'Auto Parts' }</des_of_goods>| &&
                          |<no_kind_pkg>{ wa_pack_data-no_kind_pkg }</no_kind_pkg>| &&

                          |<total_pcs>{ wa_pack_data-total_pcs }</total_pcs>| &&
                          |<tot_net_wgt>{ wa_pack_data-tot_net_wgt }</tot_net_wgt>| &&
                          |<tot_gross_wgt>{ wa_pack_data-tot_gross_wgt }</tot_gross_wgt>| &&
                          |<total_vol>{ 'C' }</total_vol>| &&

                          |<other_ref> { lv_other_ref }</other_ref>| &&

                          |<lut_urn> { lv_lut_num }</lut_urn>| &&
                          |<lut_date> { '09/03/2023' }</lut_date>| &&
                          |<end_use_code> { lv_po_numbers }</end_use_code>| &&
                          |<plant_website> { 'www.diaelec-hd.co.jp' }</plant_website>| &&

                          |<total_amt>{ tot_amt }</total_amt>| &&
                          |<other_charges>{ tot_oth }</other_charges>| &&
                          |<discount>{ tot_dis }</discount>| &&
                          |<grand_total>{ grand_tot }</grand_total>| &&

                          |<bank1>{ lv_bank1 }</bank1>| &&
                          |<bank2>{ lv_bank2 }</bank2>| &&
                          |<bank3>{ lv_bank3 }</bank3>| &&
                          |<bank4>{ lv_bank4 }</bank4>| &&


                           |<lv_dec1>{ lv_declaration1 }</lv_dec1>| &&
*                          |<lv_dec2>{ lv_declaration2 }</lv_dec2>| &&
*                          |<lv_dec3>{ lv_declaration3 }</lv_dec3>| &&
*                          |<lv_dec4>{ lv_declaration4 }</lv_dec4>| &&
*                          |<lv_dec5>{ lv_declaration5 }</lv_dec5>| &&
*                          |<lv_dec6>{ lv_declaration6 }</lv_dec6>| &&

                          |<rate_curr>{ w_final-transactioncurrency }</rate_curr>| &&
                          |<amt_words>{ grand_tot_amt_words }</amt_words>| &&

                        |<inst_hsn_code>{ inst_hsn_code }</inst_hsn_code>| &&
                        |<inst_sbno>{ inst_sbno }</inst_sbno>| &&
                        |<inst_collect>{ inst_collect  }</inst_collect>| &&
                        |<inst_sb_date>{ inst_sb_date }</inst_sb_date>| &&
                        |<inst_rcno>{ inst_rcno }</inst_rcno>| &&
                        |<trans_mode>{ trans_mode }</trans_mode>| &&
                        |<inst_date_accpt>{ inst_date_accpt }</inst_date_accpt>| &&
                        |<inst_delv_date>{ inst_delv_date }</inst_delv_date>| &&
*                        |<inst_transipment>{ inst_transipment }</inst_transipment| &&
                        |<inst_no_orginl>{ inst_no_orginl }</inst_no_orginl>| &&
                        |<inst_frt_amt>{ inst_frt_amt }</inst_frt_amt>| &&
                        |<inst_frt_pay_at>{ inst_frt_pay_at }</inst_frt_pay_at>| &&
                        |<inst_destination>{ inst_destination }</inst_destination>| &&
                        |<inst_particular>{ inst_particular }</inst_particular>| &&

                         |<ItemData>| ##NO_TEXT.

          ""*****End: Header XML*****************************************************

          """****Merging Header & Item XML
          lv_xml = |{ lv_xml }{ lv_item }| &&
                             |</ItemData>| &&
                             |</BillingDocumentNode>| &&
                             |</Form>|.

          DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
          iv_xml_base64 = ls_data_xml_64.

        ENDIF.

      ENDMETHOD.


      METHOD prep_xml_pack_inv1.


        DATA:
          lv_plant_addrs1 TYPE string,
          lv_plant_addrs2 TYPE string,
          lv_plant_addrs3 TYPE string,
          lv_plant_cin    TYPE string,
          lv_plant_iec    TYPE string.

        DATA: lv_vbeln_n  TYPE c LENGTH 10. "char10 .

        DATA:
*          tot_amt   TYPE p LENGTH 16 DECIMALS 2,
*          tot_dis   TYPE p LENGTH 16 DECIMALS 2,
          tot_oth       TYPE p LENGTH 16 DECIMALS 2,
          grand_tot     TYPE p LENGTH 16 DECIMALS 2,
          lv_unit_price TYPE p LENGTH 16 DECIMALS 2,
          lv_tot_qty    TYPE p LENGTH 16 DECIMALS 2,
          lv_po_numbers TYPE string,
          lv_lut_num    TYPE c LENGTH 40,
          lv_bank1      TYPE c LENGTH 100,
          lv_bank2      TYPE c LENGTH 100,
          lv_bank3      TYPE c LENGTH 100,
          lv_bank4      TYPE c LENGTH 100.

        IF it_final[] IS NOT INITIAL.

          DATA(lv_xml) =
|<Form>|.

          DO 4 TIMES. "added by neelam!


            LOOP AT it_final INTO DATA(wa_final).

              IF sy-tabix = 1.
                lv_po_numbers = lv_po_numbers && wa_final-purchaseorderbycustomer.
              ELSE.
                lv_po_numbers = lv_po_numbers && '/' && wa_final-purchaseorderbycustomer.
              ENDIF.

              CLEAR: wa_final.
            ENDLOOP.

            READ TABLE it_final INTO DATA(w_final) INDEX 1 .
            lv_vbeln_n = w_final-billingdocument.
            lv_vbeln_n = |{ lv_vbeln_n ALPHA = IN }| .
            """    SHIFT lv_vbeln_n LEFT DELETING LEADING '0'.

            SELECT * FROM zsd_pack_data WHERE pack_num = @im_pack
                     INTO TABLE @DATA(lt_pack).

            SELECT SINGLE * FROM zsd_pack_data WHERE pack_num =  @im_pack INTO @DATA(wa_pack_data). "#EC WARNOK

            REPLACE ALL OCCURRENCES OF '&' IN  w_final-re_name WITH '' .
            REPLACE ALL OCCURRENCES OF '&' IN  w_final-we_name WITH '' .

            DATA : odte_text TYPE c LENGTH 20 , """"original duplicate triplicate ....
                   tot_qty   TYPE p LENGTH 16 DECIMALS 2,
                   tot_amt   TYPE p LENGTH 16 DECIMALS 2,
                   tot_dis   TYPE p LENGTH 16 DECIMALS 2.

            IF im_prntval = 'Original' ##NO_TEXT.
              "odte_text = odte_text = |White-Original            Pink-Duplicate          Yellow-Triplicate|  ##NO_TEXT.
              odte_text = 'Original' ##NO_TEXT.
            ELSEIF im_prntval = 'Duplicate' ##NO_TEXT.
              odte_text = 'Duplicate' ##NO_TEXT.
            ELSEIF im_prntval = 'Triplicate' ##NO_TEXT.
              odte_text = 'Triplicate'  ##NO_TEXT.
            ELSEIF im_prntval = 'Extra' ##NO_TEXT.
              odte_text = 'Extra Copy' ##NO_TEXT.
            ENDIF.

            DATA : heading     TYPE c LENGTH 100,
                   sub_heading TYPE c LENGTH 100,
                   for_sign    TYPE c LENGTH 100.


            IF iv_action = 'export'  ##NO_TEXT.
              heading = 'EXPORT INVOICE' ##NO_TEXT.
            ELSEIF iv_action = 'packls'  ##NO_TEXT.
              heading = 'PACKING LIST' ##NO_TEXT.
            ENDIF .


            for_sign  = 'DE DIAMOND ELECTRIC INDIA PVT. LTD.' ##NO_TEXT.

            DATA : lv_bill_adr1 TYPE c LENGTH 100 .
            DATA : lv_bill_adr2 TYPE c LENGTH 100 .
            DATA : lv_bill_adr3 TYPE c LENGTH 100.

            DATA : lv_shp_adr1 TYPE c LENGTH 100.
            DATA : lv_shp_adr2 TYPE c LENGTH 100.
            DATA : lv_shp_adr3 TYPE c LENGTH 100.

            DATA : lv_sp_adr1 TYPE c LENGTH 100,
                   lv_sp_adr2 TYPE c LENGTH 100,
                   lv_sp_adr3 TYPE c LENGTH 100,
                   lv_es_adr1 TYPE c LENGTH 100,
                   lv_es_adr2 TYPE c LENGTH 100,
                   lv_es_adr3 TYPE c LENGTH 100.

            """"""" bill address set """"""""
            IF w_final-re_house_no IS NOT INITIAL .
              lv_bill_adr1 = |{ w_final-re_house_no }| .
            ENDIF .

            IF w_final-re_street IS NOT INITIAL .
              IF lv_bill_adr1 IS NOT INITIAL   .
                lv_bill_adr1 = |{ lv_bill_adr1 } , { w_final-re_street }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
              ELSE .
                lv_bill_adr1 = |{ w_final-re_street }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
              ENDIF .
            ENDIF .

            IF w_final-re_street1 IS NOT INITIAL .
              IF lv_bill_adr1 IS NOT INITIAL   .
                lv_bill_adr1 = |{ lv_bill_adr1 }, { w_final-re_street1 }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
              ELSE .
                lv_bill_adr1 = |{ w_final-re_street1 }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
              ENDIF .
            ENDIF .

            DATA(len) = strlen( lv_bill_adr1 ) .
            len = len - 40.
            IF strlen( lv_bill_adr1 ) GT 40 .
              lv_bill_adr2 = |{ lv_bill_adr1+40(len) },| .
              lv_bill_adr1 = lv_bill_adr1+0(40) .
            ENDIF .
            """"""" eoc bill address set """"""""


            """"""" ship address set """"""""
            IF w_final-we_house_no IS NOT INITIAL .
              lv_shp_adr1 = |{ w_final-we_house_no }| .
            ENDIF .

            IF w_final-we_street IS NOT INITIAL .
              IF lv_shp_adr1 IS NOT INITIAL   .
                lv_shp_adr1 = |{ lv_shp_adr1 } , { w_final-we_street }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
              ELSE .
                lv_shp_adr1 = |{ w_final-we_street }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
              ENDIF .
            ENDIF .

            IF w_final-we_street1 IS NOT INITIAL .
              IF lv_shp_adr1 IS NOT INITIAL   .
                lv_shp_adr1 = |{ lv_shp_adr1 } , { w_final-we_street1 }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
              ELSE .
                lv_shp_adr1 = |{ w_final-we_street1 }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
              ENDIF .
            ENDIF .

            len = strlen( lv_shp_adr1 ) .
            len = len - 40.
            IF strlen( lv_shp_adr1 ) GT 40 .
              lv_shp_adr2 = |{ lv_shp_adr1+40(len) },| .
              lv_shp_adr1 = lv_shp_adr1+0(40) .
            ENDIF .

*          """"""" sp address set """"""""
            IF w_final-sp_house_no IS NOT INITIAL .
              lv_sp_adr1 = |{ w_final-sp_house_no }| .
            ENDIF .

            IF w_final-sp_street IS NOT INITIAL .
              IF lv_sp_adr1 IS NOT INITIAL   .
                lv_sp_adr1 = |{ lv_sp_adr1 } , { w_final-sp_street }| .
              ELSE .
                lv_sp_adr1 = |{ w_final-sp_street }| .
              ENDIF .
            ENDIF .

            IF w_final-sp_street1 IS NOT INITIAL .
              IF lv_sp_adr1 IS NOT INITIAL   .
                lv_sp_adr1 = |{ lv_sp_adr1 } , { w_final-sp_street1 }| .
              ELSE .
                lv_sp_adr1 = |{ w_final-sp_street1 }| .
              ENDIF .
            ENDIF .

            len = strlen( lv_sp_adr1 ) .
            IF len GT 40 .
              lv_sp_adr2 = |{ lv_sp_adr1+40(len) },| .
              lv_sp_adr1 = lv_sp_adr1+0(40) .
            ENDIF .

*          """"""" ES address set """"""""
*          IF w_final-es_house_no IS NOT INITIAL .
*            lv_es_adr1 = |{ w_final-es_house_no }| .
*          ENDIF .
*
*          IF w_final-es_street IS NOT INITIAL .
*            IF lv_es_adr1 IS NOT INITIAL   .
*              lv_es_adr1 = |{ lv_es_adr1 } , { w_final-es_street }| .
*            ELSE .
*              lv_es_adr1 = |{ w_final-es_street }| .
*            ENDIF .
*          ENDIF .
*
*          IF w_final-es_street1 IS NOT INITIAL .
*            IF lv_es_adr1 IS NOT INITIAL   .
*              lv_es_adr1 = |{ lv_es_adr1 } , { w_final-es_street1 }| .
*            ELSE .
*              lv_es_adr1 = |{ w_final-es_street1 }| .
*            ENDIF .
*          ENDIF .

            len = strlen( lv_es_adr1 ) .
            IF len GT 40 .
              lv_es_adr2 = |{ lv_es_adr1+40(len) },| .
              lv_es_adr1 = lv_es_adr1+0(40) .
            ENDIF .

            ""****Start:Logic to read text of Billing Header************
            DATA:
              lo_text           TYPE REF TO zcl_read_text,
              gt_text           TYPE TABLE OF zstr_billing_text,
              gt_item_text      TYPE TABLE OF zstr_billing_text,
              lo_amt_words      TYPE REF TO zcl_amt_words,
              lv_grand_tot_word TYPE string.

            DATA:
              inst_hsn_code    TYPE string,
              inst_sbno        TYPE string,
              inst_sb_date     TYPE string,
              inst_rcno        TYPE string,
              trans_mode       TYPE string,
              inst_date_accpt  TYPE string,
              inst_delv_date   TYPE string,
              inst_transipment TYPE string,
              inst_no_orginl   TYPE string,
              inst_frt_amt     TYPE string,
              inst_frt_pay_at  TYPE string,
              inst_destination TYPE string,
              inst_particular  TYPE string,
              inst_collect     TYPE string.

            CREATE OBJECT lo_text.
            CREATE OBJECT lo_amt_words.

            ""****End:Logic to read text of Billing Header************

            lo_text->read_text_billing_header(
               EXPORTING
                 iv_billnum = lv_vbeln_n
               RECEIVING
                 xt_text    = gt_text "This will contain all text IDs data of given billing document
             ).


            DATA : lv_vessel     TYPE c LENGTH 100,
                   lv_plant_name TYPE c LENGTH 100.
            DATA : lv_no_pck TYPE c LENGTH 100.

            DATA : lv_gross TYPE c LENGTH 100.

            DATA : lv_other_ref TYPE c LENGTH 100.
            CLEAR : lv_vessel , lv_no_pck , lv_gross .
            READ TABLE gt_text INTO DATA(w_text) WITH KEY longtextid = 'Z004' .
            IF sy-subrc = 0 .
              lv_vessel = w_text-longtext .
            ENDIF .

            READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z011' .
            IF sy-subrc = 0 .
              lv_gross = w_text-longtext .
            ENDIF .

            READ TABLE gt_text INTO w_text WITH KEY longtextid = 'TX05' .
            IF sy-subrc = 0 .
              lv_other_ref = w_text-longtext .
            ENDIF .

            """***For Shipping Instruction****************
            CLEAR: w_text.
            READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z005' .
            IF sy-subrc = 0 .
              inst_sbno = w_text-longtext .
            ENDIF .

            CLEAR: w_text.
            READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z006' .
            IF sy-subrc = 0 .
              inst_rcno = w_text-longtext .
            ENDIF .

            CLEAR: w_text.
            READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z013' .
            IF sy-subrc = 0 .
              inst_no_orginl = w_text-longtext .
            ENDIF .

            CLEAR: w_text.
            READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z014' .
            IF sy-subrc = 0 .
              inst_particular = w_text-longtext .
            ENDIF .

            CLEAR: w_text.
            READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z015' .
            IF sy-subrc = 0 .
              inst_date_accpt = w_text-longtext .
            ENDIF .

            CLEAR: w_text.
            READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z002' .
            IF sy-subrc = 0 .
              trans_mode = w_text-longtext .
            ENDIF .
            """***For Shipping Instruction****************

            ""   CLEAR : w_final , wa_pack_data , for_sign , sub_heading , heading , odte_text .
            "  FREE : it_final .

            DATA:
               lv_bill_date TYPE c LENGTH 10.

            lv_bill_date = w_final-billingdocumentdate+6(2) && '.' && w_final-billingdocumentdate+4(2) && '.' && w_final-billingdocumentdate+0(4).
            wa_pack_data-iec = ''.
            w_final-phoneareacodesubscribernumber = '+91-129-2275001' ##NO_TEXT.
            wa_pack_data-country_org = 'India' ##NO_TEXT.
            wa_pack_data-country_of_fdest = w_final-re_country.

            ""*****Start: Item XML*****************************************************
            DATA : lv_item      TYPE string,
                   lv_pallet_no TYPE string,
                   srn          TYPE c LENGTH 3,
                   lv_anp_part  TYPE string.

            IF w_final-item_igstrate EQ 0.

              sub_heading = '(Supply meant for Export Under Bond or Letter of Undertaking Without Payment of Integrated Tax)' ##NO_TEXT.

              SELECT SINGLE * FROM zsd_sysid
                              WHERE objcode = 'LUTNO' AND sysid = @sy-sysid
                              INTO @DATA(ls_sysid_pass).

              IF sy-subrc EQ 0.
                lv_lut_num = ls_sysid_pass-objvalue.
              ENDIF.

            ELSE.
              sub_heading = '(Supply meant for Export Under Bond or Letter of Undertaking With Payment of Integrated Tax)' ##NO_TEXT.
            ENDIF.

            IF iv_action = 'export'  ##NO_TEXT.

              DATA(xt_pack) = lt_pack[].
              SORT lt_pack BY vbeln posnr.
              DELETE ADJACENT DUPLICATES FROM lt_pack COMPARING vbeln posnr.

              LOOP AT lt_pack ASSIGNING FIELD-SYMBOL(<lfs_pack>).

                IF <lfs_pack> IS ASSIGNED.
                  CLEAR: <lfs_pack>-qty_in_pcs, <lfs_pack>-pkg_vol, <lfs_pack>-pkg_length.
                  LOOP AT xt_pack INTO DATA(xs_pack) WHERE vbeln = <lfs_pack>-vbeln AND posnr = <lfs_pack>-posnr.
                    "<lfs_pack>-qty_in_pcs = <lfs_pack>-qty_in_pcs + xs_pack-qty_in_pcs.
                    <lfs_pack>-pkg_vol    = <lfs_pack>-pkg_vol + xs_pack-pkg_vol.
                    <lfs_pack>-pkg_length = <lfs_pack>-pkg_length + xs_pack-pkg_length.
                    CLEAR: xs_pack.
                  ENDLOOP.

                  READ TABLE it_final INTO DATA(xw_final) WITH KEY billingdocument = <lfs_pack>-vbeln billingdocumentitem = <lfs_pack>-posnr.
                  IF sy-subrc EQ 0.
                    <lfs_pack>-qty_in_pcs = xw_final-billingquantity.
                  ENDIF.

                ENDIF.

              ENDLOOP.

            ENDIF.

            IF iv_action = 'packls'.
              SORT lt_pack BY pallet_no.
            ENDIF.

            CLEAR : lv_item , srn .
            CLEAR: tot_amt, tot_dis, tot_oth, grand_tot.
            LOOP AT lt_pack INTO DATA(w_pack) .

              READ TABLE it_final INTO DATA(w_item) WITH KEY
                                  billingdocument     = w_pack-vbeln billingdocumentitem = w_pack-posnr.
              "DeliveryDocumentItem = w_pack-posnr.

              CLEAR: gt_item_text.
              lo_text->read_text_billing_item(
                EXPORTING
                  im_billnum  = w_item-billingdocument
                  im_billitem = w_item-billingdocumentitem
                RECEIVING
                  xt_text     = gt_item_text
              ).

              IF gt_item_text[] IS NOT INITIAL.
                READ TABLE gt_item_text INTO DATA(gs_item_text) INDEX 1.
              ENDIF.

              srn = srn + 1 .
              lv_pallet_no =  |{ w_item-purchaseorderbycustomer } / { w_item-customerpurchaseorderdate+6(2) }.{ w_item-customerpurchaseorderdate+4(2) }.{ w_item-customerpurchaseorderdate+0(4) } / { gs_item_text-longtext }| .

              lv_tot_qty    =  w_pack-qty_in_pcs * w_pack-type_pkg.

              IF iv_action = 'export'.
                wa_pack_data-total_pcs      = wa_pack_data-total_pcs + w_pack-qty_in_pcs.
              ELSE.
                wa_pack_data-total_pcs      = wa_pack_data-total_pcs + lv_tot_qty.
              ENDIF.

              wa_pack_data-tot_net_wgt    = wa_pack_data-tot_net_wgt + w_pack-pkg_vol.
              wa_pack_data-tot_gross_wgt  = wa_pack_data-tot_gross_wgt +  w_pack-pkg_length.




              lv_anp_part  = w_item-materialbycustomer. "w_pack-matnr. "w_item-ProductOldID.
              IF w_pack-kdmat IS INITIAL.
                w_pack-kdmat = lv_anp_part.
              ENDIF.
              """""""""""""""""""""""""""""""""""
              SELECT SINGLE * FROM zi_regiontext  WHERE region = @w_final-region AND language = 'E' AND country = @w_final-country
               INTO @DATA(lv_st_nm1).         "#EC CI_ALL_FIELDS_NEEDED

              SELECT SINGLE * FROM zi_regiontext  WHERE region = @w_final-re_region AND language = 'E' AND country = @w_final-re_country
              INTO @DATA(lv_st_name_re1).     "#EC CI_ALL_FIELDS_NEEDED

              SELECT SINGLE * FROM zi_regiontext  WHERE region = @w_final-we_region AND language = 'E' AND country = @w_final-we_country
              INTO @DATA(lv_st_name_we1).     "#EC CI_ALL_FIELDS_NEEDED


              SELECT SINGLE * FROM zi_countrytext   WHERE country = @w_final-country AND language = 'E'
              INTO @DATA(lv_cn_nm1).          "#EC CI_ALL_FIELDS_NEEDED

              SELECT SINGLE * FROM zi_countrytext   WHERE country = @w_final-re_country AND language = 'E'
              INTO @DATA(lv_cn_name_re1).     "#EC CI_ALL_FIELDS_NEEDED

              SELECT SINGLE * FROM zi_countrytext   WHERE country = @w_final-we_country AND language = 'E'
              INTO @DATA(lv_cn_name_we1).     "#EC CI_ALL_FIELDS_NEEDED

              SELECT SINGLE * FROM zi_countrytext   WHERE country = @wa_pack_data-country_of_fdest
               AND language = 'E'  INTO @DATA(lv_cn_name_fdes). "#EC CI_ALL_FIELDS_NEEDED

              REPLACE ALL OCCURRENCES OF '&' IN  w_item-materialbycustomer WITH '' .
              REPLACE ALL OCCURRENCES OF '&' IN  lv_anp_part WITH '' .
              REPLACE ALL OCCURRENCES OF '&' IN  w_item-billingdocumentitemtext WITH '' .

              IF w_item-conditionquantity IS NOT INITIAL .
                lv_unit_price = w_item-item_unitprice / w_item-conditionquantity.
              ELSE.
                lv_unit_price = w_item-item_unitprice.
              ENDIF.

              "w_item-item_unitprice = w_item-item_unitprice / w_item-ConditionQuantity.
              w_item-item_totalamount = w_item-billingquantity * lv_unit_price. "w_item-item_unitprice.

              tot_amt = tot_amt + w_item-item_totalamount.
              tot_dis = tot_dis + w_item-item_discountamount.
              tot_oth = tot_oth + w_item-item_freight + w_item-item_othercharge.

              lv_item = |{ lv_item }| && |<ItemDataNode>| &&

                        |<cust_pono> { lv_pallet_no }</cust_pono>| &&
                        |<pallet_no>{ w_pack-pallet_no }</pallet_no>| &&
                        |<pkgs_from_to>{ w_pack-pkg_no }</pkgs_from_to>| &&
                        |<buyer_code>{ w_pack-kdmat }</buyer_code>| &&
                        |<anp_part>{ lv_anp_part }</anp_part>| &&
                        |<item_code>{ lv_anp_part }</item_code>| &&
                        |<item_desc>{  w_item-billingdocumentitemtext }</item_desc>| &&
                        |<hsn_code>{  w_item-hsn }</hsn_code>| &&
                        |<qty>{ w_item-billingquantity }</qty>| &&
                        |<uom>{ w_item-baseunit }</uom>| &&
                        |<qty_pcs>{ w_pack-qty_in_pcs }</qty_pcs>| &&
                        |<net_wgt>{ w_pack-pkg_vol }</net_wgt>| &&
                        |<gross_wgt>{ w_pack-pkg_length }</gross_wgt>| &&
                        |<rate>{ lv_unit_price }</rate>| &&
                        |<amount>{ w_item-item_totalamount }</amount>| &&
                        |<no_of_pkg>{ w_pack-type_pkg }</no_of_pkg>| &&
                        |<tot_qty>{ lv_tot_qty }</tot_qty>| &&
                        |<box_size>{ w_pack-box_size }</box_size>| &&
*                    |<item_code>{ w_item-MaterialDescriptionByCustomer }</item_code>| &&
                        |</ItemDataNode>|  .

            ENDLOOP .

            IF iv_action = 'shpinst'.

              heading = 'SLI'.

              inst_delv_date     = ''.
              inst_transipment   = ''.
              inst_frt_amt       = ''.
              inst_frt_pay_at    = ''.
              inst_destination   = ''.

              IF w_final-incotermsclassification = 'FOB' OR w_final-incotermsclassification = 'FCA'.
                inst_collect       = 'FREIGHT COLLECT' ##NO_TEXT.
              ELSE.
                inst_collect       = 'IHC COLLECT' ##NO_TEXT.
              ENDIF.

              DATA(lt_inst) = it_final[].
              SORT lt_inst BY hsn.
              DELETE ADJACENT DUPLICATES FROM lt_inst COMPARING hsn.

              LOOP AT lt_inst INTO DATA(ls_inst).
                inst_hsn_code  = inst_hsn_code && ls_inst-hsn.
              ENDLOOP.

              CLEAR: lv_item.
              lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                        |<cust_pono> { lv_pallet_no }</cust_pono>| &&
                        |</ItemDataNode>|  .

            ENDIF.

            grand_tot = tot_amt - tot_dis + tot_oth.
            lv_grand_tot_word  = grand_tot.
            lo_amt_words->number_to_words_export(
             EXPORTING
               iv_num   = lv_grand_tot_word
             RECEIVING
               rv_words = DATA(grand_tot_amt_words)
           ).

            IF w_final-transactioncurrency EQ 'USD'.

            ELSEIF w_final-transactioncurrency EQ 'EUR'.
              REPLACE ALL OCCURRENCES OF 'Dollars' IN grand_tot_amt_words WITH 'Euro' ##NO_TEXT.
            ENDIF.

            DATA : lv_declaration1 TYPE string .
            CLEAR: w_text.
            READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z016' .
            IF sy-subrc = 0 .
              lv_declaration1 = w_text-longtext .
            ENDIF .

            ""*****End: Item XML*****************************************************
            CLEAR : odte_text .
            ""*****Start: Header XML*****************************************************
*          w_final-plantname = 'DE DIAMOND ELECTRIC INDIA PVT. LTD' ##NO_TEXT.
            lv_plant_name     = 'DE DIAMOND ELECTRIC INDIA PVT. LTD' ##NO_TEXT.
            w_final-phoneareacodesubscribernumber = '9053029817' ##NO_TEXT.
            wa_pack_data-ad_code = ''.
            lv_vessel = wa_pack_data-vessel.

            REPLACE ALL OCCURRENCES OF '&' IN w_final-incotermslocation1 WITH ''.


            lv_plant_addrs1  = 'Sector - 5, HSIIDC Growth Centre, Plot no. 38' ##NO_TEXT.
            lv_plant_addrs2  = 'Phase-II, Industrial Model Twp, Bawal' ##NO_TEXT.
            lv_plant_addrs3  = 'Haryana 123501' ##NO_TEXT. "-121003, HR-India
            lv_plant_cin     = 'U31908HR2007FTC039788' ##NO_TEXT.
            lv_plant_iec     = '0507048172' ##NO_TEXT.

            lv_bank1 = 'MUFG Bank Limited' ##NO_TEXT.
            lv_bank2 = '10 Ground floor Commercial Plot No.09, RIICO, Japanese Zone,' ##NO_TEXT.
            lv_bank3 = 'Neemrana, Alwar, Rajasthan-301705 India' ##NO_TEXT.

            DATA(lv_xml1) = "|<Form>| &&
                           |<BillingDocumentNode>| &&
                           |<heading>{ heading }</heading>| &&
                           |<sub_heading>{ sub_heading }</sub_heading>| &&
                           |<for_sign>{ for_sign }</for_sign>| &&
                           |<odte_text>{ odte_text }</odte_text>| &&


                            |<plant_code>{ w_final-plant }</plant_code>| &&
                            |<plant_name>{ lv_plant_name }</plant_name>| &&
                            |<plant_address_l1>{ lv_plant_addrs1 }</plant_address_l1>| &&
                            |<plant_address_l2>{ lv_plant_addrs2 }</plant_address_l2>| &&
                            |<plant_address_l3>{ lv_plant_addrs3 }</plant_address_l3>| &&
                            |<plant_cin>{ lv_plant_cin }</plant_cin>| &&
                            |<plant_gstin>{ w_final-plant_gstin }</plant_gstin>| &&
                            |<plant_pan>{ w_final-plant_gstin+2(10) }</plant_pan>| &&
                            |<plant_state_code>{ w_final-region }</plant_state_code>| &&
                            |<plant_state_name>{ w_final-plantname }</plant_state_name>| &&
                            |<plant_phone>{ w_final-phoneareacodesubscribernumber }</plant_phone>| &&
                            |<plant_email>{ w_final-plant_email }</plant_email>| &&

                            |<consignee_code>{ w_final-ship_to_party }</consignee_code>| &&
                            |<consignee_name>{ w_final-we_name }</consignee_name>| &&
                            |<consignee_address_l1>{ lv_shp_adr1 }</consignee_address_l1>| &&
                            |<consignee_address_l2>{ lv_shp_adr2 }</consignee_address_l2>| &&
                            |<consignee_address_l3>{ w_final-we_pin } ({ lv_cn_name_we1-countryname })</consignee_address_l3>| &&
                            |<consignee_cin>{ w_final-plantname }</consignee_cin>| &&
                            |<consignee_gstin>{ w_final-we_tax }</consignee_gstin>| &&
                            |<consignee_pan>{ w_final-we_pan }</consignee_pan>| &&
                            |<consignee_state_code>{ w_final-we_region } ({ lv_st_name_we1-regionname })</consignee_state_code>| &&
                            |<consignee_state_name>{ w_final-we_city }</consignee_state_name>| &&
                            |<consignee_place_suply>{ w_final-we_region }</consignee_place_suply>| &&
                            |<consignee_phone>{ w_final-we_phone4 }</consignee_phone>| &&
                            |<consignee_email>{ w_final-we_email }</consignee_email>| &&


                            |<shipto_code>{ w_final-sp_code }</shipto_code>| &&
                            |<shipto_name>{ w_final-sp_name }</shipto_name>| &&
                            |<shipto_addrs1>{ lv_sp_adr1 }</shipto_addrs1>| &&
                            |<shipto_addrs2>{ lv_sp_adr2 }</shipto_addrs2>| &&
                            |<shipto_addrs3>{ w_final-sp_pin }</shipto_addrs3>| &&

*                          |<secnd_ntfy_code>{ w_final-es_code }</secnd_ntfy_code>| &&
*                          |<secnd_ntfy_name>{ w_final-es_name }</secnd_ntfy_name>| &&
*                          |<secnd_ntfy_addrs1>{ lv_es_adr1 }</secnd_ntfy_addrs1>| &&
*                          |<secnd_ntfy_addrs2>{ lv_es_adr2 }</secnd_ntfy_addrs2>| &&
*                          |<secnd_ntfy_addrs3>{ w_final-es_pin }</secnd_ntfy_addrs3>| &&


                            |<buyer_code>{ w_final-bill_to_party }</buyer_code>| &&
                            |<buyer_name>{ w_final-re_name }</buyer_name>| &&
                            |<buyer_address_l1>{ lv_bill_adr1 }</buyer_address_l1>| &&
                            |<buyer_address_l2>{ lv_bill_adr2 }</buyer_address_l2>| &&
                            |<buyer_address_l3>{ w_final-re_pin } ({ lv_cn_name_re1-countryname })</buyer_address_l3>| &&
                            |<buyer_cin></buyer_cin>| &&   """ { w_final-PlantName }
                            |<buyer_gstin>{ w_final-re_tax }</buyer_gstin>| &&
                            |<buyer_pan>{ w_final-re_pan }</buyer_pan>| &&
                            |<buyer_state_code>{ w_final-re_region } ({ lv_st_name_re1-regionname })</buyer_state_code>| &&
                            |<buyer_state_name>{ w_final-re_city }</buyer_state_name>| &&
                            |<buyer_place_suply>{ w_final-re_region }</buyer_place_suply>| &&
                            |<buyer_phone>{ w_final-re_phone4 }</buyer_phone>| &&
                            |<buyer_email>{ w_final-re_email }</buyer_email>| &&

                            |<inv_no>{ w_final-documentreferenceid }</inv_no>| &&
                            |<inv_date>{ lv_bill_date }</inv_date>| &&

                            |<iec_num>{ lv_plant_iec }</iec_num>| &&
                            |<pan_num>{ wa_pack_data-ex_pan }</pan_num>| &&
                            |<ad_code>{ wa_pack_data-ad_code }</ad_code>| &&
                            |<pre_carig_by>{ wa_pack_data-pre_carig_by }</pre_carig_by>| &&
                            |<vessel>{ lv_vessel }</vessel>| &&
                            |<port_of_discg>{ wa_pack_data-port_of_discg }</port_of_discg>| &&
                            |<mark_no_of_cont>{ wa_pack_data-mark_no_of_cont }</mark_no_of_cont>| &&
                            |<pre_carrier>{ wa_pack_data-pre_carrier }</pre_carrier>| &&
                            |<port_of_load>{ wa_pack_data-port_of_load }</port_of_load>| &&
                            |<final_dest>{ wa_pack_data-final_dest }</final_dest>| &&
                            |<country_org>{ wa_pack_data-country_org }</country_org>| &&
                            |<country_of_fdest>{ lv_cn_name_fdes-countryname }</country_of_fdest>| &&

                            |<pay_term>{ w_final-incotermslocation1 } ({ w_final-incotermsclassification })</pay_term>| &&
                            |<payment>{ w_final-customerpaymenttermsname }</payment>| &&

                            |<des_of_goods>{ 'Auto Parts' }</des_of_goods>| &&
                            |<no_kind_pkg>{ wa_pack_data-no_kind_pkg }</no_kind_pkg>| &&

                            |<total_pcs>{ wa_pack_data-total_pcs }</total_pcs>| &&
                            |<tot_net_wgt>{ wa_pack_data-tot_net_wgt }</tot_net_wgt>| &&
                            |<tot_gross_wgt>{ wa_pack_data-tot_gross_wgt }</tot_gross_wgt>| &&
                            |<total_vol>{ 'C' }</total_vol>| &&

                            |<other_ref> { lv_other_ref }</other_ref>| &&

                            |<lut_urn> { lv_lut_num }</lut_urn>| &&
                            |<lut_date> { '09/03/2023' }</lut_date>| &&
                            |<end_use_code> { lv_po_numbers }</end_use_code>| &&
                            |<plant_website> { 'www.diaelec-hd.co.jp' }</plant_website>| &&

                            |<total_amt>{ tot_amt }</total_amt>| &&
                            |<other_charges>{ tot_oth }</other_charges>| &&
                            |<discount>{ tot_dis }</discount>| &&
                            |<grand_total>{ grand_tot }</grand_total>| &&

                            |<bank1>{ lv_bank1 }</bank1>| &&
                            |<bank2>{ lv_bank2 }</bank2>| &&
                            |<bank3>{ lv_bank3 }</bank3>| &&
                            |<bank4>{ lv_bank4 }</bank4>| &&


                             |<lv_dec1>{ lv_declaration1 }</lv_dec1>| &&
*                          |<lv_dec2>{ lv_declaration2 }</lv_dec2>| &&
*                          |<lv_dec3>{ lv_declaration3 }</lv_dec3>| &&
*                          |<lv_dec4>{ lv_declaration4 }</lv_dec4>| &&
*                          |<lv_dec5>{ lv_declaration5 }</lv_dec5>| &&
*                          |<lv_dec6>{ lv_declaration6 }</lv_dec6>| &&

                            |<rate_curr>{ w_final-transactioncurrency }</rate_curr>| &&
                            |<amt_words>{ grand_tot_amt_words }</amt_words>| &&

                          |<inst_hsn_code>{ inst_hsn_code }</inst_hsn_code>| &&
                          |<inst_sbno>{ inst_sbno }</inst_sbno>| &&
                          |<inst_collect>{ inst_collect  }</inst_collect>| &&
                          |<inst_sb_date>{ inst_sb_date }</inst_sb_date>| &&
                          |<inst_rcno>{ inst_rcno }</inst_rcno>| &&
                          |<trans_mode>{ trans_mode }</trans_mode>| &&
                          |<inst_date_accpt>{ inst_date_accpt }</inst_date_accpt>| &&
                          |<inst_delv_date>{ inst_delv_date }</inst_delv_date>| &&
*                        |<inst_transipment>{ inst_transipment }</inst_transipment| &&
                          |<inst_no_orginl>{ inst_no_orginl }</inst_no_orginl>| &&
                          |<inst_frt_amt>{ inst_frt_amt }</inst_frt_amt>| &&
                          |<inst_frt_pay_at>{ inst_frt_pay_at }</inst_frt_pay_at>| &&
                          |<inst_destination>{ inst_destination }</inst_destination>| &&
                          |<inst_particular>{ inst_particular }</inst_particular>| &&

                           |<ItemData>| ##NO_TEXT.

            ""*****End: Header XML*****************************************************

            """****Merging Header & Item XML
            lv_xml = |{ lv_xml } { lv_xml1 }{ lv_item }| &&
                               |</ItemData>| &&
                               |</BillingDocumentNode>|." &&
*                             |</Form>|.

          ENDDO.

          DATA(lv_last_form) =
           |</Form>|.

          CONCATENATE lv_xml lv_last_form INTO lv_xml.

          DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
          iv_xml_base64 = ls_data_xml_64.

        ENDIF.

      ENDMETHOD.


      METHOD prep_xml_tax_inv. " sr

        DATA(lv_xml) =
  |<Form>|.

        "  DO 4 TIMES. "added by neelam!


        DATA: lv_vbeln_n     TYPE c LENGTH 10,
              lv_qr_code     TYPE string,
              lv_cust_qr     TYPE string,
              lv_cust_itm    TYPE string,
              lv_billqty     TYPE i,
              lv_billqty_txt TYPE c LENGTH 20,
              lv_unit_price  TYPE string,
              lv_item_amount TYPE string,
              lv_irn_num     TYPE c LENGTH 64, "w_irn-irnno
              lv_ack_no      TYPE c LENGTH 20, "w_irn-ackno
              lv_ack_date    TYPE c LENGTH 10, "w_irn-ackdat
              lv_ref_sddoc   TYPE c LENGTH 20. "w_item-ReferenceSDDocument

        ""****Start:Logic to convert amount in Words************
        DATA:
          lo_amt_words TYPE REF TO zcl_amt_words.
        CREATE OBJECT lo_amt_words.
        ""****End:Logic to convert amount in Words************

        ""****Start:Logic to read text of Billing Header************
        DATA:
          lo_text TYPE REF TO zcl_read_text,
          gt_text TYPE TABLE OF zstr_billing_text.

        CREATE OBJECT lo_text.


        ""****End:Logic to read text of Billing Header************

        lv_qr_code = |This is a demo QR code. So please keep patience... And do not scan it with bar code scanner till i say to scan #sumit| ##NO_TEXT.

        READ TABLE it_final INTO DATA(w_final) INDEX 1 .
        lv_vbeln_n = w_final-billingdocument.


        lo_text->read_text_billing_header(
           EXPORTING
             iv_billnum = lv_vbeln_n
           RECEIVING
             xt_text    = gt_text "This will contain all text IDs data of given billing document
         ).

        SHIFT lv_vbeln_n LEFT DELETING LEADING '0'.

        DATA : odte_text TYPE string , """" original duplicate triplicate ....
               tot_qty   TYPE p LENGTH 16 DECIMALS 2,
               tot_amt   TYPE p LENGTH 16 DECIMALS 2,
               tot_dis   TYPE p LENGTH 16 DECIMALS 2.

        REPLACE ALL OCCURRENCES OF '&' IN  w_final-re_name WITH '' .
        REPLACE ALL OCCURRENCES OF '&' IN  w_final-we_name WITH '' .

        """"""""""""""""""" for total ...
        DATA : lv_qty              TYPE i, "p LENGTH 16 DECIMALS 2,
               lv_netwt            TYPE p LENGTH 16 DECIMALS 2,
               lv_grosswt          TYPE p LENGTH 16 DECIMALS 2,
               lv_dis              TYPE p LENGTH 16 DECIMALS 2,
               lv_tot_amt          TYPE p LENGTH 16 DECIMALS 2,
               lv_tax_amt          TYPE p LENGTH 16 DECIMALS 2,
               lv_tax_amt1         TYPE p LENGTH 16 DECIMALS 2,
               lv_sgst             TYPE p LENGTH 16 DECIMALS 2,
               lv_cgst             TYPE p LENGTH 16 DECIMALS 2,
               lv_igst             TYPE p LENGTH 16 DECIMALS 2,
               lv_tot_sgst         TYPE p LENGTH 16 DECIMALS 2,
               lv_tot_cgst         TYPE p LENGTH 16 DECIMALS 2,
               lv_tot_igst         TYPE p LENGTH 16 DECIMALS 2,
               lv_tot_igst1        TYPE p LENGTH 16 DECIMALS 2,
               lv_tot_cgst1        TYPE p LENGTH 16 DECIMALS 2,
               lv_tot_amort        TYPE p LENGTH 16 DECIMALS 2,
               lv_tot_sgst1        TYPE p LENGTH 16 DECIMALS 2,
               lv_tot_pkgchrg      TYPE p LENGTH 16 DECIMALS 2,
               lv_tcs              TYPE p LENGTH 16 DECIMALS 2,
               lv_other_chrg       TYPE p LENGTH 16 DECIMALS 2,
               sum_other_chrg      TYPE p LENGTH 16 DECIMALS 2,
               lv_round_off        TYPE p LENGTH 16 DECIMALS 2,
               lv_tot_gst          TYPE p LENGTH 16 DECIMALS 2,
               lv_grand_tot        TYPE p LENGTH 16 DECIMALS 2,
               lv_item_urate       TYPE p LENGTH 16 DECIMALS 5,
               lv_item_urate1      TYPE p LENGTH 16 DECIMALS 5,
               lv_item_urate2      TYPE p LENGTH 16 DECIMALS 2,
               lv_item_amtinr      TYPE p LENGTH 16 DECIMALS 2,
               lv_item_amtexp      TYPE p LENGTH 16 DECIMALS 2,
               lv_mrp_of_goods     TYPE p LENGTH 16 DECIMALS 2,
               lv_amt_expcurr      TYPE p LENGTH 16 DECIMALS 2,
               lv_net              TYPE p LENGTH 16 DECIMALS 2,
               lv_gross            TYPE p LENGTH 16 DECIMALS 2,
               lv_exchng_rate      TYPE p LENGTH 16 DECIMALS 2,
               lv_item_gst_rate    TYPE p LENGTH 16 DECIMALS 2,
               lv_certify_1        TYPE string,
               lv_certify_2        TYPE string,
               lv_certify_3        TYPE string,
               lv_certify_4        TYPE string,
               lv_certify_5        TYPE string,
               insur_policy_no     TYPE c LENGTH 20,
               insur_policy_date   TYPE c LENGTH 20,
               lv_tin_no           TYPE c LENGTH 20,
               lv_tin_date         TYPE c LENGTH 20,
               lv_fssai_lic_no     TYPE c LENGTH 20,
               lv_excise_pass_no   TYPE c LENGTH 20,
               lv_excise_pass_date TYPE c LENGTH 20,
               lv_bl_no            TYPE c LENGTH 20,
               lv_excise_no_h      TYPE c LENGTH 40,
               lv_excise_dt_h      TYPE c LENGTH 40,
               lv_blno_h           TYPE c LENGTH 40,
               lv_pur_odr_h        TYPE c LENGTH 40,
               lv_pur_dt_h         TYPE c LENGTH 40,
               lv_gr_no            TYPE c LENGTH 40,
               lv_gr_date          TYPE c LENGTH 40,
               lv_regd_adrs_1      TYPE c LENGTH 255,
               lv_regd_adrs_2      TYPE c LENGTH 255,
               lv_place_supply     TYPE string,
               lv_plant_name       TYPE c LENGTH 100,
               ex_pay              TYPE c LENGTH 50,
               lv_order_num        TYPE string.

        LOOP AT it_final INTO DATA(w_sum) .
          lv_qty = lv_qty + w_sum-billingquantity .
          lv_dis = lv_dis + w_sum-item_discountamount .
          lv_tot_amt = lv_tot_amt + w_sum-item_totalamount_inr .
          lv_tax_amt = lv_tax_amt + w_sum-item_assessableamount .
          lv_tot_igst = lv_tot_igst + w_sum-item_igstamount .
          lv_tot_igst1 = lv_tot_igst1 + w_sum-item_igstamount .
          lv_tot_sgst = lv_tot_sgst + w_sum-item_sgstamount .
          lv_tot_cgst = lv_tot_cgst + w_sum-item_cgstamount .
          lv_tcs = lv_tcs + w_sum-item_othercharge .
          lv_other_chrg = lv_other_chrg + w_sum-item_freight .
          lv_round_off = lv_round_off + w_sum-item_roundoff .
*          lv_gross = lv_gross + w_sum-grossweight .
*          lv_net = lv_net + w_sum-netweight .
        ENDLOOP.



        lv_tot_amt = lv_tot_amt - lv_other_chrg .
        lv_tax_amt = lv_tax_amt - lv_other_chrg .

        lv_grand_tot =  lv_tax_amt + lv_tot_sgst + lv_tot_cgst + lv_tot_igst
                        + lv_other_chrg + lv_tcs + lv_round_off .
        lv_tot_gst = lv_tot_sgst + lv_tot_cgst + lv_tot_igst .

        """ IF w_final-DistributionChannel = '30' .
        CLEAR : lv_qty , lv_dis , lv_tot_amt , lv_tax_amt ,lv_tot_igst , lv_tot_igst1 ,lv_tot_gst ,
         lv_tcs , lv_other_chrg , lv_round_off ,  lv_tot_amt ,lv_tax_amt ,lv_grand_tot , lv_tot_sgst , lv_tot_cgst.
        "" ENDIF .

        """""""""""""""""""""

*        IF w_final-re_tax  = 'URP' .
*          CLEAR : w_final-re_tax .
*        ENDIF .
*        IF w_final-we_tax  = 'URP' .
*          CLEAR : w_final-we_tax .
*        ENDIF .

        DATA : lv_remarks TYPE c LENGTH 100.

        DATA : lv_gsdb TYPE c LENGTH 100 .
        DATA : lv_cus_pl TYPE c LENGTH 100 .
        DATA :  vcode TYPE c LENGTH 100 .
        DATA : lv_vehicle TYPE c LENGTH 15 .
        DATA : lv_eway TYPE c LENGTH 15,
               lv_bags TYPE c LENGTH 15.
        DATA : lv_eway_dt TYPE c LENGTH 10,
               lv_so_dt   TYPE c LENGTH 10.
        DATA : lv_transmode TYPE c LENGTH 10 .  """lv_exp_no
        DATA : lv_exp_no TYPE c LENGTH 100.
        DATA : lv_no_pck TYPE c LENGTH 100.
        DATA : head_lut TYPE c LENGTH 100.
        CLEAR : lv_remarks , lv_no_pck .

        READ TABLE gt_text INTO DATA(w_text) WITH KEY longtextid = 'Z001' .
        IF sy-subrc = 0 .
          lv_vehicle = w_text-longtext .
        ENDIF .

        READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z002' .
        IF sy-subrc = 0 .
          lv_transmode = w_text-longtext .
        ENDIF .

        READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z004' .
        IF sy-subrc = 0 .
          lv_remarks = w_text-longtext .
        ENDIF .

        READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z007' .
        IF sy-subrc = 0 .
          lv_no_pck = w_text-longtext .
        ENDIF .

*        READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z011' .
*        IF sy-subrc = 0 .
*          lv_gross = w_text-longtext .
*        ENDIF .

*        READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z016' .
*        IF sy-subrc = 0 .
*          vcode = w_text-longtext .
*        ENDIF .

        READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z017' .
        IF sy-subrc = 0 .
          lv_cus_pl = w_text-longtext .
        ENDIF .

        READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z010' .
        IF sy-subrc = 0 .
          lv_exp_no = w_text-longtext .
        ENDIF .

        READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z016'.
        IF sy-subrc = 0 .
          head_lut = w_text-longtext .
        ENDIF .

        CLEAR w_text.
        READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z007'.
        IF sy-subrc = 0 .
          lv_bags = w_text-longtext .
        ENDIF .

        CLEAR w_text.
        READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z011'.
        IF sy-subrc = 0 .
          lv_gross = w_text-longtext .
        ENDIF .

        CLEAR w_text.
        READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z013'.
        IF sy-subrc = 0 .
          lv_net = w_text-longtext .
        ENDIF .

        CLEAR w_text.
        READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z008'.
        IF sy-subrc = 0 .
          lv_order_num = w_text-longtext .
          DATA(order_num_qr) = w_text-longtext .
        ENDIF .


        DATA: lv_so_party TYPE c LENGTH 10.
        lv_so_party = w_final-soldtoparty.
        SHIFT lv_so_party LEFT DELETING LEADING '0'.
        SELECT SINGLE customer,
               plant,
               vendor,
               qr_required
               FROM zsd_vendor_code
               WHERE customer = @lv_so_party AND plant = @w_final-plant
               INTO @DATA(ls_vcode).                    "#EC CI_NOORDER


        vcode = ls_vcode-vendor.

        DATA : lv_bill_adr1 TYPE c LENGTH 100.
        DATA : lv_bill_adr2 TYPE c LENGTH 100.
        DATA : lv_bill_adr3 TYPE c LENGTH 100.

        DATA : lv_shp_adr1 TYPE c LENGTH 100.
        DATA : lv_shp_adr2 TYPE c LENGTH 100.
        DATA : lv_shp_adr3 TYPE c LENGTH 100.

        """"""" bill address set """"""""
        IF w_final-re_house_no IS NOT INITIAL .
          lv_bill_adr1 = |{ w_final-re_house_no }| .
        ENDIF .

        IF w_final-re_street IS NOT INITIAL .
          IF lv_bill_adr1 IS NOT INITIAL   .
            lv_bill_adr1 = |{ lv_bill_adr1 } , { w_final-re_street }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
          ELSE .
            lv_bill_adr1 = |{ w_final-re_street }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
          ENDIF .
        ENDIF .

        IF w_final-re_street1 IS NOT INITIAL .
          IF lv_bill_adr1 IS NOT INITIAL   .
            lv_bill_adr1 = |{ lv_bill_adr1 } , { w_final-re_street1 }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
          ELSE .
            lv_bill_adr1 = |{ w_final-re_street1 }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
          ENDIF .
        ENDIF .

        DATA(len) = strlen( lv_bill_adr1 ) .
        len = len - 40.
        IF strlen( lv_bill_adr1 ) GT 40 .
          lv_bill_adr2 = |{ lv_bill_adr1+40(len) },| .
          lv_bill_adr1 = lv_bill_adr1+0(40) .
        ENDIF .
        """""""eoc bill address set""""""""


        """"""" ship address set """"""""

        IF w_final-we_house_no IS NOT INITIAL .
          lv_shp_adr1 = |{ w_final-we_house_no }| .
        ENDIF .

        IF w_final-we_street IS NOT INITIAL .
          IF lv_shp_adr1 IS NOT INITIAL   .
            lv_shp_adr1 = |{ lv_shp_adr1 } , { w_final-we_street }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
          ELSE .
            lv_shp_adr1 = |{ w_final-we_street }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
          ENDIF .
        ENDIF .

        IF w_final-we_street1 IS NOT INITIAL .
          IF lv_shp_adr1 IS NOT INITIAL   .
            lv_shp_adr1 = |{ lv_shp_adr1 } , { w_final-we_street1 }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
          ELSE .
            lv_shp_adr1 = |{ w_final-we_street1 }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
          ENDIF .
        ENDIF .

        len = strlen( lv_shp_adr1 ) .
        len = len - 40.
        IF strlen( lv_shp_adr1 ) GT 40 .
          lv_shp_adr2 = |{ lv_shp_adr1+40(len) },| .
          lv_shp_adr1 = lv_shp_adr1+0(40) .
        ENDIF .

        """"""" ship bill address set """"""""
        DATA : heading      TYPE c LENGTH 100,
               sub_heading  TYPE c LENGTH 255,
               for_sign     TYPE c LENGTH 100,
               curr         TYPE c LENGTH 100,
               exp_curr     TYPE c LENGTH 100,
               exc_rt       TYPE c LENGTH 100,
               lv_delv_term TYPE c LENGTH 100.

        DATA : lv_dt_bill      TYPE c LENGTH 10,
               lv_dt_bill_qr   TYPE c LENGTH 6,
               lv_dt_bill_tkap TYPE c LENGTH 8.
        DATA : lv_dt_po TYPE c LENGTH 10.
        DATA : lv_dt_ack TYPE c LENGTH 10.

        IF w_final-transactioncurrency = 'JPY'.
          w_final-accountingexchangerate = w_final-accountingexchangerate." / 10 .
        ENDIF.
        lv_exchng_rate = w_final-accountingexchangerate .

        exc_rt = lv_exchng_rate.
        SELECT SINGLE * FROM zsd_einv_data WHERE billingdocument = @w_final-billingdocument
          INTO @DATA(w_einvvoice) .                         "#EC WARNOK
        CLEAR : lv_qr_code , lv_irn_num   , lv_ack_no ,lv_ack_date .

        lv_vehicle    = w_einvvoice-vehiclenum.
        lv_transmode  = w_einvvoice-modeoftransp.
        CONDENSE w_einvvoice-modeoftransp.
        IF w_einvvoice-modeoftransp = '1'.
          lv_transmode  = 'Road' ##NO_TEXT.
        ELSEIF w_einvvoice-modeoftransp = '2'.
          lv_transmode  = 'Rail' ##NO_TEXT.
        ELSEIF w_einvvoice-modeoftransp = '3'.
          lv_transmode  = 'Air' ##NO_TEXT.
        ENDIF.
        lv_qr_code = w_einvvoice-signedqrcode .
        lv_irn_num = w_einvvoice-irn .
        lv_ack_no =  w_einvvoice-ackno .
        lv_ack_date =  w_einvvoice-ackdt .
        lv_eway     = w_einvvoice-ewbno.
        lv_eway_dt  = w_einvvoice-ewbdt+6(2) && '.' && w_einvvoice-ewbdt+4(2) && '.' &&  w_einvvoice-ewbdt+0(4). " 2024-04-27
        """sub_heading = '(Issued Under Section 31 of Central Goods & Service Tax Act 2017 and HARYANA State Goods & Service Tax Act 2017)' .
        sub_heading = '' .
        for_sign  = 'DE Diamond Electric India Pvt. Ltd.'  ##NO_TEXT.

        """""" Date conversion """"
        lv_dt_bill    = w_final-billingdocumentdate+6(2) && '/' && w_final-billingdocumentdate+4(2) && '/' && w_final-billingdocumentdate+0(4).
        lv_dt_ack   = lv_ack_date+8(2) && '/' && lv_ack_date+5(2) && '/' && lv_ack_date+0(4).
        lv_dt_po    = w_final-customerpurchaseorderdate+6(2) && '/' && w_final-customerpurchaseorderdate+4(2) && '/' && w_final-customerpurchaseorderdate+0(4).
        lv_so_dt    = w_final-salesdocumentdate+6(2) && '/' && w_final-salesdocumentdate+4(2) && '/' && w_final-salesdocumentdate+0(4).
        """""" Date Conversion """"

        IF im_prntval = 'Original' ##NO_TEXT.
          ""odte_text = |Original                                   Duplicate                                 Triplicate                                      Extra| ##NO_TEXT.
          odte_text = 'Original' ##NO_TEXT.
        ELSEIF im_prntval = 'Duplicate' ##NO_TEXT.
          odte_text = 'Duplicate' ##NO_TEXT.
        ELSEIF im_prntval = 'Triplicate' ##NO_TEXT.
          odte_text = 'Triplicate' ##NO_TEXT.
        ELSEIF im_prntval = 'Extra' ##NO_TEXT.
          odte_text = 'Extra Invoice Copy' ##NO_TEXT.
        ENDIF.

        "BOC by Neelam Goyal on 22.06.2025
        IF im_prntval = 'All '  ##NO_TEXT.
          IF sy-index = 1.
            odte_text = 'ORIGINAL FOR RECIPIENT'  ##NO_TEXT.
          ENDIF.
          IF sy-index = 2.
            odte_text = 'DUPLICATE FOR TRANSPORTER'  ##NO_TEXT.
          ENDIF.
          IF sy-index = 3.
            odte_text = 'TRIPLICATE FOR SUPPLIER'  ##NO_TEXT.
          ENDIF.
          IF sy-index = 4.
            odte_text = 'EXTRA COPY'.
          ENDIF.
        ENDIF.
        "EOC by Neelam Goyal on 22.06.2025

        IF iv_action = 'taxinv' .

          heading = 'EXPORT INVOICE' ##NO_TEXT.

          IF w_final-distributionchannel = '30' .
            "heading = 'EXPORT INVOICE'  .
            IF w_final-item_igstrate IS INITIAL .
              sub_heading = 'Issued Under Section 31 of Central Goods and Service Tax Act 2017 and HARYANA State Goods and Service Tax Act 2017' ##NO_TEXT.
              "*head_lut = 'Against LUT No.(ARN No. AD060323015122V DT. 29/03/23'.
            ELSE .
              sub_heading = 'Issued Under Section 31 of Central Goods and Service Tax Act 2017 and HARYANA State Goods and Service Tax Act 2017' ##NO_TEXT.
              "" head_lut = 'Against LUT No.(ARN No. AD060323015122V DT. 21/03/23'.
            ENDIF .
          ELSE .
            "heading = 'TAX INVOICE'  .
            sub_heading = 'Under Section 31 of CGST Act and SGST Act read with section 20 of IGST Act' ##NO_TEXT.
          ENDIF .

        ELSEIF iv_action = 'qrinv' OR  iv_action = 'oeminv' ..
          heading = 'TAX INVOICE'  ##NO_TEXT.
          sub_heading = 'Under section 31 of  CGST Act 2017, read with rule 46 of CGST Rules 2017.' ##NO_TEXT.

          IF w_final-billingdocumenttype = 'JSTO'.
            """"""""""""""""""" bill to party equals ship to party in challan case .
            w_final-ship_to_party = w_final-bill_to_party .
            w_final-we_name  = w_final-re_name .
            lv_shp_adr1 = lv_bill_adr1 .
            lv_shp_adr2 = lv_bill_adr2 .
            w_final-we_city  = w_final-re_city .
            w_final-we_pin = w_final-re_pin   .
            w_final-we_tax  = w_final-re_tax  .
            w_final-we_pan = w_final-re_pan  .
            w_final-we_region = w_final-re_region  .
            w_final-we_city = w_final-re_city .
            w_final-we_city = w_final-re_city  .
            w_final-we_phone4  = w_final-re_phone4  .
            w_final-we_email = w_final-re_email .
            lv_dt_po = lv_dt_bill .

          ENDIF.

        ELSEIF iv_action = 'dchlpr' ##NO_TEXT.

          heading     = 'DELIVERY CHALLAN' ##NO_TEXT.
          sub_heading = '(As per Rule 31 read with rule 46 of GST ACT,2017)' ##NO_TEXT.

          IF w_final-billingdocumenttype = 'JSN' ##NO_TEXT.
            heading     = 'JOB WORK CHALLAN' ##NO_TEXT.
            sub_heading = 'As per Rule 55(1)B of CGST Rule 2017' ##NO_TEXT.
          ENDIF.

          IF w_final-billingdocumenttype = 'JDC' OR w_final-billingdocumenttype = 'JVR' ##NO_TEXT.
            sub_heading = 'As per Rule 55(1)C of CGST Rule 2017' ##NO_TEXT.
          ENDIF.

          IF im_prntval = 'Original' ##NO_TEXT.
            "*odte_text = |Original                                   Duplicate                                 Triplicate                                      Extra| ##NO_TEXT.
            odte_text = 'Original' ##NO_TEXT.
          ELSEIF im_prntval = 'Duplicate' ##NO_TEXT.
            odte_text = 'Duplicate Challan' ##NO_TEXT.
          ELSEIF im_prntval = 'Triplicate' ##NO_TEXT.
            odte_text = 'Triplicate Challan' ##NO_TEXT.
          ELSEIF im_prntval = 'Extra' ##NO_TEXT.
            odte_text = 'Extra Challan Copy' ##NO_TEXT.
          ENDIF.

          CLEAR : exc_rt .  """" will add read text of nature of work ...
          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z018' .
          IF sy-subrc = 0 .
            exc_rt = w_text-longtext .
          ENDIF .
          """"""""""""""""""" bill to party equals ship to party in challan case .
          IF w_final-billingdocumenttype = 'JVR' OR
             w_final-billingdocumenttype = 'JSN' OR
             w_final-billingdocumenttype = 'JDC'.

            w_final-ship_to_party   = w_final-bill_to_party .
            w_final-we_name         = w_final-re_name .
            lv_shp_adr1             = lv_bill_adr1 .
            lv_shp_adr2             = lv_bill_adr2 .
            w_final-we_city         = w_final-re_city .
            w_final-we_pin          = w_final-re_pin   .
            w_final-we_tax          = w_final-re_tax  .
            w_final-we_pan          = w_final-re_pan  .
            w_final-we_region       = w_final-re_region  .
            w_final-we_city         = w_final-re_city .
            w_final-we_city         = w_final-re_city  .
            w_final-we_phone4       = w_final-re_phone4  .
            w_final-we_email        = w_final-re_email .
            lv_dt_po                = lv_dt_bill .

            """"""""""""""""""" bill to party equals ship to party in challan case .
            SELECT SINGLE
            supplier,
            suppliername,
            suplrmanufacturerexternalname
            FROM i_supplier WHERE supplier = @w_final-bill_to_party
            INTO @DATA(ls_lfa1).

            IF ls_lfa1-suplrmanufacturerexternalname IS INITIAL.

            ELSE.

              CLEAR:
              lv_bill_adr1,
              lv_bill_adr2,
              w_final-bill_to_party,
              w_final-re_name,
              w_final-re_city,
              w_final-re_pin,
              w_final-re_tax,
              w_final-re_pan,
              w_final-re_region ,
              w_final-re_city ,
              w_final-re_phone4,
              w_final-re_email.

              SELECT SINGLE * FROM zi_supplier_address
              WHERE supplier = @ls_lfa1-suplrmanufacturerexternalname
              INTO @DATA(ls_suplr_adrs).

              w_final-bill_to_party = ls_suplr_adrs-supplier.
              w_final-re_name       = ls_suplr_adrs-suppliername.

              IF ls_suplr_adrs-housenumber IS NOT INITIAL .
                lv_bill_adr1 = |{ ls_suplr_adrs-housenumber }| .
              ENDIF .

              IF ls_suplr_adrs-streetname IS NOT INITIAL .
                IF lv_bill_adr1 IS NOT INITIAL   .
                  lv_bill_adr1 = |{ lv_bill_adr1 } , { ls_suplr_adrs-streetname }, { ls_suplr_adrs-streetprefixname1 }, { ls_suplr_adrs-streetprefixname2 }, { ls_suplr_adrs-streetsuffixname1 }| .
                ELSE .
                  lv_bill_adr1 = |{ ls_suplr_adrs-streetname }, { ls_suplr_adrs-streetprefixname1 }, { ls_suplr_adrs-streetprefixname2 }, { ls_suplr_adrs-streetsuffixname1 }| .
                ENDIF .
              ENDIF .

              len = strlen( lv_bill_adr1 ) .
              len = len - 40.
              IF strlen( lv_bill_adr1 ) GT 40 .
                lv_bill_adr2 = |{ lv_bill_adr1+40(len) },| .
                lv_bill_adr1 = lv_bill_adr1+0(40) .
              ENDIF .

              w_final-re_city        = ls_suplr_adrs-cityname.
              w_final-re_pin         = ls_suplr_adrs-postalcode.
              w_final-re_tax         = ls_suplr_adrs-taxnumber3.
              w_final-re_pan         = ls_suplr_adrs-taxnumber3.
              w_final-re_region      = ls_suplr_adrs-region.
              w_final-re_city        = ls_suplr_adrs-cityname.
              w_final-re_phone4      = ls_suplr_adrs-phonenumber1.
              w_final-re_email       = ls_suplr_adrs-emailaddress.


            ENDIF.

          ENDIF.

        ELSEIF iv_action = 'dcnote' ##NO_TEXT.
          IF w_final-billingdocumenttype = 'G2' OR w_final-billingdocumenttype = 'CBRE'.
            heading = 'CREDIT NOTE' ##NO_TEXT.
            sub_heading = '(Section 34 (2) of CGST Act and Rule 53 of CGST Rules 2017)' ##NO_TEXT.
          ELSEIF w_final-billingdocumenttype = 'L2' ##NO_TEXT.
            heading = 'DEBIT NOTE' ##NO_TEXT.
            sub_heading = '(Section 34 (3) of CGST Act and Rule 53 of CGST Rules 2017)' ##NO_TEXT.
          ENDIF .

        ELSEIF iv_action = 'aftinv' ##NO_TEXT.
          heading = 'TAX INVOICE' ##NO_TEXT.
          sub_heading = 'Issued Under Section 31 of Central Goods and Service Tax Act 2017 and HARYANA State Goods and Service Tax Act 2017' ##NO_TEXT.
        ENDIF .

        curr     = w_final-transactioncurrency .
        exp_curr = w_final-transactioncurrency.

        CONDENSE : exc_rt , curr , heading , sub_heading , head_lut , for_sign ,  lv_shp_adr1 , lv_shp_adr2, exp_curr.


        SELECT SINGLE * FROM zi_regiontext WHERE region = @w_final-region AND language = 'E' AND country = @w_final-country
         INTO @DATA(lv_st_nm).                "#EC CI_ALL_FIELDS_NEEDED

        SELECT SINGLE * FROM zi_regiontext  WHERE region = @w_final-re_region AND language = 'E' AND country = @w_final-re_country
        INTO @DATA(lv_st_name_re).            "#EC CI_ALL_FIELDS_NEEDED

        SELECT SINGLE * FROM zi_regiontext  WHERE region = @w_final-we_region AND language = 'E' AND country = @w_final-we_country
        INTO @DATA(lv_st_name_we).            "#EC CI_ALL_FIELDS_NEEDED

        SELECT SINGLE * FROM zi_countrytext  WHERE country = @w_final-country AND language = 'E'
        INTO @DATA(lv_cn_nm).                 "#EC CI_ALL_FIELDS_NEEDED

        SELECT SINGLE * FROM zi_countrytext   WHERE country = @w_final-re_country AND language = 'E'
        INTO @DATA(lv_cn_name_re).            "#EC CI_ALL_FIELDS_NEEDED

        SELECT SINGLE * FROM zi_countrytext   WHERE country = @w_final-we_country AND language = 'E'
        INTO @DATA(lv_cn_name_we).            "#EC CI_ALL_FIELDS_NEEDED

        IF iv_action = 'dchlpr' .
          w_final-purchaseorderbycustomer = w_final-purchaseorder .
        ENDIF.

        DATA:
          lv_plant_addrs1 TYPE string,
          lv_plant_addrs2 TYPE string,
          lv_plant_addrs3 TYPE string,
          lv_plant_cin    TYPE string,
          lv_plant_pan    TYPE string.

        SELECT SINGLE * FROM zi_plant_address
                        WHERE plant = @w_final-plant
                        INTO @DATA(ls_plant_adrs).

        lv_plant_addrs1 = ls_plant_adrs-streetname.
        lv_plant_addrs2 = |{ ls_plant_adrs-cityname } - { ls_plant_adrs-postalcode }, { ls_plant_adrs-regionname } - { ls_plant_adrs-addresstimezone }|.
*    lv_plant_addrs3 = |{ ls_plant_adrs-regionname } - { ls_plant_adrs-addresstimezone }|.

        lv_delv_term = |{ w_final-incotermsclassification } ({ w_final-incotermslocation1 })|.

        lv_plant_cin = 'U31908HR2007FTC039788' ##NO_TEXT.
        lv_plant_pan = w_final-plant_gstin+2(10).
        "*w_final-plantname = 'DE DIAMOND ELECTRIC INDIA PVT. LTD.' ##NO_TEXT.
        lv_plant_name     = 'DE DIAMOND ELECTRIC INDIA PVT. LTD.' ##NO_TEXT.
        w_final-phoneareacodesubscribernumber = '9053029817'.

        """add by sb 10.02.2026""""
        IF w_final-distributionchannel = '30'.
          lv_place_supply = 'Out Side India'.
        ELSE.
          lv_place_supply = w_final-we_city && '-' && lv_st_name_we-regionname. "lv_cn_name_we-CountryName.
        ENDIF.

        """add by sb 10.02.2026""""
        REPLACE ALL OCCURRENCES OF '&' IN lv_bill_adr1 WITH ''.
        REPLACE ALL OCCURRENCES OF '&' IN lv_shp_adr1 WITH ''.

        IF w_final-distributionchannel = '30' OR w_final-distributionchannel = '40'.
          head_lut = |LUT No: { head_lut }| ##NO_TEXT.
        ELSE.
          CLEAR: head_lut.
        ENDIF.

        IF w_final-billingdocumenttype = 'JDC' OR
           w_final-billingdocumenttype = 'JSN' OR
           w_final-billingdocumenttype = 'JVR'.

          w_final-purchaseorderbycustomer = w_final-purchaseorder.

        ENDIF.

        REPLACE ALL OCCURRENCES OF '&' IN w_final-purchaseorderbycustomer WITH 'and'.
        REPLACE ALL OCCURRENCES OF '&' IN lv_bill_adr2 WITH 'and'.
        REPLACE ALL OCCURRENCES OF '&' IN lv_shp_adr2 WITH 'and'.

        """add by sb 10.02.2026""""""'
        IF  w_sum-item_igstamount IS NOT INITIAL.
          ex_pay = 'Export with Payment of tax'.
        ENDIF.

        ""add by sb 10.02.2026""""""'
        " DATA(lv_xml) = |<Form>| &&
        DATA(lv_xml1) = "|<Form>| &&
                       |<BillingDocumentNode>| &&
                       |<heading>{ heading }</heading>| &&
                       |<sub_heading>{ sub_heading }</sub_heading>| &&
                       |<head_lut>{ head_lut }</head_lut>| &&
                       |<for_sign>{ for_sign }</for_sign>| &&
                       |<odte_text>{ odte_text }</odte_text>| &&
                       |<doc_curr>{ curr }</doc_curr>| &&
                       |<exp_curr>{ exp_curr }</exp_curr>| &&
                       |<plant_code>{ w_final-plant }</plant_code>| &&
                       |<plant_name>{ lv_plant_name }</plant_name>| &&
                       |<plant_address_l1>{ lv_plant_addrs1 }</plant_address_l1>| &&
                       |<plant_address_l2>{ lv_plant_addrs2 }</plant_address_l2>| &&
                       |<plant_address_l3>{ lv_plant_addrs3 }</plant_address_l3>| &&
                        |<plant_cin>{ lv_plant_cin }</plant_cin>| &&
                        |<plant_gstin>{ w_final-plant_gstin }</plant_gstin>| &&
                        |<plant_pan>{ lv_plant_pan }</plant_pan>| &&
                        |<plant_state_code>{ w_final-region } ({ ls_plant_adrs-regionname })</plant_state_code>| &&
                        |<plant_state_name></plant_state_name>| &&
                        |<plant_phone>{ w_final-phoneareacodesubscribernumber }</plant_phone>| &&
                        |<plant_email>{ w_final-plant_email }</plant_email>| &&
                        |<billto_code>{ w_final-bill_to_party }</billto_code>| &&
                        |<billto_name>{ w_final-re_name }</billto_name>| &&
                        |<billto_address_l1>{ lv_bill_adr1 }</billto_address_l1>| &&
                        |<billto_address_l2>{ lv_bill_adr2 }{ w_final-re_city }</billto_address_l2>| &&
                        |<billto_address_l3>{ w_final-re_pin } ({ lv_cn_name_re-countryname })</billto_address_l3>| &&
*        |<billto_cin>{ W_FINAL-re }</billto_cin>| &&
                        |<billto_gstin>{ w_final-re_tax }</billto_gstin>| &&
                        |<billto_pan>{ w_final-re_pan }</billto_pan>| &&
                        |<billto_state_code>{ w_final-re_region } ({ lv_st_name_re-regionname })</billto_state_code>| &&
                        |<billto_state_name></billto_state_name>| &&
                        |<billto_place_suply>{ w_final-re_region }</billto_place_suply>| &&
                        |<billto_phone>{ w_final-re_phone4 }</billto_phone>| &&
                        |<billto_email>{ w_final-re_email }</billto_email>| &&

                        |<shipto_code>{ w_final-ship_to_party }</shipto_code>| &&
                        |<shipto_name>{ w_final-we_name }</shipto_name>| &&
                        |<shipto_address_l1>{ lv_shp_adr1 }</shipto_address_l1>| &&
                        |<shipto_address_l2>{ lv_shp_adr2 }{ w_final-we_city }</shipto_address_l2>| &&
                        |<shipto_address_l3>{ w_final-we_pin } ({ lv_cn_name_we-countryname })</shipto_address_l3>| &&
*        |<shipto_cin>{ W_FINAL-PlantName }</shipto_cin>| &&
                        |<shipto_gstin>{ w_final-we_tax }</shipto_gstin>| &&
                        |<shipto_pan>{ w_final-we_pan }</shipto_pan>| &&
                        |<shipto_state_code>{ w_final-we_region } ({ lv_st_name_we-regionname })</shipto_state_code>| &&
                        |<shipto_state_name>{ lv_st_name_we-regionname }</shipto_state_name>| &&
                        |<shipto_place_suply>{ lv_place_supply }</shipto_place_suply>| &&
                        |<shipto_phone>{ w_final-we_phone4 }</shipto_phone>| &&
                        |<shipto_email>{ w_final-we_email }</shipto_email>| &&

                        |<inv_no>{ w_final-documentreferenceid }  </inv_no>| &&
                        |<inv_date>{ lv_dt_bill }</inv_date>| &&
                        |<inv_ref>{ w_final-billingdocument }</inv_ref>| &&
                        |<exchange_rate>{ exc_rt }</exchange_rate>| &&
                        |<currency>{ w_final-transactioncurrency }</currency>| &&
                        |<Exp_Inv_No>{ lv_exp_no }</Exp_Inv_No>| &&       """""""
                        |<IRN_num>{ lv_irn_num }</IRN_num>| &&
                        |<IRN_ack_No>{ lv_ack_no }</IRN_ack_No>| &&
                        |<irn_ack_date>{ lv_dt_ack }</irn_ack_date>| &&
                        |<irn_doc_type></irn_doc_type>| &&     """"""
                        |<irn_category></irn_category>| &&     """"""
                        |<qrcode>{ lv_qr_code }</qrcode>| &&
                        |<vcode>{ vcode }</vcode>| &&    """"" USING ZTABLE DATA TO BE MAINTAINED ...
                        |<vplant>{ lv_cus_pl }</vplant>| &&
                        |<pur_odr_no>{ w_final-purchaseorderbycustomer }</pur_odr_no>| &&
                        |<pur_odr_date>{ lv_dt_po }</pur_odr_date>| &&
                        |<order_num>{ lv_order_num }</order_num>| &&
                        |<Pay_term>{ w_final-customerpaymenttermsname }</Pay_term>| &&  """"
                        |<Delivery_term>{ lv_delv_term }</Delivery_term>| &&  """"
                        |<Veh_no>{ lv_vehicle }</Veh_no>| &&
                        |<Trans_mode>{ lv_transmode }</Trans_mode>| &&
                        |<Ewaybill_no>{ lv_eway }</Ewaybill_no>| &&
                        |<Ewaybill_date>{ lv_eway_dt }</Ewaybill_date>| &&

                        |<material_doc>{ w_final-materialdocument }</material_doc>| &&
                        |<ex_pay>{ ex_pay }</ex_pay>| &&

                        |<sale_odr_no>{ w_final-salesdocument }</sale_odr_no>| &&
                        |<sale_odr_date>{ lv_so_dt }</sale_odr_date>| &&
                        |<delivery_note_no>{ w_final-deliverydocument }</delivery_note_no>| &&
                        |<delivery_note_date>{ w_final-salesdocumentdate }</delivery_note_date>| &&
                        |<ref_doc_no>{ lv_bags }</ref_doc_no>| &&  "**Used for Total Cases/Bags/BINs:
*        |<ref_doc_date>{ lv_eway }</ref_doc_date>| &&

                       |<ItemData>| .

        CONCATENATE lv_xml lv_xml1 INTO lv_xml. " added by neelam goyal

        DATA : lv_item TYPE string .
        DATA : srn      TYPE c LENGTH 3,
               lv_matnr TYPE c LENGTH 120.

        CLEAR : lv_item , srn .

        IF iv_action = 'dchlpr' AND w_final-billingdocumenttype = 'F2'.

          SELECT
            lips~deliverydocument,
            lips~deliverydocumentitem,
            lips~distributionchannel,
            lips~division,
            lips~material,
            lips~product,
            lips~materialbycustomer,
            lips~plant,
            lips~deliverydocumentitemcategory,
            lips~deliverydocumentitemtext,
            lips~actualdeliveryquantity,
            lips~deliveryquantityunit,
            marc~consumptiontaxctrlcode AS hsn
            FROM i_deliverydocumentitem AS lips
            INNER JOIN i_productplantbasic AS marc
            ON lips~product = marc~product AND
               lips~plant   = marc~plant
            WHERE deliverydocument = @w_final-deliverydocument
            INTO TABLE @DATA(lt_lips).

          LOOP AT lt_lips INTO DATA(ls_lips)
                  WHERE ( deliverydocumentitemcategory = 'DLN' OR deliverydocumentitemcategory = 'CB10' ).

            lv_matnr     = ls_lips-product.
            lv_qty         = lv_qty  +  ls_lips-actualdeliveryquantity.

            srn = srn + 1.
            lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                      |<sno>{ srn }</sno>| &&
                      |<item_code>{ lv_matnr }</item_code>| &&
                      |<item_cust_refno>{ lv_ref_sddoc }</item_cust_refno>| &&
                      |<item_desc>{ ls_lips-deliverydocumentitemtext }</item_desc>| &&
                      |<item_hsn_code>{ ls_lips-hsn }</item_hsn_code>| &&
*      |<mrp_of_goods>{ lv_mrp_of_goods }</mrp_of_goods>| &&
                      |<item_uom>{ ls_lips-deliveryquantityunit }</item_uom>| &&
                      |<item_qty>{ ls_lips-actualdeliveryquantity }</item_qty>| &&
*      |<item_unit_rate>{ lv_item_urate }</item_unit_rate>| &&
*      |<item_amt_inr>{ lv_item_amtinr }</item_amt_inr>| &&
*      |<item_amt_expcurr>{ lv_item_amtexp }</item_amt_expcurr>| &&
*      |<item_discount>{ w_item-item_discountamount }</item_discount>| &&
*      |<item_taxable_amt>{ w_item-item_assessableamount }</item_taxable_amt>| &&
*      |<item_sgst_rate>{ w_item-item_sgstrate }</item_sgst_rate>| &&
*      |<item_sgst_amt>{ w_item-item_sgstamount }</item_sgst_amt>| &&
*      |<item_cgst_amt>{ w_item-item_cgstamount }</item_cgst_amt>| &&
*      |<item_cgst_rate>{ w_item-item_cgstrate }</item_cgst_rate>| &&
*      |<item_igst_amt>{ w_item-item_igstamount }</item_igst_amt>| &&
*      |<item_igst_rate>{ w_item-item_igstrate }</item_igst_rate>| &&
*      |<item_amort_amt>{ w_item-item_amotization }</item_amort_amt>| &&
*      |<item_gst_rate>{ lv_item_gst_rate }</item_gst_rate>| &&

                      |</ItemDataNode>|.

            CLEAR: ls_lips.
          ENDLOOP.


        ELSE.


          LOOP AT it_final INTO DATA(w_item) .
            srn = srn + 1 .

            IF iv_action = 'oeminv' AND w_final-billingdocumenttype = 'JSTO'.  ""IV_ACTION
              w_item-item_unitprice  = w_item-item_pcip_amt.
              w_item-item_totalamount_inr = w_item-item_pcip_amt * w_item-billingquantity.
            ENDIF.

            IF iv_action = 'dchlpr'
            AND ( w_final-billingdocumenttype = 'JVR' OR w_final-billingdocumenttype = 'JSN' OR w_final-billingdocumenttype = 'JDC' ).

              IF w_item-item_pcip_amt IS NOT INITIAL.

                w_item-item_unitprice  = w_item-item_pcip_amt.

              ELSE.

                w_item-item_unitprice  = w_item-item_unitprice.

              ENDIF.

              w_item-item_totalamount_inr = w_item-item_pcip_amt * w_item-billingquantity.

            ENDIF.

            IF w_item-conditionquantity IS NOT INITIAL .
              lv_item_urate = w_item-item_unitprice / w_item-conditionquantity.
              IF w_item-transactioncurrency EQ 'JPY'.
                lv_item_urate1 = lv_item_urate ."/ 10.

              ELSE.
                lv_item_urate1 = lv_item_urate.
              ENDIF.
              lv_item_urate  = lv_item_urate * w_final-accountingexchangerate.
              IF w_item-transactioncurrency EQ 'JPY'.
                lv_item_urate = lv_item_urate / w_item-conditionquantity.
                lv_item_urate = lv_item_urate / 10.           "inr
                lv_item_urate = ( lv_item_urate1 * w_final-accountingexchangerate ) / 100.   ""added by aman/mani 30.10.2025

              ENDIF.
              lv_item_amtinr = w_item-billingquantity * lv_item_urate.
              lv_item_amtexp = lv_item_urate * w_item-billingquantity.
            ELSE.
              lv_item_urate  = w_item-item_unitprice * w_final-accountingexchangerate.
              lv_item_urate1 = lv_item_urate.
              lv_item_amtinr = w_item-item_totalamount_inr.
              lv_item_amtexp = w_item-item_unitprice * w_item-billingquantity.
            ENDIF.

            w_item-item_amotization = w_item-item_amotization  *   w_final-accountingexchangerate  .
            w_item-item_totalamount_inr = w_item-billingquantity * lv_item_urate .
            w_item-item_discountamount = w_item-item_discountamount *   w_final-accountingexchangerate  .
            w_item-item_assessableamount = w_item-item_totalamount_inr -  w_item-item_discountamount.

            w_item-item_assessableamount = w_item-item_assessableamount +
                                           w_item-item_fert_oth +
                                           w_item-item_freight +
*                           w_item-item_othercharge +
                                           w_item-item_pkg_chrg +
                                           w_item-item_amotization.


            lv_qty         = lv_qty  +   w_item-billingquantity .
            lv_dis         = lv_dis + w_item-item_discountamount .
            lv_tcs         = lv_tcs +  w_item-item_othercharge .

            IF ( w_final-distributionchannel = '10' OR w_final-distributionchannel = '20' ).

              lv_other_chrg  = lv_other_chrg + w_item-item_freight_zfrg .

            ELSE.

              lv_other_chrg  = lv_other_chrg + w_item-item_freight_zfrt.

            ENDIF.


            lv_round_off   = lv_round_off +  w_item-item_roundoff .
            sum_other_chrg = sum_other_chrg + w_item-item_fert_oth.
            """"       ENDIF

            DATA : lv_item_text TYPE string .
            CLEAR : lv_item_text .

            IF w_item-materialdescriptionbycustomer IS INITIAL.
              lv_item_text = w_item-billingdocumentitemtext.
            ELSE.
              lv_item_text = w_item-materialdescriptionbycustomer.
            ENDIF.
*    COMMENT BY SB 12/15/2025
**            lv_item_text = |{ w_item-billingdocumentitemtext } - { w_item-materialbycustomer }|.
*    COMMENT BY SB 12/15/2025
            lv_item_text = w_item-billingdocumentitemtext .
**    * ADD BY SB 12/15/2025
            SELECT SINGLE
            salesdocument,
            salesdocumentitem,
            materialbycustomer
            FROM i_salesdocumentitem
            WHERE salesdocument = @w_item-salesdocument AND salesdocumentitem = @w_item-salesdocumentitem
            INTO @DATA(ls_sale_doc).

            IF ls_sale_doc-materialbycustomer IS NOT INITIAL.
              w_item-materialbycustomer = ls_sale_doc-materialbycustomer.
            ENDIF.

            lv_matnr = w_item-product.

* w_item-MaterialByCustomer IS NOT INITIAL. "w_item-ProductOldID IS NOT INITIAL.
*    lv_matnr = w_item-MaterialByCustomer.       "w_item-ProductOldID.
*  ELSE.
*    lv_matnr = w_item-product.
*  ENDIF.

            lv_ref_sddoc = w_item-materialbycustomer.

            REPLACE ALL OCCURRENCES OF '&' IN lv_item_text WITH '' .
            REPLACE ALL OCCURRENCES OF '&' IN lv_ref_sddoc WITH '' .

            CLEAR : w_item-item_sgstamount, w_item-item_cgstamount, w_item-item_igstamount.
            w_item-item_sgstamount = w_item-item_assessableamount  *     w_item-item_cgstrate / 100  .
            w_item-item_cgstamount = w_item-item_assessableamount  *    w_item-item_cgstrate / 100    .
            w_item-item_igstamount = w_item-item_assessableamount  *   w_item-item_igstrate / 100   .

            lv_tot_cgst    = lv_tot_cgst  + w_item-item_cgstamount .
            lv_tot_sgst    = lv_tot_sgst  + w_item-item_sgstamount .
            lv_tot_igst    = lv_tot_igst  + w_item-item_igstamount .

            lv_amt_expcurr  = lv_amt_expcurr + lv_item_amtexp.
            lv_mrp_of_goods = w_item-item_zmrp_amount.
            lv_tot_amt      = lv_tot_amt +   lv_item_amtinr. "w_item-item_totalamount_inr .
*    lv_tot_igst     = lv_tot_igst  + w_item-item_igstamount .

            IF w_item-billingquantityunit EQ 'ST'.
              w_item-billingquantityunit = 'NOS'.
            ENDIF.

            lv_item_gst_rate = w_item-item_sgstrate + w_item-item_cgstrate + w_item-item_igstrate.




            REPLACE ALL OCCURRENCES OF '&' IN lv_item_text WITH 'and'.
            REPLACE ALL OCCURRENCES OF '×' IN lv_item_text WITH ''.
            REPLACE ALL OCCURRENCES OF '±' IN lv_item_text WITH ''.
            REPLACE ALL OCCURRENCES OF '#' IN lv_item_text WITH ''.
            REPLACE ALL OCCURRENCES OF '&' IN w_item-purchaseorderbycustomer WITH 'and'.
            REPLACE ALL OCCURRENCES OF '&' IN w_item-materialbycustomer WITH 'and'.


            lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                      |<sno>{ srn }</sno>| &&
                      |<item_code>{ lv_matnr }</item_code>| &&
                      |<item_cust_refno>{ lv_ref_sddoc }</item_cust_refno>| &&
                      |<item_desc>{ lv_item_text }</item_desc>| &&
                      |<cust_code>{ w_item-materialbycustomer }</cust_code>| &&
                      |<po_number>{ w_item-purchaseorderbycustomer }</po_number>| &&
                      |<item_hsn_code>{ w_item-hsn }</item_hsn_code>| &&
                      |<mrp_of_goods>{ lv_mrp_of_goods }</mrp_of_goods>| &&
                      |<item_uom>{ w_item-billingquantityunit }</item_uom>| &&
                      |<item_qty>{ w_item-billingquantity }</item_qty>| &&
                      |<item_unit_rate>{ lv_item_urate }</item_unit_rate>| &&
                      |<item_unit_rate1>{ lv_item_urate1 }</item_unit_rate1>| &&
                      |<item_amt_inr>{ lv_item_amtinr }</item_amt_inr>| &&
                      |<item_amt_expcurr>{ lv_item_amtexp }</item_amt_expcurr>| &&
                      |<item_discount>{ w_item-item_discountamount }</item_discount>| &&
                      |<item_taxable_amt>{ w_item-item_assessableamount }</item_taxable_amt>| &&
                      |<item_sgst_rate>{ w_item-item_sgstrate }</item_sgst_rate>| &&
                      |<item_sgst_amt>{ w_item-item_sgstamount }</item_sgst_amt>| &&
                      |<item_cgst_amt>{ w_item-item_cgstamount }</item_cgst_amt>| &&
                      |<item_cgst_rate>{ w_item-item_cgstrate }</item_cgst_rate>| &&
                      |<item_igst_amt>{ w_item-item_igstamount }</item_igst_amt>| &&
                      |<item_igst_rate>{ w_item-item_igstrate }</item_igst_rate>| &&
                      |<item_amort_amt>{ w_item-item_amotization }</item_amort_amt>| &&
                      |<item_gst_rate>{ lv_item_gst_rate }</item_gst_rate>| &&

                      |</ItemDataNode>|  .

            lv_tot_pkgchrg = lv_tot_pkgchrg + w_item-item_pkg_chrg.
            lv_tot_amort   = lv_tot_amort + w_item-item_amotization.

            lv_tax_amt     = lv_tax_amt + w_item-item_assessableamount .
            lv_tax_amt1    = lv_tax_amt1 + w_item-item_assessableamount .

*  "lv_tot_igst1 = lv_tot_igst1 + ( ( w_item-item_assessableamount + w_item-item_freight + w_item-item_fert_oth ) * w_item-item_igstrate / 100 ) .
*  "lv_tot_cgst1 = lv_tot_cgst1 + ( ( w_item-item_assessableamount + w_item-item_freight + w_item-item_fert_oth ) * w_item-item_cgstrate / 100 ) .
*  "lv_tot_sgst1 = lv_tot_sgst1 + ( ( w_item-item_assessableamount + w_item-item_freight + w_item-item_fert_oth ) * w_item-item_sgstrate / 100 ) .

            lv_tot_sgst1 = lv_tot_sgst1 + ( ( w_item-item_assessableamount ) * w_item-item_sgstrate / 100 ) .
            lv_tot_cgst1 = lv_tot_cgst1 + ( ( w_item-item_assessableamount ) * w_item-item_cgstrate / 100 ) .
            lv_tot_igst1 = lv_tot_igst1 + ( ( w_item-item_assessableamount ) * w_item-item_igstrate / 100 ) .

            """***Start:Preparation of customer QR Code Item Detail: TOYOTA-TKAP & TOYOTA-TIEI ***
            lv_billqty     = w_item-billingquantity.
            lv_billqty_txt = lv_billqty.
            IF ls_vcode-qr_required = 'Y'.
              lv_unit_price  = lv_item_urate.
            ELSE.
              lv_item_urate2 = lv_item_urate.
              lv_unit_price  = lv_item_urate2.
            ENDIF.
            IF ls_vcode-qr_required = 'Y'.
              lv_item_amount = w_item-item_assessableamount.
            ELSE.
              lv_item_amount = '0.00'.
            ENDIF.

            CONDENSE:
            lv_billqty_txt,
            w_item-materialbycustomer,
            w_item-hsn,
            lv_unit_price,
            lv_item_amount.

            IF ls_vcode-qr_required = 'Y'.
              lv_cust_itm = lv_cust_itm &&
                            |{ w_item-materialbycustomer },| &&
                            |{ lv_billqty_txt },| &&
                            |{ w_item-hsn }~|.
              """***End:Preparation of customer QR Code Item Detail: TOYOTA-TIEI ***
            ELSEIF ls_vcode-qr_required = 'X'.
              lv_cust_itm = lv_cust_itm &&
                            |{ w_item-materialbycustomer },| &&
                            |{ lv_unit_price },| &&
                            |{ lv_billqty_txt },| &&
                            |{ lv_item_amount },~|.
              """***End:Preparation of customer QR Code Item Detail: TOYOTA-TKAP ***
            ENDIF.

            """""""""""""""""""""""""""""""""""""""""""""""""""""EOC by neelam CP/2025/CUST-128/1236
            IF iv_action = 'oeminv' or  iv_action = 'taxinv'.
              IF ls_vcode-qr_required = 'T' .
                lv_cust_qr = |{ w_final-documentreferenceid },| &&     "*Invoice_Number
                |{ w_item-billingquantity },~|.                                        "*Total Qty

                lv_cust_qr = lv_cust_qr && lv_cust_itm.
                REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_cust_qr WITH space.

              ENDIF.
            ENDIF.
            """""""""""""""""""""""""""""""""""""""""""""""""""""EOC by neelam CP/2025/CUST-128/1236
            CLEAR : w_item.
          ENDLOOP .

        ENDIF .

        IF w_final-distributionchannel = '30' .

          lv_other_chrg  = lv_other_chrg * w_final-accountingexchangerate .
          sum_other_chrg = sum_other_chrg * w_final-accountingexchangerate .

          ""lv_tot_igst1 = ( lv_tax_amt + lv_other_chrg ) * w_item-item_igstrate / 100  .

          "" lv_tot_igst  = lv_tot_igst * w_final-AccountingExchangeRate .

          lv_grand_tot =  lv_tax_amt + lv_tot_sgst + lv_tot_cgst + lv_tot_igst1
                          + lv_other_chrg  + lv_round_off + sum_other_chrg + ( lv_dis * -1 )." + lv_tot_amort.  "" + lv_tcs

          lv_tot_gst = lv_tot_sgst + lv_tot_cgst + lv_tot_igst1 .
        ELSE .

          lv_other_chrg  = lv_other_chrg * w_final-accountingexchangerate.
          sum_other_chrg = sum_other_chrg * w_final-accountingexchangerate.

          "       lv_tot_igst1 = ( lv_tax_amt + lv_other_chrg ) * w_item-item_igstrate / 100  .
          "       lv_tot_cgst1 = ( lv_tax_amt + lv_other_chrg ) * w_item-item_cgstrate / 100  .
          "       lv_tot_sgst1 = ( lv_tax_amt + lv_other_chrg ) * w_item-item_sgstrate / 100  .
          "" lv_tot_igst  = lv_tot_igst * w_final-AccountingExchangeRate .

          lv_grand_tot =  lv_tax_amt + lv_tot_sgst1 + lv_tot_cgst1 + lv_tot_igst1
                          + lv_other_chrg  + lv_round_off  + lv_tcs + sum_other_chrg + lv_tot_pkgchrg." + lv_tot_amort.

          lv_tot_gst = lv_tot_sgst1 + lv_tot_cgst1 + lv_tot_igst1 .

        ENDIF .

        IF w_final-customerpricegroup EQ 'C1'.
          CLEAR lv_grand_tot.
          lv_grand_tot = lv_tot_sgst1 + lv_tot_cgst1 + lv_tot_igst1.
        ENDIF.

        DATA : lv_grand_tot_word TYPE string,
               lv_gst_tot_word   TYPE string.
*   gst_tot_amt_words TYPE string,
*   grand_tot_amt_words TYPE string.

        lv_grand_tot_word = lv_grand_tot .
        lv_gst_tot_word = lv_tot_gst .

        lo_amt_words->number_to_words(
         EXPORTING
           iv_num   = lv_grand_tot_word
         RECEIVING
           rv_words = DATA(grand_tot_amt_words)
       ).
        CONDENSE grand_tot_amt_words.
        grand_tot_amt_words = |{ grand_tot_amt_words } Only| ##NO_TEXT.

        lo_amt_words->number_to_words(
          EXPORTING
            iv_num   = lv_gst_tot_word
          RECEIVING
            rv_words = DATA(gst_tot_amt_words)
        ).
        CONDENSE gst_tot_amt_words.
        gst_tot_amt_words = |{ gst_tot_amt_words } Only| ##NO_TEXT.

        IF iv_action = 'dchlpr' .
          IF w_final-billingdocumenttype = 'F8'.

            lv_certify_1 = 'It is Certified that the particulars given above are true and correct and'
                        && 'amount indicated represents the price actually changed and that there'
                        && 'is no flow of additional consideration directly or indirectly from the buyer' ##NO_TEXT.

          ELSEIF w_final-billingdocumenttype = 'JSN'.

            lv_certify_1 = 'Tax is payable under reverse charge: Yes / No' ##NO_TEXT.
            lv_certify_2 = 'For JOB WORK / RETURNABLE MATERIAL DELIVERY CHALLAN, THE MATERIAL MUST BE SENT BACK'
                        && 'WITHIN 1 YEAR FOR CAPITAL GOODS LIKE FIXTURES, THE GOODS MUST BE SENT BACK WITHIN 3 YEAR' ##NO_TEXT.

          ENDIF.
        ENDIF.

*    SELECT SINGLE
*    billingdocument,
*    yy1_gr_no_bdh,
*    yy1_gr_date_bdh,
*    yy1_exiseno_bdh,
*    yy1_exisedate_bdh,
*    yy1_vehical_no_bdh
*    FROM i_billingdocumentbasic
*    WHERE billingdocument = @w_final-billingdocument
*    INTO @DATA(ls_bill_doc).

        lv_certify_1 = 'Delivery: As per Tender Terms and Conditions.' ##NO_TEXT.
        lv_certify_2 = 'Payment will be accepted through NEFT/RTGS in the following Bank' ##NO_TEXT.
        lv_certify_3 = 'Account Beneficiary Name: DE Diamond Electric India Pvt. Ltd Bank  Name: INDIAN BANK,'
                        && 'IFSC Code: IDIB000H517     Account No: 7363402673' ##NO_TEXT.
        lv_certify_4 = ''.
        lv_certify_5 = ''.
        insur_policy_no     = '2345678900987654' ##NO_TEXT.
        insur_policy_date   = '18.06.2024' ##NO_TEXT.
        lv_tin_no           = ''.
        lv_tin_date         = ''.
        lv_fssai_lic_no     = ''.
*    lv_excise_pass_no   = ls_bill_doc-yy1_exiseno_bdh.
*    lv_excise_pass_date = ls_bill_doc-yy1_exisedate_bdh.
*    lv_bl_no            = ''.
*    lv_gr_no            = ls_bill_doc-yy1_gr_no_bdh.
*    lv_gr_date          = ls_bill_doc-yy1_gr_date_bdh.

        IF w_final-distributionchannel = '10' OR w_final-distributionchannel = '20'.
          lv_excise_no_h  = 'Excise Pass No:' ##NO_TEXT.
          lv_excise_dt_h  = 'Excise Pass Date:' ##NO_TEXT.
          lv_blno_h       = ''. "'KL:'.
          lv_pur_odr_h    = 'Tendor / Permit No.:' ##NO_TEXT.
          lv_pur_dt_h     = 'Tendor / Permit Date:' ##NO_TEXT.
        ELSE.
          lv_pur_odr_h    = 'Purchase Order No.:' ##NO_TEXT.
          lv_pur_dt_h     = 'Purchase Order Date:' ##NO_TEXT.
          CLEAR: lv_excise_pass_no, lv_excise_pass_date, lv_bl_no.
        ENDIF.

        lv_regd_adrs_1 = 'Plot No- 38, Sector-5, HSIIDC Growth Centre, Phase-II, Bawal, Distt: Rewari, Haryana 123051' ##NO_TEXT.

        """***Start:Preparation of customer QR Code: TOYOTA-TKAP & TOYOTA-TIEI ***
        DATA: lv_grand_tot_txt TYPE c LENGTH 20,
              lv_tot_tax_txt   TYPE c LENGTH 20,
              lv_tot_igst_txt  TYPE c LENGTH 20,
              lv_tot_cgst_txt  TYPE c LENGTH 20,
              lv_tot_sgst_txt  TYPE c LENGTH 20,
              lv_tot_ugst_txt  TYPE c LENGTH 20,
              lv_tot_cess_txt  TYPE c LENGTH 20,
              lv_label_num_txt TYPE c LENGTH 60,
              lv_gst_num       TYPE string.

        lv_grand_tot_txt = lv_grand_tot.
        lv_tot_tax_txt   = lv_tax_amt.

        IF lv_tot_igst1 IS NOT INITIAL.
          lv_tot_igst_txt  = lv_tot_igst1.
        ELSE.
          IF ls_vcode-qr_required = 'X'.
            lv_tot_igst_txt  = '0.00'.
          ELSE.
            lv_tot_igst_txt  = '0'.
          ENDIF.

        ENDIF.

        IF lv_tot_sgst1 IS NOT INITIAL.
          lv_tot_sgst_txt  = lv_tot_sgst1.
        ELSE.
          IF ls_vcode-qr_required = 'X'.
            lv_tot_sgst_txt  = '0.00'.
          ELSE.
            lv_tot_sgst_txt  = '0'.
          ENDIF.
        ENDIF.

        IF lv_tot_cgst1 IS NOT INITIAL.
          lv_tot_cgst_txt  = lv_tot_cgst1.
        ELSE.
          IF ls_vcode-qr_required = 'X'.
            lv_tot_cgst_txt  = '0.00'.
          ELSE.
            lv_tot_cgst_txt  = '0'.
          ENDIF.
        ENDIF.

        IF ls_vcode-qr_required = 'X'.
          lv_tot_ugst_txt  = '0.00'.
          lv_tot_cess_txt  = '0.00'.
        ELSE.
          lv_tot_ugst_txt  = '0'.
          lv_tot_cess_txt  = '0'.
        ENDIF.
        lv_label_num_txt = '1/1'.

        lv_gst_num    = w_final-plant_gstin.

        CONDENSE:
        lv_grand_tot_txt,
        lv_tot_igst_txt,
        lv_tot_sgst_txt,
        lv_tot_cgst_txt,
        lv_tot_ugst_txt,
        lv_tot_cess_txt,
        lv_gst_num,
        lv_tot_tax_txt,
        order_num_qr.

        IF ls_vcode-qr_required = 'X'.
          lv_dt_bill_tkap = w_final-billingdocumentdate+6(2) &&
                            w_final-billingdocumentdate+4(2) &&
                            w_final-billingdocumentdate+0(4).
        ELSE.
          lv_dt_bill_qr = w_final-billingdocumentdate+6(2) &&
                          w_final-billingdocumentdate+4(2) &&
                          w_final-billingdocumentdate+2(2).
        ENDIF.

        IF ls_vcode-qr_required = 'Y'.
*         lv_cust_qr = |{ w_final-purchaseorderbycustomer },| && "*Order_Number
          lv_cust_qr = |{ order_num_qr },| && "*Order_Number
                       |{ w_final-billingdocument },| &&         "*Invoice_Number
                       |{ lv_dt_bill_qr },| &&                   "*Invoice_Date
                       |{ lv_grand_tot_txt },| &&                "*Total_Invoice_Amount(Incl taxes)
                       |{ lv_tot_cgst_txt },| &&                 "*Central_GST
                       |{ lv_tot_sgst_txt },| &&                 "*State_GST
                       |{ lv_tot_igst_txt },| &&                 "*Intergated_GST
                       |{ lv_tot_ugst_txt },| &&                 "*UT_GST
                       |{ lv_tot_cess_txt },| &&                 "*Cess
                       |{ lv_label_num_txt }~|.                  "*Label_Number/Total No. of Labels~Part_Number

          lv_cust_qr = lv_cust_qr && lv_cust_itm.

        ELSEIF ls_vcode-qr_required = 'X'.
          lv_cust_qr = |{ w_final-purchaseorderbycustomer },| && "*Order_Number
          |{ lv_gst_num },| &&                      "*GST Number
          |{ w_final-billingdocument },| &&         "*Invoice_Number
          |{ lv_dt_bill_tkap },| &&                 "*Invoice_Date
          |{ lv_tot_tax_txt },| &&                  "*Total_Taxable_Amount
          |{ lv_tot_cgst_txt },| &&                 "*Central_GST
          |{ lv_tot_sgst_txt },| &&                 "*State_GST
          |{ lv_tot_igst_txt },| &&                 "*Intergated_GST
          |{ lv_tot_ugst_txt },| &&                 "*UT_GST
          |{ lv_tot_cess_txt },| &&                 "*Cess
          |{ lv_grand_tot_txt },~|.                 "*Total_Invoice_Amount(Incl taxes)

          lv_cust_qr = lv_cust_qr && lv_cust_itm.

        ENDIF.

        """***End:Preparation of customer QR Code*********************************

        lv_xml = |{ lv_xml }{ lv_item }| &&
                           |</ItemData>| &&
                        |<cust_qrcode>{ lv_cust_qr }</cust_qrcode>| &&
                        |<total_amount_words>(INR) { grand_tot_amt_words }</total_amount_words>| &&
                        |<gst_amt_words>(INR) { gst_tot_amt_words }</gst_amt_words>| &&
                        |<remark_if_any>{ lv_remarks }</remark_if_any>| &&
                        |<no_of_package>{ lv_no_pck }</no_of_package>| &&
                        |<total_Weight>{ lv_qty }</total_Weight>| &&
                        |<gross_Weight>{ lv_gross }</gross_Weight>| &&
                        |<net_Weight>{ lv_net }</net_Weight>| &&
                        |<tot_qty>{ lv_qty }</tot_qty>| &&  """ line item total quantity
                        |<total_amount>{ lv_tot_amt }</total_amount>| &&
                        |<total_discount>{ lv_dis }</total_discount>| &&
                        |<total_taxable_value>{ lv_tax_amt }</total_taxable_value>| &&
                        |<total_taxable_value1>{ lv_tax_amt1 }</total_taxable_value1>| &&
                        |<total_cgst>{ lv_tot_cgst }</total_cgst>| &&
                        |<total_sgst>{ lv_tot_sgst }</total_sgst>| &&
                        |<total_igst>{ lv_tot_igst }</total_igst>| &&
                        |<total_igst1>{ lv_tot_igst1 }</total_igst1>| &&  """ printing in total
                        |<total_sgst1>{ lv_tot_sgst1 }</total_sgst1>| &&  """ printing in total
                        |<total_cgst1>{ lv_tot_cgst1 }</total_cgst1>| &&  """ printing in total
                        |<total_amort>{ lv_tot_amort }</total_amort>| &&
                        |<sum_packing_chrg>{ lv_tot_pkgchrg }</sum_packing_chrg>| &&
                        |<total_tcs>{ lv_tcs }</total_tcs>| &&
                        |<total_other_chrg>{ lv_other_chrg }</total_other_chrg>| &&
                        |<sum_other_chrg>{ sum_other_chrg }</sum_other_chrg>| &&
                        |<round_off>{ lv_round_off }</round_off>| &&
                        |<grand_total>{ lv_grand_tot }</grand_total>| &&
                        |<total_amt_expcurr>{ lv_amt_expcurr }</total_amt_expcurr>| &&
                        |<certify_1>{ lv_certify_1 }</certify_1>| &&
                        |<certify_2>{ lv_certify_2 }</certify_2>| &&
                        |<certify_3>{ lv_certify_3 }</certify_3>| &&
                        |<certify_4>{ lv_certify_4 }</certify_4>| &&
                        |<certify_5>{ lv_certify_5 }</certify_5>| &&
                        |<insur_policy_no>{ insur_policy_no }</insur_policy_no>| &&
                        |<insur_policy_date>{ insur_policy_date }</insur_policy_date>| &&
                        |<tin_no>{ lv_tin_no }</tin_no>| &&
                        |<tin_date>{ lv_tin_date }</tin_date>| &&
                        |<fssai_lic_no>{ lv_fssai_lic_no }</fssai_lic_no>| &&
                        |<excise_pass_no>{ lv_excise_pass_no }</excise_pass_no>| &&
                        |<excise_pass_date>{ lv_excise_pass_date }</excise_pass_date>| &&
                        |<bl_no>{ lv_bl_no }</bl_no>| &&
                        |<lv_excise_no_h>{ lv_excise_no_h }</lv_excise_no_h>| &&
                        |<lv_excise_dt_h>{ lv_excise_dt_h }</lv_excise_dt_h>| &&
                        |<lv_blno_h>{ lv_blno_h }</lv_blno_h>| &&
                        |<lv_pur_odr_h>{ lv_pur_odr_h }</lv_pur_odr_h>| &&
                        |<lv_pur_dt_h>{ lv_pur_dt_h }</lv_pur_dt_h>| &&
                        |<gr_number>{ lv_gr_no }</gr_number>| &&
                        |<gr_date>{ lv_gr_date }</gr_date>| &&
                        |<regd_adrs_1>{ lv_regd_adrs_1 }</regd_adrs_1>| &&
                        |<regd_adrs_2>{ lv_regd_adrs_2 }</regd_adrs_2>| &&
                        |</BillingDocumentNode>|." &&
*  |</Form>|. "commented By Neelam goyal
        "BOC by Neelam goyal
        " ENDDO.


        DATA(lv_last_form) =
         |</Form>|.

        CONCATENATE lv_xml lv_last_form INTO lv_xml.

        "Eoc by neelam

        DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
        iv_xml_base64 = ls_data_xml_64.

      ENDMETHOD.


      METHOD prep_xml_tax_inv1. " "BOC by Neelam on 22.06.2025

        DATA(lv_xml) =
  |<Form>|.

        DO 4 TIMES. "added by neelam!


          DATA: lv_vbeln_n     TYPE c LENGTH 10,
                lv_qr_code     TYPE string,
                lv_cust_qr     TYPE string,
                lv_cust_itm    TYPE string,
                lv_billqty     TYPE i,
                lv_billqty_txt TYPE c LENGTH 20,
                lv_unit_price  TYPE string,
                lv_item_amount TYPE string,
                lv_irn_num     TYPE c LENGTH 64, "w_irn-irnno
                lv_ack_no      TYPE c LENGTH 20, "w_irn-ackno
                lv_ack_date    TYPE c LENGTH 10, "w_irn-ackdat
                lv_ref_sddoc   TYPE c LENGTH 20. "w_item-ReferenceSDDocument

          ""****Start:Logic to convert amount in Words************
          DATA:
            lo_amt_words TYPE REF TO zcl_amt_words.
          CREATE OBJECT lo_amt_words.
          ""****End:Logic to convert amount in Words************

          ""****Start:Logic to read text of Billing Header************
          DATA:
            lo_text TYPE REF TO zcl_read_text,
            gt_text TYPE TABLE OF zstr_billing_text.

          CREATE OBJECT lo_text.


          ""****End:Logic to read text of Billing Header************

          lv_qr_code = |This is a demo QR code. So please keep patience... And do not scan it with bar code scanner till i say to scan #sumit| ##NO_TEXT.

          READ TABLE it_final INTO DATA(w_final) INDEX 1 .
          lv_vbeln_n = w_final-billingdocument.


          lo_text->read_text_billing_header(
             EXPORTING
               iv_billnum = lv_vbeln_n
             RECEIVING
               xt_text    = gt_text "This will contain all text IDs data of given billing document
           ).

          SHIFT lv_vbeln_n LEFT DELETING LEADING '0'.

          DATA : odte_text TYPE string , """" original duplicate triplicate ....
                 tot_qty   TYPE p LENGTH 16 DECIMALS 2,
                 tot_amt   TYPE p LENGTH 16 DECIMALS 2,
                 tot_dis   TYPE p LENGTH 16 DECIMALS 2.

          REPLACE ALL OCCURRENCES OF '&' IN  w_final-re_name WITH '' .
          REPLACE ALL OCCURRENCES OF '&' IN  w_final-we_name WITH '' .

          """"""""""""""""""" for total ...
          DATA : lv_qty              TYPE i, "p LENGTH 16 DECIMALS 2,
                 lv_netwt            TYPE p LENGTH 16 DECIMALS 2,
                 lv_grosswt          TYPE p LENGTH 16 DECIMALS 2,
                 lv_dis              TYPE p LENGTH 16 DECIMALS 2,
                 lv_tot_amt          TYPE p LENGTH 16 DECIMALS 2,
                 lv_tax_amt          TYPE p LENGTH 16 DECIMALS 2,
                 lv_tax_amt1         TYPE p LENGTH 16 DECIMALS 2,
                 lv_sgst             TYPE p LENGTH 16 DECIMALS 2,
                 lv_cgst             TYPE p LENGTH 16 DECIMALS 2,
                 lv_igst             TYPE p LENGTH 16 DECIMALS 2,
                 lv_tot_sgst         TYPE p LENGTH 16 DECIMALS 2,
                 lv_tot_cgst         TYPE p LENGTH 16 DECIMALS 2,
                 lv_tot_igst         TYPE p LENGTH 16 DECIMALS 2,
                 lv_tot_igst1        TYPE p LENGTH 16 DECIMALS 2,
                 lv_tot_cgst1        TYPE p LENGTH 16 DECIMALS 2,
                 lv_tot_amort        TYPE p LENGTH 16 DECIMALS 2,
                 lv_tot_sgst1        TYPE p LENGTH 16 DECIMALS 2,
                 lv_tot_pkgchrg      TYPE p LENGTH 16 DECIMALS 2,
                 lv_tcs              TYPE p LENGTH 16 DECIMALS 2,
                 lv_other_chrg       TYPE p LENGTH 16 DECIMALS 2,
                 sum_other_chrg      TYPE p LENGTH 16 DECIMALS 2,
                 lv_round_off        TYPE p LENGTH 16 DECIMALS 2,
                 lv_tot_gst          TYPE p LENGTH 16 DECIMALS 2,
                 lv_grand_tot        TYPE p LENGTH 16 DECIMALS 2,
                 lv_item_urate       TYPE p LENGTH 16 DECIMALS 5,
                 lv_item_urate1      TYPE p LENGTH 16 DECIMALS 5,
                 lv_item_urate2      TYPE p LENGTH 16 DECIMALS 2,
                 lv_item_amtinr      TYPE p LENGTH 16 DECIMALS 2,
                 lv_item_amtexp      TYPE p LENGTH 16 DECIMALS 2,
                 lv_mrp_of_goods     TYPE p LENGTH 16 DECIMALS 2,
                 lv_amt_expcurr      TYPE p LENGTH 16 DECIMALS 2,
                 lv_net              TYPE p LENGTH 16 DECIMALS 2,
                 lv_gross            TYPE p LENGTH 16 DECIMALS 2,
                 lv_exchng_rate      TYPE p LENGTH 16 DECIMALS 2,
                 lv_item_gst_rate    TYPE p LENGTH 16 DECIMALS 2,
                 lv_certify_1        TYPE string,
                 lv_certify_2        TYPE string,
                 lv_certify_3        TYPE string,
                 lv_certify_4        TYPE string,
                 lv_certify_5        TYPE string,
                 insur_policy_no     TYPE c LENGTH 20,
                 insur_policy_date   TYPE c LENGTH 20,
                 lv_tin_no           TYPE c LENGTH 20,
                 lv_tin_date         TYPE c LENGTH 20,
                 lv_fssai_lic_no     TYPE c LENGTH 20,
                 lv_excise_pass_no   TYPE c LENGTH 20,
                 lv_excise_pass_date TYPE c LENGTH 20,
                 lv_bl_no            TYPE c LENGTH 20,
                 lv_excise_no_h      TYPE c LENGTH 40,
                 lv_excise_dt_h      TYPE c LENGTH 40,
                 lv_blno_h           TYPE c LENGTH 40,
                 lv_pur_odr_h        TYPE c LENGTH 40,
                 lv_pur_dt_h         TYPE c LENGTH 40,
                 lv_gr_no            TYPE c LENGTH 40,
                 lv_gr_date          TYPE c LENGTH 40,
                 lv_regd_adrs_1      TYPE c LENGTH 255,
                 lv_regd_adrs_2      TYPE c LENGTH 255,
                 lv_place_supply     TYPE string,
                 lv_plant_name       TYPE c LENGTH 100,
                 lv_order_num        TYPE string.

          LOOP AT it_final INTO DATA(w_sum) .
            lv_qty = lv_qty + w_sum-billingquantity .
            lv_dis = lv_dis + w_sum-item_discountamount .
            lv_tot_amt = lv_tot_amt + w_sum-item_totalamount_inr .
            lv_tax_amt = lv_tax_amt + w_sum-item_assessableamount .
            lv_tot_igst = lv_tot_igst + w_sum-item_igstamount .
            lv_tot_igst1 = lv_tot_igst1 + w_sum-item_igstamount .
            lv_tot_sgst = lv_tot_sgst + w_sum-item_sgstamount .
            lv_tot_cgst = lv_tot_cgst + w_sum-item_cgstamount .
            lv_tcs = lv_tcs + w_sum-item_othercharge .
            lv_other_chrg = lv_other_chrg + w_sum-item_freight .
            lv_round_off = lv_round_off + w_sum-item_roundoff .
*  lv_gross = lv_gross + w_sum-grossweight .
*  lv_net = lv_net + w_sum-netweight .
          ENDLOOP. .

          lv_tot_amt = lv_tot_amt - lv_other_chrg .
          lv_tax_amt = lv_tax_amt - lv_other_chrg .

          lv_grand_tot =  lv_tax_amt + lv_tot_sgst + lv_tot_cgst + lv_tot_igst
                          + lv_other_chrg + lv_tcs + lv_round_off .
          lv_tot_gst = lv_tot_sgst + lv_tot_cgst + lv_tot_igst .

          """ IF w_final-DistributionChannel = '30' .
          CLEAR : lv_qty , lv_dis , lv_tot_amt , lv_tax_amt ,lv_tot_igst , lv_tot_igst1 ,lv_tot_gst ,
           lv_tcs , lv_other_chrg , lv_round_off ,  lv_tot_amt ,lv_tax_amt ,lv_grand_tot , lv_tot_sgst , lv_tot_cgst.
          "" ENDIF .

          """""""""""""""""""""

*    IF w_final-re_tax  = 'URP' .
*  CLEAR : w_final-re_tax .
*    ENDIF .
*    IF w_final-we_tax  = 'URP' .
*  CLEAR : w_final-we_tax .
*    ENDIF .

          DATA : lv_remarks TYPE c LENGTH 100.

          DATA : lv_gsdb TYPE c LENGTH 100 .
          DATA : lv_cus_pl TYPE c LENGTH 100 .
          DATA :  vcode TYPE c LENGTH 100 .
          DATA : lv_vehicle TYPE c LENGTH 15 .
          DATA : lv_eway TYPE c LENGTH 15,
                 lv_bags TYPE c LENGTH 15.
          DATA : lv_eway_dt TYPE c LENGTH 10,
                 lv_so_dt   TYPE c LENGTH 10.
          DATA : lv_transmode TYPE c LENGTH 10 .  """lv_exp_no
          DATA : lv_exp_no TYPE c LENGTH 100.
          DATA : lv_no_pck TYPE c LENGTH 100.
          DATA : head_lut TYPE c LENGTH 100.
          CLEAR : lv_remarks , lv_no_pck .

          READ TABLE gt_text INTO DATA(w_text) WITH KEY longtextid = 'Z001' .
          IF sy-subrc = 0 .
            lv_vehicle = w_text-longtext .
          ENDIF .

          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z002' .
          IF sy-subrc = 0 .
            lv_transmode = w_text-longtext .
          ENDIF .

          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z004' .
          IF sy-subrc = 0 .
            lv_remarks = w_text-longtext .
          ENDIF .

          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z007' .
          IF sy-subrc = 0 .
            lv_no_pck = w_text-longtext .
          ENDIF .

*    READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z011' .
*    IF sy-subrc = 0 .
*  lv_gross = w_text-longtext .
*    ENDIF .

*    READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z016' .
*    IF sy-subrc = 0 .
*  vcode = w_text-longtext .
*    ENDIF .

          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z017' .
          IF sy-subrc = 0 .
            lv_cus_pl = w_text-longtext .
          ENDIF .

          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z010' .
          IF sy-subrc = 0 .
            lv_exp_no = w_text-longtext .
          ENDIF .

          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z016'.
          IF sy-subrc = 0 .
            head_lut = w_text-longtext .
          ENDIF .

          CLEAR w_text.
          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z007'.
          IF sy-subrc = 0 .
            lv_bags = w_text-longtext .
          ENDIF .

          CLEAR w_text.
          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z011'.
          IF sy-subrc = 0 .
            lv_gross = w_text-longtext .
          ENDIF .

          CLEAR w_text.
          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z013'.
          IF sy-subrc = 0 .
            lv_net = w_text-longtext .
          ENDIF .

          CLEAR w_text.
          READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z008'.
          IF sy-subrc = 0 .
            lv_order_num = w_text-longtext .
            DATA(order_num_qr) = w_text-longtext .
          ENDIF .


          DATA: lv_so_party TYPE c LENGTH 10.
          lv_so_party = w_final-soldtoparty.
          SHIFT lv_so_party LEFT DELETING LEADING '0'.
          SELECT SINGLE customer,
                 plant,
                 vendor,
                 qr_required
                 FROM zsd_vendor_code
                 WHERE customer = @lv_so_party AND plant = @w_final-plant
                 INTO @DATA(ls_vcode).                  "#EC CI_NOORDER

          vcode = ls_vcode-vendor.

          DATA : lv_bill_adr1 TYPE c LENGTH 100.
          DATA : lv_bill_adr2 TYPE c LENGTH 100.
          DATA : lv_bill_adr3 TYPE c LENGTH 100.

          DATA : lv_shp_adr1 TYPE c LENGTH 100.
          DATA : lv_shp_adr2 TYPE c LENGTH 100.
          DATA : lv_shp_adr3 TYPE c LENGTH 100.

          """"""" bill address set """"""""
          IF w_final-re_house_no IS NOT INITIAL .
            lv_bill_adr1 = |{ w_final-re_house_no }| .
          ENDIF .

          IF w_final-re_street IS NOT INITIAL .
            IF lv_bill_adr1 IS NOT INITIAL   .
              lv_bill_adr1 = |{ lv_bill_adr1 } , { w_final-re_street }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
            ELSE .
              lv_bill_adr1 = |{ w_final-re_street }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
            ENDIF .
          ENDIF .

          IF w_final-re_street1 IS NOT INITIAL .
            IF lv_bill_adr1 IS NOT INITIAL   .
              lv_bill_adr1 = |{ lv_bill_adr1 } , { w_final-re_street1 }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
            ELSE .
              lv_bill_adr1 = |{ w_final-re_street1 }, { w_final-re_streetprefixname1 }, { w_final-re_streetprefixname2 }, { w_final-re_streetsuffixname1 }| .
            ENDIF .
          ENDIF .

          DATA(len) = strlen( lv_bill_adr1 ) .
          len = len - 40.
          IF strlen( lv_bill_adr1 ) GT 40 .
            lv_bill_adr2 = |{ lv_bill_adr1+40(len) },| .
            lv_bill_adr1 = lv_bill_adr1+0(40) .
          ENDIF .
          """""""eoc bill address set""""""""


          """"""" ship address set """"""""

          IF w_final-we_house_no IS NOT INITIAL .
            lv_shp_adr1 = |{ w_final-we_house_no }| .
          ENDIF .

          IF w_final-we_street IS NOT INITIAL .
            IF lv_shp_adr1 IS NOT INITIAL   .
              lv_shp_adr1 = |{ lv_shp_adr1 } , { w_final-we_street }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
            ELSE .
              lv_shp_adr1 = |{ w_final-we_street }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
            ENDIF .
          ENDIF .

          IF w_final-we_street1 IS NOT INITIAL .
            IF lv_shp_adr1 IS NOT INITIAL   .
              lv_shp_adr1 = |{ lv_shp_adr1 } , { w_final-we_street1 }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
            ELSE .
              lv_shp_adr1 = |{ w_final-we_street1 }, { w_final-we_streetprefixname1 }, { w_final-we_streetprefixname2 }, { w_final-we_streetsuffixname1 }| .
            ENDIF .
          ENDIF .

          len = strlen( lv_shp_adr1 ) .
          len = len - 40.
          IF strlen( lv_shp_adr1 ) GT 40 .
            lv_shp_adr2 = |{ lv_shp_adr1+40(len) },| .
            lv_shp_adr1 = lv_shp_adr1+0(40) .
          ENDIF .

          """"""" ship bill address set """"""""
          DATA : heading      TYPE c LENGTH 100,
                 sub_heading  TYPE c LENGTH 255,
                 for_sign     TYPE c LENGTH 100,
                 curr         TYPE c LENGTH 100,
                 exp_curr     TYPE c LENGTH 100,
                 exc_rt       TYPE c LENGTH 100,
                 lv_delv_term TYPE c LENGTH 100.

          DATA : lv_dt_bill      TYPE c LENGTH 10,
                 lv_dt_bill_qr   TYPE c LENGTH 6,
                 lv_dt_bill_tkap TYPE c LENGTH 8.
          DATA : lv_dt_po TYPE c LENGTH 10.
          DATA : lv_dt_ack TYPE c LENGTH 10.

          lv_exchng_rate = w_final-accountingexchangerate .

          exc_rt = lv_exchng_rate.
          SELECT SINGLE * FROM zsd_einv_data WHERE billingdocument = @w_final-billingdocument
            INTO @DATA(w_einvvoice) .                       "#EC WARNOK
          CLEAR : lv_qr_code , lv_irn_num   , lv_ack_no ,lv_ack_date .

          lv_vehicle    = w_einvvoice-vehiclenum.
          lv_transmode  = w_einvvoice-modeoftransp.
          CONDENSE w_einvvoice-modeoftransp.
          IF w_einvvoice-modeoftransp = '1'.
            lv_transmode  = 'Road' ##NO_TEXT.
          ELSEIF w_einvvoice-modeoftransp = '2'.
            lv_transmode  = 'Rail' ##NO_TEXT.
          ELSEIF w_einvvoice-modeoftransp = '3'.
            lv_transmode  = 'Air' ##NO_TEXT.
          ENDIF.
          lv_qr_code = w_einvvoice-signedqrcode .
          lv_irn_num = w_einvvoice-irn .
          lv_ack_no =  w_einvvoice-ackno .
          lv_ack_date =  w_einvvoice-ackdt .
          lv_eway     = w_einvvoice-ewbno.
          lv_eway_dt  = w_einvvoice-ewbdt+6(2) && '.' && w_einvvoice-ewbdt+4(2) && '.' &&  w_einvvoice-ewbdt+0(4). " 2024-04-27
          """sub_heading = '(Issued Under Section 31 of Central Goods & Service Tax Act 2017 and HARYANA State Goods & Service Tax Act 2017)' .
          sub_heading = '' .
          for_sign  = 'DE Diamond Electric India Pvt. Ltd.'  ##NO_TEXT.

          """""" Date conversion """"
          lv_dt_bill    = w_final-billingdocumentdate+6(2) && '/' && w_final-billingdocumentdate+4(2) && '/' && w_final-billingdocumentdate+0(4).
          lv_dt_ack   = lv_ack_date+8(2) && '/' && lv_ack_date+5(2) && '/' && lv_ack_date+0(4).
          lv_dt_po    = w_final-customerpurchaseorderdate+6(2) && '/' && w_final-customerpurchaseorderdate+4(2) && '/' && w_final-customerpurchaseorderdate+0(4).
          lv_so_dt    = w_final-salesdocumentdate+6(2) && '/' && w_final-salesdocumentdate+4(2) && '/' && w_final-salesdocumentdate+0(4).
          """""" Date Conversion """"

          IF im_prntval = 'Original' ##NO_TEXT.
            ""odte_text = |Original                                   Duplicate                                 Triplicate                                      Extra| ##NO_TEXT.
            odte_text = 'Original' ##NO_TEXT.
          ELSEIF im_prntval = 'Duplicate' ##NO_TEXT.
            odte_text = 'Duplicate' ##NO_TEXT.
          ELSEIF im_prntval = 'Triplicate' ##NO_TEXT.
            odte_text = 'Triplicate' ##NO_TEXT.
          ELSEIF im_prntval = 'Extra' ##NO_TEXT.
            odte_text = 'Extra Invoice Copy' ##NO_TEXT.
          ENDIF.

          "BOC by Neelam Goyal on 22.06.2025
          IF im_prntval = 'All'. ##NO_TEXT.
            IF sy-index = 1.
              odte_text = 'ORIGINAL FOR RECIPIENT'.
            ENDIF.
            IF sy-index = 2.
              odte_text = 'DUPLICATE FOR TRANSPORTER'.
            ENDIF.
            IF sy-index = 3.
              odte_text = 'TRIPLICATE FOR SUPPLIER'.
            ENDIF.
            IF sy-index = 4.
              odte_text = 'EXTRA COPY'.
            ENDIF.
          ENDIF.
          "EOC by Neelam Goyal on 22.06.2025

          IF iv_action = 'taxinv' .

            heading = 'EXPORT INVOICE' ##NO_TEXT.

            IF w_final-distributionchannel = '30' .
              "heading = 'EXPORT INVOICE'  .
              IF w_final-item_igstrate IS INITIAL .
                sub_heading = 'Issued Under Section 31 of Central Goods and Service Tax Act 2017 and HARYANA State Goods and Service Tax Act 2017' ##NO_TEXT.
                "*head_lut = 'Against LUT No.(ARN No. AD060323015122V DT. 29/03/23'.
              ELSE .
                sub_heading = 'Issued Under Section 31 of Central Goods and Service Tax Act 2017 and HARYANA State Goods and Service Tax Act 2017' ##NO_TEXT.
                "" head_lut = 'Against LUT No.(ARN No. AD060323015122V DT. 21/03/23'.
              ENDIF .
            ELSE .
              "heading = 'TAX INVOICE'  .
              sub_heading = 'Under Section 31 of CGST Act and SGST Act read with section 20 of IGST Act' ##NO_TEXT.
            ENDIF .

          ELSEIF iv_action = 'oeminv' .
            heading = 'TAX INVOICE'  ##NO_TEXT.
            sub_heading = 'Under section 31 of  CGST Act 2017, read with rule 46 of CGST Rules 2017.' ##NO_TEXT.

            IF w_final-billingdocumenttype = 'JSTO'.
              """"""""""""""""""" bill to party equals ship to party in challan case .
              w_final-ship_to_party = w_final-bill_to_party .
              w_final-we_name  = w_final-re_name .
              lv_shp_adr1 = lv_bill_adr1 .
              lv_shp_adr2 = lv_bill_adr2 .
              w_final-we_city  = w_final-re_city .
              w_final-we_pin = w_final-re_pin   .
              w_final-we_tax  = w_final-re_tax  .
              w_final-we_pan = w_final-re_pan  .
              w_final-we_region = w_final-re_region  .
              w_final-we_city = w_final-re_city .
              w_final-we_city = w_final-re_city  .
              w_final-we_phone4  = w_final-re_phone4  .
              w_final-we_email = w_final-re_email .
              lv_dt_po = lv_dt_bill .

            ENDIF.

          ELSEIF iv_action = 'dchlpr' ##NO_TEXT.

            heading     = 'DELIVERY CHALLAN' ##NO_TEXT.
            sub_heading = '(As per Rule 31 read with rule 46 of GST ACT,2017)' ##NO_TEXT.

            IF w_final-billingdocumenttype = 'JSN' ##NO_TEXT.
              heading     = 'JOB WORK CHALLAN' ##NO_TEXT.
              sub_heading = 'As per Rule 55(1)B of CGST Rule 2017' ##NO_TEXT.
            ENDIF.

            IF w_final-billingdocumenttype = 'JDC' OR w_final-billingdocumenttype = 'JVR' ##NO_TEXT.
              sub_heading = 'As per Rule 55(1)C of CGST Rule 2017' ##NO_TEXT.
            ENDIF.

            IF im_prntval = 'Original' ##NO_TEXT.
              "*odte_text = |Original                                   Duplicate                                 Triplicate                                      Extra| ##NO_TEXT.
              odte_text = 'Original' ##NO_TEXT.
            ELSEIF im_prntval = 'Duplicate' ##NO_TEXT.
              odte_text = 'Duplicate Challan' ##NO_TEXT.
            ELSEIF im_prntval = 'Triplicate' ##NO_TEXT.
              odte_text = 'Triplicate Challan' ##NO_TEXT.
            ELSEIF im_prntval = 'Extra' ##NO_TEXT.
              odte_text = 'Extra Challan Copy' ##NO_TEXT.
            ENDIF.

            CLEAR : exc_rt .  """" will add read text of nature of work ...
            READ TABLE gt_text INTO w_text WITH KEY longtextid = 'Z018' .
            IF sy-subrc = 0 .
              exc_rt = w_text-longtext .
            ENDIF .
            """"""""""""""""""" bill to party equals ship to party in challan case .
            IF w_final-billingdocumenttype = 'JVR' OR
               w_final-billingdocumenttype = 'JSN' OR
               w_final-billingdocumenttype = 'JDC'.

              w_final-ship_to_party   = w_final-bill_to_party .
              w_final-we_name         = w_final-re_name .
              lv_shp_adr1             = lv_bill_adr1 .
              lv_shp_adr2             = lv_bill_adr2 .
              w_final-we_city         = w_final-re_city .
              w_final-we_pin          = w_final-re_pin   .
              w_final-we_tax          = w_final-re_tax  .
              w_final-we_pan          = w_final-re_pan  .
              w_final-we_region       = w_final-re_region  .
              w_final-we_city         = w_final-re_city .
              w_final-we_city         = w_final-re_city  .
              w_final-we_phone4       = w_final-re_phone4  .
              w_final-we_email        = w_final-re_email .
              lv_dt_po                = lv_dt_bill .

              """"""""""""""""""" bill to party equals ship to party in challan case .
              SELECT SINGLE
              supplier,
              suppliername,
              suplrmanufacturerexternalname
              FROM i_supplier WHERE supplier = @w_final-bill_to_party
              INTO @DATA(ls_lfa1).

              IF ls_lfa1-suplrmanufacturerexternalname IS INITIAL.

              ELSE.

                CLEAR:
                lv_bill_adr1,
                lv_bill_adr2,
                w_final-bill_to_party,
                w_final-re_name,
                w_final-re_city,
                w_final-re_pin,
                w_final-re_tax,
                w_final-re_pan,
                w_final-re_region ,
                w_final-re_city ,
                w_final-re_phone4,
                w_final-re_email.

                SELECT SINGLE * FROM zi_supplier_address
                WHERE supplier = @ls_lfa1-suplrmanufacturerexternalname
                INTO @DATA(ls_suplr_adrs).

                w_final-bill_to_party = ls_suplr_adrs-supplier.
                w_final-re_name       = ls_suplr_adrs-suppliername.

                IF ls_suplr_adrs-housenumber IS NOT INITIAL .
                  lv_bill_adr1 = |{ ls_suplr_adrs-housenumber }| .
                ENDIF .

                IF ls_suplr_adrs-streetname IS NOT INITIAL .
                  IF lv_bill_adr1 IS NOT INITIAL   .
                    lv_bill_adr1 = |{ lv_bill_adr1 } , { ls_suplr_adrs-streetname }, { ls_suplr_adrs-streetprefixname1 }, { ls_suplr_adrs-streetprefixname2 }, { ls_suplr_adrs-streetsuffixname1 }| .
                  ELSE .
                    lv_bill_adr1 = |{ ls_suplr_adrs-streetname }, { ls_suplr_adrs-streetprefixname1 }, { ls_suplr_adrs-streetprefixname2 }, { ls_suplr_adrs-streetsuffixname1 }| .
                  ENDIF .
                ENDIF .

                len = strlen( lv_bill_adr1 ) .
                len = len - 40.
                IF strlen( lv_bill_adr1 ) GT 40 .
                  lv_bill_adr2 = |{ lv_bill_adr1+40(len) },| .
                  lv_bill_adr1 = lv_bill_adr1+0(40) .
                ENDIF .

                w_final-re_city        = ls_suplr_adrs-cityname.
                w_final-re_pin         = ls_suplr_adrs-postalcode.
                w_final-re_tax         = ls_suplr_adrs-taxnumber3.
                w_final-re_pan         = ls_suplr_adrs-taxnumber3.
                w_final-re_region      = ls_suplr_adrs-region.
                w_final-re_city        = ls_suplr_adrs-cityname.
                w_final-re_phone4      = ls_suplr_adrs-phonenumber1.
                w_final-re_email       = ls_suplr_adrs-emailaddress.


              ENDIF.

            ENDIF.

          ELSEIF iv_action = 'dcnote' ##NO_TEXT.
            IF w_final-billingdocumenttype = 'G2' OR w_final-billingdocumenttype = 'CBRE'.
              heading = 'CREDIT NOTE' ##NO_TEXT.
              sub_heading = '(Section 34 (2) of CGST Act and Rule 53 of CGST Rules 2017)' ##NO_TEXT.
            ELSEIF w_final-billingdocumenttype = 'L2' ##NO_TEXT.
              heading = 'DEBIT NOTE' ##NO_TEXT.
              sub_heading = '(Section 34 (3) of CGST Act and Rule 53 of CGST Rules 2017)' ##NO_TEXT.
            ENDIF .

          ELSEIF iv_action = 'aftinv' ##NO_TEXT.
            heading = 'TAX INVOICE'. ##NO_TEXT.
            sub_heading = 'Issued Under Section 31 of Central Goods and Service Tax Act 2017 and HARYANA State Goods and Service Tax Act 2017' ##NO_TEXT.
          ENDIF .

          curr     = w_final-transactioncurrency .
          exp_curr = w_final-transactioncurrency.

          CONDENSE : exc_rt , curr , heading , sub_heading , head_lut , for_sign ,  lv_shp_adr1 , lv_shp_adr2, exp_curr.


          SELECT SINGLE * FROM zi_regiontext WHERE region = @w_final-region AND language = 'E' AND country = @w_final-country
             INTO @DATA(lv_st_nm).            "#EC CI_ALL_FIELDS_NEEDED

          SELECT SINGLE * FROM zi_regiontext  WHERE region = @w_final-re_region AND language = 'E' AND country = @w_final-re_country
          INTO @DATA(lv_st_name_re).          "#EC CI_ALL_FIELDS_NEEDED

          SELECT SINGLE * FROM zi_regiontext  WHERE region = @w_final-we_region AND language = 'E' AND country = @w_final-we_country
          INTO @DATA(lv_st_name_we).          "#EC CI_ALL_FIELDS_NEEDED

          SELECT SINGLE * FROM zi_countrytext  WHERE country = @w_final-country AND language = 'E'
          INTO @DATA(lv_cn_nm).               "#EC CI_ALL_FIELDS_NEEDED

          SELECT SINGLE * FROM zi_countrytext   WHERE country = @w_final-re_country AND language = 'E'
          INTO @DATA(lv_cn_name_re).          "#EC CI_ALL_FIELDS_NEEDED

          SELECT SINGLE * FROM zi_countrytext   WHERE country = @w_final-we_country AND language = 'E'
          INTO @DATA(lv_cn_name_we).          "#EC CI_ALL_FIELDS_NEEDED

          IF iv_action = 'dchlpr' .
            w_final-purchaseorderbycustomer = w_final-purchaseorder .
          ENDIF.

          DATA:
            lv_plant_addrs1 TYPE string,
            lv_plant_addrs2 TYPE string,
            lv_plant_addrs3 TYPE string,
            lv_plant_cin    TYPE string,
            lv_plant_pan    TYPE string.

          SELECT SINGLE * FROM zi_plant_address
                          WHERE plant = @w_final-plant
                          INTO @DATA(ls_plant_adrs).

          lv_plant_addrs1 = ls_plant_adrs-streetname.
          lv_plant_addrs2 = |{ ls_plant_adrs-cityname } - { ls_plant_adrs-postalcode }, { ls_plant_adrs-regionname } - { ls_plant_adrs-addresstimezone }|.
*    lv_plant_addrs3 = |{ ls_plant_adrs-regionname } - { ls_plant_adrs-addresstimezone }|.

          lv_delv_term = |{ w_final-incotermsclassification } ({ w_final-incotermslocation1 })|.

          lv_plant_cin = 'U31908HR2007FTC039788' ##NO_TEXT.
          lv_plant_pan = w_final-plant_gstin+2(10).
          "*w_final-plantname = 'DE DIAMOND ELECTRIC INDIA PVT. LTD.' ##NO_TEXT.
          lv_plant_name     = 'DE DIAMOND ELECTRIC INDIA PVT. LTD.' ##NO_TEXT.
          w_final-phoneareacodesubscribernumber = '9053029817'.
          lv_place_supply = w_final-we_city && '-' && lv_st_name_we-regionname. "lv_cn_name_we-CountryName.
          REPLACE ALL OCCURRENCES OF '&' IN lv_bill_adr1 WITH ''.
          REPLACE ALL OCCURRENCES OF '&' IN lv_shp_adr1 WITH ''.

          IF w_final-distributionchannel = '30' OR w_final-distributionchannel = '40'.
            head_lut = |LUT No: { head_lut }| ##NO_TEXT.
          ELSE.
            CLEAR: head_lut.
          ENDIF.

          IF w_final-billingdocumenttype = 'JDC' OR
             w_final-billingdocumenttype = 'JSN' OR
             w_final-billingdocumenttype = 'JVR'.

            w_final-purchaseorderbycustomer = w_final-purchaseorder.

          ENDIF.

          REPLACE ALL OCCURRENCES OF '&' IN w_final-purchaseorderbycustomer WITH 'and'.
          REPLACE ALL OCCURRENCES OF '&' IN lv_bill_adr2 WITH 'and'.
          REPLACE ALL OCCURRENCES OF '&' IN lv_shp_adr2 WITH 'and'.

          " DATA(lv_xml) = |<Form>| &&
          DATA(lv_xml1) = "|<Form>| &&
                 |<BillingDocumentNode>| &&
                 |<heading>{ heading }</heading>| &&
                 |<sub_heading>{ sub_heading }</sub_heading>| &&
                 |<head_lut>{ head_lut }</head_lut>| &&
                 |<for_sign>{ for_sign }</for_sign>| &&
                 |<odte_text>{ odte_text }</odte_text>| &&
                 |<doc_curr>{ curr }</doc_curr>| &&
                 |<exp_curr>{ exp_curr }</exp_curr>| &&
                 |<plant_code>{ w_final-plant }</plant_code>| &&
                 |<plant_name>{ lv_plant_name }</plant_name>| &&
                 |<plant_address_l1>{ lv_plant_addrs1 }</plant_address_l1>| &&
                 |<plant_address_l2>{ lv_plant_addrs2 }</plant_address_l2>| &&
                 |<plant_address_l3>{ lv_plant_addrs3 }</plant_address_l3>| &&
                  |<plant_cin>{ lv_plant_cin }</plant_cin>| &&
                  |<plant_gstin>{ w_final-plant_gstin }</plant_gstin>| &&
                  |<plant_pan>{ lv_plant_pan }</plant_pan>| &&
                  |<plant_state_code>{ w_final-region } ({ ls_plant_adrs-regionname })</plant_state_code>| &&
                  |<plant_state_name></plant_state_name>| &&
                  |<plant_phone>{ w_final-phoneareacodesubscribernumber }</plant_phone>| &&
                  |<plant_email>{ w_final-plant_email }</plant_email>| &&
                  |<billto_code>{ w_final-bill_to_party }</billto_code>| &&
                  |<billto_name>{ w_final-re_name }</billto_name>| &&
                  |<billto_address_l1>{ lv_bill_adr1 }</billto_address_l1>| &&
                  |<billto_address_l2>{ lv_bill_adr2 }{ w_final-re_city }</billto_address_l2>| &&
                  |<billto_address_l3>{ w_final-re_pin } ({ lv_cn_name_re-countryname })</billto_address_l3>| &&
*               |<billto_cin>{ W_FINAL-re }</billto_cin>| &&
                  |<billto_gstin>{ w_final-re_tax }</billto_gstin>| &&
                  |<billto_pan>{ w_final-re_pan }</billto_pan>| &&
                  |<billto_state_code>{ w_final-re_region } ({ lv_st_name_re-regionname })</billto_state_code>| &&
                  |<billto_state_name></billto_state_name>| &&
                  |<billto_place_suply>{ w_final-re_region }</billto_place_suply>| &&
                  |<billto_phone>{ w_final-re_phone4 }</billto_phone>| &&
                  |<billto_email>{ w_final-re_email }</billto_email>| &&

                  |<shipto_code>{ w_final-ship_to_party }</shipto_code>| &&
                  |<shipto_name>{ w_final-we_name }</shipto_name>| &&
                  |<shipto_address_l1>{ lv_shp_adr1 }</shipto_address_l1>| &&
                  |<shipto_address_l2>{ lv_shp_adr2 }{ w_final-we_city }</shipto_address_l2>| &&
                  |<shipto_address_l3>{ w_final-we_pin } ({ lv_cn_name_we-countryname })</shipto_address_l3>| &&
*               |<shipto_cin>{ W_FINAL-PlantName }</shipto_cin>| &&
                  |<shipto_gstin>{ w_final-we_tax }</shipto_gstin>| &&
                  |<shipto_pan>{ w_final-we_pan }</shipto_pan>| &&
                  |<shipto_state_code>{ w_final-we_region } ({ lv_st_name_we-regionname })</shipto_state_code>| &&
                  |<shipto_state_name>{ lv_st_name_we-regionname }</shipto_state_name>| &&
                  |<shipto_place_suply>{ lv_place_supply }</shipto_place_suply>| &&
                  |<shipto_phone>{ w_final-we_phone4 }</shipto_phone>| &&
                  |<shipto_email>{ w_final-we_email }</shipto_email>| &&

                  |<inv_no>{ w_final-documentreferenceid }  </inv_no>| &&
                  |<inv_date>{ lv_dt_bill }</inv_date>| &&
                  |<inv_ref>{ w_final-billingdocument }</inv_ref>| &&
                  |<exchange_rate>{ exc_rt }</exchange_rate>| &&
                  |<currency>{ w_final-transactioncurrency }</currency>| &&
                  |<Exp_Inv_No>{ lv_exp_no }</Exp_Inv_No>| &&       """""""
                  |<IRN_num>{ lv_irn_num }</IRN_num>| &&
                  |<IRN_ack_No>{ lv_ack_no }</IRN_ack_No>| &&
                  |<irn_ack_date>{ lv_dt_ack }</irn_ack_date>| &&
                  |<irn_doc_type></irn_doc_type>| &&     """"""
                  |<irn_category></irn_category>| &&     """"""
                  |<qrcode>{ lv_qr_code }</qrcode>| &&
                  |<vcode>{ vcode }</vcode>| &&    """"" USING ZTABLE DATA TO BE MAINTAINED ...
                  |<vplant>{ lv_cus_pl }</vplant>| &&
                  |<pur_odr_no>{ w_final-purchaseorderbycustomer }</pur_odr_no>| &&
                  |<pur_odr_date>{ lv_dt_po }</pur_odr_date>| &&
                  |<order_num>{ lv_order_num }</order_num>| &&
                  |<Pay_term>{ w_final-customerpaymenttermsname }</Pay_term>| &&  """"
                  |<Delivery_term>{ lv_delv_term }</Delivery_term>| &&  """"
                  |<Veh_no>{ lv_vehicle }</Veh_no>| &&
                  |<Trans_mode>{ lv_transmode }</Trans_mode>| &&
                  |<Ewaybill_no>{ lv_eway }</Ewaybill_no>| &&
                  |<Ewaybill_date>{ lv_eway_dt }</Ewaybill_date>| &&

                  |<material_doc>{ w_final-materialdocument }</material_doc>| &&

                  |<sale_odr_no>{ w_final-salesdocument }</sale_odr_no>| &&
                  |<sale_odr_date>{ lv_so_dt }</sale_odr_date>| &&
                  |<delivery_note_no>{ w_final-deliverydocument }</delivery_note_no>| &&
                  |<delivery_note_date>{ w_final-salesdocumentdate }</delivery_note_date>| &&
                  |<ref_doc_no>{ lv_bags }</ref_doc_no>| &&  "**Used for Total Cases/Bags/BINs:
*    |<ref_doc_date>{ lv_eway }</ref_doc_date>| &&

                 |<ItemData>| .

          CONCATENATE lv_xml lv_xml1 INTO lv_xml. " added by neelam goyal

          DATA : lv_item TYPE string .
          DATA : srn      TYPE c LENGTH 3,
                 lv_matnr TYPE c LENGTH 120.

          CLEAR : lv_item , srn .

          IF iv_action = 'dchlpr' AND w_final-billingdocumenttype = 'F2'.

            SELECT
              lips~deliverydocument,
              lips~deliverydocumentitem,
              lips~distributionchannel,
              lips~division,
              lips~material,
              lips~product,
              lips~materialbycustomer,
              lips~plant,
              lips~deliverydocumentitemcategory,
              lips~deliverydocumentitemtext,
              lips~actualdeliveryquantity,
              lips~deliveryquantityunit,
              marc~consumptiontaxctrlcode AS hsn
              FROM i_deliverydocumentitem AS lips
              INNER JOIN i_productplantbasic AS marc
              ON lips~product = marc~product AND
                 lips~plant   = marc~plant
              WHERE deliverydocument = @w_final-deliverydocument
              INTO TABLE @DATA(lt_lips).

            LOOP AT lt_lips INTO DATA(ls_lips)
                    WHERE ( deliverydocumentitemcategory = 'DLN' OR deliverydocumentitemcategory = 'CB10' ).

              lv_matnr     = ls_lips-product.
              lv_qty         = lv_qty  +  ls_lips-actualdeliveryquantity.

              srn = srn + 1.
              lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                        |<sno>{ srn }</sno>| &&
                        |<item_code>{ lv_matnr }</item_code>| &&
                        |<item_cust_refno>{ lv_ref_sddoc }</item_cust_refno>| &&
                        |<item_desc>{ ls_lips-deliverydocumentitemtext }</item_desc>| &&
                                                                    |<item_hsn_code>{ ls_lips-hsn }</item_hsn_code>| &&
*              |<mrp_of_goods>{ lv_mrp_of_goods }</mrp_of_goods>| &&
                                                                    |<item_uom>{ ls_lips-deliveryquantityunit }</item_uom>| &&
                                                                    |<item_qty>{ ls_lips-actualdeliveryquantity }</item_qty>| &&
*              |<item_unit_rate>{ lv_item_urate }</item_unit_rate>| &&
*              |<item_amt_inr>{ lv_item_amtinr }</item_amt_inr>| &&
*              |<item_amt_expcurr>{ lv_item_amtexp }</item_amt_expcurr>| &&
*              |<item_discount>{ w_item-item_discountamount }</item_discount>| &&
*              |<item_taxable_amt>{ w_item-item_assessableamount }</item_taxable_amt>| &&
*              |<item_sgst_rate>{ w_item-item_sgstrate }</item_sgst_rate>| &&
*              |<item_sgst_amt>{ w_item-item_sgstamount }</item_sgst_amt>| &&
*              |<item_cgst_amt>{ w_item-item_cgstamount }</item_cgst_amt>| &&
*              |<item_cgst_rate>{ w_item-item_cgstrate }</item_cgst_rate>| &&
*              |<item_igst_amt>{ w_item-item_igstamount }</item_igst_amt>| &&
*              |<item_igst_rate>{ w_item-item_igstrate }</item_igst_rate>| &&
*              |<item_amort_amt>{ w_item-item_amotization }</item_amort_amt>| &&
*              |<item_gst_rate>{ lv_item_gst_rate }</item_gst_rate>| &&

                            |</ItemDataNode>|.

              CLEAR: ls_lips.
            ENDLOOP.


          ELSE.


            LOOP AT it_final INTO DATA(w_item) .
              srn = srn + 1 .

              IF iv_action = 'oeminv' AND w_final-billingdocumenttype = 'JSTO'.  ""IV_ACTION
                w_item-item_unitprice  = w_item-item_pcip_amt.
                w_item-item_totalamount_inr = w_item-item_pcip_amt * w_item-billingquantity.
              ENDIF.

              IF iv_action = 'dchlpr'
              AND ( w_final-billingdocumenttype = 'JVR' OR w_final-billingdocumenttype = 'JSN' OR w_final-billingdocumenttype = 'JDC' ).

                IF w_item-item_pcip_amt IS NOT INITIAL.

                  w_item-item_unitprice  = w_item-item_pcip_amt.

                ELSE.

                  w_item-item_unitprice  = w_item-item_unitprice.

                ENDIF.

                w_item-item_totalamount_inr = w_item-item_pcip_amt * w_item-billingquantity.

              ENDIF.

              IF w_item-conditionquantity IS NOT INITIAL .
                lv_item_urate = w_item-item_unitprice / w_item-conditionquantity.
                lv_item_urate1 = lv_item_urate.
                lv_item_urate  = lv_item_urate * w_item-accountingexchangerate.
                IF w_item-transactioncurrency EQ 'JPY'.
                  lv_item_urate = lv_item_urate / w_item-conditionquantity.
                ENDIF.
                lv_item_amtinr = w_item-billingquantity * lv_item_urate.
                lv_item_amtexp = lv_item_urate * w_item-billingquantity.
              ELSE.
                lv_item_urate  = w_item-item_unitprice * w_item-accountingexchangerate.
                lv_item_urate1 = lv_item_urate.
                lv_item_amtinr = w_item-item_totalamount_inr.
                lv_item_amtexp = w_item-item_unitprice * w_item-billingquantity.
              ENDIF.

              w_item-item_amotization = w_item-item_amotization  *   w_final-accountingexchangerate  .
              w_item-item_totalamount_inr = w_item-billingquantity * lv_item_urate .
              w_item-item_discountamount = w_item-item_discountamount *   w_final-accountingexchangerate  .
              w_item-item_assessableamount = w_item-item_totalamount_inr -  w_item-item_discountamount.

              w_item-item_assessableamount = w_item-item_assessableamount +
                                             w_item-item_fert_oth +
                                             w_item-item_freight +
*   w_item-item_othercharge +
                                             w_item-item_pkg_chrg +
                                             w_item-item_amotization.


              lv_qty         = lv_qty  +   w_item-billingquantity .
              lv_dis         = lv_dis + w_item-item_discountamount .
              lv_tcs         = lv_tcs +  w_item-item_othercharge .

              IF ( w_final-distributionchannel = '10' OR w_final-distributionchannel = '20' ).

                lv_other_chrg  = lv_other_chrg + w_item-item_freight_zfrg .

              ELSE.

                lv_other_chrg  = lv_other_chrg + w_item-item_freight_zfrt.

              ENDIF.


              lv_round_off   = lv_round_off +  w_item-item_roundoff .
              sum_other_chrg = sum_other_chrg + w_item-item_fert_oth.
              """"       ENDIF

              DATA : lv_item_text TYPE string .
              CLEAR : lv_item_text .

              IF w_item-materialdescriptionbycustomer IS INITIAL.
                lv_item_text = w_item-billingdocumentitemtext.
              ELSE.
                lv_item_text = w_item-materialdescriptionbycustomer.
              ENDIF.
              lv_item_text = |{ w_item-billingdocumentitemtext } - { w_item-materialbycustomer }|.

              SELECT SINGLE
              salesdocument,
              salesdocumentitem,
              materialbycustomer
              FROM i_salesdocumentitem
              WHERE salesdocument = @w_item-salesdocument AND salesdocumentitem = @w_item-salesdocumentitem
              INTO @DATA(ls_sale_doc).

              IF ls_sale_doc-materialbycustomer IS NOT INITIAL.
                w_item-materialbycustomer = ls_sale_doc-materialbycustomer.
              ENDIF.

              lv_matnr = w_item-product.

*         w_item-MaterialByCustomer IS NOT INITIAL. "w_item-ProductOldID IS NOT INITIAL.
*            lv_matnr = w_item-MaterialByCustomer.       "w_item-ProductOldID.
*          ELSE.
*            lv_matnr = w_item-product.
*          ENDIF.

              lv_ref_sddoc = w_item-materialbycustomer.

              REPLACE ALL OCCURRENCES OF '&' IN lv_item_text WITH '' .
              REPLACE ALL OCCURRENCES OF '&' IN lv_ref_sddoc WITH '' .

              CLEAR : w_item-item_sgstamount, w_item-item_cgstamount, w_item-item_igstamount.
              w_item-item_sgstamount = w_item-item_assessableamount  *     w_item-item_cgstrate / 100  .
              w_item-item_cgstamount = w_item-item_assessableamount  *    w_item-item_cgstrate / 100    .
              w_item-item_igstamount = w_item-item_assessableamount  *   w_item-item_igstrate / 100   .

              lv_tot_cgst    = lv_tot_cgst  + w_item-item_cgstamount .
              lv_tot_sgst    = lv_tot_sgst  + w_item-item_sgstamount .
              lv_tot_igst    = lv_tot_igst  + w_item-item_igstamount .

              lv_amt_expcurr  = lv_amt_expcurr + lv_item_amtexp.
              lv_mrp_of_goods = w_item-item_zmrp_amount.
              lv_tot_amt      = lv_tot_amt +   lv_item_amtinr. "w_item-item_totalamount_inr .
*            lv_tot_igst     = lv_tot_igst  + w_item-item_igstamount .

              IF w_item-billingquantityunit EQ 'ST'.
                w_item-billingquantityunit = 'NOS'.
              ENDIF.

              lv_item_gst_rate = w_item-item_sgstrate + w_item-item_cgstrate + w_item-item_igstrate.

              REPLACE ALL OCCURRENCES OF '&' IN lv_item_text WITH 'and'.
              REPLACE ALL OCCURRENCES OF '×' IN lv_item_text WITH ''.
              REPLACE ALL OCCURRENCES OF '±' IN lv_item_text WITH ''.
              REPLACE ALL OCCURRENCES OF '#' IN lv_item_text WITH ''.
              REPLACE ALL OCCURRENCES OF '&' IN w_item-purchaseorderbycustomer WITH 'and'.
              REPLACE ALL OCCURRENCES OF '&' IN w_item-materialbycustomer WITH 'and'.

              lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                        |<sno>{ srn }</sno>| &&
                        |<item_code>{ lv_matnr }</item_code>| &&
                        |<item_cust_refno>{ lv_ref_sddoc }</item_cust_refno>| &&
                        |<item_desc>{ lv_item_text }</item_desc>| &&
                        |<cust_code>{ w_item-materialbycustomer }</cust_code>| &&
                        |<po_number>{ w_item-purchaseorderbycustomer }</po_number>| &&
                        |<item_hsn_code>{ w_item-hsn }</item_hsn_code>| &&
                        |<mrp_of_goods>{ lv_mrp_of_goods }</mrp_of_goods>| &&
                        |<item_uom>{ w_item-billingquantityunit }</item_uom>| &&
                        |<item_qty>{ w_item-billingquantity }</item_qty>| &&
                        |<item_unit_rate>{ lv_item_urate }</item_unit_rate>| &&
                        |<item_unit_rate1>{ lv_item_urate1 }</item_unit_rate1>| &&
                        |<item_amt_inr>{ lv_item_amtinr }</item_amt_inr>| &&
                        |<item_amt_expcurr>{ lv_item_amtexp }</item_amt_expcurr>| &&
                        |<item_discount>{ w_item-item_discountamount }</item_discount>| &&
                        |<item_taxable_amt>{ w_item-item_assessableamount }</item_taxable_amt>| &&
                        |<item_sgst_rate>{ w_item-item_sgstrate }</item_sgst_rate>| &&
                        |<item_sgst_amt>{ w_item-item_sgstamount }</item_sgst_amt>| &&
                        |<item_cgst_amt>{ w_item-item_cgstamount }</item_cgst_amt>| &&
                        |<item_cgst_rate>{ w_item-item_cgstrate }</item_cgst_rate>| &&
                        |<item_igst_amt>{ w_item-item_igstamount }</item_igst_amt>| &&
                        |<item_igst_rate>{ w_item-item_igstrate }</item_igst_rate>| &&
                        |<item_amort_amt>{ w_item-item_amotization }</item_amort_amt>| &&
                        |<item_gst_rate>{ lv_item_gst_rate }</item_gst_rate>| &&

                        |</ItemDataNode>|  .

              lv_tot_pkgchrg = lv_tot_pkgchrg + w_item-item_pkg_chrg.
              lv_tot_amort   = lv_tot_amort + w_item-item_amotization.

              lv_tax_amt     = lv_tax_amt + w_item-item_assessableamount .
              lv_tax_amt1    = lv_tax_amt1 + w_item-item_assessableamount .

*      "lv_tot_igst1 = lv_tot_igst1 + ( ( w_item-item_assessableamount + w_item-item_freight + w_item-item_fert_oth ) * w_item-item_igstrate / 100 ) .
*      "lv_tot_cgst1 = lv_tot_cgst1 + ( ( w_item-item_assessableamount + w_item-item_freight + w_item-item_fert_oth ) * w_item-item_cgstrate / 100 ) .
*      "lv_tot_sgst1 = lv_tot_sgst1 + ( ( w_item-item_assessableamount + w_item-item_freight + w_item-item_fert_oth ) * w_item-item_sgstrate / 100 ) .

              lv_tot_sgst1 = lv_tot_sgst1 + ( ( w_item-item_assessableamount ) * w_item-item_sgstrate / 100 ) .
              lv_tot_cgst1 = lv_tot_cgst1 + ( ( w_item-item_assessableamount ) * w_item-item_cgstrate / 100 ) .
              lv_tot_igst1 = lv_tot_igst1 + ( ( w_item-item_assessableamount ) * w_item-item_igstrate / 100 ) .

              """***Start:Preparation of customer QR Code Item Detail: TOYOTA-TKAP & TOYOTA-TIEI ***
              lv_billqty     = w_item-billingquantity.
              lv_billqty_txt = lv_billqty.
              IF ls_vcode-qr_required = 'Y'.
                lv_unit_price  = lv_item_urate.
              ELSE.
                lv_item_urate2 = lv_item_urate.
                lv_unit_price  = lv_item_urate2.
              ENDIF.
              IF ls_vcode-qr_required = 'Y'.
                lv_item_amount = w_item-item_assessableamount.
              ELSE.
                lv_item_amount = '0.00'.
              ENDIF.

              CONDENSE:
              lv_billqty_txt,
              w_item-materialbycustomer,
              w_item-hsn,
              lv_unit_price,
              lv_item_amount.

              IF ls_vcode-qr_required = 'Y'.
                lv_cust_itm = lv_cust_itm &&
                              |{ w_item-materialbycustomer },| &&
                              |{ lv_billqty_txt },| &&
                              |{ w_item-hsn }~|.
                """***End:Preparation of customer QR Code Item Detail: TOYOTA-TIEI ***
              ELSEIF ls_vcode-qr_required = 'X'.
                lv_cust_itm = lv_cust_itm &&
                              |{ w_item-materialbycustomer },| &&
                              |{ lv_unit_price },| &&
                              |{ lv_billqty_txt },| &&
                              |{ lv_item_amount },~|.
                """***End:Preparation of customer QR Code Item Detail: TOYOTA-TKAP ***
              ENDIF.

              """""""""""""""""""""""""""""""""""""""""""""""""""""EOC by neelam CP/2025/CUST-128/1236
              IF iv_action = 'oeminv' or  iv_action = 'taxinv'.
                IF ls_vcode-qr_required = 'T'.
                  lv_cust_qr = |{ w_final-documentreferenceid },| &&     "*Invoice_Number
                  |{ w_item-billingquantity },~|.                                        "*Total Qty

                  lv_cust_qr = lv_cust_qr && lv_cust_itm.
                  REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN lv_cust_qr WITH space.

                ENDIF.
              ENDIF.
              """""""""""""""""""""""""""""""""""""""""""""""""""""EOC by neelam CP/2025/CUST-128/1236
              CLEAR : w_item.
            ENDLOOP .

          ENDIF .

          IF w_final-distributionchannel = '30' .

            lv_other_chrg  = lv_other_chrg * w_final-accountingexchangerate .
            sum_other_chrg = sum_other_chrg * w_final-accountingexchangerate .

            ""lv_tot_igst1 = ( lv_tax_amt + lv_other_chrg ) * w_item-item_igstrate / 100  .

            "" lv_tot_igst  = lv_tot_igst * w_final-AccountingExchangeRate .

            lv_grand_tot =  lv_tax_amt + lv_tot_sgst + lv_tot_cgst + lv_tot_igst1
                            + lv_other_chrg  + lv_round_off + sum_other_chrg + ( lv_dis * -1 )." + lv_tot_amort.  "" + lv_tcs

            lv_tot_gst = lv_tot_sgst + lv_tot_cgst + lv_tot_igst1 .
          ELSE .

            lv_other_chrg  = lv_other_chrg * w_final-accountingexchangerate.
            sum_other_chrg = sum_other_chrg * w_final-accountingexchangerate.

            "       lv_tot_igst1 = ( lv_tax_amt + lv_other_chrg ) * w_item-item_igstrate / 100  .
            "       lv_tot_cgst1 = ( lv_tax_amt + lv_other_chrg ) * w_item-item_cgstrate / 100  .
            "       lv_tot_sgst1 = ( lv_tax_amt + lv_other_chrg ) * w_item-item_sgstrate / 100  .
            "" lv_tot_igst  = lv_tot_igst * w_final-AccountingExchangeRate .

            lv_grand_tot =  lv_tax_amt + lv_tot_sgst1 + lv_tot_cgst1 + lv_tot_igst1
                            + lv_other_chrg  + lv_round_off  + lv_tcs + sum_other_chrg + lv_tot_pkgchrg." + lv_tot_amort.

            lv_tot_gst = lv_tot_sgst1 + lv_tot_cgst1 + lv_tot_igst1 .

          ENDIF .

          IF w_final-customerpricegroup EQ 'C1'.
            CLEAR lv_grand_tot.
            lv_grand_tot = lv_tot_sgst1 + lv_tot_cgst1 + lv_tot_igst1.
          ENDIF.

          DATA : lv_grand_tot_word TYPE string,
                 lv_gst_tot_word   TYPE string.
*       gst_tot_amt_words TYPE string,
*       grand_tot_amt_words TYPE string.

          lv_grand_tot_word = lv_grand_tot .
          lv_gst_tot_word = lv_tot_gst .

          lo_amt_words->number_to_words(
           EXPORTING
             iv_num   = lv_grand_tot_word
           RECEIVING
             rv_words = DATA(grand_tot_amt_words)
         ).
          CONDENSE grand_tot_amt_words.
          grand_tot_amt_words = |{ grand_tot_amt_words } Only| ##NO_TEXT.

          lo_amt_words->number_to_words(
            EXPORTING
              iv_num   = lv_gst_tot_word
            RECEIVING
              rv_words = DATA(gst_tot_amt_words)
          ).
          CONDENSE gst_tot_amt_words.
          gst_tot_amt_words = |{ gst_tot_amt_words } Only| ##NO_TEXT.

          IF iv_action = 'dchlpr' .
            IF w_final-billingdocumenttype = 'F8'.

              lv_certify_1 = 'It is Certified that the particulars given above are true and correct and'
                          && 'amount indicated represents the price actually changed and that there'
                          && 'is no flow of additional consideration directly or indirectly from the buyer' ##NO_TEXT.

            ELSEIF w_final-billingdocumenttype = 'JSN'.

              lv_certify_1 = 'Tax is payable under reverse charge: Yes / No' ##NO_TEXT.
              lv_certify_2 = 'For JOB WORK / RETURNABLE MATERIAL DELIVERY CHALLAN, THE MATERIAL MUST BE SENT BACK'
                          && 'WITHIN 1 YEAR FOR CAPITAL GOODS LIKE FIXTURES, THE GOODS MUST BE SENT BACK WITHIN 3 YEAR' ##NO_TEXT.

            ENDIF.
          ENDIF.

*        SELECT SINGLE
*        billingdocument,
*        yy1_gr_no_bdh,
*        yy1_gr_date_bdh,
*        yy1_exiseno_bdh,
*        yy1_exisedate_bdh,
*        yy1_vehical_no_bdh
*        FROM i_billingdocumentbasic
*        WHERE billingdocument = @w_final-billingdocument
*        INTO @DATA(ls_bill_doc).

          lv_certify_1 = 'Delivery: As per Tender Terms and Conditions.' ##NO_TEXT.
          lv_certify_2 = 'Payment will be accepted through NEFT/RTGS in the following Bank' ##NO_TEXT.
          lv_certify_3 = 'Account Beneficiary Name: DE Diamond Electric India Pvt. Ltd Bank  Name: INDIAN BANK,'
                          && 'IFSC Code: IDIB000H517     Account No: 7363402673' ##NO_TEXT.
          lv_certify_4 = ''.
          lv_certify_5 = ''.
          insur_policy_no     = '2345678900987654' ##NO_TEXT.
          insur_policy_date   = '18.06.2024' ##NO_TEXT.
          lv_tin_no           = ''.
          lv_tin_date         = ''.
          lv_fssai_lic_no     = ''.
*        lv_excise_pass_no   = ls_bill_doc-yy1_exiseno_bdh.
*        lv_excise_pass_date = ls_bill_doc-yy1_exisedate_bdh.
*        lv_bl_no            = ''.
*        lv_gr_no            = ls_bill_doc-yy1_gr_no_bdh.
*        lv_gr_date          = ls_bill_doc-yy1_gr_date_bdh.

          IF w_final-distributionchannel = '10' OR w_final-distributionchannel = '20'.
            lv_excise_no_h  = 'Excise Pass No:' ##NO_TEXT.
            lv_excise_dt_h  = 'Excise Pass Date:' ##NO_TEXT.
            lv_blno_h       = ''. "'KL:'.
            lv_pur_odr_h    = 'Tendor / Permit No.:' ##NO_TEXT.
            lv_pur_dt_h     = 'Tendor / Permit Date:' ##NO_TEXT.
          ELSE.
            lv_pur_odr_h    = 'Purchase Order No.:' ##NO_TEXT.
            lv_pur_dt_h     = 'Purchase Order Date:' ##NO_TEXT.
            CLEAR: lv_excise_pass_no, lv_excise_pass_date, lv_bl_no.
          ENDIF.

          lv_regd_adrs_1 = 'Plot No- 38, Sector-5, HSIIDC Growth Centre, Phase-II, Bawal, Distt: Rewari, Haryana 123051' ##NO_TEXT.

          """***Start:Preparation of customer QR Code: TOYOTA-TKAP & TOYOTA-TIEI ***
          DATA: lv_grand_tot_txt TYPE c LENGTH 20,
                lv_tot_tax_txt   TYPE c LENGTH 20,
                lv_tot_igst_txt  TYPE c LENGTH 20,
                lv_tot_cgst_txt  TYPE c LENGTH 20,
                lv_tot_sgst_txt  TYPE c LENGTH 20,
                lv_tot_ugst_txt  TYPE c LENGTH 20,
                lv_tot_cess_txt  TYPE c LENGTH 20,
                lv_label_num_txt TYPE c LENGTH 60,
                lv_gst_num       TYPE string.

          lv_grand_tot_txt = lv_grand_tot.
          lv_tot_tax_txt   = lv_tax_amt.

          IF lv_tot_igst1 IS NOT INITIAL.
            lv_tot_igst_txt  = lv_tot_igst1.
          ELSE.
            IF ls_vcode-qr_required = 'X'.
              lv_tot_igst_txt  = '0.00'.
            ELSE.
              lv_tot_igst_txt  = '0'.
            ENDIF.

          ENDIF.

          IF lv_tot_sgst1 IS NOT INITIAL.
            lv_tot_sgst_txt  = lv_tot_sgst1.
          ELSE.
            IF ls_vcode-qr_required = 'X'.
              lv_tot_sgst_txt  = '0.00'.
            ELSE.
              lv_tot_sgst_txt  = '0'.
            ENDIF.
          ENDIF.

          IF lv_tot_cgst1 IS NOT INITIAL.
            lv_tot_cgst_txt  = lv_tot_cgst1.
          ELSE.
            IF ls_vcode-qr_required = 'X'.
              lv_tot_cgst_txt  = '0.00'.
            ELSE.
              lv_tot_cgst_txt  = '0'.
            ENDIF.
          ENDIF.

          IF ls_vcode-qr_required = 'X'.
            lv_tot_ugst_txt  = '0.00'.
            lv_tot_cess_txt  = '0.00'.
          ELSE.
            lv_tot_ugst_txt  = '0'.
            lv_tot_cess_txt  = '0'.
          ENDIF.
          lv_label_num_txt = '1/1'.

          lv_gst_num    = w_final-plant_gstin.

          CONDENSE:
          lv_grand_tot_txt,
          lv_tot_igst_txt,
          lv_tot_sgst_txt,
          lv_tot_cgst_txt,
          lv_tot_ugst_txt,
          lv_tot_cess_txt,
          lv_gst_num,
          lv_tot_tax_txt,
          order_num_qr.

          IF ls_vcode-qr_required = 'X'.
            lv_dt_bill_tkap = w_final-billingdocumentdate+6(2) &&
                              w_final-billingdocumentdate+4(2) &&
                              w_final-billingdocumentdate+0(4).
          ELSE.
            lv_dt_bill_qr = w_final-billingdocumentdate+6(2) &&
                            w_final-billingdocumentdate+4(2) &&
                            w_final-billingdocumentdate+2(2).
          ENDIF.

          IF ls_vcode-qr_required = 'Y'.
*          lv_cust_qr = |{ w_final-purchaseorderbycustomer },| && "*Order_Number
            lv_cust_qr = |{ order_num_qr },| && "*Order_Number
                         |{ w_final-billingdocument },| &&         "*Invoice_Number
                         |{ lv_dt_bill_qr },| &&                   "*Invoice_Date
                         |{ lv_grand_tot_txt },| &&                "*Total_Invoice_Amount(Incl taxes)
                         |{ lv_tot_cgst_txt },| &&                 "*Central_GST
                         |{ lv_tot_sgst_txt },| &&                 "*State_GST
                         |{ lv_tot_igst_txt },| &&                 "*Intergated_GST
                         |{ lv_tot_ugst_txt },| &&                 "*UT_GST
                         |{ lv_tot_cess_txt },| &&                 "*Cess
                         |{ lv_label_num_txt }~|.                  "*Label_Number/Total No. of Labels~Part_Number

            lv_cust_qr = lv_cust_qr && lv_cust_itm.

          ELSEIF ls_vcode-qr_required = 'X'.
            lv_cust_qr = |{ w_final-purchaseorderbycustomer },| && "*Order_Number
            |{ lv_gst_num },| &&                      "*GST Number
            |{ w_final-billingdocument },| &&         "*Invoice_Number
            |{ lv_dt_bill_tkap },| &&                 "*Invoice_Date
            |{ lv_tot_tax_txt },| &&                  "*Total_Taxable_Amount
            |{ lv_tot_cgst_txt },| &&                 "*Central_GST
            |{ lv_tot_sgst_txt },| &&                 "*State_GST
            |{ lv_tot_igst_txt },| &&                 "*Intergated_GST
            |{ lv_tot_ugst_txt },| &&                 "*UT_GST
            |{ lv_tot_cess_txt },| &&                 "*Cess
            |{ lv_grand_tot_txt },~|.                 "*Total_Invoice_Amount(Incl taxes)

            lv_cust_qr = lv_cust_qr && lv_cust_itm.

          ENDIF.

          """***End:Preparation of customer QR Code*********************************


          lv_xml = |{ lv_xml }{ lv_item }| &&
                     |</ItemData>| &&
                  |<cust_qrcode>{ lv_cust_qr }</cust_qrcode>| &&
                  |<total_amount_words>(INR) { grand_tot_amt_words }</total_amount_words>| &&
                  |<gst_amt_words>(INR) { gst_tot_amt_words }</gst_amt_words>| &&
                  |<remark_if_any>{ lv_remarks }</remark_if_any>| &&
                  |<no_of_package>{ lv_no_pck }</no_of_package>| &&
                  |<total_Weight>{ lv_qty }</total_Weight>| &&
                  |<gross_Weight>{ lv_gross }</gross_Weight>| &&
                  |<net_Weight>{ lv_net }</net_Weight>| &&
                  |<tot_qty>{ lv_qty }</tot_qty>| &&  """ line item total quantity
                  |<total_amount>{ lv_tot_amt }</total_amount>| &&
                  |<total_discount>{ lv_dis }</total_discount>| &&
                  |<total_taxable_value>{ lv_tax_amt }</total_taxable_value>| &&
                  |<total_taxable_value1>{ lv_tax_amt1 }</total_taxable_value1>| &&
                  |<total_cgst>{ lv_tot_cgst }</total_cgst>| &&
                  |<total_sgst>{ lv_tot_sgst }</total_sgst>| &&
                  |<total_igst>{ lv_tot_igst }</total_igst>| &&
                  |<total_igst1>{ lv_tot_igst1 }</total_igst1>| &&  """ printing in total
                  |<total_sgst1>{ lv_tot_sgst1 }</total_sgst1>| &&  """ printing in total
                  |<total_cgst1>{ lv_tot_cgst1 }</total_cgst1>| &&  """ printing in total
                  |<total_amort>{ lv_tot_amort }</total_amort>| &&
                  |<sum_packing_chrg>{ lv_tot_pkgchrg }</sum_packing_chrg>| &&
                  |<total_tcs>{ lv_tcs }</total_tcs>| &&
                  |<total_other_chrg>{ lv_other_chrg }</total_other_chrg>| &&
                  |<sum_other_chrg>{ sum_other_chrg }</sum_other_chrg>| &&
                  |<round_off>{ lv_round_off }</round_off>| &&
                  |<grand_total>{ lv_grand_tot }</grand_total>| &&
                  |<total_amt_expcurr>{ lv_amt_expcurr }</total_amt_expcurr>| &&
                  |<certify_1>{ lv_certify_1 }</certify_1>| &&
                  |<certify_2>{ lv_certify_2 }</certify_2>| &&
                  |<certify_3>{ lv_certify_3 }</certify_3>| &&
                  |<certify_4>{ lv_certify_4 }</certify_4>| &&
                  |<certify_5>{ lv_certify_5 }</certify_5>| &&
                  |<insur_policy_no>{ insur_policy_no }</insur_policy_no>| &&
                  |<insur_policy_date>{ insur_policy_date }</insur_policy_date>| &&
                  |<tin_no>{ lv_tin_no }</tin_no>| &&
                  |<tin_date>{ lv_tin_date }</tin_date>| &&
                  |<fssai_lic_no>{ lv_fssai_lic_no }</fssai_lic_no>| &&
                  |<excise_pass_no>{ lv_excise_pass_no }</excise_pass_no>| &&
                  |<excise_pass_date>{ lv_excise_pass_date }</excise_pass_date>| &&
                  |<bl_no>{ lv_bl_no }</bl_no>| &&
                  |<lv_excise_no_h>{ lv_excise_no_h }</lv_excise_no_h>| &&
                  |<lv_excise_dt_h>{ lv_excise_dt_h }</lv_excise_dt_h>| &&
                  |<lv_blno_h>{ lv_blno_h }</lv_blno_h>| &&
                  |<lv_pur_odr_h>{ lv_pur_odr_h }</lv_pur_odr_h>| &&
                  |<lv_pur_dt_h>{ lv_pur_dt_h }</lv_pur_dt_h>| &&
                  |<gr_number>{ lv_gr_no }</gr_number>| &&
                  |<gr_date>{ lv_gr_date }</gr_date>| &&
                  |<regd_adrs_1>{ lv_regd_adrs_1 }</regd_adrs_1>| &&
                  |<regd_adrs_2>{ lv_regd_adrs_2 }</regd_adrs_2>|." &&
*               |</BillingDocumentNode>|." &&
*              |</Form>|. "commented By Neelam goyal
*         *      "BOC by Neelam goyal

          DATA(lv_footer) =
                 |</BillingDocumentNode>|.

          " Concatenate the footer to the main XML string
          CONCATENATE lv_xml lv_footer INTO lv_xml.

          " Final XML is now in lv_xml
          CLEAR: lv_tot_amort,lv_cust_qr,lv_gst_num,w_final-billingdocument,lv_dt_bill_tkap,lv_tot_tax_txt,lv_tot_cgst_txt,lv_tot_sgst_txt,
          lv_tot_igst_txt,lv_tot_cess_txt,lv_grand_tot_txt,lv_tot_ugst_txt,lv_label_num_txt,lv_dt_bill_qr,lv_cust_itm,lv_item_text,
      lv_tax_amt1,lv_dis,lv_grand_tot,lv_tcs,lv_tot_cgst,lv_tot_cgst1,lv_tot_sgst,lv_tot_sgst1,lv_tot_igst,lv_tot_igst1,
      lv_bill_adr1,lv_bill_adr2,w_final-re_pin,lv_cn_name_re-countryname ,lv_shp_adr1,lv_shp_adr2,w_final-we_pin,w_final-we_pin.

        ENDDO.

        DATA(lv_last_form) =
         |</Form>|.

        CONCATENATE lv_xml lv_last_form INTO lv_xml.


        "Eoc by neelam

        DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
        iv_xml_base64 = ls_data_xml_64.

      ENDMETHOD.   "EOC by Neelam on 22.06.2025
ENDCLASS.
