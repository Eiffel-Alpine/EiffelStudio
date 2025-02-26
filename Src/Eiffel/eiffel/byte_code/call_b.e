note
	legal: "See notice at end of class."
	status: "See notice at end of class."
deferred class CALL_B

inherit

	EXPR_B
		redefine
			enlarged, is_simple_expr, optimized_byte_node,
			inlined_byte_code, pre_inlined_code
		end;

feature

	parent: NESTED_B;
			-- Parent node

	target: ACCESS_B
			-- The target of the call
		deferred
		end;

	canonical: CALL_B
			-- Canonical call entity
			--| To be redefined in CONSTANT_B
		do
			Result := Current
		end;

	set_parent (p: NESTED_B)
			-- Set parent to `p'
		do
			parent := p;
		end;

	is_attribute: BOOLEAN
			-- Is Current an access to an attribute ?
		do
		end

	is_simple_expr: BOOLEAN
			-- A call/access is a simple expression
		do
			Result := true;
		end;

	is_single: BOOLEAN
			-- Is call/access a single one ?
			-- Definition: A call/access is single if it is a single access
			-- or a call on a predefined target and with predefined arguments.
		deferred
		end;

	is_constant: BOOLEAN
			-- Is Current a call to a constant?
		do
		end

	is_external: BOOLEAN
			-- 	Is Current a call to an external?
		do
		end

	need_target: BOOLEAN
			-- Does current call really need a target to be performed?
			-- E.g. not (a constant or a static external)
		do
			Result := True
		end

	enlarged: CALL_B
			-- Redefined only for type check
		do
			Result := Current;
		end;

	sub_enlarged (p: NESTED_BL): like enlarged
			-- Enlarge node and set parent to `p'
		deferred
		end;

feature {CALL_B} -- C code generation: kind of a call

	call_kind_unqualified: INTEGER = 0
			-- A value for an unqualified call

	call_kind_qualified: INTEGER = 1
			-- A value for a qualified call

	call_kind_creation: INTEGER = -1
			-- A value for a creation procedure call

	call_kind: INTEGER
			-- Kind of a call.
		do
			Result := call_kind_qualified
		ensure
			valid_result:
				Result = call_kind_unqualified or
				Result = call_kind_qualified or
				Result = call_kind_creation
		end

	set_call_kind (value: like call_kind)
			-- Set `call_kind' to `value' (if applicable to this node).
		do
			-- Do nothing
		end

feature -- Array optimization

	is_special_feature: BOOLEAN
			-- Is it a call to a `special' feature?
		do
		end

	optimized_byte_node: CALL_B
			-- Redefined only for type check
		do
			Result := Current
		end

feature -- Inlining

	pre_inlined_code: CALL_B
			-- Redefined only for type check
		do
			Result := Current
		end

	inlined_byte_code: CALL_B
			-- Redefined only for type check
		do
			Result := Current
		end

note
	copyright:	"Copyright (c) 1984-2010, Eiffel Software"
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
