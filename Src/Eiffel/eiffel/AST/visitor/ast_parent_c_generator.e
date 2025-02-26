note
	description: "Create a PARENT_C instance from a PARENT_AS one."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	AST_PARENT_C_GENERATOR

inherit
	AST_EXPORT_STATUS_GENERATOR
		redefine
			process_parent_as,
			process_export_item_as,
			process_feature_list_as,
			process_all_as,
			reset
		end

	SHARED_NAMES_HEAP
		export
			{NONE} all
		end

	SHARED_STATELESS_VISITOR
		export
			{NONE} all
		end

	INTERNAL_COMPILER_STRING_EXPORTER

feature -- Status report

	compiled_parent (a_system: SYSTEM_I; a_class: CLASS_C; a_parent: PARENT_AS; a_is_non_conforming: BOOLEAN): PARENT_C
			-- Compiled version of a parent. The second pass needs:
			-- 1. Internal name for features, that means infix/prefix
			--	features must have a string name
			-- 2. Search table for renaming, redefining, defining and
			--	selecting clauses (which are more efficient than
			--	simple fixed lists for queries).
		require
			a_class_not_void: a_class /= Void
			a_parent_not_void: a_parent /= Void
		do
			current_system := a_system
			current_class := a_class
			is_non_conforming := a_is_non_conforming
			process_parent_as (a_parent)
			Result := last_parent_c
			reset
		ensure
			compiled_parent_not_void: Result /= Void
		end

feature {NONE} -- Implementation: Reset

	reset
		do
			Precursor {AST_EXPORT_STATUS_GENERATOR}
			last_parent_c := Void
			last_export_adaptation := Void
			is_non_conforming := False
		end

feature {NONE} -- Implementation: Access

	is_non_conforming: BOOLEAN
		-- Should computed parent be non-conforming?

	last_parent_c: PARENT_C
			-- Last computed parent

	last_export_adaptation: EXPORT_ADAPTATION
			-- Last computed export adaptation

feature {NONE} -- Implementation

	process_parent_as (l_as: PARENT_AS)
		local
			l_renaming_c: HASH_TABLE [RENAMING, INTEGER]
			l_rename_pair: RENAME_AS
			l_old_name, l_new_name: FEATURE_NAME
			old_name_id: INTEGER
			l_vhrc2: VHRC2
		do
			if is_non_conforming then
					-- If non-conforming then we will we create the appropriate non conforming parent c class
				create {NON_CONFORMING_PARENT_C} last_parent_c.make (l_as.type.class_name)
			else
				create {PARENT_C} last_parent_c.make (l_as.type.class_name)
			end
			if attached {CL_TYPE_A} type_a_generator.evaluate_type (l_as.type, current_class) as l_parent_type then
				last_parent_c.set_parent_type (l_parent_type.as_normally_attached (current_class))
				if attached l_as.exports as l_exports then
					from
						create last_export_adaptation.make (l_exports.count)
						last_parent_c.set_exports (last_export_adaptation)
						l_exports.start
					until
						l_exports.after
					loop
						process_export_item_as (l_exports.item)
						l_exports.forth
					end
				end
				if attached l_as.renaming as l_renaming then
					from
						create l_renaming_c.make (l_renaming.count)
						last_parent_c.set_renaming (l_renaming_c)
						l_renaming.start
					until
						l_renaming.after
					loop
						l_rename_pair := l_renaming.item
						l_old_name := l_rename_pair.old_name
						old_name_id := l_old_name.internal_name.name_id
						if l_renaming_c.has (old_name_id) then
							create l_vhrc2
							l_vhrc2.set_class (current_class)
							l_vhrc2.set_parent (last_parent_c.parent)
							l_vhrc2.set_feature_name (l_old_name.internal_name.name)
							l_vhrc2.set_location (l_old_name.start_location)
							Error_handler.insert_error (l_vhrc2)
						else
							l_new_name := l_rename_pair.new_name
							l_renaming_c.put (create {RENAMING}.make (l_new_name.internal_name.name_id, l_new_name.internal_alias_name_id, l_new_name.has_convert_mark), old_name_id)
						end

						l_renaming.forth
					end
				end
				if l_as.redefining /= Void then
					last_parent_c.set_redefining (search_table (l_as, l_as.redefining, Redef))
				end
				if l_as.undefining /= Void then
					last_parent_c.set_undefining (search_table (l_as, l_as.undefining, Undef))
				end
				if l_as.selecting /= Void then
					last_parent_c.set_selecting (search_table (l_as, l_as.selecting, Selec))
				end
			else
					-- This should never occur: a CLASS_TYPE_AS being translated into something else than a CL_TYPE_A.
				Error_handler.insert_error (create {INTERNAL_ERROR}.make ("Parent AST did not yield CL_TYPE_A"))
			end
		end

	process_export_item_as (l_as: EXPORT_ITEM_AS)
		do
			l_as.clients.process (Current)
			check
				last_export_status_set: last_export_status /= Void
			end
			safe_process (l_as.features)
		end

	process_feature_list_as (l_as: FEATURE_LIST_AS)
		local
			l_feature_name_id: INTEGER
			l_vlel3: VLEL3
			l_export_status: like last_export_status
			l_export_adapt: like last_export_adaptation
		do
			from
				l_as.features.start
				l_export_status := last_export_status
				l_export_adapt := last_export_adaptation
			until
				l_as.features.after
			loop
				l_feature_name_id := l_as.features.item.internal_name.name_id
				if not l_export_adapt.has (l_feature_name_id) then
					l_export_adapt.put (l_export_status, l_feature_name_id)
				else
					create l_vlel3
					l_vlel3.set_class (current_class)
					l_vlel3.set_parent (last_parent_c.parent)
					l_vlel3.set_feature_name (names_heap.item (l_feature_name_id))
					l_vlel3.set_location (l_as.features.item.start_location)
					error_handler.insert_error (l_vlel3)
				end
				l_as.features.forth
			end
		end

	process_all_as (l_as: ALL_AS)
		local
			l_vlel1: VLEL1
		do
			if last_export_adaptation.all_export = Void then
				last_export_adaptation.set_all_export (last_export_status)
			else
				create l_vlel1
				l_vlel1.set_class (current_class)
				l_vlel1.set_parent (last_parent_c.parent)
				l_vlel1.set_location (l_as.start_location)
				error_handler.insert_error (l_vlel1)
			end
		end

feature {NONE} -- Implementation

	search_table (l_as: PARENT_AS; clause: EIFFEL_LIST [FEATURE_NAME]; flag: INTEGER): SEARCH_TABLE [INTEGER]
			-- Conversion of `clause' into a search table
		require
			l_as_not_void: l_as /= Void
			clause_exists: clause /= Void
		local
			l_vdrs3: VDRS3
			feature_name_id: INTEGER
		do
			from
				create Result.make (clause.count)
				clause.start
			until
				clause.after
			loop
				feature_name_id := clause.item.internal_name.name_id
				if Result.has (feature_name_id) then
						-- Twice the same name in a parent clause
					inspect
						flag
					when Redef then
						create l_vdrs3
					when Undef then
						create {VDUS4} l_vdrs3
					when Selec then
						create {VMSS3} l_vdrs3
					end
					l_vdrs3.set_class (current_class)
					l_vdrs3.set_parent_name (l_as.type.class_name.name)
					l_vdrs3.set_feature_name (clause.item.internal_name.name)
					l_vdrs3.set_location (clause.item.start_location)
					Error_handler.insert_error (l_vdrs3)
				else
					Result.put (feature_name_id)
				end
				clause.forth
			end
		end

feature {NONE} -- Implementation

	Redef: INTEGER = 1
	Undef: INTEGER = 2
	Selec: INTEGER = 3;

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
