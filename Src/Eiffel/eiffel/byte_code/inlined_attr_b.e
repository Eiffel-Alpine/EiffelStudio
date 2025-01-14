note
	legal: "See notice at end of class."
	status: "See notice at end of class."
class INLINED_ATTR_B

inherit
	ATTRIBUTE_BL
		redefine
			enlarged, fill_from, current_register
		end

create
	fill_from

feature

	fill_from (a: ATTRIBUTE_B)
		do
			parent := a.parent
			attribute_name_id := a.attribute_name_id
			attribute_id := a.attribute_id
			routine_id := a.routine_id
			type := a.type
			is_attachment := a.is_attachment
		end

	enlarged: INLINED_ATTR_B
		do
			Result := Current
		end

	Current_register: INLINED_CURRENT_B
		once
			create Result
		end

note
	copyright:	"Copyright (c) 1984-2019, Eiffel Software"
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
