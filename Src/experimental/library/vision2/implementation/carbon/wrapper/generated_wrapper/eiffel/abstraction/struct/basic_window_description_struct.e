-- This file has been generated by EWG. Do not edit. Changes will be lost!

class BASIC_WINDOW_DESCRIPTION_STRUCT

inherit

	EWG_STRUCT

	BASIC_WINDOW_DESCRIPTION_STRUCT_EXTERNAL
		export
			{NONE} all
		end

create

	make_new_unshared,
	make_new_shared,
	make_unshared,
	make_shared

feature {ANY} -- Access

	sizeof: INTEGER is
		do
			Result := sizeof_external
		end

feature {ANY} -- Member Access

	descriptionsize: INTEGER is
			-- Access member `descriptionSize'
		require
			exists: exists
		do
			Result := get_descriptionsize_external (item)
		ensure
			result_correct: Result = get_descriptionsize_external (item)
		end

	set_descriptionsize (a_value: INTEGER) is
			-- Set member `descriptionSize'
		require
			exists: exists
		do
			set_descriptionsize_external (item, a_value)
		ensure
			a_value_set: a_value = descriptionsize
		end

	windowcontentrect: POINTER is
			-- Access member `windowContentRect'
		require
			exists: exists
		do
			Result := get_windowcontentrect_external (item)
		ensure
			result_correct: Result = get_windowcontentrect_external (item)
		end

	set_windowcontentrect (a_value: POINTER) is
			-- Set member `windowContentRect'
		require
			exists: exists
		do
			set_windowcontentrect_external (item, a_value)
		end

	windowzoomrect: POINTER is
			-- Access member `windowZoomRect'
		require
			exists: exists
		do
			Result := get_windowzoomrect_external (item)
		ensure
			result_correct: Result = get_windowzoomrect_external (item)
		end

	set_windowzoomrect (a_value: POINTER) is
			-- Set member `windowZoomRect'
		require
			exists: exists
		do
			set_windowzoomrect_external (item, a_value)
		end

	windowrefcon: INTEGER is
			-- Access member `windowRefCon'
		require
			exists: exists
		do
			Result := get_windowrefcon_external (item)
		ensure
			result_correct: Result = get_windowrefcon_external (item)
		end

	set_windowrefcon (a_value: INTEGER) is
			-- Set member `windowRefCon'
		require
			exists: exists
		do
			set_windowrefcon_external (item, a_value)
		ensure
			a_value_set: a_value = windowrefcon
		end

	windowstateflags: INTEGER is
			-- Access member `windowStateFlags'
		require
			exists: exists
		do
			Result := get_windowstateflags_external (item)
		ensure
			result_correct: Result = get_windowstateflags_external (item)
		end

	set_windowstateflags (a_value: INTEGER) is
			-- Set member `windowStateFlags'
		require
			exists: exists
		do
			set_windowstateflags_external (item, a_value)
		ensure
			a_value_set: a_value = windowstateflags
		end

	windowpositionmethod: INTEGER is
			-- Access member `windowPositionMethod'
		require
			exists: exists
		do
			Result := get_windowpositionmethod_external (item)
		ensure
			result_correct: Result = get_windowpositionmethod_external (item)
		end

	set_windowpositionmethod (a_value: INTEGER) is
			-- Set member `windowPositionMethod'
		require
			exists: exists
		do
			set_windowpositionmethod_external (item, a_value)
		ensure
			a_value_set: a_value = windowpositionmethod
		end

	windowdefinitionversion: INTEGER is
			-- Access member `windowDefinitionVersion'
		require
			exists: exists
		do
			Result := get_windowdefinitionversion_external (item)
		ensure
			result_correct: Result = get_windowdefinitionversion_external (item)
		end

	set_windowdefinitionversion (a_value: INTEGER) is
			-- Set member `windowDefinitionVersion'
		require
			exists: exists
		do
			set_windowdefinitionversion_external (item, a_value)
		ensure
			a_value_set: a_value = windowdefinitionversion
		end

end