note

	description:

		"Test XPath Cast Expressions and type constructors"

	library: "Gobo Eiffel XPath Library"
	copyright: "Copyright (c) 2001-2017, Colin Adams and others"
	license: "MIT License"
	date: "$Date$"
	revision: "$Revision$"

class XM_XPATH_TEST_CAST_EXPRESSION

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

feature -- Test

	test_untyped_atomic_to_untyped_atomic
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:untypedAtomic.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('fred') cast as xs:untypedAtomic")
--			diagnose_evaluation_error (an_evaluator)
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("One evaluated item", evaluated_items /= Void and then evaluated_items.count = 1)
			assert ("String value", STRING_.same_string (evaluated_items.item (1).string_value, "fred"))
		end

	test_untyped_atomic_to_string
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:string.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('fred') cast as xs:string")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("One evaluated item", evaluated_items /= Void and then evaluated_items.count = 1)
			assert ("String value", STRING_.same_string (evaluated_items.item (1).string_value, "fred"))
		end

	test_untyped_atomic_to_any_uri
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:anyURI
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('fred') cast as xs:anyURI")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("One evaluated item", evaluated_items /= Void and then evaluated_items.count = 1)
			assert ("String value", STRING_.same_string (evaluated_items.item (1).string_value, "fred"))
		end

	test_untyped_atomic_to_notation
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:NOTATION.
		local
			an_evaluator: XM_XPATH_EVALUATOR
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('fred') cast as xs:NOTATION")
			-- xs:NOTATION not supported by basic-level processor
			assert ("Evaluation error", an_evaluator.is_error)
		end

	test_untyped_atomic_to_bad_float
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:float.
		local
			an_evaluator: XM_XPATH_EVALUATOR
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('fred') cast as xs:float")
			assert ("Evaluation error", an_evaluator.is_error)
		end

	test_untyped_atomic_to_float
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:float.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic (' 17.5E-12') cast as xs:float")
			assert ("No valuation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			if not attached {XM_XPATH_FLOAT_VALUE} evaluated_items.item (1) as a_float_value then
				assert ("a_float_value_not_void", False)
			else
				assert ("Correct value", a_float_value.value <= 17.5E-12 and then a_float_value.value >= 17.4E-12)
			end
		end

	test_untyped_atomic_to_double_unsucessful
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:double, with invalid value.
		local
			an_evaluator: XM_XPATH_EVALUATOR
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('fred') cast as xs:double")
			assert ("Evaluation error", an_evaluator.is_error and then an_evaluator.error_value.type = Dynamic_error and STRING_.same_string (an_evaluator.error_value.code, "FORG0001"))
		end

	test_untyped_atomic_to_double
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:double.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic (' 17.5E-12') cast as xs:double")
			assert ("No valuation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			if not attached {XM_XPATH_DOUBLE_VALUE} evaluated_items.item (1) as a_double_value then
				assert ("a_double_value_not_void", False)
			else
				assert_doubles_equal_with_tolerance ("Correct value", 17.5E-12, a_double_value.value, 1.0E-25)
			end
		end

	test_untyped_atomic_to_decimal_unsucessful
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:decimal, with invalid value.
		local
			an_evaluator: XM_XPATH_EVALUATOR
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('fred') cast as xs:decimal")
			assert ("Evaluation error", an_evaluator.is_error and then an_evaluator.error_value.type = Dynamic_error and STRING_.same_string (an_evaluator.error_value.code, "FORG0001"))
		end

	test_untyped_atomic_to_decimal
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:decimal
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
			a_decimal: MA_DECIMAL
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic (' 256.7198003 ') cast as xs:decimal")
			assert ("No valuation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			create a_decimal.make_from_string ("256.7198003")
			if not attached {XM_XPATH_DECIMAL_VALUE} evaluated_items.item (1) as a_decimal_value then
				assert ("a_decimal_value_not_void", False)
			else
				assert ("Correct value", a_decimal_value.value.is_equal (a_decimal))
			end
		end

	test_untyped_atomic_to_integer_unsucessful
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:integer, with invalid value.
		local
			an_evaluator: XM_XPATH_EVALUATOR
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('fred') cast as xs:integer")
			assert ("Evaluation error", an_evaluator.is_error and then an_evaluator.error_value.type = Dynamic_error and STRING_.same_string (an_evaluator.error_value.code, "FORG0001"))
		end

	test_untyped_atomic_to_integer
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:integer
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic (' 56 ') cast as xs:integer")
			assert ("No valuation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			if not attached {XM_XPATH_MACHINE_INTEGER_VALUE} evaluated_items.item (1) as an_integer_value then
				assert ("an_integer_value_not_void", False)
			else
				assert ("Correct value", an_integer_value.value = 56)
			end
		end

	test_untyped_atomic_to_boolean_unsucessful
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:boolean, with invalid value.
		local
			an_evaluator: XM_XPATH_EVALUATOR
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('fred') cast as xs:boolean")
			assert ("Evaluation error", an_evaluator.is_error and then an_evaluator.error_value.type = Dynamic_error and STRING_.same_string (an_evaluator.error_value.code, "FORG0001"))
		end

	test_untyped_atomic_to_boolean
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:boolean.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic (' true ') cast as xs:boolean")
			assert ("No valuation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			if not attached {XM_XPATH_BOOLEAN_VALUE} evaluated_items.item (1) as a_boolean_value then
				assert ("a_boolean_value_not_void", False)
			else
				assert ("Correct value", a_boolean_value.value)
			end
		end

	test_untyped_atomic_to_qname_unsucessful
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:QName, with invalid value.
		local
			an_evaluator: XM_XPATH_EVALUATOR
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('xs:b:fred') cast as xs:QName")
			assert ("Evaluation error", an_evaluator.is_error and then an_evaluator.error_value.type = Static_error and STRING_.same_string (an_evaluator.error_value.code, "XPTY0004"))
		end

	test_untyped_atomic_to_qname_2
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:QName.
		local
			an_evaluator: XM_XPATH_EVALUATOR
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('xs:untypedAtomic') cast as xs:QName")
			assert ("Evaluation error", an_evaluator.is_error and then an_evaluator.error_value.type = Static_error and STRING_.same_string (an_evaluator.error_value.code, "XPTY0004"))
		end

	test_untyped_atomic_to_date
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:date.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('2005-09-08Z') cast as xs:date")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("Date value", attached {XM_XPATH_DATE_VALUE} evaluated_items.item (1))
		end

	test_untyped_atomic_to_zoneless_date
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:date.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('2005-09-08') cast as xs:date")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("Date value", attached {XM_XPATH_DATE_VALUE} evaluated_items.item (1))
		end

	test_untyped_atomic_to_date_unsucessful
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:date, with invalid value.
		local
			an_evaluator: XM_XPATH_EVALUATOR
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('fred') cast as xs:date")
			assert ("Evaluation error", an_evaluator.is_error and then an_evaluator.error_value.type = Dynamic_error and STRING_.same_string (an_evaluator.error_value.code, "FORG0001"))
		end

	test_untyped_atomic_to_zoneless_time
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:time.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('12:05:35.465987') cast as xs:time")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("Time value", attached {XM_XPATH_TIME_VALUE} evaluated_items.item (1))
		end

	test_untyped_atomic_to_date_time
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:dateTime.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('2005-09-08T12:07:40.5Z') cast as xs:dateTime")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("DateTime value", attached {XM_XPATH_DATE_TIME_VALUE} evaluated_items.item (1))
		end

	test_untyped_atomic_to_duration
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:duration.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('P2Y5MT12H09M08.5674S') cast as xs:duration")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("Duration value", attached {XM_XPATH_DURATION_VALUE} evaluated_items.item (1))
		end

	test_untyped_atomic_to_year_month_duration
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:yearMonthDuration.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('P2Y5M') cast as xs:yearMonthDuration")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("YearMonthDuration value", attached {XM_XPATH_MONTHS_DURATION_VALUE} evaluated_items.item (1))
		end

	test_untyped_atomic_to_day_time_duration
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:dayTimeDuration.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('P3DT4H7M') cast as xs:dayTimeDuration")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("DayTimeDuration value", attached {XM_XPATH_SECONDS_DURATION_VALUE} evaluated_items.item (1))
		end

	test_untyped_atomic_to_g_year_month
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:gYearMonth.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('2005-09') castable as xs:gYearMonth")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			if not attached {XM_XPATH_BOOLEAN_VALUE} evaluated_items.item (1) as a_boolean_value then
				assert ("a_boolean_value_not_void_1", False)
			else
				assert ("Castable", a_boolean_value.value)
			end
			an_evaluator.evaluate ("xs:untypedAtomic ('2005-09') cast as xs:gYearMonth")
			assert ("No evaluation error 2", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("gYearMonth value", attached {XM_XPATH_YEAR_MONTH_VALUE} evaluated_items.item (1))
			an_evaluator.evaluate ("xs:untypedAtomic ('2005--09') castable as xs:gYearMonth")
			assert ("No evaluation error 3", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			if not attached {XM_XPATH_BOOLEAN_VALUE} evaluated_items.item (1) as a_boolean_value then
				assert ("a_boolean_value_not_void_2", False)
			else
				assert ("Not castable", not a_boolean_value.value)
			end
		end

	test_untyped_atomic_to_g_year
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:gYear.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('2005') castable as xs:gYear")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			if not attached {XM_XPATH_BOOLEAN_VALUE} evaluated_items.item (1) as a_boolean_value then
				assert ("a_boolean_value_not_void_1", False)
			else
				assert ("Castable", a_boolean_value.value)
			end
			an_evaluator.evaluate ("xs:untypedAtomic ('2005') cast as xs:gYear")
			assert ("No evaluation error 2", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("gYear value",  attached {XM_XPATH_YEAR_VALUE} evaluated_items.item (1))
			an_evaluator.evaluate ("xs:untypedAtomic ('2005--09') castable as xs:gYear")
			assert ("No evaluation error 3", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			if not attached {XM_XPATH_BOOLEAN_VALUE} evaluated_items.item (1) as a_boolean_value then
				assert ("a_boolean_value_not_void_2", False)
			else
				assert ("Not castable", not a_boolean_value.value)
			end
		end

	test_untyped_atomic_to_g_month
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:gMonth.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('--09') castable as xs:gMonth")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			if not attached {XM_XPATH_BOOLEAN_VALUE} evaluated_items.item (1) as a_boolean_value then
				assert ("a_boolean_value_not_void_1", False)
			else
				assert ("Castable", a_boolean_value.value)
			end
			an_evaluator.evaluate ("xs:untypedAtomic ('--09') cast as xs:gMonth")
			assert ("No evaluation error 2", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("gMonth value", attached {XM_XPATH_MONTH_VALUE} evaluated_items.item (1))
			an_evaluator.evaluate ("xs:untypedAtomic ('2005--09') castable as xs:gMonth")
			assert ("No evaluation error 3", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			if not attached {XM_XPATH_BOOLEAN_VALUE} evaluated_items.item (1) as a_boolean_value then
				assert ("a_boolean_value_not_void_2", False)
			else
				assert ("Not castable", not a_boolean_value.value)
			end
		end

	test_untyped_atomic_to_g_month_day
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:gMonthDay.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('--05-09') castable as xs:gMonthDay")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			if not attached {XM_XPATH_BOOLEAN_VALUE} evaluated_items.item (1) as a_boolean_value then
				assert ("a_boolean_value_not_void_1", False)
			else
				assert ("Castable", a_boolean_value.value)
			end
			an_evaluator.evaluate ("xs:untypedAtomic ('--05-09') cast as xs:gMonthDay")
			assert ("No evaluation error 2", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("gMonthDay value", attached {XM_XPATH_MONTH_DAY_VALUE} evaluated_items.item (1))
			an_evaluator.evaluate ("xs:untypedAtomic ('2005--09') castable as xs:gMonthDay")
			assert ("No evaluation error 3", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			if not attached {XM_XPATH_BOOLEAN_VALUE} evaluated_items.item (1) as a_boolean_value then
				assert ("a_boolean_value_not_void_2", False)
			else
				assert ("Not castable", not a_boolean_value.value)
			end
		end

	test_untyped_atomic_to_g_day
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:gDay.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('---09') castable as xs:gDay")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			if not attached {XM_XPATH_BOOLEAN_VALUE} evaluated_items.item (1) as a_boolean_value then
				assert ("a_boolean_value_not_void_1", False)
			else
				assert ("Castable", a_boolean_value.value)
			end
			an_evaluator.evaluate ("xs:untypedAtomic ('---09') cast as xs:gDay")
			assert ("No evaluation error 2", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("gDay value", attached {XM_XPATH_DAY_VALUE} evaluated_items.item (1))
			an_evaluator.evaluate ("xs:untypedAtomic ('2005--09') castable as xs:gDay")
			assert ("No evaluation error 3", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			if not attached {XM_XPATH_BOOLEAN_VALUE} evaluated_items.item (1) as a_boolean_value then
				assert ("a_boolean_value_not_void_2", False)
			else
				assert ("Not castable", not a_boolean_value.value)
			end
		end

	test_untyped_atomic_to_base64
			-- Test creating an xs:untypedAtomic from a string then casting it to an xs:base64Binary.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:untypedAtomic ('" + encoded_string + "') castable as xs:base64Binary")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			if not attached {XM_XPATH_BOOLEAN_VALUE} evaluated_items.item (1) as a_boolean_value then
				assert ("a_boolean_value_not_void_1", False)
			else
				assert ("Castable", a_boolean_value.value)
			end
			an_evaluator.evaluate ("xs:untypedAtomic ('" + encoded_string + "') cast as xs:base64Binary")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("base64Binary value", attached {XM_XPATH_BASE64_BINARY_VALUE} evaluated_items.item (1))
		end

	test_base64_to_hex_binary
			-- Test casting an xs:base64Binary to an xs:hexBinary.
		local
			an_evaluator: XM_XPATH_EVALUATOR
			evaluated_items: DS_LINKED_LIST [XM_XPATH_ITEM]
		do
			create an_evaluator.make (18, False)
			an_evaluator.set_string_mode_ascii
			an_evaluator.build_static_context (books_xml_uri.full_reference, False, False, False, True)
			assert ("Build successful", not an_evaluator.was_build_error)
			an_evaluator.evaluate ("xs:base64Binary ('" + encoded_string + "') castable as xs:hexBinary")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			if not attached {XM_XPATH_BOOLEAN_VALUE} evaluated_items.item (1) as a_boolean_value then
				assert ("a_boolean_value_not_void_1", False)
			else
				assert ("Castable", a_boolean_value.value)
			end
			an_evaluator.evaluate ("xs:base64Binary ('" + encoded_string + "') cast as xs:hexBinary")
			assert ("No evaluation error", not an_evaluator.is_error)
			evaluated_items := an_evaluator.evaluated_items
			assert ("hexBinary value", attached {XM_XPATH_HEX_BINARY_VALUE} evaluated_items.item (1))
		end

feature -- Set up

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

	diagnose_evaluation_error (an_evaluator: XM_XPATH_EVALUATOR)
			-- Print error diagnosis to standard error stream.
		do
			std.error.put_string (an_evaluator.error_value.error_message)
			std.error.put_string (", error code is ")
			std.error.put_string (an_evaluator.error_value.code.out)
			std.error.put_new_line
		end

	encoded_string: STRING = "R0lGODdhMAAwAPAAAAAAAP///ywAAAAAMAAwAAAC8IyPqcvt3wCcDkiLc7C0qwyGHhSWpjQu5yqmCYsapyuvUUlvONmOZtfzgFzByTB10QgxOR0TqBQejhRNzOfkVJ+5YiUqrXF5Y5lKh/DeuNcP5yLWGsEbtLiOSpa/TPg7JpJHxyendzWTBfX0cxOnKPjgBzi4diinWGdkF8kjdfnycQZXZeYGejmJlZeGl9i2icVqaNVailT6F5iJ90m6mvuTS4OK05M0vDk0Q4XUtwvKOzrcd3iq9uisF81M1OIcR7lEewwcLp7tuNNkM3uNna3F2JQFo97Vriy/Xl4/f1cf5VWzXyym7PHhhx4dbgYKAAA7"
			-- base64-encoded image/gif file
end


