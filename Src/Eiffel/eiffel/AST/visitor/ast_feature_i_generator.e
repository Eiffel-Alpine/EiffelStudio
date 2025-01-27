﻿note
	description: "Create new instance of FEATURE_I"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	AST_FEATURE_I_GENERATOR

inherit
	ANY

	SHARED_NAMES_HEAP
		export
			{NONE} all
		end

	SHARED_WORKBENCH
		export
			{NONE} all
		end

	SHARED_STATELESS_VISITOR
		export
			{NONE} all
		end

	REFACTORING_HELPER
		export
			{NONE} all
		end

	SHARED_ERROR_HANDLER
		export
			{NONE} all
		end

	INTERNAL_COMPILER_STRING_EXPORTER

feature -- Factory

	new_feature (a_node: FEATURE_AS; a_name_id: INTEGER; a_class: CLASS_C): FEATURE_I
			-- Create associated FEATURE_I instance of `a_node'.
		require
			a_node_not_void: a_node /= Void
			a_class_not_void: a_class /= Void
			a_name_id_positive: a_name_id >= 0
		do
			current_class := a_class
			feature_name_id := a_name_id
			node := a_node
			process_body_as (a_node.body)
			current_class := Void
			Result := last_feature
			last_feature := Void
			feature_name_id := 0
			if Result.is_once then
				if
					attached {ONCE_PROC_I} Result as l_once
				then
					if attached a_node.once_as as l_once_as then
						if l_once_as.has_key_process (a_node) then
							l_once.set_is_process_relative
						elseif l_once_as.has_key_object then
							l_once.set_is_object_relative
						else --| default: if l_once_as.has_key_thread
							l_once.set_is_thread_relative
						end
					else
						check is_once_should_has_corresponding_once_as: False end
					end
				else
					fixme ("support process-relative constants (e.g., string constants)")
				end
			end
			if attached a_node.indexes as i then
				if i.is_stable then
					Result.set_is_stable (True)
				end
				if i.is_hidden_in_debugger_call_stack then
					Result.set_is_hidden_in_debugger_call_stack (True)
				end
				if attached {ATTRIBUTE_I} Result as a and then i.is_transient then
					a.set_is_transient (True)
				end
				if i.is_ghost then
					Result.set_is_ghost (True)
				end
				if a_node.property_name /= Void then
					Result.set_has_property (True)
					if Result.type.is_void then
						Result.set_has_property_setter (True)
					else
						Result.set_has_property_getter (True)
						if Result.assigner_name_id /= 0 then
							Result.set_has_property_setter (True)
						end
					end
				end
			end
			node := Void
		end

feature {NONE} -- Implementation: Access

	last_feature: FEATURE_I
			-- Last computed feature

	feature_name_id: INTEGER
			-- Name of feature being processed

	node: FEATURE_AS
			-- Current node (can be used to report errors)

	current_class: CLASS_C
			-- Class in which a FEATURE_AS is converted into a FEATURE_I.

feature {NONE} -- Implementation

	process_body_as (l_as: BODY_AS)
		require
			l_as_not_void: l_as /= Void
		local
			l_attr: ATTRIBUTE_I
			l_const: CONSTANT_I
			l_def_func: DEF_FUNC_I
			l_def_proc: DEF_PROC_I
			l_proc, l_func: PROCEDURE_I
			l_extern_proc: EXTERNAL_I
			l_extern_func: EXTERNAL_FUNC_I
			l_external_body: EXTERNAL_AS
				-- Hack Hack Hack
				-- A litteral numeric value is interpreted as
				-- a DOUBLE. In the case of a constant REAL
				-- declaration that wont do!
			l_extension: EXTERNAL_EXT_I
			l_il_ext: IL_EXTENSION_I
			l_lang: COMPILER_EXTERNAL_LANG_AS
			l_is_deferred_external, l_is_attribute_external: BOOLEAN
			l_result: FEATURE_I
			l_assigner_name_id: INTEGER
			l_feature_as: FEATURE_AS
		do
			if l_as.assigner /= Void then
				l_assigner_name_id := l_as.assigner.name_id
			end
			if not attached l_as.content as content then
					-- It is an attribute
				create l_attr.make
				check
					type_exists: l_as.type /= Void
				end
				l_attr.set_type (query_type (l_as.type), l_assigner_name_id)
				l_result := l_attr
				l_result.set_is_empty (True)
			elseif attached {CONSTANT_AS} content as l_constant then
					-- It is a constant feature
				if content.is_unique then
						-- No constant value is processed for a unique
						-- feature, since the second pass does it.
					create {UNIQUE_I} l_const.make
				else
						-- Constant value is processed here.
					create l_const.make
					l_const.set_value (value_i_generator.value_i (l_constant.value, current_class))
				end
				check
					type_exists: l_as.type /= Void
				end
				l_const.set_type (query_type (l_as.type), l_assigner_name_id)
				l_result := l_const
				l_result.set_is_empty (True)

			elseif attached {ROUTINE_AS} content as l_routine then
				if l_as.type = Void then
					if l_routine.is_deferred then
							-- Deferred procedure
						create {DEF_PROC_I} l_proc
					elseif l_routine.is_once then
							-- Once procedure
						create {ONCE_PROC_I} l_proc
					elseif l_routine.is_external then

							-- External procedure
						l_external_body ?= l_routine.routine_body
						l_lang ?= l_external_body.language_name
						check
							l_lang_not_void: l_lang /= Void
						end

						if
							l_routine.is_built_in and then
							attached {BUILT_IN_AS} l_routine.routine_body as l_built_in_as
						then
							l_feature_as := l_built_in_as.body
						end
						if l_feature_as /= Void then
							process_body_as (l_feature_as.body)
							l_proc ?= last_feature
							if l_proc = Void then
									-- In case it is wrongly specified in the built_in spec.
								create {DYN_PROC_I} l_proc
							end
						else
							l_extension := l_lang.extension_i
							if l_external_body.alias_name_id > 0 then
								l_extension.set_alias_name_id (l_external_body.alias_name_id)
							end

							if System.il_generation then
								l_il_ext ?= l_extension
								l_is_deferred_external := l_il_ext /= Void and then
									l_il_ext.type = (create {SHARED_IL_CONSTANTS}).Deferred_type
							end
							if not l_is_deferred_external then
								create l_extern_proc.make (l_extension)

									-- if there's a macro or a signature then encapsulate
								l_extern_proc.set_encapsulated (l_extension.need_encapsulation)
								l_proc := l_extern_proc
							else
								create l_def_proc
								l_def_proc.set_extension (l_il_ext)
								l_proc := l_def_proc
							end
						end
					else
						if l_routine.is_attribute then
							error_handler.insert_error (create {VFFD1}.make_attribute_without_query_mark
								(current_class, names_heap.item_32 (feature_name_id), node.start_location)
							)
						end
						create {DYN_PROC_I} l_proc
					end
					if l_as.arguments /= Void then
							-- Arguments initialization
						l_proc.init_arg (l_as.arguments, current_class)
					end
					l_proc.set_has_rescue_clause (l_routine.has_rescue)
					l_proc.init_assertion_flags (l_routine)
					if attached l_routine.obsolete_message as m then
						l_proc.set_obsolete_message (m.value)
					end
					l_result := l_proc
					l_result.set_is_empty (content.is_empty)
				else
					check
						type_exists: l_as.type /= Void
					end
					if l_routine.is_built_in then
						if attached {BUILT_IN_AS} l_routine.routine_body as l_built_in then
							l_feature_as := l_built_in.body
						end
						if l_feature_as /= Void then
							process_body_as (l_feature_as.body)
							if last_feature.is_constant or last_feature.is_attribute then
								l_result := last_feature
							else
								l_func ?= last_feature
								if l_func = Void then
										-- In case it is wrongly specified in the built_in spec.
									create {DYN_FUNC_I} l_func
								end
							end
						elseif current_class.is_basic then
								-- All built_in in basic classes are empty routines if not specified otherwise
								-- as they are inlined by SPECIAL_FEATURES/IL_SPECIAL_FEATURES
							create {DYN_FUNC_I} l_func
						end
					end
					if l_result = Void and l_func = Void then
						if l_routine.is_attribute then
							if l_as.arguments /= Void then
								error_handler.insert_error (create {VFFD1}.make_attribute_with_arguments
									(current_class, names_heap.item_32 (feature_name_id), node.start_location)
								)
							end
							create l_attr.make
							l_attr.set_type (query_type (l_as.type), l_assigner_name_id)
							l_attr.set_has_body (True)
							l_attr.init_assertion_flags (l_routine)
							if attached l_routine.obsolete_message as m then
								l_attr.set_obsolete_message (m.value)
							end
							l_result := l_attr
							l_result.set_is_empty (content.is_empty)
						elseif l_routine.is_deferred then
								-- Deferred function
							create {DEF_FUNC_I} l_func
						elseif l_routine.is_once then
								-- Once function
							create {ONCE_FUNC_I} l_func
						elseif l_routine.is_external then

								-- External procedure
							l_external_body ?= l_routine.routine_body
							l_lang ?= l_external_body.language_name
							check
								l_lang_not_void: l_lang /= Void
							end
							l_extension := l_lang.extension_i
							if l_external_body.alias_name_id > 0 then
								l_extension.set_alias_name_id (l_external_body.alias_name_id)
							end

							if System.il_generation then
								l_il_ext ?= l_extension
								l_is_deferred_external := l_il_ext /= Void and then
									l_il_ext.type = (create {SHARED_IL_CONSTANTS}).Deferred_type
								l_is_attribute_external := l_il_ext /= Void and then
									(l_il_ext.type = (create {SHARED_IL_CONSTANTS}).Field_type or
									l_il_ext.type = (create {SHARED_IL_CONSTANTS}).Static_field_type)

							end
							if not l_is_deferred_external and not l_is_attribute_external then
								create l_extern_func.make (l_extension)

									-- if there's a macro or a signature then encapsulate
								l_extern_func.set_encapsulated (l_extension.need_encapsulation)
								l_func := l_extern_func
							elseif l_is_attribute_external then
								create l_attr.make
								check
									il_generation: System.il_generation
									type_exists: l_as.type /= Void
								end
								l_attr.set_type (query_type (l_as.type), l_assigner_name_id)
								l_attr.set_is_empty (True)
								l_attr.set_extension (l_il_ext)
								if attached l_routine.obsolete_message as m then
									l_attr.set_obsolete_message (m.value)
								end
								l_result := l_attr
								if l_external_body.alias_name_id > 0 then
									l_result.set_private_external_name_id (l_external_body.alias_name_id)
								end
							else
								check
									il_generation: System.il_generation
								end
								create l_def_func
								l_def_func.set_extension (l_il_ext)
								l_func := l_def_func
								if l_external_body.alias_name_id > 0 then
									l_func.set_private_external_name_id (l_external_body.alias_name_id)
								end
							end
						else
							create {DYN_FUNC_I} l_func
						end
					end
					if l_result = Void then
						check l_func_not_void: l_func /= Void end
						if l_as.arguments /= Void then
								-- Arguments initialization
							l_func.init_arg (l_as.arguments, current_class)
						end
						l_func.set_has_rescue_clause (l_routine.has_rescue)
						l_func.init_assertion_flags (l_routine)
						if attached l_routine.obsolete_message as m then
							l_func.set_obsolete_message (m.value)
						end
						l_func.set_type (query_type (l_as.type), l_assigner_name_id)
						l_result := l_func
						l_result.set_is_empty (content.is_empty)
					end
				end
				l_result.set_has_immediate_class_postcondition (l_routine.has_class_postcondition)
				l_result.set_has_immediate_non_object_call (l_routine.has_non_object_call)
				l_result.set_has_immediate_non_object_call_in_assertion (l_routine.has_non_object_call_in_assertion)
				l_result.set_has_immediate_unqualified_call_in_assertion (l_routine.has_unqualified_call_in_assertion)
			else
				check
					is_known_feature_content: False
				end
			end
			last_feature := l_result
		end

	query_type (a_type: TYPE_AS): TYPE_A
		require
			a_type_not_void: a_type /= Void
		do
			Result := type_a_generator.evaluate_type (a_type, current_class)
		ensure
			query_type_not_void: Result /= Void
		end

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
