﻿note
	description: "Info about access to a local variable of a feature"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	LOCAL_B

inherit
	ACCESS_B
		redefine
			enlarged, read_only, is_local, is_creatable,
			register_name,
			print_register, print_checked_target_register,
			assign_code, expanded_assign_code, reverse_code,
			assigns_to, array_descriptor,
			pre_inlined_code,
			is_fast_as_local, is_predefined
		end

create
	make

feature {NONE} -- Creation

	make (p: INTEGER)
			-- Initialialize a local variable descriptor with `position' set to `p`.
		require
			valid_position: p > 0
		do
			position := p
		ensure
			position_set: position = p
		end

feature -- Visitor

	process (v: BYTE_NODE_VISITOR)
			-- Process current element.
		do
			v.process_local_b (Current)
		end

feature

	position: INTEGER
			-- Position of the local in the list `locals' of the root
			-- byte code

	read_only: BOOLEAN = False
			-- Is the access only a read-only one ?

	type: TYPE_A
			-- Local type
		do
			Result := context.byte_code.locals.item (position)
		end

	is_predefined: BOOLEAN = True
			-- Is Current a predefined entity?

	is_local: BOOLEAN
			-- Is Current an access to a local variable?
		do
			Result := True
		end

	is_creatable: BOOLEAN
			-- Can an access to a local variable be the target for
			-- a creation?
		do
			Result := True
		end

	same (other: ACCESS_B): BOOLEAN
			-- Is `other' the same access as Current ?
		do
			if attached {LOCAL_B} other as local_b then
				Result := position = local_b.position
			end
		end

	enlarged: LOCAL_B
			-- Enlarge current node
		do
			create {LOCAL_BL} Result.make (Current)
		end

	register_name: STRING
			-- The "loc<num>" string
		do
			create Result.make (10)
			Result.append ("loc")
			Result.append (position.out)
		end

	print_register
			-- Print local
		do
			buffer.put_string (register_name)
		end

feature {REGISTRABLE} -- C code generation

	print_checked_target_register
			-- <Precursor>
		local
			buf: like {BYTE_CONTEXT}.buffer
		do
			buf := context.buffer
			buf.put_string ({C_CONST}.rtcw_loc)
			buf.put_integer (position)
			buf.put_character (')')
		end

feature -- IL code generation

	is_fast_as_local: BOOLEAN = True
			-- Is expression calculation as fast as loading a local?

feature -- Byte code generation

	assign_code: CHARACTER
			-- Simple assignment code
		do
			Result := {BYTE_CONST}.bc_lassign
		end

	expanded_assign_code: CHARACTER
			-- Expanded assignment code
		do
			Result := {BYTE_CONST}.bc_lexp_assign
		end

	reverse_code: CHARACTER
			-- Reverse assignment code
		do
			Result := {BYTE_CONST}.bc_lreverse
		end

feature -- Array optimization

	assigns_to (i: INTEGER): BOOLEAN
		do
			Result := position = - i
		end

	array_descriptor: INTEGER
		do
			Result := -position
		end

feature -- Inlining

	pre_inlined_code: INLINED_LOCAL_B
		do
			create Result
			Result.fill_from (Current)
		end

feature -- Setting

	set_position (i: INTEGER)
			-- Assign `i' to `position'.
		require
			valid_index: i > 0
		do
			position := i
		ensure
			position_set: position = i
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
