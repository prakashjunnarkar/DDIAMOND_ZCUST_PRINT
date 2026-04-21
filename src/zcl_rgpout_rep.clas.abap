CLASS zcl_rgpout_rep DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_RGPOUT_REP IMPLEMENTATION.


  METHOD if_rap_query_provider~select.


    IF io_request->is_data_requested(  ).

      DATA : lt_response TYPE TABLE OF zi_rgpout_rep.
      DATA : ls_response LIKE LINE OF lt_response.

      DATA : lt_responseout LIKE lt_response.
      DATA : ls_responseout LIKE LINE OF lt_responseout.


      DATA(lt_clause) = io_request->get_paging(  )->get_page_size( ).
      DATA(lt_parameter) = io_request->get_parameters(  ).
      DATA(lt_filter) = io_request->get_requested_elements(  ).
      DATA(lt_sort) = io_request->get_sort_elements(  ).


      DATA(lv_top) = io_request->get_paging(  )->get_page_size(  ).
      DATA(lv_skip) = io_request->get_paging(  )->get_offset(  ).
      DATA(lv_max_raws) = COND #( WHEN lv_top = if_rap_query_paging=>page_size_unlimited THEN 0 ELSE lv_top ).

      DATA:
        sys_date     TYPE d,
        sys_time     TYPE t,
        sys_timezone TYPE timezone,
        sys_uname    TYPE c LENGTH 20.

      TRY .
          DATA(lt_filter_cond) = io_request->get_filter(  )->get_as_ranges(  ).
        CATCH cx_rap_query_filter_no_range INTO DATA(lx_no_sel_option) ##NO_HANDLER.
      ENDTRY.

      LOOP AT lt_filter_cond INTO DATA(ls_filter_cond).

        IF ls_filter_cond-name = 'RGPOUT_NUM'.
          DATA(ls_rgpoutnum) = ls_filter_cond-range[].
        ENDIF.

        IF ls_filter_cond-name = 'RGPOUT_YEAR'.
          DATA(ls_rgpoutyear) = ls_filter_cond-range[].
        ENDIF.

        IF ls_filter_cond-name = 'PRNUM'.
          DATA(ls_prnum) = ls_filter_cond-range[].
        ENDIF.

        IF ls_filter_cond-name = 'WERKS'.
          DATA(ls_plant) = ls_filter_cond-range[].
        ENDIF.

        IF ls_filter_cond-name = 'LIFNR'.
          DATA(ls_lifnr) = ls_filter_cond-range[].
        ENDIF.

        IF ls_filter_cond-name = 'RGPOUT_CREATIONDATE'.
          DATA(ls_RGPDATE) = ls_filter_cond-range[].
        ENDIF.


      ENDLOOP.

* Start Of Selection

      sys_date  = cl_abap_context_info=>get_system_date( ).
      sys_time  = cl_abap_context_info=>get_system_time( ).
      sys_uname = cl_abap_context_info=>get_user_technical_name( ).

      SELECT * FROM zmm_rgp_data
      WHERE lifnr IN @LS_LIFNR
      AND rgpout_num IN @ls_rgpoutnum
      AND   rgpout_year IN @ls_rgpoutyear
      AND prnum IN @ls_prnum
      AND werks IN @ls_plant
      AND rgpout_creationdate IN @ls_rgpdate
      AND rgpoutdeleted = ''
      AND rgpindeleted  = ''
      AND rgpin_num     = ''
      INTO TABLE @DATA(it_data).

      LOOP AT it_data INTO DATA(wa_data).

        MOVE-CORRESPONDING wa_data TO ls_response.
        DATA(lv_days) = sys_date - wa_Data-rgpout_creationdate.
        ls_response-ageingdays = lv_days.

        APPEND ls_response TO lt_response.
        CLEAR : ls_response , wa_data.

      ENDLOOP.
*    End of slection
**********************************************************************
      lv_max_raws = lv_skip + lv_top.
      IF lv_skip > 0 .
        lv_skip = lv_skip + 1 .
      ENDIF.

      CLEAR lt_responseout.
      LOOP AT lt_response ASSIGNING FIELD-SYMBOL(<lfs_out_line_item>) FROM lv_skip TO lv_max_raws."#EC CI_NOORDER
        ls_responseout = <lfs_out_line_item>.
        APPEND ls_responseout TO lt_responseout.
      ENDLOOP.

      io_response->set_total_number_of_records( lines( lt_response ) ).
      io_response->set_data( lt_responseout ).


    ENDIF.
  ENDMETHOD.
ENDCLASS.
