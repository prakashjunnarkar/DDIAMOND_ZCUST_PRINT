CLASS zcl_amt_words DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
  METHODS:
      number_to_words
        IMPORTING
                  iv_num        TYPE string
        EXPORTING
                  iv_level      type int4
        RETURNING VALUE(rv_words) type string,

      number_to_words_export
        IMPORTING
                  iv_num        TYPE string
        EXPORTING
                  iv_level      type int4
        RETURNING VALUE(rv_words) type string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_AMT_WORDS IMPLEMENTATION.


METHOD number_to_words.

TYPES: BEGIN OF str_d,
             num   TYPE i,
             word1 TYPE string,
             word2 TYPE string,
           END OF str_d.

    DATA: ls_h TYPE str_d,
          ls_k TYPE str_d,
          ls_m TYPE str_d,
          ls_b TYPE str_d,
          ls_t TYPE str_d,
          ls_o TYPE str_d.

    DATA lv_int TYPE i.
    DATA lv_int1 TYPE i.
    DATA lv_int2 TYPE i.
    DATA lv_dec_s TYPE string.
    DATA lv_dec   TYPE i.
    DATA lv_wholenum TYPE i.
    DATA lv_inp1 TYPE string.
    DATA lv_inp2 TYPE string.
    DATA lv_dec_words type c length 255.

    IF iv_num IS INITIAL.
        RETURN.
    ENDIF.

    ls_h-num = 100.
    ls_h-word1 = 'Hundred' ##NO_TEXT.
    ls_h-word2 = 'Hundred' ##NO_TEXT.

    ls_k-num = ls_h-num * 10.
    ls_k-word1 = 'Thousand' ##NO_TEXT.
    ls_k-word2 = 'Thousand' ##NO_TEXT.

    ls_m-num = ls_k-num * 100.
    ls_m-word1 = 'Lakh' ##NO_TEXT.
    ls_m-word2 = 'Lakh' ##NO_TEXT.

    ls_b-num = ls_m-num * 100.
    ls_b-word1 = 'Crore' ##NO_TEXT.
    ls_b-word2 = 'Crore' ##NO_TEXT.

    SPLIT iv_num AT '.' INTO lv_inp1 lv_inp2.

    lv_int = lv_inp1.
    lv_wholenum = lv_int.

    IF iv_level IS INITIAL.
        IF lv_inp2 IS NOT INITIAL.
            CONDENSE lv_inp2.
            lv_dec_s   = lv_inp2.
            lv_dec     = lv_inp2.
        ENDIF.
    ENDIF.
    iv_level = iv_level + 1.

    SELECT * FROM zsd_num2string INTO TABLE @DATA(lt_d). "#EC CI_NOWHERE

**   Whole Number converted to Words

    IF lt_d IS NOT INITIAL.
      IF lv_int <= 20.
        READ TABLE lt_d REFERENCE INTO DATA(ls_d) WITH KEY num = lv_int.
        rv_words = |{ ls_d->word }|.
    ELSEIF lv_int < 100 AND lv_int > 20.
        DATA(mod) = lv_int MOD 10.
        DATA(floor) = floor( lv_int DIV 10 ).
        IF mod = 0.
          READ TABLE lt_d REFERENCE INTO ls_d WITH KEY num = lv_int.
          rv_words = ls_d->word.
        ELSE.
          READ TABLE lt_d REFERENCE INTO ls_d WITH KEY num = floor * 10.
          DATA(pos1) = ls_d->word.
          READ TABLE lt_d REFERENCE INTO ls_d WITH KEY num = mod.
          DATA(pos2) = ls_d->word.
          rv_words = |{ pos1 } | && |{ pos2 } |.
        ENDIF.
      ELSE.
        IF lv_int  < ls_k-num.
          ls_o = ls_h.
        ELSEIF lv_int < ls_m-num.
          ls_o = ls_k.
        ELSEIF lv_int < ls_b-num.
          ls_o = ls_m.
        ELSE.
          ls_o = ls_b.
        ENDIF.
        mod = lv_int MOD ls_o-num.
        floor = floor( iv_num DIV ls_o-num ).
        lv_inp1 = floor.
        lv_inp2 = mod.

        IF mod = 0.

          DATA(output2) = me->number_to_words(
                            EXPORTING
                              iv_num   = lv_inp1
                            IMPORTING
                              iv_level = iv_level
                          ).

          rv_words =  |{ output2 } | && |{ ls_o-word1 } |.

        ELSE.

          output2 = me->number_to_words(
                      EXPORTING
                        iv_num   = lv_inp1
                      IMPORTING
                       iv_level = iv_level
                    ).

          DATA(output3) = me->number_to_words(
                      EXPORTING
                        iv_num   = lv_inp2
                      IMPORTING
                       iv_level = iv_level
                    ).

          rv_words = |{ output2 } | && |{ ls_o-word2 } | && |{ output3 } |.

        ENDIF.

      ENDIF.

      iv_level = iv_level - 1.
      IF iv_level IS INITIAL.

**       "Dollars" is base monetary unit used in this sample,
**       but this could change as per the currency of the scenario.
**       It must be ensured that relative fractional monetary unit
**       shall be updated later in the code relative to the base unit

        rv_words = |{ rv_words }Rupees and| ##NO_TEXT. "Dollars
        IF lv_dec <= 20.
            READ TABLE lt_d REFERENCE INTO DATA(ls_d2) WITH KEY num = lv_dec.
            IF SY-SUBRC = 0.
                lv_dec_words = |{ ls_d2->word }|.
            ENDIF.
        ELSEIF lv_dec < 100 AND lv_dec > 20.
            DATA(mod1) = lv_dec MOD 10.
            DATA(floor1) = floor( lv_dec DIV 10 ).
            IF mod1 = 0.
                READ TABLE lt_d REFERENCE INTO ls_d2 WITH KEY num = lv_dec.
                IF SY-SUBRC = 0.
                    lv_dec_words = ls_d2->word.
                ENDIF.
            ELSE.
                READ TABLE lt_d REFERENCE INTO ls_d2 WITH KEY num = floor1 * 10.
                IF SY-SUBRC = 0.
                    DATA(pos1_d) = ls_d2->word.
                ENDIF.
                READ TABLE lt_d REFERENCE INTO ls_d2 WITH KEY num = mod1.
                IF SY-SUBRC = 0.
                    DATA(pos2_d) = ls_d2->word.
                ENDIF.
                IF POS1_D IS NOT INITIAL AND pos2_d IS NOT INITIAL.
                    lv_dec_words = |{ pos1_d } | && |{ pos2_d } |.
                ENDIF.
            ENDIF.
        ENDIF.

**       Since "Dollars" was used for base monetary unit, "Cents"
**       has been used as fractional monetary unit in the code below
**       This can be handled dynamically as well based on the requirement

        rv_words = |{ rv_words } { lv_dec_words } Paise| ##NO_TEXT. "Cents

      ENDIF.
      RETURN.
    ENDIF.

ENDMETHOD.


METHOD number_to_words_export.
TYPES: BEGIN OF str_d,
             num   TYPE i,
             word1 TYPE string,
             word2 TYPE string,
           END OF str_d.

    DATA: ls_h TYPE str_d,
          ls_k TYPE str_d,
          ls_m TYPE str_d,
          ls_b TYPE str_d,
          ls_t TYPE str_d,
          ls_o TYPE str_d.

    DATA lv_int TYPE i.
    DATA lv_int1 TYPE i.
    DATA lv_int2 TYPE i.
    DATA lv_dec_s TYPE string.
    DATA lv_dec   TYPE i.
    DATA lv_wholenum TYPE i.
    DATA lv_inp1 TYPE string.
    DATA lv_inp2 TYPE string.
    DATA lv_dec_words type c length 255.

    IF iv_num IS INITIAL.
        RETURN.
    ENDIF.

    ls_h-num = 100.
    ls_h-word1 = 'Hundred' ##NO_TEXT.
    ls_h-word2 = 'Hundred' ##NO_TEXT.

    ls_k-num = ls_h-num * 10.
    ls_k-word1 = 'Thousand' ##NO_TEXT.
    ls_k-word2 = 'Thousand' ##NO_TEXT.

    ls_m-num = ls_k-num * 100.
    ls_m-word1 = 'Million' ##NO_TEXT.
    ls_m-word2 = 'Million' ##NO_TEXT.

    ls_b-num = ls_m-num * 100.
    ls_b-word1 = 'Billion' ##NO_TEXT.
    ls_b-word2 = 'Billion' ##NO_TEXT.

    SPLIT iv_num AT '.' INTO lv_inp1 lv_inp2.

    lv_int = lv_inp1.
    lv_wholenum = lv_int.

    IF iv_level IS INITIAL.
        IF lv_inp2 IS NOT INITIAL.
            CONDENSE lv_inp2.
            lv_dec_s   = lv_inp2.
            lv_dec     = lv_inp2.
        ENDIF.
    ENDIF.
    iv_level = iv_level + 1.

    SELECT * FROM zsd_num2string INTO TABLE @DATA(lt_d). "#EC CI_NOWHERE

**   Whole Number converted to Words

    IF lt_d IS NOT INITIAL.
      IF lv_int <= 20.
        READ TABLE lt_d REFERENCE INTO DATA(ls_d) WITH KEY num = lv_int.
        rv_words = |{ ls_d->word }|.
    ELSEIF lv_int < 100 AND lv_int > 20.
        DATA(mod) = lv_int MOD 10.
        DATA(floor) = floor( lv_int DIV 10 ).
        IF mod = 0.
          READ TABLE lt_d REFERENCE INTO ls_d WITH KEY num = lv_int.
          rv_words = ls_d->word.
        ELSE.
          READ TABLE lt_d REFERENCE INTO ls_d WITH KEY num = floor * 10.
          DATA(pos1) = ls_d->word.
          READ TABLE lt_d REFERENCE INTO ls_d WITH KEY num = mod.
          DATA(pos2) = ls_d->word.
          rv_words = |{ pos1 } | && |{ pos2 } |.
        ENDIF.
      ELSE.
        IF lv_int  < ls_k-num.
          ls_o = ls_h.
        ELSEIF lv_int < ls_m-num.
          ls_o = ls_k.
        ELSEIF lv_int < ls_b-num.
          ls_o = ls_m.
        ELSE.
          ls_o = ls_b.
        ENDIF.
        mod = lv_int MOD ls_o-num.
        floor = floor( iv_num DIV ls_o-num ).
        lv_inp1 = floor.
        lv_inp2 = mod.

        IF mod = 0.

          DATA(output2) = me->number_to_words(
                            EXPORTING
                              iv_num   = lv_inp1
                            IMPORTING
                              iv_level = iv_level
                          ).

          rv_words =  |{ output2 } | && |{ ls_o-word1 } |.

        ELSE.

          output2 = me->number_to_words(
                      EXPORTING
                        iv_num   = lv_inp1
                      IMPORTING
                       iv_level = iv_level
                    ).

          DATA(output3) = me->number_to_words(
                      EXPORTING
                        iv_num   = lv_inp2
                      IMPORTING
                       iv_level = iv_level
                    ).

          rv_words = |{ output2 } | && |{ ls_o-word2 } | && |{ output3 } |.

        ENDIF.

      ENDIF.

      iv_level = iv_level - 1.
      IF iv_level IS INITIAL.

**       "Dollars" is base monetary unit used in this sample,
**       but this could change as per the currency of the scenario.
**       It must be ensured that relative fractional monetary unit
**       shall be updated later in the code relative to the base unit

        rv_words = |{ rv_words } and|.
        IF lv_dec <= 20.
            READ TABLE lt_d REFERENCE INTO DATA(ls_d2) WITH KEY num = lv_dec.
            IF SY-SUBRC = 0.
                lv_dec_words = |{ ls_d2->word }|.
            ENDIF.
        ELSEIF lv_dec < 100 AND lv_dec > 20.
            DATA(mod1) = lv_dec MOD 10.
            DATA(floor1) = floor( lv_dec DIV 10 ).
            IF mod1 = 0.
                READ TABLE lt_d REFERENCE INTO ls_d2 WITH KEY num = lv_dec.
                IF SY-SUBRC = 0.
                    lv_dec_words = ls_d2->word.
                ENDIF.
            ELSE.
                READ TABLE lt_d REFERENCE INTO ls_d2 WITH KEY num = floor1 * 10.
                IF SY-SUBRC = 0.
                    DATA(pos1_d) = ls_d2->word.
                ENDIF.
                READ TABLE lt_d REFERENCE INTO ls_d2 WITH KEY num = mod1.
                IF SY-SUBRC = 0.
                    DATA(pos2_d) = ls_d2->word.
                ENDIF.
                IF POS1_D IS NOT INITIAL AND pos2_d IS NOT INITIAL.
                    lv_dec_words = |{ pos1_d } | && |{ pos2_d } |.
                ENDIF.
            ENDIF.
        ENDIF.

**       Since "Dollars" was used for base monetary unit, "Cents"
**       has been used as fractional monetary unit in the code below
**       This can be handled dynamically as well based on the requirement

        rv_words = |{ rv_words } { lv_dec_words } Cents| ##NO_TEXT.
      ENDIF.
      RETURN.
    ENDIF.
ENDMETHOD.
ENDCLASS.
