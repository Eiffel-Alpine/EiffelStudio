note
	description: "Ancestor to all Windows controls (button, list box, etc.)."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

deferred class
	WEL_CONTROL

inherit
	WEL_WINDOW
		redefine
			set_default_window_procedure,
			call_default_window_procedure
		end

	WEL_WS_CONSTANTS
		export
			{NONE} all
		end

feature {NONE} -- Initialization

	make_by_id (a_parent: WEL_DIALOG; an_id: INTEGER)
			-- Make a control identified by `an_id' with `a_parent'
			-- as parent.
		require
			a_parent_not_void: a_parent /= Void
			positive_id: an_id > 0
		do
			parent := a_parent
			id := an_id
			a_parent.dialog_children.extend (Current)
		ensure
			parent_set: parent = a_parent
			id_set: id = an_id
		end

feature -- Access

	id: INTEGER
			-- Control id

	font: WEL_FONT
			-- Font with which the control is drawing its text.
		require
			exists: exists
		do
			if has_system_font then
				Result := (create {WEL_SHARED_FONTS}).system_font
			else
				create Result.make_by_pointer (
					{WEL_API}.send_message_result (item, Wm_getfont,
					default_pointer, default_pointer))
			end
		ensure
			result_not_void: Result /= Void
		end

feature -- Element change

	set_font (a_font: WEL_FONT)
			-- Set `font' with `a_font'.
		require
			exists: exists
			a_font_not_void: a_font /= Void
			a_font_exists: a_font.exists
		do
			{WEL_API}.send_message (item, Wm_setfont,
				a_font.item, cwin_make_long (1, 0))
		ensure
			font_set: not has_system_font implies font.item = a_font.item
		end

feature -- Status report

	has_system_font: BOOLEAN
			-- Does the control use the system font?
		require
			exists: exists
		do
			Result := {WEL_API}.send_message_result (item, Wm_getfont,
				default_pointer, default_pointer) = default_pointer
		end

feature -- Basic operations

	default_process_notification (notification_code: INTEGER)
			-- Process a `notification_code' which has not been
			-- processed by `process_notification'.
		require
			exists: exists
		do
		end

	go_to_next_tab_item (a_parent: WEL_COMPOSITE_WINDOW; after: BOOLEAN)
			-- Find the previous or following control with the
			-- Wm_tabstop style in `a_parent depending on the
			-- value of `after'.
		require
			valid_parent: a_parent /= Void and then a_parent.exists
		local
			hwnd: POINTER
			window: detachable WEL_WINDOW
		do
			hwnd := cwin_get_next_dlgtabitem (a_parent.item, item, after)
			window := window_of_item (hwnd)
			if window /= Void then
				window.set_focus
			end
		end

	go_to_next_group_item (a_parent: WEL_COMPOSITE_WINDOW; after: BOOLEAN)
			-- Find the previous or following control with the
			-- Wm_tabstop style in the current group in `a_parent'
			-- depending on the value of `after'.
		require
			valid_parent: a_parent /= Void and then a_parent.exists
		local
			hwnd: POINTER
			window: detachable WEL_WINDOW
		do
			hwnd := cwin_get_next_dlggroupitem (a_parent.item, item, after)
			window := window_of_item (hwnd)
			if window /= Void then
				window.set_focus
			end
		end

feature {WEL_COMPOSITE_WINDOW}

	process_notification (notification_code: INTEGER)
			-- Process a `notification_code' sent by Windows
		require
			exists: exists
		do
			default_process_notification (notification_code)
		end

	process_notification_info (notification_info: WEL_NMHDR)
			-- Process a `notification_info' sent by Windows
		require
			exists: exists
			notification_info_not_void: notification_info /= Void
			notification_info_exists: notification_info.exists
		do
		end

feature {WEL_DIALOG} -- Implementation

	set_default_window_procedure
			-- Set `default_window_procedure' with the
			-- previous window procedure and set the
			-- new one with `cwel_window_procedure_address'
		do
				-- Keep the previous one
			default_window_procedure := cwin_get_window_long (item, Gwlp_wndproc)

				-- Set the new one
			cwin_set_window_long (item, Gwlp_wndproc, cwel_window_procedure_address)
		end

	call_default_window_procedure (hwnd: POINTER; msg: INTEGER; wparam, lparam: POINTER): POINTER
		do
			Result := cwin_call_window_proc (default_window_procedure,
				hwnd, msg, wparam, lparam)
		end

feature {NONE} -- Externals

	cwin_call_window_proc (proc, hwnd: POINTER; msg: INTEGER; wparam, lparam: POINTER): POINTER
			-- SDK CallWindowProc
		external
			"C [macro <wel.h>] (WNDPROC, HWND, UINT, WPARAM, LPARAM): LRESULT"
		alias
			"CallWindowProc"
		end

	cwin_get_next_dlggroupitem (hdlg, hctl: POINTER; previous: BOOLEAN): POINTER
			-- SDK GetNextDlgGroupItem
		external
			"C [macro <wel.h>] (HWND, HWND, BOOL): HWND"
		alias
			"GetNextDlgGroupItem"
		end

	cwin_get_next_dlgtabitem (hdlg, hctl: POINTER; previous: BOOLEAN): POINTER
			-- SDK GetNextDlgGroupItem
		external
			"C [macro <wel.h>] (HWND, HWND, BOOL): HWND"
		alias
			"GetNextDlgTabItem"
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




end -- class WEL_CONTROL

