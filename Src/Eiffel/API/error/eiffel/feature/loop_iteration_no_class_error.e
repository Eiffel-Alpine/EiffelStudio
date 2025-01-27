note
	description: "Error in loop iteration class."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class LOOP_ITERATION_NO_CLASS_ERROR

inherit
	FEATURE_ERROR
		redefine
			build_explain,
			help_file_name
		end

create
	make

feature {NONE} -- Creation

	make (c: AST_CONTEXT; n: STRING; l: LOCATION_AS)
			-- Create error object for loop iteration that cannot find a suitable class `n' in the context `c'.
		require
			c_attached: c /= Void
			n_attached: n /= Void
			l_attached: l /= Void
		do
			c.init_error (Current)
			class_name := n
			set_location (l)
		ensure
			class_name_set: class_name = n
		end

feature -- Error properties

	code: STRING = "Loop iteration no class error"
			-- Error code

	help_file_name: STRING_8 = "Loop_iteration_no_class_error"
			-- Help file name

feature {NONE} -- Access

	class_name: STRING
			-- Class name

feature -- Output

	build_explain (a_text_formatter: TEXT_FORMATTER)
		do
			a_text_formatter.add ("Class: ")
			a_text_formatter.add (class_name)
			a_text_formatter.add_new_line
		end

note
	copyright:	"Copyright (c) 1984-2009, Eiffel Software"
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
