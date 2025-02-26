note
	legal: "See notice at end of class."
	status: "See notice at end of class."

class PARAN_B

inherit

	EXPR_B
		redefine
			analyze, unanalyze, generate,
			print_register, propagate,
			free_register, enlarged, allocates_memory,
			has_gcable_variable, has_call,
			is_unsafe, optimized_byte_node,
			calls_special_features, size,
			pre_inlined_code, inlined_byte_code,
			is_constant_expression, print_checked_target_register,
			evaluate
		end

create
	make

feature {NONE} -- Initialize

	make (e: EXPR_B)
			-- Set `expr' to `e'
		require
			e_not_void: e /= Void
		do
			expr := e
		ensure
			expr_set: expr = e
		end

feature -- Visitor

	process (v: BYTE_NODE_VISITOR)
			-- Process current element.
		do
			v.process_paran_b (Current)
		end

feature -- Properties

	is_constant_expression: BOOLEAN
			-- Is current a constant expression?
		do
			Result := expr.is_constant_expression
		end

	evaluate: VALUE_I
			-- <Precursor>
		do
			Result := expr.evaluate
		end

feature

	expr: EXPR_B;
			-- The expression in parenthesis

	type: TYPE_A
			-- Expression type
		do
			Result := expr.type;
		end;

	enlarged: like Current
			-- Enlarge the expression
		do
			expr := expr.enlarged;
			Result := Current;
		end;

	has_gcable_variable: BOOLEAN
			-- Is the expression using a GCable variable ?
		do
			Result := expr.has_gcable_variable;
		end;

	has_call: BOOLEAN
			-- Is the expression using a call ?
		do
			Result := expr.has_call;
		end;

	allocates_memory: BOOLEAN
		do
			Result := expr.allocates_memory
		end

	used (r: REGISTRABLE): BOOLEAN
			-- Is `r' used in the expression ?
		do
			Result := expr.used (r)
		end

	propagate (r: REGISTRABLE)
			-- Propagate a register in expression.
		do
			if r = No_register or not used (r) and not context.propagated then
				expr.propagate (r)
			end
		end

	free_register
			-- Free register used by expression
		do
			expr.free_register
		end

	analyze
			-- Analyze expression
		do
			expr.analyze;
		end;

	unanalyze
			-- Undo the analysis of the expression
		do
			expr.unanalyze;
		end;

	generate
			-- Generate expression
		do
			expr.generate;
		end;

	print_register
			-- Print expression value
		local
			buf: GENERATION_BUFFER
		do
			if
				(expr.register = Void or expr.register = No_register)
				and not expr.is_simple_expr
			then
				buf := buffer
				buf.put_character ('(');
				expr.print_register;
				buf.put_character (')');
			else
					-- No need for parenthesis if expression is held in a
					-- register (e.g. a semi-strict boolean op).
				expr.print_register;
			end;
		end;

feature {REGISTRABLE} -- C code generation

	print_checked_target_register
			-- <Precursor>
		local
			buf: GENERATION_BUFFER
		do
			if
				(expr.register = Void or expr.register = No_register)
				and not expr.is_simple_expr
			then
				buf := buffer
				buf.put_character ('(')
				expr.print_checked_target_register
				buf.put_character (')')
			else
					-- No need for parenthesis if expression is held in a
					-- register (e.g. a semi-strict boolean op).
				expr.print_checked_target_register
			end
		end

feature -- Array optimization

	calls_special_features (array_desc: INTEGER): BOOLEAN
		do
			Result := expr.calls_special_features (array_desc)
		end

	is_unsafe: BOOLEAN
		do
			Result := expr.is_unsafe
		end

	optimized_byte_node: like Current
		do
			Result := Current
			expr := expr.optimized_byte_node
		end

feature -- Inlining

	size: INTEGER
		do
			Result := expr.size
		end

	pre_inlined_code: like Current
		do
			Result := Current;
			expr := expr.pre_inlined_code
		end

	inlined_byte_code: like Current
		do
			Result := Current
			expr := expr.inlined_byte_code
		end

invariant
	expr_not_void: expr /= Void

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
