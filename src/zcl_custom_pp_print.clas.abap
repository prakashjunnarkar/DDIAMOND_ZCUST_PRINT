CLASS zcl_custom_pp_print DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA:
      gt_final        TYPE TABLE OF zstr_insplot_print_hdr,
      lt_item         TYPE TABLE OF zstr_insplot_print_itm,
      ls_item         TYPE zstr_insplot_print_itm,
      gt_final_prod   TYPE TABLE OF zstr_pp_prod_hdr,
      gt_final_joblot TYPE TABLE OF zstr_pp_joblot_hdr.

    DATA:
      sys_date     TYPE d  , " VALUE cl_abap_context_info ,
      sys_time     TYPE t  , "  VALUE  cl_abap_context_info=>get_system_time( 8,0 ),
      sys_timezone TYPE timezone,
      sy_uname     TYPE c LENGTH 20.

    DATA:
      lv_char10  TYPE c LENGTH 10,
      lv_char12  TYPE c LENGTH 12,
      lv_char120 TYPE c LENGTH 120,
      lv_char4   TYPE c LENGTH 4.

    METHODS:
      get_insplot_data
        IMPORTING
                  im_lotnum       TYPE zi_lot_print_data-inspectionlot
                  im_sel_scr      TYPE zstr_lot_print_sel
        RETURNING VALUE(et_final) LIKE gt_final,

      prep_xml_insplot_print
        IMPORTING
                  it_final             LIKE gt_final
                  iv_action            LIKE lv_char10
        RETURNING VALUE(iv_xml_base64) TYPE string,

      get_production_data
        IMPORTING
                  im_pord              LIKE lv_char12
                  im_plant             LIKE lv_char4
        RETURNING VALUE(et_final_prod) LIKE gt_final_prod,

      prep_xml_prod_print
        IMPORTING
                  it_final             LIKE gt_final_prod
                  iv_action            LIKE lv_char10
        RETURNING VALUE(iv_xml_base64) TYPE string,

      get_joblot_data
        IMPORTING
                  im_pord              LIKE lv_char12
                  im_plant             LIKE lv_char4
        RETURNING VALUE(et_final_prod) LIKE gt_final_joblot,

      prep_xml_joblot_print
        IMPORTING
                  it_final             LIKE gt_final_joblot
                  iv_action            LIKE lv_char10
        RETURNING VALUE(iv_xml_base64) TYPE string.


  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_CUSTOM_PP_PRINT IMPLEMENTATION.


  METHOD get_insplot_data.

    DATA: gt_insplot     TYPE TABLE OF zstr_insplot_print_hdr,
          gs_insplot     TYPE zstr_insplot_print_hdr,
          gt_lotitem     TYPE TABLE OF zstr_insplot_print_itm,
          gs_lotitem     TYPE zstr_insplot_print_itm,
          lv_res_val     TYPE p LENGTH 16 DECIMALS 2,
          lv_val_char    TYPE c LENGTH 40,
          lv_lower_val   TYPE p LENGTH 16 DECIMALS 2, "string,
          lv_upper_val   TYPE p LENGTH 16 DECIMALS 2, "string,
          lv_decimal_val TYPE i,
          lv_qty         TYPE c LENGTH 40.

    sys_date = cl_abap_context_info=>get_system_date( ).
    sys_time = cl_abap_context_info=>get_system_time( ).
    sy_uname = cl_abap_context_info=>get_user_technical_name( ).

    SELECT * FROM zi_insp_lot_rej WHERE inspectionlot = @im_lotnum INTO TABLE @DATA(gt_lot).
    IF gt_lot[] IS NOT INITIAL.

      SELECT
      inspectionlot,
      inspplanoperationinternalid,
      inspectioncharacteristic,
      inspectionmethod,
      inspectionmethodplant,
      inspcharccreatedby,
      inspectionspecification,
      inspectionspecificationunit,
      inspectioncharacteristictext,
      inspspecupperlimit,
      inspspeclowerlimit,
      inspspecdecimalplaces,
      inspspechaslowerlimit,
      inspspechasupperlimit,
      selectedcodeset,
      selectedcodesetplant
      FROM i_inspectioncharacteristic
      FOR ALL ENTRIES IN @gt_lot
      WHERE inspectionlot = @gt_lot-inspectionlot
      INTO TABLE @DATA(gt_lot_spec).               "#EC CI_NO_TRANSFORM

      SELECT
        inspectionlot,
        inspplanoperationinternalid,
        inspectioncharacteristic,
        inspresultvalueinternalid,
        inspectionresultattribute,
        inspresultiteminternalid,
        inspectionsubsetinternalid,
        inspectionresultmeasuredvalue,
        inspresulthasmeasuredvalue,
        inspectionresultoriginalvalue,
        inspectionvaluationresult,
        inspector,
        inspectionstartdate,
        inspectionstarttime,
        inspectionenddate,
        inspectionendtime,
        inspectionnumberofdefects,
        defectclass,
        inspresultnrofaddldcmlsplaces,
        characteristicattributecodegrp,
        characteristicattributecode
        FROM i_inspectionresultvalue
      FOR ALL ENTRIES IN @gt_lot
      WHERE inspectionlot = @gt_lot-inspectionlot
      INTO TABLE @DATA(gt_lot_res).                "#EC CI_NO_TRANSFORM

      SELECT
          inspectionlot,
          inspplanoperationinternalid,
          inspectioncharacteristic,
          inspector,
          inspectionresultstatus,
          inspresultdynmodifvaluation,
          inspectionresultmeanvalue   ,
          inspectionresulthasmeanvalue,
          inspectionresultmaximumvalue,
          inspresulthasmaximumvalue,
          inspectionresultminimumvalue,
          inspresulthasminimumvalue,
          inspectionresultoriginalvalue,
          inspresultvalidvaluesnumber,
          inspresultnmbrofrecordedrslts,
          inspectionresulttext,
          inspectionresulthaslongtext,
          inspectionvaluationresult,
          characteristicattributecode
          FROM i_inspectionresult
        FOR ALL ENTRIES IN @gt_lot
        WHERE inspectionlot = @gt_lot-inspectionlot
        INTO TABLE @DATA(gt_lot_resn).             "#EC CI_NO_TRANSFORM


      SELECT
      inspectionlot,
      inspectionoperation,
      inspectioncharacteristic,
      inspectionspecificationtext
        FROM i_inspectionlotvaluehelp
      FOR ALL ENTRIES IN @gt_lot
      WHERE inspectionlot = @gt_lot-inspectionlot
      INTO TABLE @DATA(gt_lot_help).               "#EC CI_NO_TRANSFORM

      IF gt_lot_spec[] IS  NOT INITIAL.

        SELECT
        inspectionmethod,
        inspectionmethodplant,
        inspectionmethodsearchfield
        FROM i_inspectionmethodversion
        FOR ALL ENTRIES IN @gt_lot_spec
        WHERE inspectionmethod = @gt_lot_spec-inspectionmethod AND
              inspectionmethodplant = @gt_lot_spec-inspectionmethodplant
        INTO TABLE @DATA(gt_lot_ver).              "#EC CI_NO_TRANSFORM

      ENDIF.

    ENDIF.


    ""***Header Data
    READ TABLE gt_lot INTO DATA(ls_lot) INDEX 1.
    IF sy-subrc EQ 0.
      READ TABLE gt_lot_spec INTO DATA(gs_lot_spec) WITH KEY inspectionlot = ls_lot-inspectionlot.
    ENDIF.

    IF ls_lot-inspectionlottype = '01'.
      gs_insplot-header_text        = 'IQC PART INSPECTION REPORT'.
    ELSEIF ls_lot-inspectionlottype = '04'.
      gs_insplot-header_text        = 'FINAL INSPECTION REPORT'.
    ENDIF.
    gs_insplot-part_no          = ls_lot-material. "ManufacturerPartNmbr.
    gs_insplot-part_name        = ls_lot-productdescription.
    gs_insplot-plant            = ls_lot-plant.
    gs_insplot-supplier         = ls_lot-suppliername.

    IF ls_lot-customer IS NOT INITIAL.

      SELECT SINGLE customer,
                    customername
                    FROM i_customer WHERE customer = @ls_lot-customer
                    INTO @DATA(ls_cust).

      gs_insplot-customer         = ls_cust-customername.

    ENDIF.

    gs_insplot-invoice_no       = ls_lot-deliverydocument.

    gs_insplot-date             = ls_lot-insplotcreatedonlocaldate+6(2) && '.'
                                    && ls_lot-insplotcreatedonlocaldate+4(2) && '.'
                                    && ls_lot-insplotcreatedonlocaldate+0(4).

    gs_insplot-sheet            = ''.

*    gs_insplot-r_recvng_insp    = im_sel_scr-r_recvng_insp.
    CLEAR lv_qty.
    lv_qty                      = ls_lot-inspectionlotsamplequantity.
    CONDENSE lv_qty.
    CONCATENATE lv_qty ls_lot-inspectionlotsampleunit INTO gs_insplot-r_recvng_insp
    SEPARATED BY space.
    CONDENSE gs_insplot-r_recvng_insp.
    gs_insplot-r_new_devlmnt    = im_sel_scr-r_new_devlmnt.
    gs_insplot-r_design_chng    = im_sel_scr-r_design_chng.
    gs_insplot-r_tooling_chng   = im_sel_scr-r_tooling_chng.

    gs_insplot-remark           = im_sel_scr-remark.
    CLEAR lv_qty.
    lv_qty                      = ls_lot-inspectionlotquantity.
    CONDENSE lv_qty.
    CONCATENATE lv_qty ls_lot-inspectionlotquantityunit INTO gs_insplot-insp_lot_qty
    SEPARATED BY space.
    IF ls_lot-inspectionlotusagedecisioncode = 'R1'.
      gs_insplot-rejected         = ls_lot-inspectionlotusagedecisioncode.
    ELSEIF ls_lot-inspectionlotusagedecisioncode = 'A1'.
      gs_insplot-accepted        = ls_lot-inspectionlotusagedecisioncode.
    ELSEIF ls_lot-inspectionlotusagedecisioncode = 'A2'.
      gs_insplot-cond_acceptd     = ls_lot-inspectionlotusagedecisioncode.
    ELSEIF ls_lot-inspectionlotusagedecisioncode = 'A3'.
      gs_insplot-cond_acceptd     = ls_lot-inspectionlotusagedecisioncode.
    ELSEIF ls_lot-inspectionlotusagedecisioncode = 'A4'.
      gs_insplot-cond_acceptd     = ls_lot-inspectionlotusagedecisioncode.
    ENDIF.

*    SELECT SINGLE
*    UserID,
*    FullName
*    FROM I_Userdetails WHERE UserID = @gs_lot_spec-InspCharcCreatedBy
*    INTO @DATA(ls_user).

    gs_insplot-inspected_by     = gs_lot_spec-inspcharccreatedby.
    SELECT SINGLE userid , userdescription  FROM zi_user
                    WHERE userid = @gs_lot_spec-inspcharccreatedby
                    INTO @DATA(ls_user_req).
    IF sy-subrc EQ 0.
      gs_insplot-inspected_by     = ls_user_req-userdescription.
    ENDIF.

    gs_insplot-approved_by      = ls_lot-inspectionlotusagedecidedby.
    IF ls_lot-inspectionlottype = '01' ##NO_TEXT.
      gs_insplot-approved_by      = '' ##NO_TEXT.
    ELSEIF ls_lot-inspectionlottype = '04' ##NO_TEXT.
      gs_insplot-approved_by      = '' ##NO_TEXT.
    ENDIF.

    gs_insplot-insp_lot_no      = ls_lot-inspectionlot.
    gs_insplot-batch_no         = ls_lot-batch.
    gs_insplot-grn_no           = ls_lot-materialdocument.
    IF ls_lot-inspectionlottype = '01'.
      gs_insplot-doc_no        = 'OEL/IQC/ALL/C/F/05'.
    ELSEIF ls_lot-inspectionlottype = '04'.
      gs_insplot-doc_no        = 'OEL/OQC/ASM/C/F/18'.
    ENDIF.
    gs_insplot-issue_date    = '01/01-01-2021'.
    gs_insplot-rev_date      = '02/20-01-2025'.
    READ TABLE gt_lot_res INTO DATA(wa_lot_res) INDEX 1. "#EC CI_NOORDER
    gs_insplot-inspect_date  = wa_lot_res-inspectionenddate+6(2) && '.' && wa_lot_res-inspectionenddate+4(2)
                               && '.' && wa_lot_res-inspectionenddate+0(4).
    gs_insplot-hold_by       = ''.
    gs_insplot-verified_by   = ''.


    """Item Data
    CLEAR: gs_lot_spec.
    LOOP AT gt_lot_spec INTO gs_lot_spec.

      DATA: lv_decfloat TYPE decfloat34.
      TYPES lv_char8 TYPE c LENGTH 8.

      gs_lotitem-sr_num           = gs_lot_spec-inspectioncharacteristic.
      gs_lotitem-characteristics  = gs_lot_spec-inspectioncharacteristictext."gs_lot_spec-InspectionCharacteristic.


      READ TABLE gt_lot_help INTO DATA(gs_lot_help) WITH KEY
                                  inspectionlot             = gs_lot_spec-inspectionlot
                                  inspectioncharacteristic  = gs_lot_spec-inspectioncharacteristic.
*      IF sy-subrc EQ 0.
*        gs_lotitem-specification    = gs_lot_help-InspectionSpecificationText.
*      ENDIF.

      lv_decfloat = gs_lot_spec-inspspeclowerlimit.
      DATA(lv_character) = CONV lv_char8( CONV string( lv_decfloat ) ).
      lv_lower_val  = lv_character.
*      lv_lower_val      = gs_lot_spec-InspSpecLowerLimit.
      CLEAR : lv_decfloat, lv_character.
      lv_decfloat = gs_lot_spec-inspspecupperlimit.
      lv_character = CONV lv_char8( CONV string( lv_decfloat ) ).
      lv_upper_val  = lv_character.
*      lv_upper_val      = gs_lot_spec-InspSpecUpperLimit.
      lv_decimal_val    = gs_lot_spec-inspspecdecimalplaces.
*      CONDENSE: lv_lower_val, lv_upper_val.

*      gs_lotitem-specification    = |{ lv_lower_val+0(lv_decimal_val) } / { lv_upper_val+0(lv_decimal_val) }|.
      gs_lotitem-specification    = |{ lv_lower_val } ~ { lv_upper_val } { gs_lot_spec-inspectionspecificationunit }|.

      IF gs_lot_spec-inspspechaslowerlimit IS INITIAL AND gs_lot_spec-inspspechasupperlimit IS INITIAL.
*        gs_lotitem-specification    = 'Quality lnspection Result' ##NO_TEXT.
        SELECT SINGLE selectedcodesettext FROM i_charcattribselectedcodeset
                                          WHERE selectedcodesetplant = @gs_lot_spec-selectedcodesetplant
                                          AND   selectedcodeset       = @gs_lot_spec-selectedcodeset
                                          INTO @gs_lotitem-specification.
      ENDIF.

      READ TABLE gt_lot_ver INTO DATA(gs_lot_ver) WITH KEY
                                 inspectionmethod      = gs_lot_spec-inspectionmethod
                                 inspectionmethodplant = gs_lot_spec-inspectionmethodplant.
      IF sy-subrc EQ 0.
        gs_lotitem-method_of_insp   = gs_lot_ver-inspectionmethodsearchfield.
      ENDIF.

      DATA(lt_lot_res) = gt_lot_res[].
      DELETE lt_lot_res WHERE inspplanoperationinternalid NE gs_lot_spec-inspplanoperationinternalid.
      DELETE lt_lot_res WHERE inspectioncharacteristic NE gs_lot_spec-inspectioncharacteristic.

      DATA: l_decfloat TYPE decfloat34.
      TYPES ty_char8 TYPE c LENGTH 8.

      SORT lt_lot_res BY inspectionstartdate inspectionstarttime DESCENDING.
      LOOP AT lt_lot_res INTO DATA(ls_lot_res).

        l_decfloat = ls_lot_res-inspectionresultmeasuredvalue.
        DATA(l_character) = CONV ty_char8( CONV string( l_decfloat ) ).
        lv_res_val  = l_character.
        lv_val_char = lv_res_val.
        CONDENSE lv_val_char.

        IF lv_val_char = '0.00' OR lv_val_char IS INITIAL.
          CLEAR lv_val_char.
          SELECT SINGLE characteristicattributecodetxt FROM i_charcattributecode
          WHERE characteristicattributecodegrp = @ls_lot_res-characteristicattributecodegrp
          AND   characteristicattributecode    = @ls_lot_res-characteristicattributecode
          INTO @lv_val_char.
        ENDIF.

        IF sy-tabix EQ 1.
          gs_lotitem-insp_1           = lv_val_char.
        ELSEIF sy-tabix EQ 2.
          gs_lotitem-insp_2           = lv_val_char.
        ELSEIF sy-tabix EQ 3.
          gs_lotitem-insp_3           = lv_val_char.
        ELSEIF sy-tabix EQ 4.
          gs_lotitem-insp_4           = lv_val_char.
        ELSEIF sy-tabix EQ 5.
          gs_lotitem-insp_5           = lv_val_char.
        ELSEIF sy-tabix EQ 6.
          gs_lotitem-insp_6           = lv_val_char.
        ELSEIF sy-tabix EQ 7.
          gs_lotitem-insp_7           = lv_val_char.
        ELSEIF sy-tabix EQ 8.
          gs_lotitem-insp_8           = lv_val_char.
        ELSEIF sy-tabix EQ 9.
          gs_lotitem-insp_9           = lv_val_char.
        ELSEIF sy-tabix EQ 10.
          gs_lotitem-insp_10          = lv_val_char.
        ENDIF.

        gs_lotitem-insp_remark = ''.

        CLEAR: ls_lot_res, lv_val_char.
      ENDLOOP.

      READ TABLE gt_lot_resn INTO DATA(gs_lot_resn) WITH KEY
                                  inspectionlot               = gs_lot_spec-inspectionlot
                                  inspplanoperationinternalid = gs_lot_spec-inspplanoperationinternalid
                                  inspectioncharacteristic    = gs_lot_spec-inspectioncharacteristic.

      IF sy-subrc EQ 0 AND gs_lot_resn-inspectionvaluationresult   = 'R'.
        gs_lotitem-disposition      = ''.
      ELSEIF gs_lot_resn-inspectionvaluationresult   = 'A'.
        gs_lotitem-disposition      = ''.
      ENDIF.

      CLEAR: gs_lot_resn.
      READ TABLE gt_lot_resn INTO gs_lot_resn WITH KEY
                                  inspectionlot               = gs_lot_spec-inspectionlot
                                  inspplanoperationinternalid = gs_lot_spec-inspplanoperationinternalid
                                  inspectioncharacteristic    =  gs_lot_spec-inspectioncharacteristic
                                  characteristicattributecode = '01'.
      IF sy-subrc EQ 0.
        gs_lotitem-insp_1           = 'OK'.
        gs_lotitem-insp_2           = 'OK'.
        gs_lotitem-insp_3           = 'OK'.
        gs_lotitem-insp_4           = 'OK'.
        gs_lotitem-insp_5           = 'OK'.
      ENDIF.

      APPEND gs_lotitem TO gt_lotitem.
      CLEAR: gs_lot_spec, lt_lot_res, gs_lot_resn, gs_lot_help, gs_lot_ver.
    ENDLOOP.

    INSERT LINES OF gt_lotitem INTO TABLE gs_insplot-lot_item.
    APPEND gs_insplot TO gt_insplot.

    et_final[] = gt_insplot[].

  ENDMETHOD.


  METHOD get_production_data.

    DATA: gt_prodhdr  TYPE TABLE OF zstr_pp_prod_hdr,
          gs_prodhdr  TYPE zstr_pp_prod_hdr,
          gt_proditem TYPE TABLE OF zstr_pp_prod_itm,
          gs_proditem TYPE zstr_pp_prod_itm.

    sys_date = cl_abap_context_info=>get_system_date( ).
    sys_time = cl_abap_context_info=>get_system_time( ).
    sy_uname = cl_abap_context_info=>get_user_technical_name( ).

*    data lv_char12 type c LENGTH 12.
*    CONCATENATE '00' im_pord into lv_char12.

    SELECT manufacturingorder,
           mfgorderplannedreleasedate,
           creationdate,
           storagelocation,
           product,
           material,
           manufacturingordertext,
           productionplant,
           mfgorderplannedstartdate,
           mfgorderplannedenddate,
           mfgorderplannedtotalqty
           FROM i_manufacturingorder
           WHERE manufacturingorder EQ @im_pord
*           AND   ProductionPlant EQ @im_plant
           INTO TABLE @DATA(it_prod_hdr).          "#EC CI_NO_TRANSFORM

    IF it_prod_hdr IS NOT INITIAL.

      SELECT manufacturingorder,
             plant,
             material,
             matlcompistextitem,
             baseunit,
             requiredquantity
             FROM i_mfgorderoperationcomponent
             FOR ALL ENTRIES IN @it_prod_hdr
             WHERE manufacturingorder = @it_prod_hdr-manufacturingorder
             AND   plant              = @it_prod_hdr-productionplant
             INTO TABLE @DATA(it_prod_itm).        "#EC CI_NO_TRANSFORM

    ENDIF.


*    ""Header data
    READ TABLE it_prod_hdr INTO DATA(wa_prod_hdr) INDEX 1. "#EC CI_NOORDER
    IF sy-subrc = 0.
      READ TABLE it_prod_itm INTO DATA(wa_prod_itm) INDEX 1. "#EC CI_NOORDER
      SELECT SINGLE * FROM zi_plant_address WHERE plant EQ @wa_prod_itm-plant INTO @DATA(wa_plant_adrs).

      gs_prodhdr-production_order = wa_prod_hdr-manufacturingorder.
      gs_prodhdr-plant            = wa_prod_hdr-productionplant.
      gs_prodhdr-plant_name       = wa_plant_adrs-plantname.
      gs_prodhdr-plant_adr1       = wa_plant_adrs-streetname.
      gs_prodhdr-plant_adr2       = wa_plant_adrs-cityname && ',' && wa_plant_adrs-regionname && '-' && wa_plant_adrs-postalcode.
      gs_prodhdr-voucher_no       = ''.
      gs_prodhdr-voucher_date     = wa_prod_hdr-creationdate+6(2) && '.' &&
                                    wa_prod_hdr-creationdate+4(2) && '.' &&
                                    wa_prod_hdr-creationdate+0(4).
      gs_prodhdr-godown           = wa_prod_hdr-storagelocation.
      gs_prodhdr-prod_line        = wa_prod_hdr-storagelocation.
      gs_prodhdr-prod_start_date  = wa_prod_hdr-mfgorderplannedstartdate+6(2) && '.' &&
                                    wa_prod_hdr-mfgorderplannedstartdate+4(2) && '.' &&
                                    wa_prod_hdr-mfgorderplannedstartdate+0(4).
      gs_prodhdr-prod_end_date    = wa_prod_hdr-mfgorderplannedenddate+6(2) && '.' &&
                                    wa_prod_hdr-mfgorderplannedenddate+4(2) && '.' &&
                                    wa_prod_hdr-mfgorderplannedenddate+0(4).
      gs_prodhdr-parent_prod      = wa_prod_hdr-manufacturingorder.
      SHIFT gs_prodhdr-parent_prod LEFT DELETING LEADING '0'.
      gs_prodhdr-plan_now         = wa_prod_hdr-mfgorderplannedtotalqty.
      gs_prodhdr-target_qty       = wa_prod_hdr-mfgorderplannedtotalqty.
      gs_prodhdr-bom              = wa_prod_hdr-material.
      SELECT SINGLE productdescription FROM i_productdescription WHERE product EQ @wa_prod_hdr-material
      AND language EQ @sy-langu INTO @gs_prodhdr-finish_item.
      gs_prodhdr-total_qty        = ''.
      gs_prodhdr-prepared_by      = ''.
      gs_prodhdr-checked_by       = ''.
      gs_prodhdr-authorised_by    = ''.

* "" Item Details
      CLEAR wa_prod_itm.
      LOOP AT it_prod_itm INTO wa_prod_itm WHERE manufacturingorder EQ wa_prod_hdr-manufacturingorder.
        gs_proditem-item_code = wa_prod_itm-material.
        gs_proditem-item_name = wa_prod_itm-matlcompistextitem.
        SELECT SINGLE productdescription FROM i_productdescription WHERE product EQ @wa_prod_itm-material
        AND language EQ @sy-langu INTO @gs_proditem-item_desc.
        gs_proditem-item_unit = wa_prod_itm-baseunit.
        gs_proditem-item_qty  = wa_prod_itm-requiredquantity.
        gs_prodhdr-total_qty  = gs_prodhdr-total_qty + gs_proditem-item_qty.
        APPEND gs_proditem TO gt_proditem.
        CLEAR: wa_prod_itm, gs_proditem.
      ENDLOOP.

      INSERT LINES OF gt_proditem INTO TABLE gs_prodhdr-prod_item.
      APPEND gs_prodhdr TO gt_prodhdr.

      et_final_prod[] = gt_prodhdr[].
    ENDIF.




  ENDMETHOD.


  METHOD get_joblot_data.

    DATA: gt_joblothdr  TYPE TABLE OF zstr_pp_joblot_hdr,
          gs_joblothdr  TYPE zstr_pp_joblot_hdr,
          gt_joblotitem TYPE TABLE OF zstr_pp_joblot_itm,
          gs_joblotitem TYPE zstr_pp_joblot_itm.

    DATA:         lv_compname    TYPE c LENGTH 40.
    DATA:         lv_comp        TYPE c LENGTH 18.

    sys_date = cl_abap_context_info=>get_system_date( ).
    sys_time = cl_abap_context_info=>get_system_time( ).
    sy_uname = cl_abap_context_info=>get_user_technical_name( ).

    SELECT DISTINCT
    orderheader~productionorder,
    orderheader~productionordertype,
    orderheader~creationdate,
    orderheader~ismarkedfordeletion,
    item~product,
    item~plannedyieldquantity,
    materialtext~productname
    FROM i_productionorder AS orderheader
    INNER JOIN i_productionorderitem AS item
    ON orderheader~productionorder = item~productionorder
    LEFT OUTER JOIN i_producttext AS materialtext
    ON  item~product = materialtext~product
    AND materialtext~language = 'E'
    WHERE orderheader~productionorder = @im_pord
    AND orderheader~ismarkedfordeletion <> 'X'
    ORDER BY orderheader~productionorder
    INTO TABLE @DATA(it_hdr1).

    IF it_hdr1 IS NOT INITIAL.

      SELECT
      component~productionorder,
      component~material AS componentmaterial,
      comptext~productname AS compdescription
      FROM i_productionordercomponent AS component
      LEFT OUTER JOIN i_producttext AS comptext
      ON  component~material = comptext~product
      AND comptext~language = 'E'
      WHERE component~productionorder = @im_pord
      ORDER BY component~material
      INTO TABLE @DATA(it_component).

      SELECT
      operation~productionorderoperationtext AS operationdescription,
      workcentertext~workcentertext          AS workcenterdescription,
      workcenter~workcenter
      FROM i_productionorderoperation_2  AS operation
      LEFT OUTER JOIN i_workcenter                       AS workcenter
      ON  operation~workcenterinternalid = workcenter~workcenterinternalid
      LEFT OUTER JOIN i_workcentertext                   AS workcentertext
      ON  workcentertext~workcenterinternalid = workcenter~workcenterinternalid
      AND  workcentertext~language = 'E'
    WHERE operation~productionorder = @im_pord
     ORDER BY operation~productionorderoperation
    INTO TABLE @DATA(it_opr).

    ENDIF.

    READ TABLE it_hdr1 INTO DATA(wa_hdr) INDEX 1.       "#EC CI_NOORDER
    IF sy-subrc EQ 0.
      gs_joblothdr-part_no = wa_hdr-product.
      gs_joblothdr-part_name = wa_hdr-productname.
      gs_joblothdr-lot_no = wa_hdr-productionorder.
      gs_joblothdr-lot_no = |{ gs_joblothdr-lot_no ALPHA = OUT }|.
      gs_joblothdr-lot_qty = wa_hdr-plannedyieldquantity.
      gs_joblothdr-plan_date = wa_hdr-creationdate+6(2) && '.' && wa_hdr-creationdate+4(2) && '.' &&  wa_hdr-creationdate+0(4).
    ENDIF.

    DATA(lv_idx) = 1.
    DATA(lv_idxx) = 1.

    LOOP AT it_component INTO DATA(wa_componenet) FROM 1 TO 12.
      CASE lv_idx.
        WHEN 1.
          gs_joblotitem-rm1 = wa_componenet-componentmaterial.
          gs_joblotitem-rm_name1 = wa_componenet-compdescription.
        WHEN 2.
          gs_joblotitem-rm2 = wa_componenet-componentmaterial.
          gs_joblotitem-rm_name2 = wa_componenet-compdescription.
        WHEN 3.
          gs_joblotitem-rm3 = wa_componenet-componentmaterial.
          gs_joblotitem-rm_name3 = wa_componenet-compdescription.
        WHEN 4.
          gs_joblotitem-rm4 = wa_componenet-componentmaterial.
          gs_joblotitem-rm_name4 = wa_componenet-compdescription.
        WHEN 5.
          gs_joblotitem-rm5 = wa_componenet-componentmaterial.
          gs_joblotitem-rm_name5 = wa_componenet-compdescription.
        WHEN 6.
          gs_joblotitem-rm6 = wa_componenet-componentmaterial.
          gs_joblotitem-rm_name6 = wa_componenet-compdescription.
        WHEN 7.
          gs_joblotitem-rm7 = wa_componenet-componentmaterial.
          gs_joblotitem-rm_name7 = wa_componenet-compdescription.
        WHEN 8.
          gs_joblotitem-rm8 = wa_componenet-componentmaterial.
          gs_joblotitem-rm_name8 = wa_componenet-compdescription.
        WHEN 9.
          gs_joblotitem-rm9 = wa_componenet-componentmaterial.
          gs_joblotitem-rm_name9 = wa_componenet-compdescription.
        WHEN 10.
          gs_joblotitem-rm10 = wa_componenet-componentmaterial.
          gs_joblotitem-rm_name10 = wa_componenet-compdescription.
        WHEN 11.
          gs_joblotitem-rm11 = wa_componenet-componentmaterial.
          gs_joblotitem-rm_name11 = wa_componenet-compdescription.
        WHEN 12.
          gs_joblotitem-rm12 = wa_componenet-componentmaterial.
          gs_joblotitem-rm_name12 = wa_componenet-compdescription.
          " continue till 12
      ENDCASE.
      lv_idx += 1.
    ENDLOOP.

    LOOP AT it_opr INTO DATA(wa_opr) FROM 1 TO 9.
      CASE lv_idxx.
        WHEN 1.
          gs_joblotitem-process1      = wa_opr-operationdescription .
          gs_joblotitem-opr1          = wa_opr-workcenter.
        WHEN 2.
          gs_joblotitem-process2      =  wa_opr-operationdescription .
          gs_joblotitem-opr2          =  wa_opr-workcenter.
        WHEN 3.
          gs_joblotitem-process3      =  wa_opr-operationdescription .
          gs_joblotitem-opr3          =  wa_opr-workcenter.
        WHEN 4.
          gs_joblotitem-process4      =  wa_opr-operationdescription .
          gs_joblotitem-opr4          =  wa_opr-workcenter.
        WHEN 5.
          gs_joblotitem-process5      =  wa_opr-operationdescription .
          gs_joblotitem-opr5          =  wa_opr-workcenter.
        WHEN 6.
          gs_joblotitem-process6      =  wa_opr-operationdescription .
          gs_joblotitem-opr6          =  wa_opr-workcenter.
        WHEN 7.
          gs_joblotitem-process7      =  wa_opr-operationdescription .
          gs_joblotitem-opr7          =  wa_opr-workcenter.
        WHEN 8.
          gs_joblotitem-process8      =  wa_opr-operationdescription .
          gs_joblotitem-opr8         =  wa_opr-workcenter.
        WHEN 9.
          gs_joblotitem-process9     =  wa_opr-operationdescription .
          gs_joblotitem-opr9          =  wa_opr-workcenter.
      ENDCASE.
      lv_idxx += 1.
    ENDLOOP.

    APPEND gs_joblotitem TO gt_joblotitem.
**    CLEAR: wa_componenet.

    INSERT LINES OF gt_joblotitem INTO TABLE gs_joblothdr-prod_item.
    APPEND gs_joblothdr TO gt_joblothdr.

    et_final_prod[] = gt_joblothdr[].


  ENDMETHOD.


  METHOD prep_xml_insplot_print.

    DATA : heading      TYPE c LENGTH 100,
           sub_heading  TYPE c LENGTH 200,
           lv_xml_final TYPE string.

    READ TABLE it_final INTO DATA(ls_final) INDEX 1.
    "REPLACE ALL OCCURRENCES OF '&' IN ls_final-suppl_name WITH 'AND' ##NO_TEXT .
    SHIFT ls_final-insp_lot_qty LEFT DELETING LEADING ''.

*    ls_final-header_text = 'IQC PART INSPECTION REPORT'.
    heading = 'OPTIEMUS ELECTRONICS LTD' ##NO_TEXT.
    sub_heading = 'K-20, Second Floor, Lajpat Nagar-II, New Delhi – 110024' ##NO_TEXT.

    DATA(lv_xml) =  |<Form>| &&
                    |<InspectionNode>| &&
                    |<header>{ heading }</header>| &&
                    |<sub_header>{ sub_heading }</sub_header>| &&
                    |<header_text>{ ls_final-header_text }</header_text>| &&
                    |<part_no>{ ls_final-part_no }</part_no>| &&
                    |<part_name>{ ls_final-part_name }</part_name>| &&
                    |<plant>{ ls_final-plant  }</plant>| &&
                    |<supplier>{ ls_final-supplier }</supplier>| &&
                    |<customer>{ ls_final-customer }</customer>| &&
                    |<invoice_no>{ ls_final-invoice_no }</invoice_no>| &&
                    |<date>{ ls_final-date }</date>| &&
                    |<sheet>{ ls_final-sheet }</sheet>| &&
                    |<r_recvng_insp>{ ls_final-r_recvng_insp }</r_recvng_insp>| &&
                    |<r_new_devlmnt>{ ls_final-r_new_devlmnt }</r_new_devlmnt>| &&
                    |<r_design_chng>{ ls_final-r_design_chng }</r_design_chng>| &&
                    |<r_tooling_chng>{ ls_final-r_tooling_chng }</r_tooling_chng>| &&
                    |<insp_lot_qty>{ ls_final-insp_lot_qty }</insp_lot_qty>| &&
                    |<remark>{ ls_final-remark }</remark>| &&
                    |<accepted>{ ls_final-accepted }</accepted>| &&
                    |<rejected>{ ls_final-rejected }</rejected>| &&
                    |<Cond_accepted>{ ls_final-cond_acceptd }</Cond_accepted>| &&
                    |<inspected_by>{ ls_final-inspected_by }</inspected_by>| &&
                    |<approved_by>{ ls_final-approved_by }</approved_by>| &&
                    |<insp_lot_no>{ ls_final-insp_lot_no }</insp_lot_no>| &&
                    |<batch_no>{ ls_final-batch_no }</batch_no>| &&
                    |<grn_no>{ ls_final-grn_no }</grn_no>| &&
                    |<doc_no>{ ls_final-doc_no }</doc_no>| &&
                    |<issue_date>{ ls_final-issue_date }</issue_date>| &&
                    |<rev_date>{ ls_final-rev_date }</rev_date>| &&
                    |<inspect_date>{ ls_final-inspect_date }</inspect_date>| &&
                    |<hold_by>{ ls_final-hold_by }</hold_by>| &&
                    |<verified_by>{ ls_final-verified_by }</verified_by>| &&
                    |<ItemData>|  ##NO_TEXT.

    DATA : lv_item TYPE string .
    DATA : srn TYPE c LENGTH 3 .
    CLEAR : lv_item , srn .

    LOOP AT ls_final-lot_item INTO DATA(ls_item).

      srn = srn + 1 .

      lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                |<sr_num>{ srn }</sr_num>| &&
                |<characteristics>{ ls_item-characteristics }</characteristics>| &&
                |<specification>{ ls_item-specification }</specification>| &&
                |<method_of_insp>{ ls_item-method_of_insp }</method_of_insp>| &&
                |<insp_1>{ ls_item-insp_1 }</insp_1>| &&
                |<insp_2>{ ls_item-insp_2 }</insp_2>| &&
                |<insp_3>{ ls_item-insp_3 }</insp_3>| &&
                |<insp_4>{ ls_item-insp_4 }</insp_4>| &&
                |<insp_5>{ ls_item-insp_5 }</insp_5>| &&
                |<insp_6>{ ls_item-insp_6 }</insp_6>| &&
                |<insp_7>{ ls_item-insp_7 }</insp_7>| &&
                |<insp_8>{ ls_item-insp_8 }</insp_8>| &&
                |<insp_9>{ ls_item-insp_9 }</insp_9>| &&
                |<insp_10>{ ls_item-insp_10 }</insp_10>| &&
                |<insp_remark>{ ls_item-insp_remark }</insp_remark>| &&
                |<disposition>{ ls_item-disposition }</disposition>| &&
                |</ItemDataNode>|  ##NO_TEXT .

    ENDLOOP.

    lv_xml = |{ lv_xml }{ lv_item }| &&
                       |</ItemData>| &&
                       |</InspectionNode>| &&
                       |</Form>| ##NO_TEXT .

    DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
    iv_xml_base64 = ls_data_xml_64.

  ENDMETHOD.


  METHOD prep_xml_prod_print.

    DATA : sub_heading TYPE c LENGTH 100.

    READ TABLE it_final INTO DATA(ls_final) INDEX 1.

    sub_heading = 'Daily Production Order-Assembly Voucher' ##NO_TEXT.

    DATA(lv_xml) =  |<Form>| &&
                    |<ProductionOrderNode>| &&
                    |<header1>{ ls_final-plant_name }</header1>| &&
                    |<header2>{ sub_heading }</header2>| &&
                    |<plant_adr1>{ ls_final-plant_adr1 }</plant_adr1>| &&
                    |<plant_adr2>{ ls_final-plant_adr2 }</plant_adr2>| &&
                    |<voucher_no>{ ls_final-voucher_no }</voucher_no>| &&
                    |<voucher_date>{ ls_final-voucher_date  }</voucher_date>| &&
                    |<godown>{ ls_final-godown }</godown>| &&
                    |<prod_line>{ ls_final-prod_line }</prod_line>| &&
                    |<prod_start_date>{ ls_final-prod_start_date }</prod_start_date>| &&
                    |<prod_end_date>{ ls_final-prod_end_date }</prod_end_date>| &&
                    |<parent_prod_order>{ ls_final-parent_prod }</parent_prod_order>| &&
                    |<plan_now>{ ls_final-plan_now }</plan_now>| &&
                    |<target_qty>{ ls_final-target_qty }</target_qty>| &&
                    |<bom_item>{ ls_final-bom }</bom_item>| &&
                    |<finish_item>{ ls_final-finish_item }</finish_item>| &&
                    |<total_qty>{ ls_final-total_qty }</total_qty>| &&
                    |<prepared_by>{ ls_final-prepared_by }</prepared_by>| &&
                    |<checked_by>{ ls_final-checked_by }</checked_by>| &&
                    |<authorised_by>{ ls_final-authorised_by }</authorised_by>| &&
                    |<ItemData>|  ##NO_TEXT.

    DATA : lv_item TYPE string .
    DATA : srn TYPE c LENGTH 3 .
    CLEAR : lv_item , srn .

    LOOP AT ls_final-prod_item INTO DATA(ls_item).

      srn = srn + 1 .

      lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                |<sl_num>{ srn }</sl_num>| &&
                |<item_code>{ ls_item-item_code }</item_code>| &&
                |<item_name>{ ls_item-item_name }</item_name>| &&
                |<item_desc>{ ls_item-item_desc }</item_desc>| &&
                |<item_unit>{ ls_item-item_unit }</item_unit>| &&
                |<item_qty>{ ls_item-item_qty }</item_qty>| &&
                |</ItemDataNode>|  ##NO_TEXT .

    ENDLOOP.

    lv_xml = |{ lv_xml }{ lv_item }| &&
                       |</ItemData>| &&
                       |</ProductionOrderNode>| &&
                       |</Form>| ##NO_TEXT .

    DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
    iv_xml_base64 = ls_data_xml_64.
  ENDMETHOD.


  METHOD prep_xml_joblot_print.

    DATA : sub_heading TYPE c LENGTH 100.

    READ TABLE it_final INTO DATA(ls_final) INDEX 1.

    sub_heading = 'LOT CARD' ##NO_TEXT.

    DATA(lv_xml) =  |<Form>| &&
                    |<ProductionOrderNode>| &&
                    |<partno>{ ls_final-part_no }</partno>| &&
                    |<partname>{ ls_final-part_name }</partname>| &&
                    |<productionplandate>{ ls_final-plan_date }</productionplandate>| &&
                    |<lotno>{ ls_final-lot_no }</lotno>| &&
                    |<lotqty>{ ls_final-lot_qty }</lotqty>| &&
                    |<qrcode>{ ls_final-lot_no }</qrcode>| &&
                    |<division>{ '' } </division>| &&
                    |<divisionqty>{ '' } </divisionqty>| &&
                    |<ItemData>|  ##NO_TEXT.

    DATA : lv_item TYPE string .
    DATA : srn TYPE c LENGTH 3 .
    CLEAR : lv_item , srn .

    LOOP AT ls_final-prod_item INTO DATA(ls_item).

      REPLACE ALL OCCURRENCES OF '&' IN ls_item-process1 WITH '&amp;'.
      REPLACE ALL OCCURRENCES OF '&' IN ls_item-process2 WITH '&amp;'.
      REPLACE ALL OCCURRENCES OF '&' IN ls_item-process3 WITH '&amp;'.
      REPLACE ALL OCCURRENCES OF '&' IN ls_item-process4 WITH '&amp;'.
      REPLACE ALL OCCURRENCES OF '&' IN ls_item-process5 WITH '&amp;'.
      REPLACE ALL OCCURRENCES OF '&' IN ls_item-process6 WITH '&amp;'.
      REPLACE ALL OCCURRENCES OF '&' IN ls_item-process7 WITH '&amp;'.
      REPLACE ALL OCCURRENCES OF '&' IN ls_item-process8 WITH '&amp;'.
      REPLACE ALL OCCURRENCES OF '&' IN ls_item-process9 WITH '&amp;'.
      REPLACE ALL OCCURRENCES OF '<' IN ls_item-process1  WITH '&lt;'.
      REPLACE ALL OCCURRENCES OF '<' IN ls_item-process2  WITH '&lt;'.
      REPLACE ALL OCCURRENCES OF '<' IN ls_item-process3  WITH '&lt;'.
      REPLACE ALL OCCURRENCES OF '<' IN ls_item-process4  WITH '&lt;'.
      REPLACE ALL OCCURRENCES OF '<' IN ls_item-process5  WITH '&lt;'.
      REPLACE ALL OCCURRENCES OF '<' IN ls_item-process6  WITH '&lt;'.
      REPLACE ALL OCCURRENCES OF '<' IN ls_item-process7  WITH '&lt;'.
      REPLACE ALL OCCURRENCES OF '<' IN ls_item-process8  WITH '&lt;'.
      REPLACE ALL OCCURRENCES OF '<' IN ls_item-process9  WITH '&lt;'.
      REPLACE ALL OCCURRENCES OF '>' IN ls_item-process6  WITH '&gt;'.
      REPLACE ALL OCCURRENCES OF '"' IN ls_item-process6  WITH '&quot;'.
      REPLACE ALL OCCURRENCES OF '''' IN ls_item-process6 WITH '&apos;'.

      REPLACE ALL OCCURRENCES OF '&' IN ls_item-opr1 WITH '&amp;'.
      REPLACE ALL OCCURRENCES OF '&' IN ls_item-opr2 WITH '&amp;'.
      REPLACE ALL OCCURRENCES OF '&' IN ls_item-opr3 WITH '&amp;'.
      REPLACE ALL OCCURRENCES OF '&' IN ls_item-opr4 WITH '&amp;'.
      REPLACE ALL OCCURRENCES OF '&' IN ls_item-opr5 WITH '&amp;'.
      REPLACE ALL OCCURRENCES OF '&' IN ls_item-opr6 WITH '&amp;'.
      REPLACE ALL OCCURRENCES OF '&' IN ls_item-opr7 WITH '&amp;'.
      REPLACE ALL OCCURRENCES OF '&' IN ls_item-opr8 WITH '&amp;'.
      REPLACE ALL OCCURRENCES OF '&' IN ls_item-opr9 WITH '&amp;'.
      REPLACE ALL OCCURRENCES OF '<' IN ls_item-opr1  WITH '&lt;'.
      REPLACE ALL OCCURRENCES OF '<' IN ls_item-opr2  WITH '&lt;'.
      REPLACE ALL OCCURRENCES OF '<' IN ls_item-opr3  WITH '&lt;'.
      REPLACE ALL OCCURRENCES OF '<' IN ls_item-opr4  WITH '&lt;'.
      REPLACE ALL OCCURRENCES OF '<' IN ls_item-opr5  WITH '&lt;'.
      REPLACE ALL OCCURRENCES OF '<' IN ls_item-opr6  WITH '&lt;'.
      REPLACE ALL OCCURRENCES OF '<' IN ls_item-opr7  WITH '&lt;'.
      REPLACE ALL OCCURRENCES OF '<' IN ls_item-opr8  WITH '&lt;'.
      REPLACE ALL OCCURRENCES OF '<' IN ls_item-opr9  WITH '&lt;'.
      REPLACE ALL OCCURRENCES OF '>' IN ls_item-process6  WITH '&gt;'.
      REPLACE ALL OCCURRENCES OF '"' IN ls_item-process6  WITH '&quot;'.
      REPLACE ALL OCCURRENCES OF '''' IN ls_item-process6 WITH '&apos;'.


      REPLACE ALL OCCURRENCES OF '>' IN ls_item-opr6  WITH '&gt;'.
      REPLACE ALL OCCURRENCES OF '"' IN ls_item-opr6  WITH '&quot;'.
      REPLACE ALL OCCURRENCES OF '''' IN ls_item-opr6 WITH '&apos;'.


      srn = srn + 1 .

      lv_item = |{ lv_item }| && |<ItemDataNode>| &&
                |<sl_num>{ srn }</sl_num>| &&
                |<batch>{ '' }</batch>| &&
                |<rm1>{ ls_item-rm1 }</rm1>| &&
                |<rm2>{ ls_item-rm2 }</rm2>| &&
                |<rm3>{ ls_item-rm3 }</rm3>| &&
                |<rm4>{ ls_item-rm4 }</rm4>| &&
                |<rm5>{ ls_item-rm5 }</rm5>| &&
                |<rm6>{ ls_item-rm6 }</rm6>| &&
                |<rm7>{ ls_item-rm7 }</rm7>| &&
                |<rm8>{ ls_item-rm8 }</rm8>| &&
                |<rm9>{ ls_item-rm9 }</rm9>| &&
                |<rm10>{ ls_item-rm10 }</rm10>| &&
                |<rm11>{ ls_item-rm11 }</rm11>| &&
                |<rm12>{ ls_item-rm12 }</rm12>| &&
                |<rm_name1>{ ls_item-rm_name1 }</rm_name1>| &&
                |<rm_name2>{ ls_item-rm_name2 }</rm_name2>| &&
                |<rm_name3>{ ls_item-rm_name3 }</rm_name3>| &&
                |<rm_name4>{ ls_item-rm_name4 }</rm_name4>| &&
                |<rm_name5>{ ls_item-rm_name5 }</rm_name5>| &&
                |<rm_name6>{ ls_item-rm_name6 }</rm_name6>| &&
                |<rm_name7>{ ls_item-rm_name7 }</rm_name7>| &&
                |<rm_name8>{ ls_item-rm_name8 }</rm_name8>| &&
                |<rm_name9>{ ls_item-rm_name9 }</rm_name9>| &&
                |<rm_name10>{ ls_item-rm_name10 }</rm_name10>| &&
                |<rm_name11>{ ls_item-rm_name11 }</rm_name11>| &&
                |<rm_name12>{ ls_item-rm_name12 }</rm_name12>| &&
                |<process1>{ ls_item-process1 }</process1>| &&
                |<process2>{ ls_item-process2 }</process2>| &&
                |<process3>{ ls_item-process3 }</process3>| &&
                |<process4>{ ls_item-process4 }</process4>| &&
                |<process5>{ ls_item-process5 }</process5>| &&
                |<process6>{ ls_item-process6 }</process6>| &&
                |<process7>{ ls_item-process7 }</process7>| &&
                |<process8>{ ls_item-process8 }</process8>| &&
                |<process9>{ ls_item-process9 }</process9>| &&
                |<opr1>{ ls_item-opr1 }</opr1>| &&
                |<opr2>{ ls_item-opr2 }</opr2>| &&
                |<opr3>{ ls_item-opr3 }</opr3>| &&
                |<opr4>{ ls_item-opr4 }</opr4>| &&
                |<opr5>{ ls_item-opr5 }</opr5>| &&
                |<opr6>{ ls_item-opr6 }</opr6>| &&
                |<opr7>{ ls_item-opr7 }</opr7>| &&
                |<opr8>{ ls_item-opr8 }</opr8>| &&
                |<opr9>{ ls_item-opr9 }</opr9>| &&

         |</ItemDataNode>|  ##NO_TEXT .

      CLEAR: ls_item.

    ENDLOOP.

    lv_xml = |{ lv_xml }{ lv_item }| &&
                       |</ItemData>| &&
                       |</ProductionOrderNode>| &&
                       |</Form>| ##NO_TEXT .

    DATA(ls_data_xml_64) = cl_web_http_utility=>encode_base64( lv_xml ).
    iv_xml_base64 = ls_data_xml_64.
  ENDMETHOD.
ENDCLASS.
