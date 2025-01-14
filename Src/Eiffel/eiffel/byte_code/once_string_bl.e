note

	description: "Enlarged byte code for once manifest string."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	ONCE_STRING_BL

inherit
	ONCE_STRING_B
		rename
			print_checked_target_register as print_register
		redefine
			allocates_memory,
			analyze,
			generate,
			print_register,
			register,
			set_register,
			unanalyze
		end

	SHARED_ENCODING_CONVERTER

create
	make

feature

	register: REGISTRABLE
			-- Where string is kept to ensure it is GC safe

	set_register (r: REGISTRABLE)
			-- Set `register' to `r'.
		do
			register := r
		end

	unanalyze
			-- Undo analysis work.
		do
			register := Void
		end

	analyze
			-- Analyze the string.
		do
			if allocates_memory then
				get_register
			else
				-- Once manifest string is pre-initialized and can be used inside expression or feature call
			end
		end

	generate
			-- Generate the string.
		local
			buf: like buffer
			l_value_32: STRING_32
			l_value_8: STRING_8
		do
			if register = Void then
					-- Remember once manifest string to generate its pre-initialization.
				context.register_once_manifest_string (value, is_string_32, number)
			else
					-- Generate once manifest string initialization.
				buf := buffer
					-- RTCOMS is the macro used to retrieve previously created once manifest strings
					-- or to create a new one if this is the first acceess to the string
				buf.put_new_line
				if is_string_32 then
					buf.put_string ("RTCOMS32(")
				else
					buf.put_string ("RTCOMS(")
				end
				register.print_register
				buf.put_character (',')
				buf.put_integer (body_index - 1)
				buf.put_character (',')
				buf.put_integer (number - 1)
				buf.put_character (',')
				if is_string_32 then
					l_value_32 := encoding_converter.utf8_to_utf32 (value)
					buf.put_string_literal (encoding_converter.string_32_to_stream (l_value_32))
				else
					l_value_8 := value_8
					buf.put_string_literal (l_value_8)
				end
				buf.put_character (',')
				if is_string_32 then
					buf.put_integer (l_value_32.count)
				else
					buf.put_integer (l_value_8.count)
				end
				buf.put_character(',')
				if is_string_32 then
					buf.put_integer (l_value_32.hash_code)
				else
					buf.put_integer (l_value_8.hash_code)
				end
				buf.put_character (')')
				buf.put_character (';')
			end
		end

	print_register
			-- Print the string (or the register in which it is held).
		local
			buf: like buffer
		do
			if register = Void then
					-- Once manifest string access is inlined.
				buf := buffer
				buf.put_string ("RTOMS(")
				buf.put_integer (body_index - 1)
				buf.put_character (',')
				buf.put_integer (number - 1)
				buf.put_character (')')
			else
					-- Once manifest string value is in a register.
				register.print_register
			end
		end

feature -- Properties

	allocates_memory: BOOLEAN
			-- Does the expression allocates memory?
		do
				-- Memory is allocated only when strings are not pre-initialized
			Result := not context.is_static_system_data_safe
		end

note
	copyright:	"Copyright (c) 1984-2017, Eiffel Software"
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
