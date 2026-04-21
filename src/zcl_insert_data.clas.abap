CLASS zcl_insert_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .

    METHODS:
      upload_sample_data.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS ZCL_INSERT_DATA IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    upload_sample_data(  ).
  ENDMETHOD.


  METHOD upload_sample_data.

  ENDMETHOD.
ENDCLASS.
