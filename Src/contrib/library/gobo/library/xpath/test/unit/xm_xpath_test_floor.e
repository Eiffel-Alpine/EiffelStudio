note

	description:

		"Test XPath floor() function."

	library: "Gobo Eiffel XPath Library"
	copyright: "Copyright (c) 2005-2017, Colin Adams and others"
	license: "MIT License"
	date: "$Date$"
	revision: "$Revision$"

class XM_XPATH_TEST_FLOOR

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

feature -- Constant

	ten: MA_DECIMAL
			-- 10 as a decimal
		once
			create Result.make_from_integer (10)
		ensure
			ten_not_void: Result /= Void
		end

	minus_eleven: MA_DECIMAL
			-- -11 as a decimal
		once
			create Result.make_from_integer (-11)
		ensure
			minus_eleven_not_void: Result /= Void
		end

feature -- Test

	test_positive_floor
			-- Test fn:floor (10.5) returns 10.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("floor (10.5)")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("One evaluated item", evaluated_items /= Void and then evaluated_items.count = 1)
			if not attached {XM_XPATH_DECIMAL_VALUE} evaluated_items.item (1) as a_decimal_value then
				assert ("Decimal value", False)
			else
				assert ("Result is 10", a_decimal_value.value.is_equal (ten))
			end
		end

	test_negative_floor
			-- Test fn:floor (-10.5) returns -11.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("floor (-10.5)")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("One evaluated item", evaluated_items /= Void and then evaluated_items.count = 1)
			if not attached {XM_XPATH_DECIMAL_VALUE} evaluated_items.item (1) as a_decimal_value then
				assert ("Decimal value", False)
			else
				assert ("Result is -11", a_decimal_value.value.is_equal (minus_eleven))
			end
		end

	test_positive_double_floor
			-- Test fn:floor (10.5E0) returns 10.0.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("floor (10.5E0)")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("One evaluated item", evaluated_items /= Void and then evaluated_items.count = 1)
			if not attached {XM_XPATH_DOUBLE_VALUE} evaluated_items.item (1) as a_double_value then
				assert ("Double value", False)
			else
				assert ("Result is 10.0", a_double_value.value = 10.0)
			end
		end

	test_negative_double_floor
			-- Test fn:floor (-10.5) returns -11.0.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("floor (-10.5E0)")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("One evaluated item", evaluated_items /= Void and then evaluated_items.count = 1)
			if not attached {XM_XPATH_DOUBLE_VALUE} evaluated_items.item (1) as a_double_value then
				assert ("Double value", False)
			else
				assert ("Result is -11.0", a_double_value.value = -11.0)
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


