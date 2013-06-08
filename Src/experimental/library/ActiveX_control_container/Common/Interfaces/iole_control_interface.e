note
	description: "Control interfaces. Help file: "
	legal: "See notice at end of class."
	status: "See notice at end of class."
	generator: "Automatically generated by the EiffelCOM Wizard."

deferred class
	IOLE_CONTROL_INTERFACE

inherit
	ECOM_INTERFACE

feature -- Status Report

	get_control_info_user_precondition (p_ci: TAG_CONTROLINFO_RECORD): BOOLEAN
			-- User-defined preconditions for `get_control_info'.
			-- Redefine in descendants if needed.
		do
			Result := True
		end

	on_mnemonic_user_precondition (p_msg: TAG_MSG_RECORD): BOOLEAN
			-- User-defined preconditions for `on_mnemonic'.
			-- Redefine in descendants if needed.
		do
			Result := True
		end

	on_ambient_property_change_user_precondition (disp_id: INTEGER): BOOLEAN
			-- User-defined preconditions for `on_ambient_property_change'.
			-- Redefine in descendants if needed.
		do
			Result := True
		end

	freeze_events_user_precondition (b_freeze: INTEGER): BOOLEAN
			-- User-defined preconditions for `freeze_events'.
			-- Redefine in descendants if needed.
		do
			Result := True
		end

feature -- Basic Operations

	get_control_info (p_ci: TAG_CONTROLINFO_RECORD)
			-- No description available.
			-- `p_ci' [out].  
		require
			non_void_p_ci: p_ci /= Void
			valid_p_ci: p_ci.item /= default_pointer
			get_control_info_user_precondition: get_control_info_user_precondition (p_ci)
		deferred

		end

	on_mnemonic (p_msg: TAG_MSG_RECORD)
			-- No description available.
			-- `p_msg' [in].  
		require
			non_void_p_msg: p_msg /= Void
			valid_p_msg: p_msg.item /= default_pointer
			on_mnemonic_user_precondition: on_mnemonic_user_precondition (p_msg)
		deferred

		end

	on_ambient_property_change (disp_id: INTEGER)
			-- No description available.
			-- `disp_id' [in].  
		require
			on_ambient_property_change_user_precondition: on_ambient_property_change_user_precondition (disp_id)
		deferred

		end

	freeze_events (b_freeze: INTEGER)
			-- No description available.
			-- `b_freeze' [in].  
		require
			freeze_events_user_precondition: freeze_events_user_precondition (b_freeze)
		deferred

		end

note
	copyright:	"Copyright (c) 1984-2006, Eiffel Software and others"
	license:	"Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			 Eiffel Software
			 356 Storke Road, Goleta, CA 93117 USA
			 Telephone 805-685-1006, Fax 805-685-6869
			 Website http://www.eiffel.com
			 Customer support http://support.eiffel.com
		]"




end -- IOLE_CONTROL_INTERFACE
