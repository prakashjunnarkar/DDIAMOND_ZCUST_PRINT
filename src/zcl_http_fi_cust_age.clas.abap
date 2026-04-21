CLASS zcl_http_fi_cust_age DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_service_extension .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_HTTP_FI_CUST_AGE IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.

    DATA: im_input_str TYPE string,
          lv_date      TYPE d,
**          lv_date      TYPE d,
          miw_string   TYPE string,
          lv_index     TYPE sy-tabix.

    DATA:lv_selradio   TYPE c LENGTH 50.

    TYPES:
      BEGIN OF gty_customer,
        customer TYPE c LENGTH 10,
      END OF gty_customer.

    DATA:
      gt_customer TYPE TABLE OF gty_customer,
      gs_customer TYPE gty_customer.

    TYPES:
      BEGIN OF gty_companycode,
        companycode TYPE c LENGTH 4,
      END OF gty_companycode.

    DATA:
      gt_companycode TYPE TABLE OF gty_companycode,
      gs_companycode TYPE gty_companycode.

    TYPES: BEGIN OF gty_input,
             keydate     TYPE c LENGTH 10,
**             keydate     LIKE gt_keydate,
             budat_low   TYPE c LENGTH 10, "LIKE gt_budat,
             budat_high  TYPE c LENGTH 10,
             customer    LIKE gt_customer,
             companycode LIKE gt_companycode,
             lv_selradio TYPE c LENGTH 120,
           END OF gty_input.

    TYPES: BEGIN OF ty_sum,

             customer                     TYPE kunnr,
             companycode                  TYPE bukrs,
             accountingdocument           TYPE belnr_d,
             doctype                      TYPE blart,
             customername                 TYPE string,
             profitcenter                 TYPE kostl,
             postingdate                  TYPE budat,
             netduedate                   TYPE budat,
             paymentterms                 TYPE dzterm,
             no_days                      TYPE i,
             amountincompanycodecurrency  TYPE p LENGTH 16 DECIMALS 3, " o/s amount
             amountintransactioncurrency  TYPE p LENGTH 16 DECIMALS 3, "advance amt
             balanceintransactioncurrency TYPE p LENGTH 16 DECIMALS 3, "PDC amt
             balanceincompanycodecurrency TYPE p LENGTH 16 DECIMALS 3, "balance
             cumulative_balance           TYPE p LENGTH 16 DECIMALS 3, "commulative
             days_21_30                   TYPE p LENGTH 16 DECIMALS 3,
             days_31_60                   TYPE p LENGTH 16 DECIMALS 3,
             days_61_90                   TYPE p LENGTH 16 DECIMALS 3,
             days_91_120                  TYPE p LENGTH 16 DECIMALS 3,
             days_121_150                 TYPE p LENGTH 16 DECIMALS 3,
             days_151_180                 TYPE p LENGTH 16 DECIMALS 3,
             days_ge_180                  TYPE p LENGTH 16 DECIMALS 3,

             is_total                     TYPE abap_bool,

           END OF ty_sum.

    DATA: it_sum  TYPE STANDARD TABLE OF ty_sum,
          : it_sum1 TYPE STANDARD TABLE OF ty_sum,
          wa_sum1 TYPE ty_sum.

    DATA: it_final  TYPE STANDARD TABLE OF ty_sum,
          : it_final1 TYPE STANDARD TABLE OF ty_sum,
          ls_final  TYPE ty_sum.

    DATA: lv_advamt TYPE p LENGTH 16 DECIMALS 3.

    DATA:
      lv_b0_30_cust     TYPE p LENGTH 16 DECIMALS 3,
      lv_b31_60_cust    TYPE p LENGTH 16 DECIMALS 3,
      lv_b61_90_cust    TYPE p LENGTH 16 DECIMALS 3,
      lv_b91_120_cust   TYPE p LENGTH 16 DECIMALS 3,
      lv_b121_150_cust  TYPE p LENGTH 16 DECIMALS 3,
      lv_b151_180_cust  TYPE p LENGTH 16 DECIMALS 3,
      lv_b180_ge        TYPE p LENGTH 16 DECIMALS 3,

      lv_b0_30_grand    TYPE p LENGTH 16 DECIMALS 3,
      lv_b31_60_grand   TYPE p LENGTH 16 DECIMALS 3,
      lv_b61_90_grand   TYPE p LENGTH 16 DECIMALS 3,
      lv_b91_120_grand  TYPE p LENGTH 16 DECIMALS 3,
      lv_b121_150_grand TYPE p LENGTH 16 DECIMALS 3,
      lv_b151_180_grand TYPE p LENGTH 16 DECIMALS 3,
      lv_b180_ge_grand  TYPE p LENGTH 16 DECIMALS 3.

    DATA:
      gt_input TYPE TABLE OF gty_input,
      gs_input TYPE gty_input.

    DATA :
      r_budat     TYPE RANGE OF i_operationalacctgdocitem-postingdate,
      rs_budat    LIKE LINE OF  r_budat,

      r_bukrs     TYPE RANGE OF zi_dc_note-companycode,
      rs_bukrs    LIKE LINE OF  r_bukrs,

      r_customer  TYPE RANGE OF i_supplier-customer,
      rs_customer LIKE LINE OF r_customer,

      r_keydate   TYPE RANGE OF i_operationalacctgdocitem-postingdate,
      rs_keydate  LIKE LINE OF r_keydate.

    DATA:
      sys_date     TYPE d,
      sys_time     TYPE t,
      sys_timezone TYPE timezone,
      sy_uname     TYPE c LENGTH 20.


    "Get inbound data
    DATA(lv_request_body) = request->get_text( ).
    im_input_str = lv_request_body.

    sys_date = cl_abap_context_info=>get_system_date( ).
    sys_time = cl_abap_context_info=>get_system_time( ).
    sy_uname = cl_abap_context_info=>get_user_technical_name( ).

    /ui2/cl_json=>deserialize(
      EXPORTING json = im_input_str
         pretty_name = /ui2/cl_json=>pretty_mode-camel_case
         CHANGING data = gt_input
                                 ).

    READ TABLE gt_input INTO gs_input INDEX 1.
    CLEAR: r_budat,r_keydate, r_customer, r_bukrs.

    ""***Preparing range for posting date
    IF gs_input-budat_high IS INITIAL.

      rs_budat-low     = gs_input-budat_low+6(4) && gs_input-budat_low+3(2)  && gs_input-budat_low+0(2).
      rs_budat-high    = '' .
      rs_budat-option  = 'EQ' .
      rs_budat-sign    = 'I' .
      APPEND rs_budat TO r_budat.

    ELSE.

      rs_budat-low     = gs_input-budat_low+6(4) && gs_input-budat_low+3(2)  && gs_input-budat_low+0(2).
      rs_budat-high    = gs_input-budat_high+6(4) && gs_input-budat_high+3(2)  && gs_input-budat_high+0(2).
      rs_budat-option  = 'BT'.
      rs_budat-sign    = 'I'.
      APPEND rs_budat TO r_budat.

    ENDIF.

    ""***Preparing range for customer code
    LOOP AT gs_input-customer INTO DATA(ls_customer).

      rs_customer-low     = ls_customer-customer.
      rs_customer-high    = '' .
      rs_customer-option  = 'EQ' .
      rs_customer-sign    = 'I' .
      APPEND rs_customer TO r_customer.

      CLEAR: ls_customer.
    ENDLOOP.

    ""***Preparing range for customer code

    LOOP AT gs_input-companycode INTO DATA(ls_companycode).

      rs_bukrs-low     = ls_companycode-companycode.
      rs_bukrs-high    = '' .
      rs_bukrs-option  = 'EQ' .
      rs_bukrs-sign    = 'I' .
      APPEND rs_bukrs TO r_bukrs.

      CLEAR: ls_companycode.
    ENDLOOP.

    lv_date = sys_date.

    IF gs_input-keydate IS NOT INITIAL.
      lv_date = gs_input-keydate+6(4) && gs_input-keydate+3(2) && gs_input-keydate+0(2).
    ELSE.
      lv_date = cl_abap_context_info=>get_system_date( ).
    ENDIF.

    SELECT a~customer,                             "#EC CI_NO_TRANSFORM
           a~companycode,
           b~customername,
           a~accountingdocument,
           a~accountingdocumenttype,
           a~specialglcode,
           a~amountincompanycodecurrency,
           a~postingdate,
           a~netduedate,
           a~companycodecurrency,
           a~paymentterms,
           a~profitcenter
      FROM i_operationalacctgdocitem AS a
      LEFT JOIN i_customer AS b
       ON b~customer = a~customer
      WHERE a~customer    IN @r_customer
        AND a~companycode IN @r_bukrs
        AND a~postingdate <= @lv_date
        AND a~financialaccounttype = 'D'
        AND a~clearingjournalentry = ''
        AND a~accountingdocumenttype IN ( 'DG','DR','RV','DZ' )
*        AND a~specialglcode IN ('A','I','W','')
        AND a~specialglcode IN ('A','W','')
        INTO TABLE @DATA(lt_data).

    IF lt_data IS INITIAL.
      RETURN.
    ENDIF.

    SORT lt_data BY companycode customer accountingdocument.
    DELETE lt_data WHERE accountingdocumenttype = 'DZ' AND specialglcode = ''.

    "------------------------------------------------------------
    " 4️⃣ ITEM LEVEL BUTTON
    "------------------------------------------------------------
**    IF gs_input-lv_selradio = 'lineitem'.

      DATA: lv_days    TYPE i,
            lv_balance TYPE p LENGTH 16 DECIMALS 3.

      SORT lt_data BY customer.

      DATA: lv_prev_customer TYPE kunnr,
            ls_cust_total    TYPE ty_sum.

      LOOP AT lt_data INTO DATA(ls_data).

**        IF lv_prev_customer IS NOT INITIAL
**                  AND lv_prev_customer <> ls_data-customer.
**
**          ls_cust_total-customername = 'Customer Total'.
**          ls_cust_total-is_total = abap_true.
**
**          APPEND ls_cust_total TO it_final.
**          CLEAR ls_cust_total.
**
**        ENDIF.

        CLEAR: ls_final, lv_days, lv_balance.

        lv_balance = ls_data-amountincompanycodecurrency.

        ls_final-customer     = |{ ls_data-customer ALPHA = OUT }|.
        ls_final-companycode  = ls_data-companycode.
        ls_final-customername = ls_data-customername.
        ls_final-profitcenter = ls_data-ProfitCenter.
        ls_final-accountingdocument = ls_data-accountingdocument.
        ls_final-doctype      = ls_data-accountingdocumenttype.
        ls_final-postingdate  = ls_data-postingdate.
        ls_final-netduedate   = ls_data-netduedate.
        ls_final-paymentterms = ls_data-paymentterms.

        IF ls_data-accountingdocumenttype = 'DG' OR ls_data-accountingdocumenttype = 'DR' OR ls_data-accountingdocumenttype = 'RV'
           AND ls_data-netduedate IS NOT INITIAL.

          lv_days = lv_date - ls_data-netduedate.
          ls_final-no_days = lv_days.

          IF lv_days <= 30.
            ls_final-days_21_30 = lv_balance.
          ELSEIF lv_days BETWEEN 31 AND 60.
            ls_final-days_31_60 = lv_balance.
          ELSEIF lv_days BETWEEN 61 AND 90.
            ls_final-days_61_90 = lv_balance.
          ELSEIF lv_days BETWEEN 91 AND 120.
            ls_final-days_91_120 = lv_balance.
          ELSEIF lv_days BETWEEN 121 AND 150.
            ls_final-days_121_150 = lv_balance.
          ELSEIF lv_days BETWEEN 151 AND 180.
            ls_final-days_151_180 = lv_balance.
          ELSE.
            ls_final-days_ge_180 = lv_balance.
          ENDIF.

          ls_final-amountincompanycodecurrency = lv_balance.
        ENDIF.

        "Advance
        IF ls_data-specialglcode = 'A'." OR ls_data-specialglcode = 'I'.
          ls_final-amountintransactioncurrency = lv_balance.
        ENDIF.

        "PDC
        IF ls_data-specialglcode = 'W'.
          ls_final-balanceintransactioncurrency = lv_balance.
        ENDIF.

        ls_final-balanceincompanycodecurrency =
              ls_final-amountincompanycodecurrency
            - abs( ls_final-amountintransactioncurrency )
            + ls_final-balanceintransactioncurrency.

        APPEND ls_final TO it_final.
        clear: ls_final.

        "--------------------------------------------------
        " Accumulate Customer Total
        "--------------------------------------------------

**        ls_cust_total-days_21_30      += ls_final-days_21_30.
**        ls_cust_total-days_31_60      += ls_final-days_31_60.
**        ls_cust_total-days_61_90      += ls_final-days_61_90.
**        ls_cust_total-days_91_120     += ls_final-days_91_120.
**        ls_cust_total-days_121_150    += ls_final-days_121_150.
**        ls_cust_total-days_151_180    += ls_final-days_151_180.
**        ls_cust_total-days_ge_180     += ls_final-days_ge_180.
**
**        ls_cust_total-amountincompanycodecurrency += ls_final-amountincompanycodecurrency.
**        ls_cust_total-amountintransactioncurrency += ls_final-amountintransactioncurrency.
**        ls_cust_total-balanceintransactioncurrency += ls_final-balanceintransactioncurrency.
**        ls_cust_total-balanceincompanycodecurrency += ls_final-balanceincompanycodecurrency.
**
**        lv_prev_customer = ls_data-customer.

      ENDLOOP.

**      IF lv_prev_customer IS NOT INITIAL.
**        ls_cust_total-customername = 'Customer Total'.
**        ls_cust_total-is_total = abap_true.
**        APPEND ls_cust_total TO it_final.
**      ENDIF.

***    ELSE.
***
***      "------------------------------------------------------------
***      " 5️⃣ CONSOLIDATED BUTTON (FAST GROUP BY)
***      "------------------------------------------------------------
***
***      LOOP AT lt_data INTO DATA(ls_group)
***        GROUP BY ( customer = ls_group-customer
***                   companycode = ls_group-companycode
***                   customername = ls_group-customername )
***        INTO DATA(group).
***
***        CLEAR ls_final.
***
***        ls_final-customer     = |{ group-customer ALPHA = OUT }|.
***        ls_final-companycode  = group-companycode.
***        ls_final-customername = group-customername.
***
***        LOOP AT GROUP group INTO DATA(member).
***
***          DATA(lv_amt) = member-amountincompanycodecurrency.
***
***          IF member-accountingdocumenttype = 'DG' OR member-accountingdocumenttype = 'DR' OR member-accountingdocumenttype = 'RV'
***             AND member-netduedate IS NOT INITIAL.
***
***            DATA(lv_days2) = lv_date - member-netduedate.
***
***            IF lv_days2 <= 30.
***              ls_final-days_21_30 += lv_amt.
***            ELSEIF lv_days2 BETWEEN 31 AND 60.
***              ls_final-days_31_60 += lv_amt.
***            ELSEIF lv_days2 BETWEEN 61 AND 90.
***              ls_final-days_61_90 += lv_amt.
***            ELSEIF lv_days2 BETWEEN 91 AND 120.
***              ls_final-days_91_120 += lv_amt.
***            ELSEIF lv_days2 BETWEEN 121 AND 150.
***              ls_final-days_121_150 += lv_amt.
***            ELSEIF lv_days2 BETWEEN 151 AND 180.
***              ls_final-days_151_180 += lv_amt.
***            ELSE.
***              ls_final-days_ge_180 += lv_amt.
***            ENDIF.
***
***            ls_final-amountincompanycodecurrency += lv_amt.
***          ENDIF.
***
***          IF member-specialglcode = 'A' OR member-specialglcode = 'I'.
***            ls_final-amountintransactioncurrency += lv_amt.
***          ENDIF.
***
***          IF member-specialglcode = 'W'.
***            ls_final-balanceintransactioncurrency += lv_amt.
***          ENDIF.
***
***        ENDLOOP.
***
***        ls_final-balanceincompanycodecurrency =
***              ls_final-amountincompanycodecurrency
***            - abs( ls_final-amountintransactioncurrency )
***            + ls_final-balanceintransactioncurrency.
***
***        APPEND ls_final TO it_final.
***
***      ENDLOOP.
***
***    ENDIF.

    "------------------------------------------------------------
    " 6️⃣ GRAND TOTAL (COMMON FOR BOTH BUTTONS)
    "------------------------------------------------------------

**    DATA: ls_total TYPE ty_sum.   "Use your final structure type
**
**    CLEAR ls_total.
**
**    ls_total-customer     = ''.
**    ls_total-customername = 'GRAND TOTAL'.
**    ls_total-companycode  = ''.
**    ls_total-is_total = abap_true.
**
**    LOOP AT it_final INTO DATA(ls_sum)
**     WHERE is_total IS INITIAL.   "VERY IMPORTANT.
**
**      ls_total-days_21_30      += ls_sum-days_21_30.
**      ls_total-days_31_60      += ls_sum-days_31_60.
**      ls_total-days_61_90      += ls_sum-days_61_90.
**      ls_total-days_91_120     += ls_sum-days_91_120.
**      ls_total-days_121_150    += ls_sum-days_121_150.
**      ls_total-days_151_180    += ls_sum-days_151_180.
**      ls_total-days_ge_180     += ls_sum-days_ge_180.
**
**      ls_total-amountincompanycodecurrency += ls_sum-amountincompanycodecurrency.
**      ls_total-amountintransactioncurrency += ls_sum-amountintransactioncurrency.
**      ls_total-balanceintransactioncurrency += ls_sum-balanceintransactioncurrency.
**      ls_total-balanceincompanycodecurrency += ls_sum-balanceincompanycodecurrency.
**
**    ENDLOOP.
**
**    APPEND ls_total TO it_final.

    "------------------------------------------------------------
    " 6️⃣ Return JSON
    "------------------------------------------------------------
    DATA(lv_json) = /ui2/cl_json=>serialize(
                      data = it_final
                      pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).

    response->set_text( lv_json ).
  ENDMETHOD.
ENDCLASS.
