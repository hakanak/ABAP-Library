CLASS zcl_mm_valuation_class DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF t_key,
        bklas TYPE bklas,
      END OF t_key.

    DATA gs_def TYPE t025 READ-ONLY.

    CLASS-METHODS:
      get_instance
        IMPORTING !is_key       TYPE t_key
        RETURNING VALUE(ro_obj) TYPE REF TO zcl_mm_valuation_class
        RAISING   cx_no_entry_in_table,

      get_text_safe
        IMPORTING !is_key         TYPE t_key
        RETURNING VALUE(rv_bkbez) TYPE bkbez.

    METHODS:
      get_text RETURNING VALUE(rv_bkbez) TYPE bkbez.

  PROTECTED SECTION.

  PRIVATE SECTION.

    TYPES:
      BEGIN OF t_multiton,
        key TYPE t_key,
        obj TYPE REF TO zcl_mm_valuation_class,
        cx  TYPE REF TO cx_no_entry_in_table,
      END OF t_multiton,

      tt_multiton
        TYPE HASHED TABLE OF t_multiton
        WITH UNIQUE KEY primary_key COMPONENTS key.

    CONSTANTS:
      BEGIN OF c_tabname,
        def TYPE tabname VALUE 'T025',
      END OF c_tabname.

    CLASS-DATA gt_multiton TYPE tt_multiton.

    DATA: gv_text      TYPE bkbez,
          gv_text_read TYPE abap_bool.

    METHODS:
      constructor
        IMPORTING !is_key TYPE t_key
        RAISING   cx_no_entry_in_table.

ENDCLASS.

CLASS zcl_mm_valuation_class IMPLEMENTATION.

  METHOD constructor.
    SELECT SINGLE *
           FROM t025
           WHERE bklas EQ @is_key-bklas
           INTO CORRESPONDING FIELDS OF @gs_def.

    IF sy-subrc NE 0.
      RAISE EXCEPTION TYPE cx_no_entry_in_table
        EXPORTING
          table_name = CONV #( c_tabname-def )
          entry_name = |{ is_key-bklas }|.
    ENDIF.
  ENDMETHOD.


  METHOD get_instance.

    ASSIGN gt_multiton[ KEY primary_key COMPONENTS key = is_key
                      ] TO FIELD-SYMBOL(<ls_multiton>).

    IF sy-subrc NE 0.
      DATA(ls_multiton) = VALUE t_multiton( key = is_key ).

      TRY.
          ls_multiton-obj = NEW #( ls_multiton-key ).
        CATCH cx_no_entry_in_table INTO ls_multiton-cx ##NO_HANDLER.
      ENDTRY.

      INSERT ls_multiton INTO TABLE gt_multiton ASSIGNING <ls_multiton>.
    ENDIF.

    IF <ls_multiton>-cx IS NOT INITIAL.
      RAISE EXCEPTION <ls_multiton>-cx.
    ENDIF.

    ro_obj = <ls_multiton>-obj.
  ENDMETHOD.


  METHOD get_text.
    IF gv_text_read EQ abap_false.
      SELECT SINGLE bkbez
             FROM t025t
             WHERE spras EQ @sy-langu AND
                   bklas EQ @gs_def-bklas
             INTO @gv_text.
    ENDIF.

    rv_bkbez = gv_text.
  ENDMETHOD.


  METHOD get_text_safe.
    TRY.
        rv_bkbez = get_instance( is_key )->get_text( ).
      CATCH cx_root ##no_Handler .
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
