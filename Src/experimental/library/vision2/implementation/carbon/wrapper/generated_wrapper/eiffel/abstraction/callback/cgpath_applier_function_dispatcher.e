-- This file has been generated by EWG. Do not edit. Changes will be lost!

class CGPATH_APPLIER_FUNCTION_DISPATCHER

inherit

	ANY

	EWG_CARBON_CALLBACK_C_GLUE_CODE_FUNCTIONS_EXTERNAL
		export {NONE} all end

create

	make

feature {NONE}

	make (a_callback: CGPATH_APPLIER_FUNCTION_CALLBACK) is
		require
			a_callback_not_void: a_callback /= Void
		do
			callback := a_callback
			set_cgpath_applier_function_entry_external (Current, $on_callback)
		end

feature {ANY}

	callback: CGPATH_APPLIER_FUNCTION_CALLBACK

	c_dispatcher: POINTER is
		do
			Result := get_cgpath_applier_function_stub_external
		end

feature {NONE} -- Implementation

	frozen on_callback (a_info: POINTER; a_element: POINTER) is 
		do
			callback.on_callback (a_info, a_element) 
		end

invariant

	 callback_not_void: callback /= Void

end