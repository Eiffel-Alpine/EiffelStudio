note
	description: "TODO"
	date: "$Date$"
	revision: "$Revision$"

class
	E2B_SIMPLE_LIST_ACROSS_HANDLER

inherit
	E2B_ACROSS_HANDLER

create
	make

feature -- Access

	set: IV_EXPRESSION
		-- Boogie set to quantify over.

feature -- Basic operations

	handle_call_item (a_feature: FEATURE_I)
			-- <Precursor>
		do
			expression_translator.set_last_expression (expression_translator.locals_map.item (bound_variable.position))
		end

	handle_call_cursor_index (a_feature: FEATURE_I)
			-- <Precursor>
		do
		end

	handle_call_after (a_feature: FEATURE_I)
			-- <Precursor>
		do
		end

	handle_call_forth (a_feature: FEATURE_I)
			-- <Precursor>
		do
		end

feature {NONE} -- Implementation

	translate_domain
			-- <Precursor>
		local
			l_type: GEN_TYPE_A
			l_gen_type: CL_TYPE_A
			l_content_type: IV_TYPE
			l_class: CLASS_C
			l_seq_feature: FEATURE_I
			l_heap_access: IV_EXPRESSION
		do
			l_type ?= domain.type
			check l_type /= Void and l_type.generics.count = 1 end
			l_gen_type ?= l_type.generics.first
			l_class := l_type.base_class
			l_seq_feature := l_class.feature_named_32 ("sequence")
			l_content_type := types.for_class_type (l_gen_type)

			domain.process (expression_translator)
			l_heap_access := factory.heap_access (expression_translator.entity_mapping.heap, expression_translator.last_expression, name_translator.boogie_procedure_for_feature (l_seq_feature, l_type), l_content_type)
			set := factory.function_call ("Seq#Range", << l_heap_access >>, types.set (l_content_type))
		end

	bound_var_type: IV_TYPE
			-- <Precursor>
		do
			Result := types.for_class_type (expression_translator.class_type_in_current_context (bound_variable.type.generics.first))
		end

	guard (a_bound_var: IV_ENTITY): IV_EXPRESSION
			-- <Precursor>
		do
			Result := factory.map_access (set, << a_bound_var >>)
		end

	add_triggers (a_quantifier: IV_QUANTIFIER)
			-- Add triggers to `a_quantifier' generated from the current across expression.
		do
			a_quantifier.add_trigger (guard (a_quantifier.bound_variables.first.entity))
		end

end
