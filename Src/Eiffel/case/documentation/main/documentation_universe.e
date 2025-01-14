﻿note
	description:
		"Groups selection for documentation."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	DOCUMENTATION_UNIVERSE

inherit
	SHARED_WORKBENCH

create
	make,
	make_all

feature {NONE} -- Initialization

	make
			-- Initialize with no groups in system.
		do
			create groups.make (10)
			create classes_internal.make (100)
			any_group_format_generated := True
			any_class_format_generated := True
			any_feature_format_generated := True
		end

	make_all
			-- Initialize with all groups in system.
		do
			make
			include_all
		end

feature -- Element change

	include_group (gr: CONF_GROUP)
			-- Add `gr' (if not yet present) to universe.
		require
			gr_not_void: gr /= Void
			not_is_universe_completed: not is_universe_completed
		do
			if not groups.has (gr) then
				groups.extend (gr)
				if attached gr.classes as cs then
					across
						cs as c
					loop
						if
							attached {CLASS_I} c.item as class_i and then
							class_i.is_compiled
						then
							classes_internal.extend (class_i)
						end
					end
				end
			end
		end

	include_all
			-- Include all groups from the universe in the documentation.
		require
			not_is_universe_completed: not is_universe_completed
		local
			g: CONF_GROUP
		do
			across
				Universe.groups as gs
			loop
				g := gs.item
				groups.extend (g)
				if attached g.classes as cs then
					across
						cs as c
					loop
						if
							attached {CLASS_I} c.item as class_i and then
							class_i.is_compiled
						then
							classes_internal.extend (class_i)
						end
					end
				end
			end
		end

feature -- Setting

	complete_universe
			-- Set `is_universe_completed' to True.
		do
			group_sorter.sort (groups)
			is_universe_completed := True
		ensure
			is_universe_completed_set: is_universe_completed
			groups_sorter: group_sorter.sorted (groups)
		end

feature -- Access

	groups: ARRAYED_LIST [CONF_GROUP]
			-- All groups in universe.

	classes: ARRAYED_LIST [CLASS_I]
			-- All classes from `groups' sorted.
		do
			Result := classes_internal
			if not class_sorted then
				class_sorter.sort (Result)
				class_sorted := True
			end
		ensure
			classes_not_void: Result /= Void
			sorted: class_sorter.sorted (Result)
		end

	classes_in_group (group: CONF_GROUP): like classes
			-- List of all items from `classes' whose group is `group' and alphabetically sorted.
		require
			group_not_void: group /= Void
		do
			Result := unsorted_classes_in_group (group)
			class_sorter.sort (Result)
		ensure
			classes_in_group_not_void: Result /= Void
			sorted: class_sorter.sorted (Result)
		end

	any_group_format_generated: BOOLEAN
			-- Is a format generated where a group link can be redirected to?

	any_class_format_generated: BOOLEAN
			-- Is a format generated where a class link can be redirected to?

	any_feature_format_generated: BOOLEAN
			-- Is a format generated where a feature link can be redirected to?

	found_group: CONF_GROUP
			-- Last found group in a search in `is_class_in_group', `is_XXX_generated', otherwise Void.

feature -- Status report

	is_universe_completed: BOOLEAN
			-- Is setting of `groups' completed?

	is_group_generated (a_group: CONF_GROUP): BOOLEAN
			-- Is documentation for `a_group' generated?
		do
			Result := any_group_format_generated and then groups.has (a_group)
			if Result then
				found_group := a_group
			else
				found_group := Void
			end
		ensure
			found_group_reset: not Result implies found_group = Void
			found_group_set: Result implies (found_group /= Void and then groups.has (found_group))
		end

	is_class_generated (a_class: CLASS_I): BOOLEAN
			-- Is documentation for `a_class' generated?
		do
			Result := any_class_format_generated and then is_class_in_group (a_class)
		ensure
			found_group_reset: not Result implies found_group = Void
			found_group_set: Result implies (found_group /= Void and then groups.has (found_group))
		end

	is_feature_generated (a_feature: E_FEATURE): BOOLEAN
			-- Is documentation for `cl' generated?
		do
			Result := any_feature_format_generated and then is_class_in_group (a_feature.written_class.lace_class)
		ensure
			found_group_reset: not Result implies found_group = Void
			found_group_set: Result implies (found_group /= Void and then groups.has (found_group))
		end

	is_class_in_group (a_class: CLASS_I): BOOLEAN
			-- Does `a_class' belongs to one of the group in `groups'.
		local
			l_assemblies: ARRAYED_LIST [CONF_ASSEMBLY]
			l_index: INTEGER
		do
			l_index := classes.index
			classes.start
			classes.search (a_class)
			if not classes.after then
				Result := True
				found_group := classes.item_for_iteration.group
					-- if the class is in the list of classes there has to be a group that is included
				if not groups.has (found_group) then
					if found_group.is_physical_assembly then
						if attached {CONF_PHYSICAL_ASSEMBLY} found_group as l_phys_as then
							from
								l_assemblies := l_phys_as.assemblies
								l_assemblies.start
							until
								groups.has (found_group) or l_assemblies.after
							loop
								found_group := l_assemblies.item
								l_assemblies.forth
							end
						else
							check is_physical_assembly: False end
						end
					else
						found_group := found_group.target.system.lowest_used_in_library
					end
				end
			else
				found_group := Void
			end
			classes.go_i_th (l_index)
		ensure
			found_group_reset: not Result implies found_group = Void
			found_group_set: Result implies (found_group /= Void and then groups.has (found_group))
		end

feature -- Status setting

	set_any_group_format_generated (f: BOOLEAN)
		do
			any_group_format_generated := f
		end

	set_any_class_format_generated (f: BOOLEAN)
		do
			any_class_format_generated := f
		end

	set_any_feature_format_generated (f: BOOLEAN)
		do
			any_feature_format_generated := f
		end

feature {NONE} -- Implementation

	unsorted_classes_in_group (group: CONF_GROUP): like classes
			-- List of all items from `classes' whose group is `group'.
		require
			group_not_void: group /= Void
		do
			create Result.make (100)
			if group.classes_set then
				across
					group.classes as cs
				loop
					if
						attached {CLASS_I} cs.item as class_i and then
						class_i.is_compiled
					then
						Result.extend (class_i)
					end
				end
			end
		ensure
			unsorted_classes_in_group_not_void: Result /= Void
		end

feature {NONE} -- Implementation: Access

	class_sorter: QUICK_SORTER [CLASS_I]
			-- Sorter object for classes.
		once
			create Result.make (create {COMPARABLE_COMPARATOR [CLASS_I]})
		ensure
			Result_not_void: Result /= Void
		end

	group_sorter: QUICK_SORTER [CONF_GROUP]
			-- Sorter object for groups.
		once
			create Result.make (create {COMPARABLE_COMPARATOR [CONF_GROUP]})
		ensure
			Result_not_void: Result /= Void
		end

	classes_internal: ARRAYED_LIST [CLASS_I]
			-- Classes internal.

	class_sorted: BOOLEAN
			-- Is classes sorted?

invariant
	groups_not_void: groups /= Void

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
