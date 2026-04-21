CLASS ycl_trigger_email_insplot DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    DATA: gt_rej TYPE TABLE OF zi_insp_lot_rej,
          gs_rej LIKE LINE OF gt_rej.

    DATA:
              lv_char10 TYPE c LENGTH 10.

    INTERFACES if_oo_adt_classrun .
    INTERFACES if_apj_dt_exec_object .
    INTERFACES if_apj_rt_exec_object .

    CONSTANTS : default_inventory_id          TYPE c LENGTH 1 VALUE '1',
                wait_time_in_seconds          TYPE i VALUE 5,
                selection_name                TYPE c LENGTH 8   VALUE 'INSPLOT' ##NO_TEXT,
                selection_description         TYPE c LENGTH 255 VALUE 'Lot Data' ##NO_TEXT,
                application_log_object_name   TYPE if_bali_object_handler=>ty_object VALUE 'ZAPP_DEMO_ALOG_01' ##NO_TEXT,
                application_log_sub_obj1_name TYPE if_bali_object_handler=>ty_object VALUE 'ZAPP_DEMO_ALOGS_01' ##NO_TEXT.


    METHODS:
      send_mail
        IMPORTING
          xt_rej  LIKE gt_rej
          im_date TYPE d
          im_mode LIKE lv_char10.
    "RETURNING VALUE(rv_mail_stat) TYPE char120.


  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS YCL_TRIGGER_EMAIL_INSPLOT IMPLEMENTATION.


  METHOD if_apj_dt_exec_object~get_parameters.

    DATA:
      sys_date TYPE d.

    sys_date = cl_abap_context_info=>get_system_date( ).

    "Return the supported selection parameters here
    et_parameter_def = VALUE #(
      ( selname  = selection_name
        kind     = if_apj_dt_exec_object=>parameter
        datatype = 'C'
        length   =  8
        param_text = selection_description
        changeable_ind = abap_true )
    ).

    "Return the default parameters values here
    et_parameter_val = VALUE #(
      ( selname = selection_name
        kind = if_apj_dt_exec_object=>parameter
        sign = 'I'
        option = 'EQ'
        low = sys_date )
    ).

  ENDMETHOD.


  METHOD if_apj_rt_exec_object~execute.

    DATA:
      is_date TYPE d.

    is_date = cl_abap_context_info=>get_system_date( ). "sy-datum.
    me->send_mail(
      EXPORTING
        xt_rej       = gt_rej
        im_date      = is_date
        im_mode      = 'BCG'
    ).

  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.

    DATA  et_parameters TYPE if_apj_rt_exec_object=>tt_templ_val  .

    DATA:
      sys_date TYPE d.

    sys_date = cl_abap_context_info=>get_system_date( ).

    et_parameters = VALUE #(
        ( selname = selection_name
          kind = if_apj_dt_exec_object=>parameter
          sign = 'I'
          option = 'EQ'
          low = sys_date )
      ).

    TRY.

        if_apj_rt_exec_object~execute( it_parameters = et_parameters ).
        out->write( |Finished| ) ##NO_TEXT.

      CATCH cx_root INTO DATA(job_scheduling_exception) ##NO_HANDLER.

    ENDTRY.


  ENDMETHOD.


  METHOD send_mail.

    DATA: ct_rej TYPE TABLE OF zi_insp_lot_rej,
          cs_rej LIKE LINE OF gt_rej.

    DATA:
      lv_docnum         TYPE c LENGTH 15,
      lv_refdoc         TYPE c LENGTH 30,
      lv_eobj           TYPE c LENGTH 15,
      lv_date           TYPE c LENGTH 10,
      lv_decision       TYPE c LENGTH 20,
      lv_desc_date      TYPE c LENGTH 10,
      lv_post_date      TYPE c LENGTH 10,
      lv_email_add(512) TYPE c.

    DATA: lt_done TYPE TABLE OF yemail_triggered,
          ls_done TYPE yemail_triggered.

    DATA : rt_lot TYPE RANGE OF zi_insp_lot_rej-InspectionLot,
           rs_lot LIKE LINE OF  rt_lot.

    IF im_mode NE 'BCG'.
      IF xt_rej[] IS NOT INITIAL.

        LOOP AT xt_rej INTO DATA(xs_rej).

          rs_lot-low    = xs_rej-InspectionLot.
          rs_lot-high   = '' .
          rs_lot-option = 'EQ' .
          rs_lot-sign   = 'I' .
          APPEND rs_lot TO rt_lot.

          CLEAR: xs_rej.
        ENDLOOP.

      ENDIF.

      SELECT * FROM zi_insp_lot_rej
               WHERE InspectionLot IN @rt_lot INTO TABLE @DATA(gt_lot).
    ELSE.

      lv_date = im_date.
      SELECT * FROM zi_insp_lot_rej WHERE InspectionLotUsageDecidedOn = @lv_date INTO TABLE @gt_lot.

    ENDIF.

    IF gt_lot[] IS NOT INITIAL.

      SELECT
  documentnumber ,
  email_done,
  email_obj ,
  email_date,
  email_time
      FROM yemail_triggered
                     FOR ALL ENTRIES IN @gt_lot
                    WHERE documentnumber = @gt_lot-InspectionLot
                    INTO TABLE @DATA(gt_done).     "#EC CI_NO_TRANSFORM

      SELECT
MaterialDocument,
MaterialDocumentYear,
DocumentDate,
PostingDate,
MaterialDocumentHeaderText,
DeliveryDocument,
ReferenceDocument,
BillOfLading,
Plant,
MaterialDocumentItem,
GoodsMovementType,
Supplier,
PurchaseOrder,
PurchaseOrderItem,
Material,
EntryUnit,
QuantityInEntryUnit,
TotalGoodsMvtAmtInCCCrcy,
InventorySpecialStockType,
InventoryStockType,
ReversedMaterialDocument,
ReversedMaterialDocumentItem,
ReversedMaterialDocumentYear,
Batch,
GoodsMovementIsCancelled,
GoodsRecipientName,
UnloadingPointName,
IsAutomaticallyCreated,
ManufacturingOrder,
Reservation,
ReservationItem,
StorageLocation,
StorageBin,
IssgOrRcvgBatch,
IssuingOrReceivingStorageLoc,
EWMStorageBin,
PurchaseOrderDate,
OrderQuantity,
NetPriceAmount,
QuantityInDeliveryQtyUnit,
SupplierName,
Country,
AddressID,
InspectionLot,
InspLotQtyToBlocked,
InspLotQtyToFree,
MatlDocLatestPostgDate,
InspectionLotType,
InspectionLotUsageDecidedBy,
InspectionLotUsageDecidedOn,
StreetPrefixName1,
StreetPrefixName2,
StreetName,
StreetSuffixName1,
DistrictName,
CityName,
PostalCode,
AddressRepresentationCode,
AddressPersonID,
Region,
supll_email,
ProductDescription
      FROM zi_grn_detail
               FOR ALL ENTRIES IN @gt_lot
               WHERE MaterialDocument = @gt_lot-MaterialDocument AND MaterialDocumentYear = @gt_lot-MaterialDocumentYear
               INTO TABLE @DATA(gt_matodc).        "#EC CI_NO_TRANSFORM

    ENDIF.

    IF gt_lot[] IS NOT INITIAL.

      LOOP AT gt_lot INTO DATA(gs_lot) WHERE InspLotQtyToBlocked IS NOT INITIAL.

        READ TABLE gt_matodc INTO DATA(gs_matdoc) WITH KEY
                                                  MaterialDocument = gs_lot-MaterialDocument
                                                  MaterialDocumentYear = gs_lot-MaterialDocumentYear.
        IF sy-subrc EQ 0.
          lv_refdoc = gs_matdoc-ReferenceDocument.
        ENDIF.

        READ TABLE gt_done INTO DATA(gs_done) WITH KEY documentnumber = gs_lot-InspectionLot.
        IF sy-subrc NE 0.

          SELECT * FROM zi_insp_lot_email WHERE lot_type = @gs_lot-InspectionLotType AND
                                                plant    = @gs_lot-Plant
                                                INTO TABLE @DATA(lt_email).
        ENDIF.

        IF lt_email[] IS NOT INITIAL.

          TRY.

              lv_docnum   = gs_lot-InspectionLot.
              lv_desc_date = gs_lot-InspectionLotUsageDecidedOn+6(2) && '.'
                             &&  gs_lot-InspectionLotUsageDecidedOn+4(2) && '.'
                             &&  gs_lot-InspectionLotUsageDecidedOn+0(4).

              CLEAR: lv_decision.
              IF gs_lot-InspectionLotUsageDecisionCode+0(1) EQ 'A'.
                lv_decision = 'Accepted' ##NO_TEXT.
              ELSEIF gs_lot-InspectionLotUsageDecisionCode+0(1) EQ 'R'.
                lv_decision = 'Rejected' ##NO_TEXT.
              ENDIF.

              DATA(lo_mail) = cl_bcs_mail_message=>create_instance( ).

              CLEAR: lv_email_add.
              lv_email_add = gs_matdoc-supll_email.
              IF lv_email_add IS NOT INITIAL.
                lo_mail->add_recipient( lv_email_add ).
              ENDIF.

              LOOP AT lt_email INTO DATA(ls_email).

                lv_email_add = ls_email-emailid.
                IF ls_email-to_cc = 'TO'.

                  IF gs_matdoc-supll_email IS INITIAL.
                    lo_mail->add_recipient( lv_email_add ).
                  ENDIF.

                ELSEIF ls_email-to_cc = 'CC'.

                  lo_mail->add_recipient( iv_address = lv_email_add iv_copy = cl_bcs_mail_message=>cc ).

                ENDIF.

              ENDLOOP.

              lo_mail->set_subject( |Quality alert for Inspection Lot - | && lv_docnum ) ##NO_TEXT.

              lv_post_date = gs_matdoc-PostingDate+6(2) && '.' && gs_matdoc-PostingDate+4(2) && '.'
                             && gs_matdoc-PostingDate+0(4).

              DATA(lv_mail_body) = '<p>Dear Sir,</p>'
              && '<p>Please find the below status of usage desicion taken by quality team</p>'
              && '<p>Requested you to please proceed for required action</p>'.

              DATA(lv_body_data) = |<p></p>|
              && |<p>Lot Number: { lv_docnum } </p>|
              && |<p>Purchase Order: { gs_lot-PurchasingDocument } </p>|
              && |<p>Material Document: { gs_lot-MaterialDocument } </p>|
              && |<p>Material: { gs_lot-Material } </p>|
              && |<p>Material Description: { gs_matdoc-ProductDescription } </p>|
              && |<p>Posting Date: { lv_post_date } </p>|
              && |<p>Delivery Number: { lv_refdoc } </p>|
              && |<p>Decision Date: { lv_desc_date } </p>|
*              && |<p>Usage Decision: { lv_decision } </p>|
              && |<p>Lot Qty: { gs_lot-InspectionLotQuantity } </p>|
              && |<p>Accepted Qty: { gs_lot-InspLotQtyToFree } </p>|
              && |<p>Rejected Qty: { gs_lot-InspLotQtyToBlocked } </p>|
              && |<p></p>|
              && '<br>'.

              DATA(lv_footer) = '<B>Regards,</B>' && '<br>'
              && 'Quality Assurance' && '<br>'
              && 'Anand NVH Products Pvt. Limited' && '<br>'
              && 'Gurgaon' && '<br>'
              && '<p>**** This is an auto generated Notification by SAP, please do not reply****</p>' ##NO_TEXT.

              DATA(lv_final_mail_body)  = lv_mail_body && lv_body_data && lv_footer.

              lo_mail->set_main( cl_bcs_mail_textpart=>create_text_html( lv_final_mail_body ) ).

              "*CATCH cx_web_http_conversion_failed.
              lo_mail->send( IMPORTING et_status = DATA(lt_status) ).

              DATA:
                sys_date     TYPE d,
                sys_time     TYPE t,
                sys_timezone TYPE timezone.

              sys_date = cl_abap_context_info=>get_system_date( ).
              sys_time = cl_abap_context_info=>get_system_time( ).

              IF sy-subrc EQ 0.
                CLEAR: ls_done.
                ls_done-documentnumber = gs_lot-InspectionLot.
                ls_done-email_done     = abap_true.
                ls_done-email_obj      = 'INSPLOT' ##NO_TEXT.
                ls_done-email_date     = sys_date.
                ls_done-email_time     = sys_time.
                APPEND ls_done TO lt_done.
              ENDIF.

            CATCH cx_bcs_mail INTO DATA(lx_mail) ##NO_HANDLER.
              "handle exceptions here

          ENDTRY.

        ENDIF.

        CLEAR: gs_lot, lt_email[].
      ENDLOOP.

      IF lt_done[] IS NOT INITIAL.
        MODIFY yemail_triggered FROM TABLE @lt_done.
      ENDIF.

    ENDIF.
  ENDMETHOD.
ENDCLASS.
