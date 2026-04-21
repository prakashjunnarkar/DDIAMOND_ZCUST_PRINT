 CLASS zcl_mm_custom_print DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

   PUBLIC SECTION.
     DATA:
       gt_final TYPE TABLE OF zstr_grn_data,
       gt_resb  TYPE TABLE OF zstr_issue_slip,
       gs_resb  TYPE zstr_issue_slip,
       lt_item  TYPE TABLE OF zstr_issue_slip_item,
       ls_item  TYPE zstr_issue_slip_item.

     DATA:
       sys_date     TYPE d  , " VALUE cl_abap_context_info ,
       sys_time     TYPE t  , "  VALUE  cl_abap_context_info=>get_system_time( 8,0 ),
       sys_timezone TYPE timezone,
       sy_uname     TYPE c LENGTH 20.

     DATA:
       lv_char10  TYPE c LENGTH 10,
       lv_char120 TYPE c LENGTH 120.

     METHODS:
       get_grn_data
         IMPORTING
                   iv_mblnr        LIKE lv_char10
                   iv_gjahr        TYPE zi_dc_note-fiscalyear
                   iv_action       LIKE lv_char10
         RETURNING VALUE(et_final) LIKE gt_final,

       prep_xml_grn_print
         IMPORTING
                   it_final             LIKE gt_final
                   iv_action            LIKE lv_char10
         RETURNING VALUE(iv_xml_base64) TYPE string,

       get_resb_data
         IMPORTING
                   iv_rsnum        LIKE lv_char10
                   iv_rsdat        TYPE zi_issue_slip-reservationdate
                   iv_action       LIKE lv_char10
         RETURNING VALUE(et_final) LIKE gt_resb,

       prep_xml_issue_slip_print
         IMPORTING
                   it_final             LIKE gt_resb
                   iv_action            LIKE lv_char10
         RETURNING VALUE(iv_xml_base64) TYPE string.

   PROTECTED SECTION.
   PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_MM_CUSTOM_PRINT IMPLEMENTATION.


   METHOD get_grn_data.

     sys_date = cl_abap_context_info=>get_system_date( ).
     sys_time = cl_abap_context_info=>get_system_time( ).
     sy_uname = cl_abap_context_info=>get_user_technical_name( ).

     DATA: gt_grn  TYPE TABLE OF zstr_grn_data,
           gs_grn  TYPE zstr_grn_data,
           gt_item TYPE TABLE OF zstr_grn_item,
           gs_item TYPE zstr_grn_item.

     IF iv_action = 'siplgrn'.

       SELECT * FROM zi_grn_detail
                WHERE materialdocument = @iv_mblnr AND materialdocumentyear = @iv_gjahr AND goodsmovementtype = '101'
                INTO TABLE @DATA(lt_grn).     "#EC CI_ALL_FIELDS_NEEDED

     ELSEIF iv_action = 'rtpprint'.

       SELECT * FROM zi_grn_detail
                WHERE materialdocument = @iv_mblnr AND materialdocumentyear = @iv_gjahr AND goodsmovementtype = '502'
                INTO TABLE @lt_grn.           "#EC CI_ALL_FIELDS_NEEDED

     ELSEIF iv_action = 'misprint'.

       SELECT * FROM zi_grn_detail
                WHERE materialdocument = @iv_mblnr AND
                     materialdocumentyear = @iv_gjahr AND
                     goodsmovementtype IN ( '311', '201', '411' ) AND
                     isautomaticallycreated = ''
                INTO TABLE @lt_grn.           "#EC CI_ALL_FIELDS_NEEDED

     ENDIF.

     IF sy-subrc EQ 0.

       DATA(lt_hdr) = lt_grn[].
       SORT lt_hdr BY materialdocument materialdocumentyear.
       DELETE ADJACENT DUPLICATES FROM lt_hdr COMPARING materialdocument materialdocumentyear.

       IF iv_action = 'misprint'.

         LOOP AT lt_hdr INTO DATA(ls_hdr).

           IF  ls_hdr-reservation IS NOT INITIAL.

             SELECT
             reservation,
             reservationitem,
             SUM( resvnitmrequiredqtyinbaseunit ) AS req_qty
             FROM i_reservationdocumentitem
             WHERE reservation = @ls_hdr-reservation
             GROUP BY
             reservation,
             reservationitem
             INTO TABLE @DATA(lt_resb).

           ENDIF.

           gs_grn-materialdocument     = ls_hdr-materialdocument.
           gs_grn-materialdocumentyear = ls_hdr-materialdocumentyear.
           gs_grn-documentdate         = ls_hdr-documentdate.
           gs_grn-postingdate          = ls_hdr-postingdate.
           gs_grn-recpt_no             = ls_hdr-materialdocument.
           gs_grn-recpt_date           = ls_hdr-postingdate+6(2) && '.' && ls_hdr-postingdate+4(2) && '.' && ls_hdr-postingdate+0(4).

           gs_grn-plant_addl1          = ''  ##NO_TEXT.
           gs_grn-plant_addl2          = ''  ##NO_TEXT.
           gs_grn-plant_addl3          = ''.

           LOOP AT lt_grn INTO DATA(ls_grn) WHERE materialdocument = ls_hdr-materialdocument
                                              AND materialdocumentyear = ls_hdr-materialdocumentyear.

             gs_item-materialdocument      = ls_grn-materialdocument.
             gs_item-materialdocumentyear  = ls_grn-materialdocumentyear.
             gs_item-documentdate          = ls_grn-documentdate.
             gs_item-postingdate           = ls_grn-postingdate.
             gs_item-item_code             = ls_grn-material.
             gs_item-item_name             = ls_grn-productdescription.
             gs_item-unit                  = ls_grn-entryunit.
             gs_item-actual_qty            = ls_grn-quantityinentryunit.                "*Required Qty
             gs_item-accept_qty            = ls_grn-quantityinentryunit.                "*Issue Qty
             gs_item-short_qty             = gs_item-actual_qty - gs_item-accept_qty.   "*Short Qty
             gs_item-batch                 = ls_grn-batch.
             gs_item-issueloc              = ls_grn-storagelocation.
             gs_item-issuebin              = ls_grn-ewmstoragebin.
             APPEND gs_item TO gt_item.

             gs_grn-sum_actual_qty       = gs_grn-sum_actual_qty + gs_item-actual_qty.
             gs_grn-sum_short_qty        = gs_grn-sum_short_qty + gs_item-short_qty.
             gs_grn-sum_accpt_qty        = gs_grn-sum_accpt_qty + gs_item-accept_qty.

             CLEAR: ls_grn.
           ENDLOOP.

           INSERT LINES OF gt_item INTO TABLE gs_grn-grn_item.
           APPEND gs_grn TO gt_grn.

         ENDLOOP.

       ELSE.

         CLEAR: ls_hdr.
         LOOP AT lt_hdr INTO ls_hdr.

           SELECT SINGLE * FROM i_purchaseorderstatus
                           WHERE purchaseorder = @ls_hdr-purchaseorder
                           INTO @DATA(ls_postat). "#EC CI_ALL_FIELDS_NEEDED

           SELECT SINGLE * FROM zi_plant_address
                           WHERE plant = @ls_hdr-plant
                           INTO @DATA(ls_plant_adrs). "#EC CI_ALL_FIELDS_NEEDED

           IF ls_postat-purchaseordertype = 'NB' OR ls_postat-purchaseordertype = 'UD'.

             gs_grn-po_num   = ls_hdr-purchaseorder.
             gs_grn-po_date  = ls_hdr-purchaseorderdate+6(2) && '.' && ls_hdr-purchaseorderdate+4(2) && '.' && ls_hdr-purchaseorderdate+0(4).

             SELECT * FROM zmm_ge_data
                      FOR ALL ENTRIES IN @lt_grn
                       WHERE ponum  = @lt_grn-purchaseorder
                        AND  poitem = @lt_grn-purchaseorderitem
                        AND  mblnr  = @ls_hdr-materialdocument
                        AND  mjahr  = @ls_hdr-materialdocumentyear
                        INTO TABLE @DATA(lt_ge_data). "#EC CI_ALL_FIELDS_NEEDED

             SELECT * FROM I_PurchaseOrderItemAPI01
                     FOR ALL ENTRIES IN @lt_grn
                      WHERE PurchaseOrder  = @lt_grn-purchaseorder
                       AND  PurchaseOrderItem = @lt_grn-purchaseorderitem
                       INTO TABLE @DATA(lt_PR_data11). "#EC CI_ALL_FIELDS_NEEDED

           ELSE.

             SELECT SINGLE * FROM i_schedgagrmthdrapi01
                             WHERE schedulingagreement = @ls_hdr-purchaseorder
                             INTO @DATA(ls_schdagr). "#EC CI_ALL_FIELDS_NEEDED

             IF ls_schdagr-purchasingdocumenttype = 'LP' OR ls_schdagr-purchasingdocumenttype = 'LU'.
               gs_grn-po_num   = ls_hdr-purchaseorder.
               gs_grn-po_date  = ls_schdagr-purchasingdocumentorderdate+6(2) && '.' && ls_schdagr-purchasingdocumentorderdate+4(2) && '.' && ls_schdagr-purchasingdocumentorderdate+0(4).
             ENDIF.

             SELECT * FROM zi_schagr_qty
                      FOR ALL ENTRIES IN @lt_grn
                      WHERE schedulingagreement = @lt_grn-purchaseorder
                       AND  schedulingagreementitem = @lt_grn-purchaseorderitem
                       INTO TABLE @DATA(lt_schdl). "#EC CI_ALL_FIELDS_NEEDED

             SELECT * FROM i_schedgagrmtitmapi01
                      FOR ALL ENTRIES IN @lt_grn
                      WHERE schedulingagreement = @lt_grn-purchaseorder
                       AND  schedulingagreementitem = @lt_grn-purchaseorderitem
                       INTO TABLE @DATA(lt_schdl_itm). "#EC CI_ALL_FIELDS_NEEDED

             SELECT * FROM zmm_ge_data
                      FOR ALL ENTRIES IN @lt_grn
                       WHERE ponum  = @lt_grn-purchaseorder
                        AND  poitem = @lt_grn-purchaseorderitem
                        AND  mblnr  = @ls_hdr-materialdocument
                        AND  mjahr  = @ls_hdr-materialdocumentyear
                        INTO TABLE @lt_ge_data. "#EC CI_ALL_FIELDS_NEEDED

             SELECT * FROM I_PurchaseOrderItemAPI01
                     FOR ALL ENTRIES IN @lt_grn
                      WHERE PurchaseOrder  = @lt_grn-purchaseorder
                       AND  PurchaseOrderItem = @lt_grn-purchaseorderitem
                       INTO TABLE @lt_PR_data11. "#EC CI_ALL_FIELDS_NEEDED

           ENDIF.

           gs_grn-materialdocument     = ls_hdr-materialdocument.
           gs_grn-materialdocumentyear = ls_hdr-materialdocumentyear.
           gs_grn-documentdate         = ls_hdr-documentdate.
           gs_grn-postingdate          = ls_hdr-postingdate.
           gs_grn-recpt_no             = ls_hdr-materialdocument.
           gs_grn-recpt_date           = ls_hdr-postingdate+6(2) && '.' && ls_hdr-postingdate+4(2) && '.' && ls_hdr-postingdate+0(4).
           gs_grn-suppl_code           = ls_hdr-supplier.
           gs_grn-suppl_name           = ls_hdr-suppliername.
           gs_grn-suppl_addl1          = ls_hdr-streetname &&  ',' && ls_hdr-streetsuffixname1 &&  ',' && ls_hdr-districtname. "ls_hdr-StreetPrefixName1 && ',' && ls_hdr-StreetPrefixName2.
           gs_grn-suppl_addl2          = ls_hdr-cityname &&  ',' && ls_hdr-postalcode &&  ',' && ls_hdr-country.
           gs_grn-suppl_addl3          = ''.
           gs_grn-inv_num              = ls_hdr-referencedocument.
           gs_grn-inv_date             = ls_hdr-documentdate+6(2) && '.' && ls_hdr-documentdate+4(2) && '.' && ls_hdr-documentdate+0(4).
           gs_grn-plant                = ls_hdr-plant.
           gs_grn-sl_gate_reg          = ''.
           gs_grn-insp_date            = ''.
           gs_grn-length_os            = ''.
           gs_grn-length_us            = ''.
           gs_grn-currcy               = ''.
           gs_grn-uom                  = ''.

           gs_grn-po_num   = ls_hdr-purchaseorder.
           gs_grn-po_date  = ls_hdr-purchaseorderdate+6(2) && '.' && ls_hdr-purchaseorderdate+4(2) && '.' && ls_hdr-purchaseorderdate+0(4).

           gs_grn-plant_addl1          = |{ ls_plant_adrs-streetprefixname1 } , { ls_plant_adrs-streetname }| ##NO_TEXT.
           gs_grn-plant_addl2          = |{ ls_plant_adrs-cityname } - { ls_plant_adrs-postalcode } , { ls_plant_adrs-addresstimezone }| ##NO_TEXT.
           gs_grn-plant_addl3          = ''.

           CLEAR: ls_grn.
           LOOP AT lt_grn INTO ls_grn WHERE materialdocument = ls_hdr-materialdocument
                                              AND materialdocumentyear = ls_hdr-materialdocumentyear.

             IF ls_schdagr-purchasingdocumenttype = 'LP' OR ls_schdagr-purchasingdocumenttype = 'LU'.

               READ TABLE lt_schdl INTO DATA(ls_schdl) WITH KEY
                                    schedulingagreement = ls_grn-purchaseorder
                                    schedulingagreementitem = ls_grn-purchaseorderitem.

               ls_grn-orderquantity = ls_schdl-schedulelineorderquantity.
               CLEAR: ls_schdl.

               READ TABLE lt_schdl_itm INTO DATA(ls_schdl_itm) WITH KEY
                                    schedulingagreement = ls_grn-purchaseorder
                                    schedulingagreementitem = ls_grn-purchaseorderitem.

               ls_grn-netpriceamount = ls_schdl_itm-netpriceamount.
               CLEAR: ls_schdl_itm.

             ENDIF.

             gs_item-actual_qty            = ls_grn-quantityinentryunit.

             READ TABLE lt_ge_data INTO DATA(ls_ge_data) WITH KEY
                                              ponum  = ls_grn-purchaseorder
                                              poitem = ls_grn-purchaseorderitem
                                              mblnr  = ls_grn-materialdocument
                                              mjahr  = ls_grn-materialdocumentyear.
             IF sy-subrc EQ 0.
               gs_item-chaln_qty           = ls_ge_data-challnqty. "ls_grn-QuantityInDeliveryQtyUnit.
               gs_item-short_qty           = gs_item-chaln_qty - gs_item-actual_qty.
             ELSE.
               gs_item-chaln_qty           = ls_grn-quantityindeliveryqtyunit.
               "gs_item-short_qty           = gs_item-chaln_qty - gs_item-actual_qty.
             ENDIF.

             gs_grn-ge_num               = ls_ge_data-gentry_num.
             gs_grn-ge_date              = ls_ge_data-created_on+6(2) && '.'
                                           && ls_ge_data-created_on+4(2) && '.'
                                           && ls_ge_data-created_on+0(4).

             gs_item-materialdocument      = ls_grn-materialdocument.
             gs_item-materialdocumentyear  = ls_grn-materialdocumentyear.
             gs_item-documentdate          = ls_grn-documentdate.
             gs_item-postingdate           = ls_grn-postingdate.
             gs_item-item_code             = ls_grn-material.
             gs_item-item_name             = ls_grn-productdescription.
             gs_item-unit                  = ls_grn-entryunit.
             gs_item-po_qty                = ls_grn-orderquantity.
             "*gs_item-chaln_qty           = ls_grn-QuantityInDeliveryQtyUnit.
             gs_item-rej_qty               = ls_grn-insplotqtytoblocked.
             gs_item-short_qty             = gs_item-chaln_qty - gs_item-actual_qty. "Bill qty - Actual qty

             IF ls_grn-inventorystocktype EQ '02'.
               gs_item-accept_qty            = ls_grn-insplotqtytofree.
             ELSE.
               gs_item-accept_qty            = ls_grn-quantityinentryunit.
             ENDIF.

             gs_item-rate_per_unit         = ls_grn-netpriceamount / 1.
             gs_item-doscount              = ''.
             gs_item-amt_val               = ''.
             gs_item-excise_gst            = ''.
             gs_item-qc_date               = ls_grn-inspectionlotusagedecidedon+6(2) && '.'
                                             && ls_grn-inspectionlotusagedecidedon+4(2) && '.'
                                             && ls_grn-inspectionlotusagedecidedon+0(4).
             gs_item-qc_date   = ls_grn-Batch.
             SELECT SINGLE * FROM i_purchaseorderapi01 WHERE PurchaseOrder = @ls_grn-purchaseorder
             INTO @DATA(l_prrr).              "#EC CI_ALL_FIELDS_NEEDED
             "           IF L_PRRR-PurchaseOrderType = 'ZOTI' OR L_PRRR-PurchaseOrderType = 'ZCGI'
             "           OR L_PRRR-PurchaseOrderType = 'ZRMI'.
             READ TABLE lt_PR_data11 INTO DATA(ls_pr_data1) WITH KEY PurchaseOrder = ls_grn-purchaseorder
                                              PurchaseOrderItem = ls_grn-purchaseorderitem.

             " gs_item-tot_val = gs_item-chaln_qty * ( ls_pr_data1-NetPriceAmount / ls_pr_data1-NetPriceQuantity ).
             gs_item-rate_per_unit = ls_pr_data1-NetPriceAmount / ls_pr_data1-NetPriceQuantity .
             IF  ls_grn-DocumentCurrency = 'JPY'.
                gs_item-rate_per_unit = gs_item-rate_per_unit * '100'.
             ENDIF.
             gs_item-tot_val               = gs_item-chaln_qty * gs_item-rate_per_unit. "ls_grn-TotalGoodsMvtAmtInCCCrcy.
             "          ENDIF.
             IF iv_action = 'rtpprint'.

               SELECT SINGLE
               product,
               plant,
               consumptiontaxctrlcode
               FROM i_productplantbasic
               WHERE product = @ls_grn-material AND plant = @ls_grn-plant
               INTO @DATA(ls_hsn).

               gs_item-hsn_code      = ls_hsn-consumptiontaxctrlcode.
               gs_item-taxable_amt   = ls_grn-quantityinentryunit * ls_grn-unloadingpointname.
               gs_item-gst_rate      = ls_grn-goodsrecipientname.

               IF ls_plant_adrs-region = ls_grn-region.

                 gs_item-cgst_amt      = gs_item-taxable_amt * ( ls_grn-goodsrecipientname / 100 ).
                 gs_item-cgst_amt      = gs_item-cgst_amt / 2.

                 gs_item-sgst_amt      = gs_item-taxable_amt * ( ls_grn-goodsrecipientname / 100 ).
                 gs_item-sgst_amt      = gs_item-sgst_amt / 2.

               ELSE.
                 gs_item-igst_amt      = gs_item-taxable_amt * 18 / 100.
               ENDIF.

               gs_item-rate_per_unit = ls_grn-unloadingpointname.

               gs_item-tot_val       = gs_item-taxable_amt + gs_item-cgst_amt + gs_item-sgst_amt + gs_item-igst_amt.

               CLEAR: ls_hsn.

             ENDIF.

             APPEND gs_item TO gt_item.

             gs_grn-sum_tot_val          = gs_grn-sum_tot_val   + gs_item-tot_val.
             gs_grn-sum_chaln_qty        = gs_grn-sum_chaln_qty + gs_item-chaln_qty.
             gs_grn-sum_actual_qty       = gs_grn-sum_actual_qty + gs_item-actual_qty.
             gs_grn-sum_rej_qty          = gs_grn-sum_rej_qty   + gs_item-rej_qty.
             gs_grn-sum_short_qty        = gs_grn-sum_short_qty + gs_item-short_qty.
             gs_grn-sum_accpt_qty        = gs_grn-sum_accpt_qty + gs_item-accept_qty.
             gs_grn-sum_po_qty           = gs_grn-sum_po_qty + gs_item-po_qty.

             gs_grn-sum_taxable_amt      = gs_grn-sum_taxable_amt + gs_item-taxable_amt.
             gs_grn-sum_cgst_amt         = gs_grn-sum_cgst_amt + gs_item-cgst_amt.
             gs_grn-sum_sgst_amt         = gs_grn-sum_sgst_amt + gs_item-sgst_amt.
             gs_grn-sum_igst_amt         = gs_grn-sum_igst_amt + gs_item-igst_amt.
             gs_grn-sum_gst_val          = gs_grn-sum_cgst_amt + gs_grn-sum_sgst_amt + gs_grn-sum_igst_amt.

           ENDLOOP.

           gs_grn-tax_on_doc           = ''.
           gs_grn-addition_val         = ''.

           INSERT LINES OF gt_item INTO TABLE gs_grn-grn_item.
           APPEND gs_grn TO gt_grn.

         ENDLOOP.

       ENDIF.

     ENDIF.

     et_final[] = gt_grn[].

   ENDMETHOD.


   METHOD get_resb_data.

     IF iv_rsnum IS NOT INITIAL.

       SELECT SINGLE * FROM i_reservationdocumentheader
                WHERE reservation = @iv_rsnum AND reservationdate = @iv_rsdat
                INTO @DATA(ls_resb_hdr).

       IF ls_resb_hdr IS NOT INITIAL.

         SELECT * FROM i_reservationdocumentitem
                  WHERE reservation = @iv_rsnum
                  INTO TABLE @DATA(lt_resb_item).

         IF lt_resb_item[] IS NOT INITIAL.

           SELECT
           Product,
           ProductDescription,
           Language
           FROM i_productdescription
                    FOR ALL ENTRIES IN @lt_resb_item
                    WHERE product = @lt_resb_item-product AND language = 'E'
                    INTO TABLE @DATA(lt_makt) .    "#EC CI_NO_TRANSFORM

           SELECT
            materialdocument,
            materialdocumentyear,
            materialdocumentitem,
            reservation,
            reservationitem,
            storagelocation,
            issgorrcvgbatch,
            DebitCreditCode
           FROM i_materialdocumentitem_2
                     FOR ALL ENTRIES IN @lt_resb_item
                     WHERE reservation = @lt_resb_item-reservation AND reservationitem = @lt_resb_item-reservationitem
                     INTO TABLE @DATA(lt_mseg) .   "#EC CI_NO_TRANSFORM

         ENDIF.

         READ TABLE lt_mseg INTO DATA(cs_mseg) INDEX 1  . "#EC CI_NOORDER

         SELECT SINGLE  materialdocument , postingdate , createdbyuser FROM i_materialdocumentheader_2
                         WHERE materialdocument = @cs_mseg-materialdocument AND materialdocumentyear = @cs_mseg-materialdocumentyear
                         INTO @DATA(ls_mkpf).      "#EC CI_NO_TRANSFORM

         SELECT SINGLE userid , userdescription FROM zi_user
                         WHERE userid = @ls_mkpf-createdbyuser
                         INTO @DATA(ls_user).      "#EC CI_NO_TRANSFORM

         SELECT SINGLE userid , userdescription  FROM zi_user
                         WHERE userid = @ls_resb_hdr-userid
                         INTO @DATA(ls_user_req).  "#EC CI_NO_TRANSFORM
       ENDIF.

       gs_resb-resv_num        = ls_resb_hdr-reservation.
       gs_resb-resv_pos        = ''.
       gs_resb-post_date       = ls_resb_hdr-reservationdate+6(2) && '.' && ls_resb_hdr-reservationdate+4(2) && '.' && ls_resb_hdr-reservationdate+0(4).
       gs_resb-requi_num       = ls_resb_hdr-reservation.
       gs_resb-req_loc         = ls_resb_hdr-issuingorreceivingstorageloc.
       gs_resb-req_person      = ls_user_req-userdescription.
       gs_resb-issue_person    = ls_user-userdescription.
       gs_resb-comp_name       = 'DE DIAMOND ELECTRIC INDIA PVT.LTD' ##NO_TEXT.
       gs_resb-slip_name       = 'Material Issue Slip' ##NO_TEXT .
       gs_resb-uom             = ''.

       LOOP AT lt_resb_item INTO DATA(ls_resb_item).

         READ TABLE lt_mseg INTO DATA(ls_mseg) WITH KEY
                                               reservation     = ls_resb_item-reservation
                                               reservationitem = ls_resb_item-reservationitem
                                               storagelocation = ls_resb_item-storagelocation.

         READ TABLE lt_makt INTO DATA(ls_makt) WITH KEY product = ls_resb_item-product.
         ls_item-resv_num      = ls_resb_item-reservation.
         ls_item-resv_pos      = ls_resb_item-reservationitem.
         ls_item-postig_date   = ls_mkpf-postingdate+6(2) && '.' && ls_mkpf-postingdate+4(2) && '.' && ls_mkpf-postingdate+0(4).
         ls_item-lot_no        = ls_mseg-issgorrcvgbatch.
         ls_item-prododr_num   = ''.
         ls_item-batch         = ls_resb_item-Batch.
         ls_item-plant         = ls_resb_item-plant.
         ls_item-item_no       = ls_resb_item-product.
         ls_item-item_desc     = ls_makt-productdescription.
         ls_item-req_qty       = ls_resb_item-resvnitmrequiredqtyinentryunit.
         ls_item-issue_qty     = ls_resb_item-resvnitmwithdrawnqtyinbaseunit.
         ls_item-pend_qty      = ls_item-req_qty - ls_item-issue_qty.
         APPEND ls_item TO lt_item.

         "gs_resb-req_loc       = ls_resb_item-StorageLocation.
         gs_resb-issue_from    = ls_resb_item-storagelocation.
         gs_resb-sum_req_qty   = gs_resb-sum_req_qty + ls_item-req_qty.
         gs_resb-sum_issue_qty = gs_resb-sum_issue_qty + ls_item-issue_qty.
         gs_resb-sum_pend_qty  = gs_resb-sum_pend_qty + ls_item-pend_qty.
         gs_resb-plant         = ls_item-plant.

         CLEAR: ls_resb_item, ls_item, ls_makt, ls_mseg.
       ENDLOOP.

       INSERT LINES OF lt_item INTO TABLE gs_resb-issue_itm.
       APPEND gs_resb TO et_final.

     ENDIF.

   ENDMETHOD.


   METHOD prep_xml_grn_print.

     DATA : heading      TYPE c LENGTH 100,
            sub_heading  TYPE c LENGTH 200,
            lv_xml_final TYPE string.

     READ TABLE it_final INTO DATA(ls_final) INDEX 1.

     sub_heading = ls_final-plant_addl1 && ls_final-plant_addl2.

     REPLACE ALL OCCURRENCES OF '&' IN ls_final-suppl_name WITH 'AND' ##NO_TEXT .

     DATA : lv_grand_tot_word TYPE string,
            lv_gst_tot_word   TYPE string,
            lv_tot_gst        TYPE p LENGTH 16 DECIMALS 2,
            lv_grand_tot      TYPE p LENGTH 16 DECIMALS 2.

     ""****Start:Logic to convert amount in Words************
     DATA:
       lo_amt_words TYPE REF TO zcl_amt_words.
     CREATE OBJECT lo_amt_words.
     ""****End:Logic to convert amount in Words************

     lv_grand_tot_word = ls_final-sum_tot_val.
     lv_gst_tot_word   = ls_final-sum_gst_val.

     lo_amt_words->number_to_words(
      EXPORTING
        iv_num   = lv_grand_tot_word
      RECEIVING
        rv_words = DATA(grand_tot_amt_words)
    ).

     grand_tot_amt_words = |{ grand_tot_amt_words } Only| ##NO_TEXT.

     lo_amt_words->number_to_words(
       EXPORTING
         iv_num   = lv_gst_tot_word
       RECEIVING
         rv_words = DATA(gst_tot_amt_words)
     ).

     gst_tot_amt_words = |{ gst_tot_amt_words } Only| ##NO_TEXT.

     DATA :
       sum_accptd_qty TYPE c LENGTH 20,
       sum_rejtd_qty  TYPE c LENGTH 20.

     sum_accptd_qty = ls_final-sum_accpt_qty.
     sum_rejtd_qty  = ls_final-sum_rej_qty.
     CONDENSE sum_accptd_qty.
     CONDENSE sum_rejtd_qty.
     IF sum_accptd_qty EQ '0.00'.
       sum_accptd_qty = ''.
     ENDIF.

     IF sum_rejtd_qty EQ '0.00'.
       sum_rejtd_qty = ''.
     ENDIF.

     SHIFT ls_final-suppl_code LEFT DELETING LEADING '0'.
     DATA(lv_xml) =  |<Form>| &&
                     |<MaterialDocumentNode>| &&
                     |<heading>{ heading }</heading>| &&
                     |<sub_heading>{ sub_heading }</sub_heading>| &&
                     |<RECPT_NO>{ ls_final-recpt_no }</RECPT_NO>| &&
                     |<RECPT_DATE>{ ls_final-recpt_date  }</RECPT_DATE>| &&
                     |<SUPPL_CODE>{ ls_final-suppl_code }</SUPPL_CODE>| &&
                     |<SUPPL_NAME>{ ls_final-suppl_name }</SUPPL_NAME>| &&
                     |<SUPPL_ADDL1>{ ls_final-suppl_addl1 }</SUPPL_ADDL1>| &&
                     |<SUPPL_ADDL2>{ ls_final-suppl_addl2 }</SUPPL_ADDL2>| &&
                     |<SUPPL_ADDL3>{ ls_final-suppl_addl3 }</SUPPL_ADDL3>| &&
                     |<plantadrs1>{ ls_final-plant_addl1 }</plantadrs1>| &&
                     |<plantadrs2>{ ls_final-plant_addl2 }</plantadrs2>| &&
                     |<PO_NUM>{ ls_final-po_num }</PO_NUM>| &&
                     |<PO_DATE>{ ls_final-po_date }</PO_DATE>| &&
                     |<GE_NUM>{ ls_final-ge_num }</GE_NUM>| &&
                     |<GE_DATE>{ ls_final-ge_date }</GE_DATE>| &&
                     |<INV_NUM>{ ls_final-inv_num }</INV_NUM>| &&
                     |<INV_DATE>{ ls_final-inv_date }</INV_DATE>| &&
                     |<SL_GATE_REG>{ ls_final-sl_gate_reg }</SL_GATE_REG>| &&
                     |<SUM_TOT_VAL>{ ls_final-sum_tot_val }</SUM_TOT_VAL>| &&
                     |<TAX_ON_DOC>{ ls_final-tax_on_doc }</TAX_ON_DOC>| &&
                     |<ADDITION_VAL>{ ls_final-addition_val }</ADDITION_VAL>| &&
                     |<INSP_DATE>{ ls_final-insp_date }</INSP_DATE>| &&
                     |<LENGTH_OS>{ ls_final-length_os }</LENGTH_OS>| &&
                     |<LENGTH_US>{ ls_final-length_us }</LENGTH_US>| &&
                     |<SUM_CHALN_QTY>{ ls_final-sum_chaln_qty }</SUM_CHALN_QTY>| &&
                     |<SUM_ACTUAL_QTY>{ ls_final-sum_actual_qty }</SUM_ACTUAL_QTY>| &&
                     |<SUM_REJ_QTY>{ sum_rejtd_qty }</SUM_REJ_QTY>| &&
                     |<SUM_PO_QTY>{ ls_final-sum_po_qty }</SUM_PO_QTY>| &&
                     |<SUM_SHORT_QTY>{ ls_final-sum_short_qty }</SUM_SHORT_QTY>| &&
                     |<SUM_ACCPT_QTY>{ sum_accptd_qty }</SUM_ACCPT_QTY>| &&
                     |<total_amount_words>{ grand_tot_amt_words }</total_amount_words>| &&
                     |<gst_amt_words>{ gst_tot_amt_words }</gst_amt_words>| &&
                     |<tot_taxble_amt>{ ls_final-sum_taxable_amt }</tot_taxble_amt>| &&
                     |<tot_cgst_amt>{ ls_final-sum_cgst_amt }</tot_cgst_amt>| &&
                     |<tot_sgst_amt>{ ls_final-sum_sgst_amt }</tot_sgst_amt>| &&
                     |<tot_igst_amt>{ ls_final-sum_igst_amt }</tot_igst_amt>| &&
                     |<ItemData>|  ##NO_TEXT.

     DATA : lv_item TYPE string .
     DATA : srn           TYPE c LENGTH 3,
            lv_accptd_qty TYPE c LENGTH 20,
            lv_rejtd_qty  TYPE c LENGTH 20,
            lv_qc_date    TYPE c LENGTH 20.

     CLEAR : lv_item , srn .

     LOOP AT ls_final-grn_item INTO DATA(ls_item).

       srn = srn + 1 .

       REPLACE ALL OCCURRENCES OF '&' IN ls_item-item_name WITH '' ##NO_TEXT .

       lv_accptd_qty = ls_item-accept_qty.
       lv_rejtd_qty  = ls_item-rej_qty.
       CONDENSE lv_accptd_qty.
       CONDENSE lv_rejtd_qty.
       IF lv_accptd_qty EQ '0.00'.
         lv_accptd_qty = ''.
       ENDIF.

       IF lv_rejtd_qty EQ '0.00'.
         lv_rejtd_qty = ''.
       ENDIF.

       lv_qc_date = ls_item-qc_date.
       CONDENSE lv_qc_date.
       IF lv_qc_date EQ '00.00.0000'.
         lv_qc_date = ''.
       ENDIF.

       SHIFT ls_item-item_code LEFT DELETING LEADING '0'.
       lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                 |<SL_NUM>{ srn }</SL_NUM>| &&
                 |<ITEM_CODE>{ ls_item-item_code }</ITEM_CODE>| &&
                 |<ITEM_NAME>{ ls_item-item_name }</ITEM_NAME>| &&
                 |<UNIT>{ ls_item-unit }</UNIT>| &&
                 |<PO_QTY>{ ls_item-po_qty }</PO_QTY>| &&
                 |<CHALN_QTY>{ ls_item-chaln_qty }</CHALN_QTY>| &&
                 |<ACTUAL_QTY>{ ls_item-actual_qty }</ACTUAL_QTY>| &&
                 |<REJ_QTY>{ lv_rejtd_qty }</REJ_QTY>| &&
                 |<SHORT_QTY>{ ls_item-short_qty }</SHORT_QTY>| &&
                 |<ACCEPT_QTY>{ lv_accptd_qty }</ACCEPT_QTY>| &&
                 |<RATE_PER_UNIT>{ ls_item-rate_per_unit }</RATE_PER_UNIT>| &&
                 |<DOSCOUNT>{ ls_item-doscount }</DOSCOUNT>| &&
                 |<AMT_VAL>{ ls_item-amt_val }</AMT_VAL>| &&
                 |<EXCISE_GST>{ ls_item-excise_gst }</EXCISE_GST>| &&
                 |<QC_DATE>{ lv_qc_date }</QC_DATE>| &&
                 |<TOT_VAL>{ ls_item-tot_val }</TOT_VAL>| &&
                 |<hsn_code>{ ls_item-hsn_code }</hsn_code>| &&
                 |<taxable_amt>{ ls_item-taxable_amt }</taxable_amt>| &&
                 |<gst_rate>{ ls_item-gst_rate }</gst_rate>| &&
                 |<cgst_amt>{ ls_item-cgst_amt }</cgst_amt>| &&
                 |<sgst_amt>{ ls_item-sgst_amt }</sgst_amt>| &&
                 |<igst_amt>{ ls_item-igst_amt }</igst_amt>| &&
                 |<batch>{ ls_item-batch }</batch>| &&
                 |<issueloc>{ ls_item-issueloc }</issueloc>| &&
                 |<issuebin>{ ls_item-issuebin }</issuebin>| &&
                 |</ItemDataNode>|  ##NO_TEXT .

     ENDLOOP.

     lv_xml = |{ lv_xml }{ lv_item }| &&
                        |</ItemData>| &&
                        |</MaterialDocumentNode>| &&
                        |</Form>| ##NO_TEXT .

     DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
     iv_xml_base64 = ls_data_xml_64.

   ENDMETHOD.


   METHOD prep_xml_issue_slip_print.

     DATA : heading       TYPE c LENGTH 100,
            sub_heading   TYPE c LENGTH 200,
            lv_xml_final  TYPE string,
            lv_plant_adrs TYPE string.

     READ TABLE it_final INTO DATA(ls_final) INDEX 1.

     heading     = 'DE DIAMOND ELECTRIC INDIA PVT.LTD' ##NO_TEXT.
     sub_heading = 'Material Issue Slip' ##NO_TEXT.

     SELECT SINGLE * FROM zi_plant_address
                     WHERE plant = @ls_final-plant
                     INTO @DATA(ls_plant_adrs). "#EC CI_ALL_FIELDS_NEEDED

     lv_plant_adrs = |{ ls_plant_adrs-Plant } - { ls_plant_adrs-PlantName } |.

     DATA(lv_xml) =  |<Form>| &&
                     |<ReservationDocumentNode>| &&
                     |<heading>{ heading }</heading>| &&
                     |<sub_heading>{ sub_heading }</sub_heading>| &&
                     |<plantadrs1>{ lv_plant_adrs }</plantadrs1>| &&
                     |<resv_num>{ ls_final-requi_num }</resv_num>| &&
                     |<post_date>{ ls_final-post_date }</post_date>| &&
                     |<requi_num>{ ls_final-requi_num }</requi_num>| &&
                     |<req_loc>{ ls_final-req_loc }</req_loc>| &&
                     |<req_person>{ ls_final-req_person }</req_person>| &&
                     |<issue_from>{ ls_final-issue_from }</issue_from>| &&
                     |<issue_person>{ ls_final-issue_person }</issue_person>| &&
                     |<sum_req_qty>{ ls_final-sum_req_qty }</sum_req_qty> | &&
                     |<sum_issue_qty>{ ls_final-sum_issue_qty }</sum_issue_qty>| &&
                     |<sum_pend_qty>{ ls_final-sum_pend_qty }</sum_pend_qty>| &&
                     |<ItemData>| ##NO_TEXT.

     DATA : lv_item TYPE string .
     DATA : srn TYPE c LENGTH 3 .
     CLEAR : lv_item , srn .

     LOOP AT ls_final-issue_itm INTO DATA(ls_item).

       srn = srn + 1 .

       SHIFT ls_item-item_no LEFT DELETING LEADING '0'.
       lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                 |<sl_num>{ srn }</sl_num>| &&
                 |<resv_pos>{ ls_item-resv_pos }</resv_pos>| &&
                 |<postig_date>{ ls_item-postig_date }</postig_date>| &&
                 |<lot_no>{ ls_item-lot_no }</lot_no>| &&
                 |<prododr_num>{ ls_item-prododr_num }</prododr_num>| &&
                 |<batch>{ ls_item-batch }</batch>| &&
                 |<item_no>{ ls_item-item_no }</item_no>| &&
                 |<item_desc>{ ls_item-item_desc }</item_desc>| &&
                 |<req_qty>{ ls_item-req_qty }</req_qty>| &&
                 |<issue_qty>{ ls_item-issue_qty }</issue_qty>| &&
                 |<pend_qty>{ ls_item-pend_qty   }</pend_qty>| &&
                 |</ItemDataNode>|  ##NO_TEXT .

     ENDLOOP.

     lv_xml = |{ lv_xml }{ lv_item }| &&
                        |</ItemData>| &&
                        |</ReservationDocumentNode>| &&
                        |</Form>| ##NO_TEXT .

     DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
     iv_xml_base64 = ls_data_xml_64.
   ENDMETHOD.
ENDCLASS.
