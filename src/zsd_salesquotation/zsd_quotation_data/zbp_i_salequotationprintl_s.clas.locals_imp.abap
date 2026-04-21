CLASS LHC_RAP_TDAT_CTS DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS:
      GET
        RETURNING
          VALUE(RESULT) TYPE REF TO IF_MBC_CP_RAP_TDAT_CTS.

ENDCLASS.

CLASS LHC_RAP_TDAT_CTS IMPLEMENTATION.
  METHOD GET.
    result = mbc_cp_api=>rap_tdat_cts( tdat_name = 'ZSALEQUOTATIONPRINTL'
                                       table_entity_relations = VALUE #(
                                         ( entity = 'SaleQuotationPrintL' table = 'ZSALESQU_TAX' )
                                       ) ) ##NO_TEXT.
  ENDMETHOD.
ENDCLASS.
CLASS LHC_ZI_SALEQUOTATIONPRINTL_S DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      GET_INSTANCE_FEATURES FOR INSTANCE FEATURES
        IMPORTING
          KEYS REQUEST requested_features FOR SaleQuotationPriAll
        RESULT result,
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR SaleQuotationPriAll
        RESULT result.
ENDCLASS.

CLASS LHC_ZI_SALEQUOTATIONPRINTL_S IMPLEMENTATION.
  METHOD GET_INSTANCE_FEATURES.
    DATA: edit_flag            TYPE abp_behv_op_ctrl    VALUE if_abap_behv=>fc-o-enabled.

    IF lhc_rap_tdat_cts=>get( )->is_editable( ) = abap_false.
      edit_flag = if_abap_behv=>fc-o-disabled.
    ENDIF.
    result = VALUE #( FOR key in keys (
               %TKY = key-%TKY
               %ACTION-edit = edit_flag
               %ASSOC-_SaleQuotationPrintL = edit_flag ) ).
  ENDMETHOD.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
    AUTHORITY-CHECK OBJECT 'S_TABU_NAM' ID 'TABLE' FIELD 'ZI_SALEQUOTATIONPRINTL' ID 'ACTVT' FIELD '02'.
    DATA(is_authorized) = COND #( WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized ).
    result-%UPDATE      = is_authorized.
    result-%ACTION-Edit = is_authorized.
  ENDMETHOD.
ENDCLASS.
CLASS LSC_ZI_SALEQUOTATIONPRINTL_S DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_SAVER.
  PROTECTED SECTION.
    METHODS:
      SAVE_MODIFIED REDEFINITION.
ENDCLASS.

CLASS LSC_ZI_SALEQUOTATIONPRINTL_S IMPLEMENTATION.
  METHOD SAVE_MODIFIED ##NEEDED.
  ENDMETHOD.
ENDCLASS.
CLASS LHC_ZI_SALEQUOTATIONPRINTL DEFINITION FINAL INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      GET_GLOBAL_FEATURES FOR GLOBAL FEATURES
        IMPORTING
          REQUEST REQUESTED_FEATURES FOR SaleQuotationPrintL
        RESULT result,
      COPYSALEQUOTATIONPRINTL FOR MODIFY
        IMPORTING
          KEYS FOR ACTION SaleQuotationPrintL~CopySaleQuotationPrintL,
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR SaleQuotationPrintL
        RESULT result,
      GET_INSTANCE_FEATURES FOR INSTANCE FEATURES
        IMPORTING
          KEYS REQUEST requested_features FOR SaleQuotationPrintL
        RESULT result.
ENDCLASS.

CLASS LHC_ZI_SALEQUOTATIONPRINTL IMPLEMENTATION.
  METHOD GET_GLOBAL_FEATURES.
    DATA edit_flag TYPE abp_behv_op_ctrl VALUE if_abap_behv=>fc-o-enabled.
    IF lhc_rap_tdat_cts=>get( )->is_editable( ) = abap_false.
      edit_flag = if_abap_behv=>fc-o-disabled.
    ENDIF.
    result-%UPDATE = edit_flag.
    result-%DELETE = edit_flag.
  ENDMETHOD.
  METHOD COPYSALEQUOTATIONPRINTL.
    DATA new_SaleQuotationPrintL TYPE TABLE FOR CREATE ZI_SaleQuotationPrintL_S\_SaleQuotationPrintL.

    IF lines( keys ) > 1.
      INSERT mbc_cp_api=>message( )->get_select_only_one_entry( ) INTO TABLE reported-%other.
      failed-SaleQuotationPrintL = VALUE #( FOR fkey IN keys ( %TKY = fkey-%TKY ) ).
      RETURN.
    ENDIF.

    READ ENTITIES OF ZI_SaleQuotationPrintL_S IN LOCAL MODE
      ENTITY SaleQuotationPrintL
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(ref_SaleQuotationPrintL)
        FAILED DATA(read_failed).

    IF ref_SaleQuotationPrintL IS NOT INITIAL.
      ASSIGN ref_SaleQuotationPrintL[ 1 ] TO FIELD-SYMBOL(<ref_SaleQuotationPrintL>).
      DATA(key) = keys[ KEY draft %TKY = <ref_SaleQuotationPrintL>-%TKY ].
      DATA(key_cid) = key-%CID.
      APPEND VALUE #(
        %TKY-SingletonID = 1
        %IS_DRAFT = <ref_SaleQuotationPrintL>-%IS_DRAFT
        %TARGET = VALUE #( (
          %CID = key_cid
          %IS_DRAFT = <ref_SaleQuotationPrintL>-%IS_DRAFT
          %DATA = CORRESPONDING #( <ref_SaleQuotationPrintL> EXCEPT
          SingletonID
          LocalCreatedBy
          LocalCeatedAt
          LocalLastChangedBy
          LocalLastChangedAt
          LastChangedAt
        ) ) )
      ) TO new_SaleQuotationPrintL ASSIGNING FIELD-SYMBOL(<new_SaleQuotationPrintL>).
      <new_SaleQuotationPrintL>-%TARGET[ 1 ]-Zvbeln = to_upper( key-%PARAM-Zvbeln ).
      <new_SaleQuotationPrintL>-%TARGET[ 1 ]-Zposnr = to_upper( key-%PARAM-Zposnr ).

      MODIFY ENTITIES OF ZI_SaleQuotationPrintL_S IN LOCAL MODE
        ENTITY SaleQuotationPriAll CREATE BY \_SaleQuotationPrintL
        FIELDS (
                 Zvbeln
                 Zposnr
                 Partscost
                 Submaterialcost
                 Assemblingcost
                 Packingandtrasnportingcost
                 Adminstrationcostandprofit
                 TtlWithoutgstInr
                 Amoritisationcostoftooling
                 TtlWithoutGstInrAmoritisat
                 Remarks1
                 Remarks2
                 Remarks3
                 Remarks4
                 Remarks5
               ) WITH new_SaleQuotationPrintL
        MAPPED DATA(mapped_create)
        FAILED failed
        REPORTED reported.

      mapped-SaleQuotationPrintL = mapped_create-SaleQuotationPrintL.
    ENDIF.

    INSERT LINES OF read_failed-SaleQuotationPrintL INTO TABLE failed-SaleQuotationPrintL.

    IF failed-SaleQuotationPrintL IS INITIAL.
      reported-SaleQuotationPrintL = VALUE #( FOR created IN mapped-SaleQuotationPrintL (
                                                 %CID = created-%CID
                                                 %ACTION-CopySaleQuotationPrintL = if_abap_behv=>mk-on
                                                 %MSG = mbc_cp_api=>message( )->get_item_copied( )
                                                 %PATH-SaleQuotationPriAll-%IS_DRAFT = created-%IS_DRAFT
                                                 %PATH-SaleQuotationPriAll-SingletonID = 1 ) ).
    ENDIF.
  ENDMETHOD.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
    AUTHORITY-CHECK OBJECT 'S_TABU_NAM' ID 'TABLE' FIELD 'ZI_SALEQUOTATIONPRINTL' ID 'ACTVT' FIELD '02'.
    DATA(is_authorized) = COND #( WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
                                  ELSE if_abap_behv=>auth-unauthorized ).
    result-%ACTION-CopySaleQuotationPrintL = is_authorized.
  ENDMETHOD.
  METHOD GET_INSTANCE_FEATURES.
    result = VALUE #( FOR row IN keys ( %TKY = row-%TKY
                                        %ACTION-CopySaleQuotationPrintL = COND #( WHEN row-%IS_DRAFT = if_abap_behv=>mk-off THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled )
    ) ).
  ENDMETHOD.
ENDCLASS.
