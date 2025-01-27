note

	description:

		"Test XPath round() function."

	library: "Gobo Eiffel XPath Library"
	copyright: "Copyright (c) 2005-2017, Colin Adams and others"
	license: "MIT License"
	date: "$Date$"
	revision: "$Revision$"

class XM_XPATH_TEST_ROUND

inherit

	TS_TEST_CASE
		redefine
			set_up
		end

	XM_XPATH_TYPE

	XM_XPATH_ERROR_TYPES

	XM_XPATH_SHARED_CONFORMANCE

	KL_IMPORTED_STRING_ROUTINES

	KL_SHARED_STANDARD_FILES

	KL_SHARED_FILE_SYSTEM
		export {NONE} all end

	UT_SHARED_FILE_URI_ROUTINES
		export {NONE} all end

create

	make_default

feature -- Constants

	two: MA_DECIMAL
			-- 2 as a decimal
		once
			create Result.make_from_integer (2)
		ensure
			two_not_void: Result /= Void
		end

	minus_two: MA_DECIMAL
			-- -2 as a decimal
		once
			create Result.make_from_integer (-2)
		ensure
			minus_two_not_void: Result /= Void
		end

	three: MA_DECIMAL
			-- 3 as a decimal
		once
			create Result.make_from_integer (3)
		ensure
			three_not_void: Result /= Void
		end

feature -- Tests

	test_round_one
			-- Test fn:round (2.5) returns 3.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("round (2.5)")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("One evaluated item", evaluated_items /= Void and then evaluated_items.count = 1)
			if not attached {XM_XPATH_DECIMAL_VALUE} evaluated_items.item (1) as a_decimal_value then
				assert ("Decimal value", False)
			else
				assert ("Result is three", a_decimal_value.value.is_equal (three))
			end
		end

	test_round_two
			-- Test fn:round (2.4999) returns 2.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("round (2.4999)")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("One evaluated item", evaluated_items /= Void and then evaluated_items.count = 1)
			if not attached {XM_XPATH_DECIMAL_VALUE} evaluated_items.item (1) as a_decimal_value then
				assert ("Decimal value", False)
			else
				assert ("Result is two", a_decimal_value.value.is_equal (two))
			end
		end

	test_round_three
			-- Test fn:round (-2.5) returns -2.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("round (-2.5)")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("One evaluated item", evaluated_items /= Void and then evaluated_items.count = 1)
			if not attached {XM_XPATH_DECIMAL_VALUE} evaluated_items.item (1) as a_decimal_value then
				assert ("Decimal value", False)
			else
				assert ("Result is minus two", a_decimal_value.value.is_equal (minus_two))
			end
		end

	test_round_double_one
			-- Test fn:round (2.5E0) returns 3E0.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("round (2.5E0)")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("One evaluated item", evaluated_items /= Void and then evaluated_items.count = 1)
			if not attached {XM_XPATH_DOUBLE_VALUE} evaluated_items.item (1) as a_double_value then
				assert ("Double value", False)
			else
				assert ("Result is three", a_double_value.value = 3.0)
			end
		end

	test_round_double_two
			-- Test fn:round (2.4999E0) returns 2E0.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("round (2.4999E0)")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("One evaluated item", evaluated_items /= Void and then evaluated_items.count = 1)
			if not attached {XM_XPATH_DOUBLE_VALUE} evaluated_items.item (1) as a_double_value then
				assert ("Double value", False)
			else
				assert ("Result is two", a_double_value.value = 2.0)
			end
		end

	test_round_double_three
			-- Test fn:round (-2.5E0) returns -2.0.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("round (-2.5E0)")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("One evaluated item", evaluated_items /= Void and then evaluated_items.count = 1)
			if not attached {XM_XPATH_DOUBLE_VALUE} evaluated_items.item (1) as a_double_value then
				assert ("Double value", False)
			else
				assert ("Result is minus two", a_double_value.value = -2.0)
			end
		end

	test_round_float
			-- Test fn:round (xs:float(-2.5E0)) returns -2.0.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("round (xs:float(-2.5E0))")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("One evaluated item", evaluated_items /= Void and then evaluated_items.count = 1)
			if not attached {XM_XPATH_FLOAT_VALUE} evaluated_items.item (1) as a_float_value then
				assert ("Float value", False)
			else
				assert ("Result is minus two", a_float_value.value = -2.0)
			end
		end

	set_up
		do
			conformance.set_basic_xslt_processor
		end

feature {NONE} -- Implementation

	data_dirname: STRING
			-- Name of directory containing data files
		once
			Result := file_system.nested_pathname ("${GOBO}", <<"library", "xpath", "test", "unit", "data">>)
			Result := Execution_environment.interpreted_string (Result)
		ensure
			data_dirname_not_void: Result /= Void
			data_dirname_not_empty: not Result.is_empty
		end

	books_xml_uri: UT_URI
			-- URI of file 'books.xml'
		local
			a_path: STRING
		once
			a_path := file_system.pathname (data_dirname, "books.xml")
			Result := File_uri.filename_to_uri (a_path)
		ensure
			books_xml_uri_not_void: Result /= Void
		end

end


