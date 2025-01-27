note
	description: "[
			Objects that provider completion possiblities for normal use.
			i.e. EB_CODE_COMPLETABLE_TEXT_FIELD which can auto complete names of features and classes
			]"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	EB_DEBUGGER_EXPRESSION_COMPLETION_POSSIBILITIES_PROVIDER

inherit
	EB_NORMAL_COMPLETION_POSSIBILITIES_PROVIDER
		redefine
			prepare_completion
		end

create
	make

feature {NONE} -- Initialization

	prepare_completion
			-- Prepare completion
		local
			retried: BOOLEAN
		do
			if not retried then
				Precursor {EB_NORMAL_COMPLETION_POSSIBILITIES_PROVIDER}
			else
				reset_completion_list
				class_completion_possibilities := Void
				is_prepared := True
			end
		rescue
			retried := True
			retry
		end

note
	copyright: "Copyright (c) 1984-2018, Eiffel Software"
	license:   "GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options: "http://www.eiffel.com/licensing"
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
