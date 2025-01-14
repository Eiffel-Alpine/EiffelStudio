﻿note
	description: "Enlarged byte code for assignment"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class ASSIGN_BL

inherit

	ASSIGN_B
		redefine
			analyze, generate,
			last_all_in_result, find_assign_result,
			mark_last_instruction
		end
	VOID_REGISTER
		redefine
			register, get_register, print_register
		end

create
	make

feature {NONE} -- Initialization

	make (other: ASSIGN_B)
			-- Create new instance from `other'.
		require
			other_not_void: other /= Void
		do
			target := other.target.enlarged
			source := other.source.enlarged
			line_number := other.line_number
		end

feature

	target_propagated: BOOLEAN
			-- Has target been propagated ?

	expand_return: BOOLEAN
			-- Do we have to expand the assignment in Result ?

	register: REGISTRABLE
			-- Where result is stored, for case where an entity is
			-- assigned to a manifest string. Usually those are expanded
			-- inline, but the RTAP macro for aging test evaluates its
			-- arguments more than once.

	register_for_metamorphosis: BOOLEAN
			-- Is register used to held metamorphosed value as opposed to the
			-- result of RTMS (for manifest strings)?

	print_register
			-- Print register
		require else
			register_exists: register /= Void
		do
			register.print_register
		end

	get_register
			-- Get a register for string constants
		do
			create {REGISTER} register.make (target.c_type)
		end

	last_in_result: BOOLEAN
			-- Is this the last assignment in Result ?

	last_instruction: BOOLEAN
			-- Is this assignment the very last instruction ?

	simple_op_assignment: INTEGER
			-- Records state of simple operations with assignments

	find_assign_result
			-- Check whether this is an assignment in Result, candidate for
			-- final 'return' optimization. This won't be done if result is
			-- expanded or if there are some postconditions which might use
			-- it or there is a rescue clause...
		local
			source_type: TYPE_A
			target_type: TYPE_A
		do
			if target.is_result and
				not context.has_postcondition and
				not context.has_invariant and
				not context.has_rescue and
				not context.current_feature.is_once and then
				source.is_simple_expr
			then
				target_type := context.real_type (target.type)
				source_type := context.real_type (source.type)
				last_in_result :=
					not target_type.is_true_expanded and
						-- No optimization if metamorphosis
					(target_type.is_basic or else source_type.is_reference)
			else
				last_in_result := False
			end
		end

	last_all_in_result: BOOLEAN
			-- Are all the function exit points an assignment to Result ?
		do
			Result := last_in_result
		ensure then
			Result = last_in_result
		end

	mark_last_instruction
			-- Signals this assigment is an exit point for the routine.
		do
			last_instruction := not context.has_postcondition
				and not context.has_invariant
		end

	No_simple_op: INTEGER = 1
			-- There is no simple operation assignment.

	Left_simple_op: INTEGER = 2
			-- The left part of the source is affected by a simple operation.

	Right_simple_op: INTEGER = 3
			-- The right part of the source is affected by a simple operation.

	analyze_simple_assignment
			-- Take care of the simple operation assigments and sets
			-- `simple_op_assigment' accordingly.
		local
			binary: BINARY_B
			access: ACCESS_B
		do
			binary ?= source
			if binary /= Void and then binary.is_simple then
				access ?= binary.left
				if access /= Void and then access.same (target) then
						-- We found x := x - f
					simple_op_assignment := Left_simple_op
						-- Expand right leaf
					context.init_propagation
					binary.right.propagate (No_register)
						-- Avoid need of a register for left leaf
					context.init_propagation
					binary.left.propagate (No_register)
				elseif binary.is_commutative then
					access ?= binary.right
					if access /= Void and then access.same (target) then
							-- We found x := f + x
						simple_op_assignment := Right_simple_op
							-- Expand left leaf
						context.init_propagation
						binary.left.propagate (No_register)
							-- Avoid need of a register for right leaf
						context.init_propagation
						binary.right.propagate (No_register)
					end
				end
			end
		end

	analyze
			-- Analyze assignment
		local
			source_has_gcable: BOOLEAN
			result_used: BOOLEAN
			source_type: TYPE_A
			target_type: TYPE_A
			expr_b: EXPR_B
			saved_context: like context
		do
			target_type := context.real_type (target.type)

				-- The target is always expanded in-line for de-referencing.
			context.init_propagation

				-- Propagation of `No_register' in any generation mode
			target.set_register (No_register)
			context.set_propagated

			target.analyze
				-- If we are not in the case "last assignment in Result" then
				-- look whether it is a simple operator assignment which could
				-- be generated nicely and efficiently in C (like c++ :-).
			simple_op_assignment := No_simple_op
			if not last_in_result then
				analyze_simple_assignment
			end
			create saved_context.make_from_context (context)

			source_type := context.real_type (source.type)
			if simple_op_assignment = No_simple_op then
				if target.is_predefined then
					result_used := target.is_result
						-- We won't attempt a propagation of the target if the
						-- target is a reference and the source is a basic type
						-- or an expanded.
					context.init_propagation
					if not target_type.is_expanded and source_type.is_expanded then
							-- Expand source but grab a register to hold cloned
							-- or metamorphosed value as aging tests might have
							-- to be performed.
						source.propagate (No_register)
						register := target
						register_for_metamorphosis := True
					elseif
							-- Do not propagate something expanded as the
							-- routines in NESTED_BL and friends won't know
							-- how to deal with that (they do real assignments,
							-- not copies). In case target is expanded, we
							-- do not propagate anything in the source.
						not target_type.is_true_expanded and then
							-- If there is invariant checking and the target
							-- is used in the source, do not propagate.
							-- Case: p := p.right in a list and p becomes
							-- void...
						not context.workbench_mode and then
						not context.assertion_level.is_invariant and then
						not source.used (target)
					then
						source.propagate (target)
						target_propagated := context.propagated
					end
				else
						-- This is an assignment in an attribute.
					context.init_propagation
					if not target_type.is_expanded and source_type.is_expanded then
							-- Expand source but grab a register to hold cloned
							-- or metamorphosed value as aging tests might have
							-- to be performed.
						source.propagate (No_register)
						get_register
						register_for_metamorphosis := True
					else
							-- Nothing to be done because:
							-- 1 - For reference target, we need an aging test which is a macro
							--     that might evaluate more than once its argument, so we have to
							--     store `source' in a register.
							-- 2 - To fix an ordering problem for assignment with gcc 4.x (see eweasel test#runtime007)
							--     we have to do the same for basic types, but this time is to ensure
							--     that target is actually evaluated after source. This is only needed
							--     if source allocates some memory.
						if not source.allocates_memory and not target.c_type.is_reference  then
							source.propagate (No_register)
						end
					end
					if target.c_type.is_reference then
							-- Mark current as used for RTAP.
						context.mark_current_used
					end
				end
			elseif target.is_result then
				context.mark_result_used
			end
				-- Analyze the source given the current propagations.
			source.analyze
			source.free_register
			if register_for_metamorphosis then
				register.free_register
			end
				-- If the source is a string constant and the target is not
				-- predefined, then a RTAP will be generated and the RTMS
				-- must NOT be expanded in line (side effect in macro).
			if
				not target.is_predefined and then
				(attached {STRING_B} source as string_b and then string_b.register = No_register or else
				target_type.is_reference and then source_type.is_reference and then source.is_dynamic_clone_required (source_type)) or else
				target_type.is_true_expanded
			then
					-- Take a register to hold the value of the string or of a cloned expanded object.
				get_register
				register.free_register
			end
				-- If source has GCable variables and is not a single call or
				-- access, then we cannot expand that in a return after the
				-- GC hooks have been removed.
			if attached {CALL_B} source as call_b and then call_b.is_single then
				source_has_gcable := call_b.has_gcable_variable and then not call_b.is_simple_expr
			else
				expr_b := source
 				source_has_gcable := expr_b.has_call or else expr_b.allocates_memory
			end

				-- Mark Result used only if not the last instruction (in which
				-- case we'll generate a direct return, hence Result won't be
				-- needed).
			if last_in_result and not source_has_gcable then
				check from_find_assign_result: target.is_result end
				context.restore (saved_context)
				source.unanalyze
				context.init_propagation
					-- If Result is already used, then propagate it. Otherwise,
					-- we won't need it. Note that if the result is an expanded
					-- entity, we need it.
				if context.result_used and then not source.used (target) then
						-- Propagation of Result may avoid a register allocation
					source.propagate (target)
					target_propagated := context.propagated
				else
						-- We won't need Result after all...
					result_used := False
					source.propagate (No_register)
				end
				source.analyze
				source.free_register
					-- We may expand the return in line, once the GC hooks
					-- have been removed.
				expand_return := True
			else
					-- Force usage of Result.
				last_in_result := False
			end
			if result_used then
				context.mark_result_used
			end
		end

	generate
			-- Generate assignment
		do
			generate_line_info
			generate_frozen_debugger_hook
			if context.workbench_mode and then context.assertion_type /= context.in_invariant then
				generate_frozen_debugger_recording_assignment (target)
			end
			if last_in_result then
					-- Assignement in Result is the last expression and
					-- the source does not use GCable variable, or only in
					-- an "atomic" way in a simple call.
				generate_last_return
			elseif simple_op_assignment /= No_simple_op then
				generate_simple_assignment
			else
				generate_assignment
			end
		end

	Simple_assignment: INTEGER = 4
			-- Simple assignment wanted

	Metamorphose_assignment: INTEGER = 5
			-- Metamorphose of source is necessary

	Unmetamorphose_assignment: INTEGER = 6
			-- Metamorphose of source is necessary

	Clone_assignment: INTEGER = 7
			-- Clone of source is needed

	Copy_assignment: INTEGER = 8
			-- Copy source into target, raise exception if source is Void

	source_print_register
			-- Generate source (the True one or the metamorphosed one)
		do
			if register /= Void then
				print_register
			else
				source.print_register
			end
		end

	generate_assignment
			-- Generate a non-optimized assignment
		local
			target_type: TYPE_A
			source_type: TYPE_A
			buf: GENERATION_BUFFER
			l_context: like context
		do
			buf := buffer
			l_context := context
			target_type := l_context.real_type (target.type)
			source_type := l_context.real_type (source.type)
			if target_type.is_expanded and source_type.is_none then
					-- Assigning Void to expanded.
				buf.put_new_line
				buf.put_string ("RTEC(EN_VEXP);")
			elseif target_type.is_true_expanded and then source_type.is_expanded then
					-- Reattachment of expanded types.
				check
					source_type_is_true_expanded: source_type.is_true_expanded
				end
				generate_regular_assignment (Copy_assignment)
			elseif target_type.is_basic and then source_type.is_basic or else
				target_type.is_reference and then source_type.is_reference
			then
					-- Reattachment of basic type to basic type or
					-- of reference type to reference type.
				generate_regular_assignment (Simple_assignment)
			elseif source_type.is_basic then
					-- Reattachment of basic type to reference.
				generate_regular_assignment (Metamorphose_assignment)
			elseif target_type.is_reference then
					-- Reattachment of expanded type to reference.
				generate_regular_assignment (Clone_assignment)
			else
				generate_regular_assignment (Unmetamorphose_assignment)
			end
		end

	generate_regular_assignment (how: INTEGER)
			-- Generate the assignment
		do
			source.generate
				-- If target has been propagated, then the assignment is
				-- generated by `generate' itself only when the source is a
				-- simple expression.
				-- Note that this does not mean the target was predefined
				-- (e.g. with a Result := "string").
			if not (target_propagated and source.stored_register = target) then
				generate_normal_assignment (how)
			end
		end

	generate_special (how: INTEGER)
			-- Generate special pre-treatment
		local
			basic_source_type: BASIC_A
			buf: GENERATION_BUFFER
		do
			buf := buffer
			if how = Metamorphose_assignment then
				basic_source_type ?= context.real_type (source.type)
				basic_source_type.metamorphose (register, source, buf)
				buf.put_character (';')
			elseif how = Clone_assignment then
				buf.put_new_line
				print_register
				buf.put_string (" = ")
				if is_creation_instruction then
						-- Just reassign source to target.
					source.print_register
					buf.put_character (';')
				else
						-- Call redefined version of `twin'/`cloned'.
					buf.put_string ("RTRCL(")
					source.print_register
					buf.put_two_character (')', ';')
				end
			end
		end

	generate_normal_assignment (how: INTEGER)
			-- Genrate assignment not taken care of by target propagation
		local
			need_aging_tests: BOOLEAN
			buf: GENERATION_BUFFER
			target_c_type: TYPE_C
			source_type: TYPE_A
		do
			buf := buffer
			generate_special (how)

				-- Find out C type of `target'.
			target_c_type := target.c_type

				-- No aging tests if target is not a reference. Of course, if
				-- the target is also pre-defined, aging tests are not needed.
				-- If it is an assignment copy, RTXA will take care of the
				-- aging test for references within the expanded
			need_aging_tests :=
				how /= copy_assignment and
				not target.is_predefined and target_c_type.is_reference
			if need_aging_tests then
					-- For strings constants, we have to be careful. Put its
					-- address in a temporary register before RTAR can
					-- handle it (it evaluates its arguments more than once).
					-- The same applies to expanded objects returned by reference expressions.
				if register /= Void and not register_for_metamorphosis then
					buf.put_new_line
					print_register
					buf.put_string (" = ")
					source_type := context.real_type (source.type)
					if
						how = Simple_assignment and then
						not attached {STRING_B} source and then
						source_type.is_reference
					then
						source.generate_dynamic_clone (source, source_type)
					else
						source.print_register
					end
					buf.put_character (';')
					buf.put_new_line
					buf.put_string ({C_CONST}.rtar_open)
					context.Current_register.print_register
					buf.put_string ({C_CONST}.comma_space)
					print_register
					buf.put_character (')')
					buf.put_character (';')
				elseif not attached {VOID_B} source then
						-- Optimization: If source is `Void' then there is nothing to remember.
					buf.put_new_line
					buf.put_string ({C_CONST}.rtar_open)
					context.Current_register.print_register
					buf.put_string ({C_CONST}.comma_space)
					source_print_register
					buf.put_character (')')
					buf.put_character (';')
				end
			end
			if how = Copy_assignment then
				if register /= Void then
						-- Initialize temporary.
					buf.put_new_line
					print_register
					buf.put_string (" = ")
					if not is_creation_instruction then
						buf.put_string ("RTRCL")
					end
					buf.put_character ('(')
					source.print_register
					buf.put_two_character (')', ';')
				end
				generate_expanded_assignment
			elseif how = Unmetamorphose_assignment then
				buf.put_new_line
				if context.real_type (target.type).is_basic then
						-- Reattachment of reference type to basic.
					target.print_register
					buf.put_string (" = *")
					target.c_type.generate_access_cast (buf)
					buf.put_character ('(')
					source.print_register
				else
						-- Reattachment of reference type to expanded.
					buf.put_string ("RTXA(")
					source.print_register
					buf.put_string ({C_CONST}.comma_space)
					target.print_register
				end
				buf.put_two_character (')', ';')
			elseif how = Simple_assignment or need_aging_tests then
				buf.put_new_line
				target.print_register
				buf.put_string (" = ")
					-- Always ensure that we perform a cast to type of target.
					-- Cast in case of basic type will never loose information
					-- as it has been validated by the Eiffel compiler.
				target_c_type.generate_cast (buf)
				if need_aging_tests and then register /= Void and not register_for_metamorphosis then
					print_register
				else
					source_type := context.real_type (source.type)
					if how = Simple_assignment and then source_type.is_reference then
							-- Support expanded types.
						if register_for_metamorphosis then
							source.generate_dynamic_clone (Current, source_type)
						else
							source.generate_dynamic_clone (source, source_type)
						end
					else
						source_print_register
					end
				end
				buf.put_character (';')
			end
		end

	generate_expanded_assignment
			-- Generate reattachment between expanded `source' and `target'.
		local
			buf: GENERATION_BUFFER
			target_type: CL_TYPE_A
			l_skeleton: SKELETON
		do
			buf := buffer
			target_type ?= context.real_type (target.type)
			check
					-- An expanded is a valid class type.
				target_type_not_void: target_type /= Void
			end
			l_skeleton := target_type.associated_class_type (context.context_class_type.type).skeleton

			if (not target.is_predefined and target.c_type.is_reference) or l_skeleton.nb_expanded >= 0 then
					-- Assignment on attribute or assignment of complex expanded objects.
					-- We need aging test, thus we use RTXA.
					-- FIXME: Optimization for attributes which are known to not have
					-- references in final mode, we should just do a `memmove' which
					-- is much faster.
				buf.put_new_line
				buf.put_string ("RTXA(")
				source_print_register
				buf.put_string ({C_CONST}.comma_space)
				target.print_register
				buf.put_character (')')
				buf.put_character (';')
			else
				buf.put_new_line
				buf.put_string ("memmove(")
				target.print_register
				buf.put_string ({C_CONST}.comma_space)
				source_print_register
				buf.put_string ({C_CONST}.comma_space)
				if context.workbench_mode then
					l_skeleton.generate_workbench_size (buf)
				else
					l_skeleton.generate_size (buf, True)
				end
				buf.put_character (')')
				buf.put_character (';')
			end
		end

	generate_last_return
			-- Generate last assignment in Result (i.e. a return)
		require
			no_postcondition: not context.has_postcondition
			no_invariant: not context.has_invariant
		local
			target_type: TYPE_A
			source_type: TYPE_A
			buf: GENERATION_BUFFER
		do
			target_type := context.real_type (target.type)
			source_type := context.real_type (source.type)
				-- Target (Result) cannot be expanded
			if target_type.is_expanded and source_type.is_none then
				buf := buffer
				buf.put_new_line
				buf.put_string ("RTEC(EN_VEXP);")
			elseif
				target_type.is_basic and then source_type.is_basic or else
				target_type.is_reference and then source_type.is_reference
			then
					-- Reattachment of basic type to basic type or
					-- of reference type to reference type.
				generate_last_assignment (Simple_assignment)
			elseif source_type.is_basic then
					-- Reattachment of basic type to reference type.
				generate_last_assignment (Metamorphose_assignment)
			elseif target_type.is_reference then
					-- Reattachment of expanded type to reference type.
				generate_last_assignment (Clone_assignment)
			else
					-- Reattachment of reference type to basic type/expanded type.
				generate_last_assignment (Unmetamorphose_assignment)
			end
		end

	generate_last_assignment (how: INTEGER)
			-- Generate last assignment in Result
		local
			buf: GENERATION_BUFFER
		do
			buf := buffer
			source.generate
			generate_special (how)
			context.byte_code.finish_compound
				-- Add a blank line before the return only if it
				-- is the last instruction.
			buf.put_new_line
			buf.put_string ("return ")
			if how = Unmetamorphose_assignment then
					-- Reattachment of reference type to basic. It cannot be reattachment
					-- to an expanded type since this is prevented during analysis.
				check is_basic_type: context.real_type (target.type).is_basic end
				buf.put_character ('*')
				target.c_type.generate_access_cast (buf)
			else
					-- Always ensure that we perform a cast to type of target.
					-- Cast in case of basic type will never loose information
					-- as it has been validated by the Eiffel compiler.
				target.c_type.generate_cast (buf)
			end
			source_print_register
			buf.put_character (';')
		end

	generate_simple_assignment
			-- Generates a simple assignment in target.
		require
			simple_assignment: simple_op_assignment = Left_simple_op or
				simple_op_assignment = Right_simple_op
		local
			binary: BINARY_B
			other: EXPR_B
			buf: GENERATION_BUFFER
		do
			buf := buffer
			binary ?= source	-- Cannot fail
			inspect
				simple_op_assignment
			when Left_simple_op then
				other := binary.right
			when Right_simple_op then
				other := binary.left
			end
				-- Generate the other side of the expression
			other.generate
			buf.put_new_line
			if not target.is_predefined then
				buf.put_character ('(')
				target.print_register
				buf.put_character (')')
			else
				target.print_register
			end
				-- Detection of <expr> +/- 1
			if
				binary.is_additive and then
				attached {INTEGER_CONSTANT} other as int
				and then int.is_one
			then
				binary.generate_plus_plus
			else
				binary.generate_simple
				other.print_register
			end
			buf.put_character (';')
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
