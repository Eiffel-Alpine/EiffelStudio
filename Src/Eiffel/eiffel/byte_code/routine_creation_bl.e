﻿note
	description: "Byte code for routine creation expression"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class ROUTINE_CREATION_BL

inherit
	ROUTINE_CREATION_B
		redefine
			analyze,
			free_register,
			generate,
			print_checked_target_register,
			register,
			set_register,
			unanalyze
		end

	SHARED_C_LEVEL
	SHARED_TABLE
	SHARED_TMP_SERVER
	SHARED_DECLARATIONS
	SHARED_INCLUDE

	SHARED_TYPE_I
		export
			{NONE} all
		end

feature

	register: REGISTRABLE
			-- Register for array containing the routine object

	set_register (r: REGISTRABLE)
			-- Set `register' to `r
		do
			register := r
		end

	unanalyze
			-- Unanalyze expression
		do
			if arguments /= Void then
				arguments.unanalyze
			end
			if open_positions /= Void then
				open_positions.unanalyze
			end
			set_register (Void)
		end

	analyze
			-- Analyze expression
		do
			if arguments /= Void then
				arguments.analyze
			end
			if open_positions /= Void then
				open_positions.analyze
			end
			get_register
			context.add_dftype_current
		end

	free_register
			-- Free used registers for later use.
		do
			Precursor {ROUTINE_CREATION_B}
			if arguments /= Void then
				arguments.free_register
			end
			if open_positions /= Void then
				open_positions.free_register
			end
		end

	generate
			-- Generate expression
		local
			buf: GENERATION_BUFFER
			sep: STRING
			wb_mode: BOOLEAN
			l_context: like context
		do
			check
				address_table_record_generated: not System.address_table.is_lazy (class_type.base_class.class_id, feature_id, is_target_closed, omap)
			end
			l_context := context
			sep := once ", "
			wb_mode := not l_context.final_mode
			if arguments /= Void then
				arguments.generate
			end

			if wb_mode and open_positions /= Void then
				open_positions.generate
			end

			buf := buffer
			buf.put_new_line
			buf.generate_block_open
			if attached {GEN_TYPE_A} l_context.real_type (type) as gen_type then
				l_context.generate_gen_type_conversion (gen_type, 0)
			end
			buf.put_new_line
			print_register
				-- rout_disp
			if wb_mode then
				buf.put_string (once "= RTLNRW(typres0.id, 0, ")
			else
				buf.put_string (once "= RTLNRF(typres0.id, ")
				generate_routine_address (True, False)
				buf.put_string (sep)
			end

				-- encaps_rout_disp
			generate_routine_address (True, True)
			buf.put_string (sep)

				-- calc_rout_addr
			if is_target_closed then
				generate_precalc_routine_address
			else
				buf.put_character ('0')
				buf.put_string (sep)
			end

			if wb_mode then
					-- Routine ID
				buf.put_integer (rout_id)
				buf.put_string (sep)
					-- open_map
				if open_positions /= Void and then not system.in_final_mode then
					open_positions.print_register
				else
					buf.put_character ('0')
				end
				buf.put_string (sep)
					-- is_basic
				if is_basic then
					buf.put_character ('1')
				else
					buf.put_character ('0')
				end
				buf.put_string (sep)
					-- is_target_closed
				if is_target_closed then
					buf.put_character ('1')
				else
					buf.put_character ('0')
				end
				buf.put_string (sep)
					-- is_inline_agent
				if is_inline_agent then
						-- Type ID of the type defining the inline agent.
					buf.put_type_id (class_type.static_type_id (l_context.current_type))
				else
					buf.put_integer (-1)
				end
				buf.put_string (sep)
			end
				-- closed_operands
			if arguments /= Void then
				arguments.print_register
			else
				buf.put_character ('0')
			end
			buf.put_string (sep)
			if not wb_mode then
					-- is_target_closed
				if is_target_closed then
					buf.put_character ('1')
				else
					buf.put_character ('0')
				end
				buf.put_string (sep)
			end
				-- open_count
			if open_positions /= Void then
				buf.put_integer (open_positions.expressions.count)
			else
				buf.put_character ('0')
			end
			buf.put_string (");")
			buf.generate_block_close

				-- Migrate an argument tuple and a routine object to a target processor.
			if type.is_separate then
				check
					arguments_attached: attached arguments as a
					arguments_non_empty: attached a.expressions as e
					arguments_has_target: not e.is_empty
				then
					buf.put_new_line
					buf.put_string (once "RTS_PID (")
					print_register
					buf.put_string (once ") = RTS_PID (")
					a.print_register
					buf.put_string (once ") = RTS_PID (")
					e [1].print_register
					buf.put_string (");")
				end
			end
		end

	generate_routine_address (optimized, oargs_encapsulated: BOOLEAN)
			-- Generate routine address
		local
			table_name	: STRING
			buf			: GENERATION_BUFFER
			array_index: INTEGER
			l_omap: like omap
			l_context: like context
		do
			buf := buffer
			if optimized then
				l_omap := omap
			end
			l_context := context

				-- Note that we use `context.current_type/context.class_type' because we do not adapt
				-- `a_node.class_type' to `context.context_class_type' for the simple reasons
				-- that `feature_id' is the one from where the agent creation is declared.
				-- If we were to adapt it, then we would need something like
				-- `{CALL_ACCESS_B}.real_feature_id' for a proper code generation.

			if not l_context.workbench_mode and then not is_inline_agent then
				array_index := Eiffel_table.is_polymorphic_for_body (rout_id, class_type, context.class_type)
			end

			if array_index = -2 then
					-- Function pointer associated to a deferred feature without
					-- any implementation
				buf.put_string ("NULL")
			else
				buf.put_string ("(EIF_POINTER) ")
				check
					system.address_table.has_agent (
						class_type.base_class.class_id, feature_id, is_target_closed, omap)
				end
				table_name := system.address_table.calc_function_name
					(True, feature_id, class_type.static_type_id (context.current_type), l_omap, oargs_encapsulated)
				buf.put_string (table_name)

					-- Remember extern declarations
				Extern_declarations.add_routine (type.c_type, table_name)

				if not l_context.workbench_mode and then not is_inline_agent and then array_index >= 0 then
						-- Mark table used
					Eiffel_table.mark_used (rout_id)
				end
			end
		end

	generate_current
		do
			buffer.put_string ("((EIF_TYPED_VALUE *)")
			arguments.print_register
			buffer.put_string (")[1].")
			reference_c_type.generate_typed_field (buffer)
		end

	generate_precalc_routine_address
		local
			l_class_type: CLASS_TYPE
			l_table_name, l_function_name: STRING
			l_feat: FEATURE_I
			l_c_return_type: TYPE_C
			l_args: ARRAY [STRING_8]
			l_return_type_string: STRING
			l_buffer: like buffer
			l_context: like context
		do
			l_buffer := buffer
			l_context := context
			l_buffer.put_string ("(EIF_POINTER)")
			l_buffer.put_character ('(')
			if is_inline_agent or else l_context.workbench_mode then
				l_buffer.put_string ("0),")
			else
					-- Note that we use `context.current_type' because we do not adapt
					-- `a_node.class_type' to `context.context_class_type' for the simple reasons
					-- that `feature_id' is the one from where the agent creation is declared.
					-- If we were to adapt it, then we would need something like
					-- `{CALL_ACCESS_B}.real_feature_id' for a proper code generation.
				l_class_type := class_type.associated_class_type (context.current_type)
				if attached {ROUT_TABLE} tmp_poly_server.item (rout_id) as t implies t.is_deferred then
						-- Function pointer associated to a deferred feature
						-- without any implementation
					l_buffer.put_string ("0),")
				elseif t.polymorphic_status_for_body (class_type, context.class_type) = 0 then
					l_table_name := Encoder.routine_table_name (rout_id)
					l_buffer.put_string (l_table_name)
					l_buffer.put_string ("[Dtype((")
					generate_current
					l_buffer.put_string (")) - ")
					l_buffer.put_type_id (t.min_used)
					l_buffer.put_string ("]),")
						-- Remember extern declarations
					Extern_declarations.add_routine_table (l_table_name)
						-- Mark table used.
					Eiffel_table.mark_used (rout_id)
				else
					t.goto_implemented (class_type, context.class_type)
					l_feat := l_class_type.associated_class.feature_of_rout_id (rout_id)
					l_c_return_type := system.address_table.solved_type (l_class_type, l_feat.type)
					l_return_type_string := l_c_return_type.c_string
					if t.is_implemented then
						l_function_name := t.feature_name
						l_buffer.put_string (l_function_name)
						l_buffer.put_string ("),")
						if l_feat.has_arguments then
							l_args := system.address_table.arg_types (l_class_type, l_feat.arguments, True, Void)
						else
							l_args := <<"EIF_REFERENCE">>
						end
						extern_declarations.add_routine_with_signature (
							l_return_type_string, l_function_name, l_args)
					else
							-- Function pointer associated to a deferred feature
							-- without any implementation. We mark `l_is_implemented'
							-- to False to not generate the argument list since
							-- RTNR takes only one argument.
						l_c_return_type.generate_function_cast (l_buffer, <<"EIF_REFERENCE">>, False)
						l_buffer.put_string ("RTNR),")
					end
				end
			end
		end

feature {REGISTRABLE} -- C code generation

	print_checked_target_register
			-- <Precursor>
		do
			print_register
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
