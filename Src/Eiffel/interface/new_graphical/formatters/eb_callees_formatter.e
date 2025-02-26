note
	description: "Command to display the callees of a feature."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	EB_CALLEES_FORMATTER

inherit
	EB_FEATURE_CONTENT_FORMATTER
		rename
			make as feature_formatter_make
		redefine
			result_data,
			browser,
			generate_result
		end

	EB_SHARED_PREFERENCES

create
	make

feature {NONE} -- Initialization

	make (a_manager: like manager; a_flag: like flag)
			-- Create callers formatter associated with `a_manager' and which only
			-- look for `a_flag' type callers.
		require
			a_manager_not_void: a_manager /= Void
		do
			flag := a_flag
			feature_formatter_make (a_manager)
		ensure
			manager_set: manager = a_manager
			flag_set: flag = a_flag
		end

feature -- Access

	symbol: ARRAY [EV_PIXMAP]
			-- Graphical representation of the command.
		do
			Result := internal_symbol
			if Result = Void then
				inspect
					flag
				when {DEPEND_UNIT}.is_in_assignment_flag then
					create Result.make_filled (pixmaps.icon_pixmaps.feature_assignees_icon, 1, 2)
				when {DEPEND_UNIT}.is_in_creation_flag then
					create Result.make_filled (pixmaps.icon_pixmaps.feature_creaters_icon, 1, 2)
				else
					create Result.make_filled (pixmaps.icon_pixmaps.feature_callees_icon, 1, 2)
				end
				internal_symbol := Result
			end
		end

	menu_name: STRING_GENERAL
			-- Identifier of `Current' in menus.
		do
			inspect flag
			when {DEPEND_UNIT}.is_in_assignment_flag then
				Result := interface_names.m_show_assignees
			when {DEPEND_UNIT}.is_in_creation_flag then
				Result := interface_names.m_Show_creation
			else
				Result := Interface_names.m_Showcallees
			end
		end

	capital_command_name: STRING_GENERAL
			-- Name of the command.
		do
			inspect flag
			when {DEPEND_UNIT}.is_in_assignment_flag then
				Result := interface_names.l_assignees
			when {DEPEND_UNIT}.is_in_creation_flag then
				Result := interface_names.l_created
			else
				Result := Interface_names.l_callees
			end
		end

	post_fix: STRING
			-- String symbol of the command, used as an extension when saving.
		do
			inspect flag
			when {DEPEND_UNIT}.is_in_assignment_flag then
				Result := "ass"
			when {DEPEND_UNIT}.is_in_creation_flag then
				Result := "cre"
			else
				Result := "cal"
			end
		end

	pixel_buffer: EV_PIXEL_BUFFER
			-- Pixel buffer representation of the command.
		do
			inspect
				flag
			when {DEPEND_UNIT}.is_in_assignment_flag then
				Result := pixmaps.icon_pixmaps.feature_assignees_icon_buffer
			when {DEPEND_UNIT}.is_in_creation_flag then
				Result := pixmaps.icon_pixmaps.feature_creaters_icon_buffer
			else
				Result := pixmaps.icon_pixmaps.feature_callees_icon_buffer
			end
		end

	flag: NATURAL_16
 			-- Flag for type of callers.

 	browser: EB_CLASS_BROWSER_CALLER_CALLEE_VIEW
 			-- Browser

	displayer_generator: TUPLE [any_generator: FUNCTION [like displayer]; name: STRING]
			-- Generator to generate proper `displayer' for Current formatter
		do
			Result := [agent displayer_generators.new_feature_callee_displayer, displayer_generators.feature_callee_displayer]
		end

	sorting_status_preference: STRING_PREFERENCE
			-- Preference to store last sorting orders of Current formatter
		do
			Result := preferences.class_browser_data.callee_sorting_order_preference
		end

	mode: NATURAL_8
			-- Formatter mode, see {ES_FEATURE_RELATION_TOOL_VIEW_MODES} for applicable values.
		do
			inspect flag
			when {DEPEND_UNIT}.is_in_assignment_flag then
				Result := {ES_FEATURE_RELATION_TOOL_VIEW_MODES}.assignees
			when {DEPEND_UNIT}.is_in_creation_flag then
				Result := {ES_FEATURE_RELATION_TOOL_VIEW_MODES}.creations
			else
				Result := {ES_FEATURE_RELATION_TOOL_VIEW_MODES}.callees
			end
		end

feature -- Status report

	is_dotnet_formatter: BOOLEAN
			-- Is Current able to format .NET XML types?
		do
			Result := True
		end

	has_breakpoints: BOOLEAN = False;
			-- Should breakpoints be shown in Current?

feature{NONE} -- Implementation

	internal_symbol: like symbol
			-- Once per object storage for `symbol.

	result_data: QL_FEATURE_DOMAIN
			-- Result for Current formatter
		local
			l_worker: E_SHOW_CALLERS
		do
			create l_worker.make (create {EB_EDITOR_TOKEN_GENERATOR}.make, associated_feature)
			l_worker.set_flag (flag)
			l_worker.set_all_callers (preferences.feature_tool_data.show_all_callers)
			l_worker.show_callees
			Result := l_worker.features
		end

	criterion: QL_CRITERION
			-- Criterion of current formatter
		do
		end

	rebuild_browser
			-- Rebuild `browser'.
		do
			browser.set_flag (flag)
		end

	generate_result
			-- Generate result for display
		do
			Precursor
			browser.set_reference_type_name (command_name)
		end

note
	copyright:	"Copyright (c) 1984-2018, Eiffel Software"
	license:	"GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options:	"http://www.eiffel.com/licensing"
	copying: "[
			This file is part of Eiffel Software's Eiffel Development Environment.
			
			Eiffel Software's Eiffel Development Environment is free
			software; you can redistribute it and/or modify it under
			the terms of the GNU General Public License as published
			by the Free Software Foundation, version 2 of the License
			(available at the URL listed under "license" above).
			
			Eiffel Software's Eiffel Development Environment is
			distributed in the hope that it will be useful, but
			WITHOUT ANY WARRANTY; without even the implied warranty
			of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
			See the GNU General Public License for more details.
			
			You should have received a copy of the GNU General Public
			License along with Eiffel Software's Eiffel Development
			Environment; if not, write to the Free Software Foundation,
			Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
		]"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
