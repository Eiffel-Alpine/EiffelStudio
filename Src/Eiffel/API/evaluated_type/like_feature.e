note
	description: "Class for an staticed type on a feature."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision $"

class
	LIKE_FEATURE

inherit
	LIKE_TYPE_A
		redefine
			dispatch_anchors,
			evaluated_type_in_descendant,
			initialize_info,
			is_expanded_creation_possible,
			is_explicit,
			is_syntactically_equal,
			update_dependance
		end

	SHARED_NAMES_HEAP
		export
			{NONE} all
		end

	SHARED_ENCODING_CONVERTER
		export
			{NONE} all
		end

create
	make

feature -- Initialization and reinitialization

	make (f: FEATURE_I; a_context_class_id: INTEGER)
			-- Creation
		require
			valid_argument: f /= Void
			a_context_class_id_positive: a_context_class_id > 0
		do
			feature_id := f.feature_id
			routine_id := f.rout_id_set.first
			feature_name_id := f.feature_name_id
			class_id := a_context_class_id
		ensure
			feature_id_set: feature_id = f.feature_id
			routine_id_set: routine_id = f.rout_id_set.first
			feature_name_id_set: feature_name_id = f.feature_name_id
			class_id_set: class_id = a_context_class_id
		end

feature -- Visitor

	process (v: TYPE_A_VISITOR)
			-- Process current element.
		do
			v.process_like_feature (Current)
		end

feature -- Properties

	feature_name_id: INTEGER
			-- Feature name ID of anchor

	class_id: INTEGER;
			-- Class ID of the class where the anchor is referenced

feature {INTERNAL_COMPILER_STRING_EXPORTER} -- Properties

	feature_name: STRING
			-- Final name of anchor.
		require
			feature_name_id_set: feature_name_id >= 1
		do
			Result := Names_heap.item (feature_name_id)
		ensure
			Result_not_void: Result /= Void
			Result_not_empty: not Result.is_empty
		end

feature -- Status Report

	is_explicit: BOOLEAN
			-- Is type fixed at compile time without anchors or formals?
		do
			if system.in_final_mode then
				initialize_info (shared_create_info)
				Result := shared_create_info.is_explicit
			else
				Result := False
			end
		end

	is_expanded_creation_possible: BOOLEAN
			-- <Precursor>
		do
			Result := attached actual_type as a and then a.is_expanded implies a.is_expanded_creation_possible
		end

feature {COMPILER_EXPORTER} -- Implementation: Access

	feature_id: INTEGER
			-- Feature ID of the anchor

	routine_id: INTEGER
			-- Routine ID of anchor in context of `class_id'.

feature -- Access

	same_as (other: TYPE_A): BOOLEAN
			-- Is the current type the same as `other' ?
		do
			if
				attached {LIKE_FEATURE} other as o and then
				o.routine_id = routine_id and then
				has_same_marks (o)
			then
					-- Compare computed actual types as otherwise they may be left
					-- from the previous compilation in an invalid state.
				if attached actual_type as a then
					Result :=
						is_valid and then
						o.is_valid and then
						attached o.actual_type as oa and then
						a.same_as (oa)
				else
					Result := not attached o.actual_type
				end
			end
		end

	update_dependance (feat_depend: FEATURE_DEPENDANCE)
			-- Update dependency for Dead Code Removal
		local
			a_class: CLASS_C
			feature_i: FEATURE_I
		do
				-- we must had a dependance to the anchor feature
			a_class := System.class_of_id (class_id)
			feature_i := a_class.feature_table.item_id (feature_name_id)
			feat_depend.extend_depend_unit_with_level (class_id, feature_i, 0)
		end

feature -- Generic conformance

	initialize_info (an_info: like shared_create_info)
		do
				-- FIXME: Should we use `make' or just `set_info'?
			an_info.make (feature_id, routine_id)
		end

	create_info: CREATE_FEAT
		do
			create Result.make (feature_id, routine_id)
		end

	shared_create_info: CREATE_FEAT
		once
			create Result
		end

feature -- IL code generation

	dispatch_anchors (a_context_class: CLASS_C)
			-- <Precursor>
		do
			a_context_class.extend_type_set (routine_id)
		end

feature -- Output

	dump: STRING
			-- Dumped trace
		local
			s: STRING
		do
			s := actual_type.dump
			create Result.make (20 + s.count)
			Result.append_character ('[')
			dump_marks (Result)
			Result.append ("like " + feature_name +"] ")
			Result.append (s)
		end

	ext_append_to (a_text_formatter: TEXT_FORMATTER; a_context_class: CLASS_C)
			-- <Precursor>
		local
			ec: CLASS_C
			l_feat: E_FEATURE
			l_full_feat_name: STRING_32
		do
			ec := Eiffel_system.class_of_id (class_id)
			a_text_formatter.process_symbol_text ({SHARED_TEXT_ITEMS}.ti_l_bracket)
			ext_append_marks (a_text_formatter)
			a_text_formatter.process_keyword_text ({SHARED_TEXT_ITEMS}.ti_like_keyword, Void)
			a_text_formatter.add_space
			if ec.has_feature_table then
				l_feat := ec.feature_with_name (feature_name)
			end
			l_full_feat_name := encoding_converter.utf8_to_utf32 (feature_name)
			if l_feat /= Void then
				a_text_formatter.add_feature (l_feat, l_full_feat_name)
			else
				a_text_formatter.add_feature_name (l_full_feat_name, ec)
			end
			a_text_formatter.process_symbol_text ({SHARED_TEXT_ITEMS}.ti_r_bracket)
			a_text_formatter.add_space
			if is_valid then
				actual_type.ext_append_to (a_text_formatter, a_context_class)
			end
		end

feature -- Primitives

	evaluated_type_in_descendant (a_ancestor, a_descendant: CLASS_C; a_feature: FEATURE_I): LIKE_FEATURE
		local
			l_anchor: FEATURE_I
		do
			if a_ancestor /= a_descendant then
				l_anchor := a_descendant.feature_of_rout_id (routine_id)
				check l_anchor_not_void: l_anchor /= Void end
				create Result.make (l_anchor, a_descendant.class_id)
				Result.set_actual_type (l_anchor.type.actual_type)
				Result.set_marks_from (Current)
			else
				Result := Current
			end
		end

feature -- Comparison

	is_equivalent (other: like Current): BOOLEAN
			-- Is `other' equivalent to the current object ?
		do
			Result := routine_id = other.routine_id and then
				equivalent (actual_type, other.actual_type) and then
				has_same_marks (other)
		end

	is_syntactically_equal (other: TYPE_A): BOOLEAN
			-- <Precursor>
		do
			if attached {like Current} other then
				Result := same_as (other)
			elseif attached {UNEVALUATED_LIKE_TYPE} other as o then
				Result := feature_name_id = o.anchor_name_id and then has_same_marks (o)
			end
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
