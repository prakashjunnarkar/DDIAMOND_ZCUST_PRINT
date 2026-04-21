CLASS zcl_rej_mail DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA: gt_rej     TYPE TABLE OF zi_insp_lot_rej,
          gs_rej     LIKE LINE OF gt_rej,
          lv_char10  TYPE c LENGTH 10,
          lv_char120 TYPE c LENGTH 120.

    METHODS:
      get_insp_lot_data
        IMPORTING
                  im_date        TYPE d
                  im_action      LIKE lv_char10
        RETURNING VALUE(et_item) LIKE gt_rej,

      get_data_send_mail
        IMPORTING
                  xt_rej              LIKE gt_rej
                  im_date             TYPE d
                  im_mode             LIKE lv_char10
                  im_action           LIKE lv_char10
        RETURNING VALUE(rv_mail_stat) LIKE lv_char120.


  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_REJ_MAIL IMPLEMENTATION.


  METHOD get_data_send_mail.

    DATA: lo_mail TYPE REF TO ycl_trigger_email_insplot.

    CREATE OBJECT lo_mail.

    lo_mail->send_mail(
      xt_rej  = xt_rej
      im_date = im_date
      im_mode = im_mode
    ).

    IF sy-subrc EQ 0.
      rv_mail_stat = 'Mail sent successfully'  ##NO_TEXT .
    ENDIF.

  ENDMETHOD.


  METHOD get_insp_lot_data.

    DATA: lv_index TYPE sy-tabix.

    DATA(lv_date) = im_date.

    SELECT * FROM zi_insp_lot_rej WHERE InspectionLotUsageDecidedOn = @lv_date INTO TABLE @DATA(gt_lot).

    IF gt_lot[] IS NOT INITIAL.

      SELECT
documentnumber ,
email_done         ,
email_obj          ,
email_date         ,
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
               INTO TABLE @DATA(gt_matodc). "#EC CI_NO_TRANSFORM

    ENDIF.

    LOOP AT gt_lot ASSIGNING FIELD-SYMBOL(<gs_lot>).

      IF <gs_lot> IS ASSIGNED.

        lv_index = sy-tabix.

        READ TABLE gt_done INTO DATA(gs_done) WITH KEY documentnumber = <gs_lot>-InspectionLot.
        IF sy-subrc EQ 0.

          DELETE gt_lot INDEX lv_index.

        ELSE.

          READ TABLE gt_matodc INTO DATA(gs_matdoc) WITH KEY
                                                    MaterialDocument = <gs_lot>-MaterialDocument
                                                    MaterialDocumentYear = <gs_lot>-MaterialDocumentYear.
          IF sy-subrc EQ 0.
            <gs_lot>-DeliveryDocument = gs_matdoc-ReferenceDocument.
          ENDIF.

        ENDIF.

      ENDIF.

    ENDLOOP.

    IF gt_lot[] IS NOT INITIAL.
      et_item[] = gt_lot[].
    ENDIF.

  ENDMETHOD.
ENDCLASS.
