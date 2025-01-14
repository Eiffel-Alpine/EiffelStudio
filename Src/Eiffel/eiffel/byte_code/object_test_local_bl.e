﻿note
	description: "Access to an object-test local in C code."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class OBJECT_TEST_LOCAL_BL

inherit

	LOCAL_BL
		rename
			make as make_local,
			print_checked_target_register as print_register -- Object test locals are always attached.
		undefine
			array_descriptor,
			assigns_to,
			enlarged,
			is_creatable,
			pre_inlined_code,
			process,
			register_name,
			same,
			used
		redefine
			analyze,
			parent,
			print_register,
			type
		end

	OBJECT_TEST_LOCAL_B
		rename
			print_checked_target_register as print_register -- Object test locals are always attached.
		undefine
			free_register,
			generate,
			propagate,
			set_parent
		redefine
			analyze,
			parent,
			print_register,
			used,
			type
		end

create
	make_from

feature {NONE} -- Creation

	make_from (other: OBJECT_TEST_LOCAL_B)
		do
			multi_constraint_static := other.multi_constraint_static
			position := other.position
			type := other.type
			body_id := other.body_id
		ensure
			multi_constraint_static_set: multi_constraint_static = other.multi_constraint_static
			position_set: position = other.position
			type_set: type = other.type
			body_id_set: body_id = other.body_id
		end

feature -- Access

	parent: NESTED_BL
			-- Parent of access

	type: TYPE_A
			-- <Precursor>

feature -- Status report

	used (r: REGISTRABLE): BOOLEAN
			-- Is `r' the same as `Current'?
		do
			if attached {OBJECT_TEST_LOCAL_B} r as o then
				Result := same (o)
			end
		end

feature -- Code generation

	analyze
			-- Register object test local.
		local
			l_reg: NAMED_REGISTER
			l_c_type: like c_type
		do
			l_c_type := c_type
			if l_c_type.is_reference then
					-- Fixed eweasel test#svalid025 where if the object test locals is defined
					-- in an inherited assertion we do not want to store the type from the
					-- ancestor in the descandant for its locals, because the local list types
					-- are always analyzed in the descendant context never in the ancestor.
				create l_reg.make (register_name, l_c_type)
				context.set_local_index (l_reg.register_name, l_reg)
			end
		end

feature {REGISTRABLE} -- C code generation

	print_register
			-- <Precursor>
		local
			ctx: BYTE_CONTEXT
			buf: like {BYTE_CONTEXT}.buffer
		do
			ctx := context
			buf := ctx.buffer
			buf.put_string ({C_CONST}.local_name)
			buf.put_integer (ctx.object_test_local_position (Current))
		end

note
	copyright:	"Copyright (c) 1984-2016, Eiffel Software"
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
