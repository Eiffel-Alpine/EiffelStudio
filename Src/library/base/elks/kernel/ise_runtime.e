﻿note
	description: "[
			Set of features to access ISE runtime functionality.
			To be used at your own risk.
			Interface may changed without notice.
		]"
	library: "Free implementation of ELKS library"
	status: "See notice at end of class."
	legal: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

frozen class
	ISE_RUNTIME

feature -- Feature specific to ISE runtime.

	frozen generator_of_type (a_type_id: INTEGER): STRING
			-- Name of the generating class of current object
		external
			"C inline use %"eif_out.h%""
		alias
			"return c_generator_of_type(eif_decoded_type($a_type_id));"
		ensure
			instance_free: class
		end

	frozen check_assert (b: BOOLEAN): BOOLEAN
		external
			"C use %"eif_copy.h%""
		alias
			"c_check_assert"
		ensure
			instance_free: class
		end

 	frozen generating_type_of_type (a_type_id: INTEGER): STRING
 		external
 			"built_in static"
		ensure
			instance_free: class
 		end

	frozen in_assertion: BOOLEAN
			-- Are we currently checking some assertions?
		external
			"C inline use %"eif_eiffel.h%""
		alias
			"[
				GTCX;	/* Needed in multithreaded mode as `in_assertion' is a per-thread data. */
				return EIF_TEST(in_assertion!=0);
			]"
		ensure
			instance_free: class
		end

	frozen once_objects (a_result_type_id: INTEGER): SPECIAL [ANY]
			-- Once objects initialized in current system.
			-- `a_result_type_id' is the dynamic type of `SPECIAL [ANY]'.
		external
			"C inline use %"eif_memory_analyzer.h%""
		alias
			"return eif_once_objects_of_result_type(eif_decoded_type($a_result_type_id));"
		ensure
			instance_free: class
		end

feature -- Internal C routines

	frozen type_conforms_to (a_type_id_1, a_type_id_2: INTEGER): BOOLEAN
			-- Does `a_type_id_1' conform to `a_type_id_2'?
		external
			"C inline use %"eif_gen_conf.h%""
		alias
			"return eif_gen_conf($a_type_id_1, $a_type_id_2);"
		ensure
			instance_free: class
		end

	frozen type_id_from_name (s: POINTER): INTEGER
			-- Dynamic type whose name is represented by `s'.
		external
			"C signature (char *): EIF_INTEGER use %"eif_cecil.h%""
		alias
			"eif_type_id"
		ensure
			instance_free: class
		end

	frozen dynamic_type (object: separate ANY): INTEGER
			-- Dynamic type of `object'.
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen pre_ecma_mapping_status: BOOLEAN
			-- Do we map old name to new name by default?
		external
			"C inline use %"eif_cecil.h%""
		alias
			"return eif_pre_ecma_mapping();"
		ensure
			instance_free: class
		end

	frozen set_pre_ecma_mapping (v: BOOLEAN)
			-- Set `pre_ecma_mapping_status' with `v'.
		external
			"C inline use %"eif_cecil.h%""
		alias
			"eif_set_pre_ecma_mapping($v)"
		ensure
			instance_free: class
		end

	frozen is_attached_type (a_type_id: INTEGER): BOOLEAN
			-- Is `a_type' an attached type?
		external
			"C inline  use %"eif_gen_conf.h%""
		alias
			"return eif_is_attached_type($a_type_id)"
		ensure
			instance_free: class
		end

	frozen detachable_type (a_type_id: INTEGER): INTEGER
			-- Detachable version of `a_type'
		external
			"C inline  use %"eif_gen_conf.h%""
		alias
			"return eif_non_attached_type($a_type_id)"
		ensure
			instance_free: class
		end

	frozen attached_type (a_type_id: INTEGER): INTEGER
			-- Attached version of `a_type'
		external
			"C inline use %"eif_gen_conf.h%""
		alias
			"return eif_attached_type($a_type_id)"
		ensure
			instance_free: class
		end

	frozen is_field_transient_of_type (i: INTEGER; a_type_id: INTEGER): BOOLEAN
			-- Is `i-th' field (zero based index) a transient field?
		external
			"C inline use %"eif_eiffel.h%""
		alias
			"return EIF_IS_TRANSIENT_ATTRIBUTE(System(To_dtype(eif_decoded_type($a_type_id).id)), $i - 1);"
		ensure
			instance_free: class
		end

	frozen is_field_expanded_of_type (i: INTEGER; a_type_id: INTEGER): BOOLEAN
			-- Is `i'-th field of `object' an expanded attribute?
		external
			"C inline use %"eif_eiffel.h%""
		alias
			"return ((System(To_dtype(eif_decoded_type($a_type_id).id)).cn_types[$i - 1] & SK_HEAD) == SK_EXP);"
		ensure
			instance_free: class
		end

	frozen persistent_field_count_of_type (a_type_id: INTEGER): INTEGER
			-- Number of logical fields in dynamic type `type_id' that are not transient.
		external
			"C inline use %"eif_eiffel.h%""
		alias
			"return (System(To_dtype(eif_decoded_type($a_type_id).id)).cn_persistent_nbattr);"
		ensure
			instance_free: class
		end

	frozen storable_version_of_type (a_type_id: INTEGER): detachable STRING
		external
			"C inline use %"eif_eiffel.h%""
		alias
			"[
				const char *l_version = System(To_dtype(eif_decoded_type($a_type_id).id)).cn_version;
				if (l_version && (l_version[0] != (char) 0)) {
					return RTMS(l_version);
				} else {
					return NULL;
				}
			]"
		ensure
			instance_free: class
		end

	compiler_version: INTEGER
		external
			"C macro use %"eif_project.h%""
		alias
			"egc_compiler_tag"
		ensure
			instance_free: class
		end

feature -- Internal support

	frozen reference_field_at_offset (a_enclosing: POINTER; a_physical_offset: INTEGER): ANY
			-- Retrieve the reference field of `a_enclosing' located at `a_physical_offset' bytes.
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen raw_reference_field_at_offset (a_enclosing: POINTER; a_physical_offset: INTEGER): POINTER
			-- Retrieve the unprotected reference field of `a_enclosing' located at `a_physical_offset' bytes.
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen dynamic_type_at_offset (a_enclosing: POINTER; a_physical_offset: INTEGER): INTEGER_32
			-- Dynamic type of the field at `a_physical_offset' bytes from `a_enclosing'.
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen is_copy_semantics_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): BOOLEAN
			-- Does `i'-th field of `a_object + a_physical_offset' denote a reference with copy semantics?
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen is_special_copy_semantics_item (i: INTEGER; a_object: POINTER): BOOLEAN
			-- Does `i'-th item of specia `a_object' denote a reference with copy semantics?
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen field_count_of_type (a_type_id: INTEGER): INTEGER
			-- Number of logical fields in dynamic type `a_type_id'.
		external
			"C macro signature (EIF_INTEGER): EIF_INTEGER use %"eif_internal.h%""
		alias
			"ei_count_field_of_type"
		ensure
			instance_free: class
		end

	frozen field_offset_of_type (i: INTEGER; a_type_id: INTEGER): INTEGER
			-- Physical offset of the `i'-th field for an object of dynamic type `a_type'.
		external
			"C macro use %"eif_eiffel.h%""
		alias
			"ei_offset_of_type"
		ensure
			instance_free: class
		end

	frozen object_size (a_object: POINTER): NATURAL_64
			-- Physical size of `a_object'
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen field_name_of_type (i: INTEGER; a_type_id: INTEGER): POINTER
			-- C pointer to name of `i'-th field of `object'
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen field_type_of_type (i: INTEGER; a_type_id: INTEGER): INTEGER
			-- Abstract type of `i'-th field of dynamic type `a_type_id'
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen field_static_type_of_type (i: INTEGER; a_type_id: INTEGER): INTEGER
			-- Static type of `i'-th field of dynamic type `a_type_id'
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen reference_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): detachable ANY
			-- Reference value of `i'-th field of `object + a_physical_offset'
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen character_8_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): CHARACTER_8
			-- Character value of `i'-th field of `object + a_physical_offset'
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen character_32_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): CHARACTER_32
			-- Character value of `i'-th field of `object + a_physical_offset'
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen boolean_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): BOOLEAN
			-- Boolean value of `i'-th field of `object + a_physical_offset'
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen natural_8_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): NATURAL_8
			-- NATURAL_8 value of `i'-th field of `object + a_physical_offset'
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen natural_16_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): NATURAL_16
			-- NATURAL_16 value of `i'-th field of `object + a_physical_offset'
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen natural_32_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): NATURAL_32
			-- NATURAL_32 value of `i'-th field of `object + a_physical_offset'
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen natural_64_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): NATURAL_64
			-- NATURAL_64 value of `i'-th field of `object + a_physical_offset'
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen integer_8_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): INTEGER_8
			-- Integer value of `i'-th field of `object + a_physical_offset'
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen integer_16_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): INTEGER_16
			-- Integer value of `i'-th field of `object + a_physical_offset'
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen integer_32_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): INTEGER
			-- Integer value of `i'-th field of `object + a_physical_offset'
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen integer_64_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): INTEGER_64
			-- Integer value of `i'-th field of `object + a_physical_offset'
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen real_32_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): REAL_32
			-- Real value of `i'-th field of `object + a_physical_offset'
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen pointer_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): POINTER
			-- Pointer value of `i'-th field of `object + a_physical_offset'
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen real_64_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): REAL_64
			-- Double precision value of `i'-th field of `object + a_physical_offset'
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen reference_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): detachable ANY
			-- Reference value of the field at `field_offset' in object `a_object + a_physical_offset'.
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen character_8_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): CHARACTER_8
			-- Character value of the field at `field_offset' in object `a_object + a_physical_offset'.
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen character_32_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): CHARACTER_32
			-- Character value of the field at `field_offset' in object `a_object + a_physical_offset'.
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen boolean_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): BOOLEAN
			-- Boolean value of the field at `field_offset' in object `a_object + a_physical_offset'.
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen natural_8_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): NATURAL_8
			-- NATURAL_8 value of the field at `field_offset' in object `a_object + a_physical_offset'.
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen natural_16_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): NATURAL_16
			-- NATURAL_16 value of the field at `field_offset' in object `a_object + a_physical_offset'.
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen natural_32_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): NATURAL_32
			-- NATURAL_32 value of the field at `field_offset' in object `a_object + a_physical_offset'.
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen natural_64_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): NATURAL_64
			-- NATURAL_64 value of the field at `field_offset' in object `a_object + a_physical_offset'.
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen integer_8_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): INTEGER_8
			-- Integer value of the field at `field_offset' in object `a_object + a_physical_offset'.
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen integer_16_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): INTEGER_16
			-- Integer value of the field at `field_offset' in object `a_object + a_physical_offset'.
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen integer_32_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): INTEGER
			-- Integer value of the field at `field_offset' in object `a_object + a_physical_offset'.
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen integer_64_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): INTEGER_64
			-- Integer value of the field at `field_offset' in object `a_object + a_physical_offset'.
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen real_32_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): REAL_32
			-- Real value of the field at `field_offset' in object `a_object + a_physical_offset'.
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen pointer_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): POINTER
			-- Pointer value of the field at `field_offset' in object `a_object + a_physical_offset'.
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen real_64_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER): REAL_64
			-- Double precision value of the field at `field_offset' in object `a_object + a_physical_offset'.
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen is_special (a_object: POINTER): BOOLEAN
			-- Is `object' a special object?
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen is_special_of_expanded (a_object: POINTER): BOOLEAN
			-- Is type represented by `type_id' represent
			-- a SPECIAL [XX] where XX is a user defined expanded type.
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen is_special_of_reference (a_object: POINTER): BOOLEAN
			-- Is type represented by `type_id' represent
			-- a SPECIAL [XX] where XX is a reference type.
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen is_expanded (a_object: POINTER): BOOLEAN
			-- Is `a_object' an instance of an expanded type?
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen is_tuple (object: POINTER): BOOLEAN
			-- Is `object' a TUPLE object?
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_reference_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: detachable ANY)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_real_64_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: REAL_64)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_character_8_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: CHARACTER_8)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_character_32_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: CHARACTER_32)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_boolean_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: BOOLEAN)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_natural_8_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: NATURAL_8)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_natural_16_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: NATURAL_16)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_natural_32_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: NATURAL_32)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_natural_64_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: NATURAL_64)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_integer_8_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: INTEGER_8)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_integer_16_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: INTEGER_16)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_integer_32_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: INTEGER)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_integer_64_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: INTEGER_64)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_real_32_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: REAL_32)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_pointer_field (i: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: POINTER)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_reference_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: detachable ANY)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_real_64_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: REAL_64)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_character_8_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: CHARACTER_8)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_character_32_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: CHARACTER_32)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_boolean_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: BOOLEAN)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_natural_8_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: NATURAL_8)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_natural_16_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: NATURAL_16)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_natural_32_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: NATURAL_32)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_natural_64_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: NATURAL_64)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_integer_8_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: INTEGER_8)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_integer_16_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: INTEGER_16)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_integer_32_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: INTEGER)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_integer_64_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: INTEGER_64)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_real_32_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: REAL_32)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen set_pointer_field_at (field_offset: INTEGER; a_object: POINTER; a_physical_offset: INTEGER; value: POINTER)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen generic_parameter_count (a_type_id: INTEGER): INTEGER
			-- Number of generic parameters for object of dynamic type `a_type_id'.
		external
			"C inline use %"eif_gen_conf.h%""
		alias
			"return eif_gen_count_with_dftype(eif_decoded_type($a_type_id).id);"
		ensure
			instance_free: class
		end

	frozen eif_gen_param_id (a_type_id: INTEGER; i: INTEGER): INTEGER
			-- Type of `i'-th generic parameter for object of dynamic type `a_type_id'.
		external
			"C inline use %"eif_gen_conf.h%""
		alias
			"return eif_gen_param_id($a_type_id, $i);"
		ensure
			instance_free: class
		end

feature -- Object marking

	frozen lock_marking
			-- Get a lock on `mark' and `unmark' routine so that 2 threads cannot `mark' and
			-- `unmark' at the same time.
		external
			"C blocking use %"eif_traverse.h%""
		alias
			"eif_lock_marking"
		ensure
			instance_free: class
		end

	frozen unlock_marking
			-- Release a lock on `mark' and `unmark', so that another thread can
			-- use `mark' and `unmark'.
		external
			"C use %"eif_traverse.h%""
		alias
			"eif_unlock_marking"
		ensure
			instance_free: class
		end

	frozen is_object_marked (obj: POINTER): BOOLEAN
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen unmark_object (obj: POINTER)
		external
			"built_in static"
		ensure
			instance_free: class
		end

	frozen mark_object (obj: POINTER)
		external
			"built_in static"
		ensure
			instance_free: class
		end

note
	copyright: "Copyright (c) 1984-2018, Eiffel Software and others"
	license:   "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
