note
	description: "A feature to be inserted into the auto-complete list"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	author     : "$Author$"
	date       : "$Date$"
	revision   : "$Revision$"

class
	EB_FEATURE_FOR_COMPLETION

inherit
	EB_NAME_FOR_COMPLETION
		rename
			make as make_old
		redefine
			icon,
			tooltip_text,
			is_class,
			insert_name,
			grid_item,
			full_insert_name,
			begins_with,
			completion_type,
			is_obsolete
		end

	PREFIX_INFIX_NAMES
		undefine
			out, copy, is_equal
		end

	EB_SHARED_EDITOR_TOKEN_UTILITY
		undefine
			out, copy, is_equal
		end

create
	make

create {EB_FEATURE_FOR_COMPLETION}
	make_old

feature {NONE} -- Initialization

	make (a_feature: E_FEATURE; a_name: like name; a_name_is_ambiguated, a_is_upper: BOOLEAN)
			-- Create and initialize a new completion feature using `a_feature'
			-- `a_name' is either an ambiguated name when `a_name_is_ambiguated',
			-- or a fixed name when not `a_name_is_ambiguated'.
			-- When `a_name' is Void, `a_name_is_ambiguated' is discarded.
			-- When `a_is_upper', it means that first letter should be in upper.
		require
			a_feature_not_void: a_feature /= Void
		local
			l_s: STRING_32
			l_name: STRING_32
			l_type: like completion_type
		do
			if a_feature.is_infix then
				l_s := a_feature.infix_symbol_32
			else
				l_s := a_feature.name_32
			end
			if a_name /= Void then
				make_old (a_name)
			else
				make_old (l_s)
			end
			full_name := l_s

			associated_feature := a_feature
			return_type := a_feature.type

			if show_signature then
				append (feature_signature)
			end
			if show_type then
				l_type := completion_type
				if not l_type.is_empty then
					append (ti_colon)
					append (ti_space)
					append (l_type)
				end
			end

			create insert_name_internal.make (name.count + feature_signature.count)
			insert_name_internal.append (name)
			if a_is_upper then
				insert_name_internal.put (insert_name_internal.item (1).as_upper, 1)
			end
			insert_name_internal.append (feature_signature)

			if a_name_is_ambiguated then
				l_name := associated_feature.name_32
				create full_insert_name_internal.make (l_name.count + feature_signature.count)
				full_insert_name_internal.append (l_name)
				if a_is_upper then
					full_insert_name_internal.put (full_insert_name_internal.item (1).as_upper, 1)
				end
				full_insert_name_internal.append (feature_signature)
			else
				full_insert_name_internal := insert_name_internal
			end
			name_is_ambiguated := a_name_is_ambiguated
		ensure
			associated_feature_set: associated_feature = a_feature
			return_type_set: return_type = a_feature.type
			name_is_ambiguated_set: name_is_ambiguated = a_name_is_ambiguated
		end

feature -- Access

	is_class: BOOLEAN = False
			-- Is completion feature a class, of course not.	

	insert_name: STRING_32
			-- Name to insert in editor
		do
			Result := insert_name_internal
		end

	full_insert_name: STRING_32
			-- Full name to insert in editor
		do
			Result := full_insert_name_internal
		end

	icon: EV_PIXMAP
			-- Associated icon based on data
		do
			Result := pixmap_from_e_feature (associated_feature)
		end

	tooltip_text: STRING_32
			-- Text for tooltip of Current.  The tooltip shall display information which is not included in the
			-- actual output of Current.
		local
			l_comments: EIFFEL_COMMENTS
			l_text: STRING_32
			l_nls: INTEGER
		do
			create Result.make_empty

			l_comments := (create {COMMENT_EXTRACTOR}).feature_comments (associated_feature)
			if attached l_comments then
				from l_comments.start until l_comments.after loop
					if attached l_comments.item as l_comment_line then
						l_text := l_comment_line.content_32
						if l_text.is_valid_as_string_8 then
							l_text.left_adjust
							l_text.right_adjust
						end

						if not l_text.is_empty then
							Result.append_string_general (l_text)
							Result.append_character (' ')
							l_nls := 0
						else
							if l_nls >= 2 and then not l_comments.islast then
								Result.append ("%N%N")
							end
						end
						l_nls := l_nls + 1
					end
					l_comments.forth
				end
			end

			if Result.is_empty then
				Result := string
			end
		end

	completion_type: STRING_32
			-- The type of the feature (for a function, attribute)
		do
			if internal_completion_type = Void then
				if return_type /= Void then
					token_writer.new_line
					return_type.ext_append_to (token_writer, associated_feature.associated_class)
					Result := token_writer.last_line.wide_image
				else
					create Result.make_empty
				end
				internal_completion_type := Result
			else
				Result := internal_completion_type
			end
		end

	grid_item: EB_GRID_EDITOR_TOKEN_ITEM
			-- Grid item
		local
			l_style: like feature_style
		do
			l_style := feature_style

			if not show_signature and then not show_type then
				l_style.disable_argument
				l_style.disable_return_type
			elseif show_signature and then not show_type then
				l_style.enable_argument
				l_style.disable_return_type
			elseif show_type and then not show_signature then
				l_style.enable_return_type
				l_style.disable_argument
			elseif show_type and then show_signature then
				l_style.enable_argument
				l_style.enable_return_type
			end
			if show_disambiguated_name and name_is_ambiguated then
				l_style.disable_use_overload_name
			else
				l_style.enable_use_overload_name
			end
			l_style.set_e_feature (associated_feature)
			l_style.set_overload_name (name)
			create Result

			Result.set_overriden_fonts (label_font_table, label_font_height)
			Result.set_pixmap (icon)
			Result.set_text_with_tokens (l_style.text)
		end

	associated_feature: E_FEATURE
			-- Feature associated with completion item

feature -- Query

	has_arguments: BOOLEAN
			-- Does `associated_feature' have arguments?
		do
			Result := associated_feature.has_arguments
		end

feature -- Status report

	is_obsolete: BOOLEAN
			-- Is item obsolete?
		do
			Result := associated_feature.is_obsolete
		end
feature -- Comparison

	begins_with (s: detachable READABLE_STRING_GENERAL): BOOLEAN
			-- Does this feature name begins with `s'?
		do
			if s /= Void then
				if show_disambiguated_name and name_is_ambiguated then
					Result := Precursor {EB_NAME_FOR_COMPLETION} (s)
				else
					Result := name_matcher.prefix_string (s.to_string_32, name)
				end
			end
		end

feature -- Setting

	set_insert_name (a_name: like insert_name)
			-- Set `insert_name' with `a_name'.
		require
			a_name_attached: a_name /= Void
		do
			insert_name_internal := a_name.twin
		ensure
			insert_name_set: insert_name /= Void and then insert_name.is_equal (a_name)
		end

feature {NONE} -- Implementation

	feature_signature: STRING_32
			-- The signature of `associated_feature'
		require
			associated_feature_not_void: associated_feature /= Void
		do
			if internal_feature_signature = Void then
				if associated_feature.has_arguments then
					token_writer.new_line
					associated_feature.append_arguments (token_writer)
					Result := token_writer.last_line.wide_image
				else
					create Result.make_empty
				end
				internal_feature_signature := Result
			else
				Result := internal_feature_signature
			end
		ensure
			result_not_void: Result /= Void
		end

	internal_feature_signature: STRING_32
			-- cache `feature_signature'

	insert_name_internal: STRING_32

	full_insert_name_internal: STRING_32

	name_is_ambiguated: BOOLEAN
			-- Is this name ambiguated. If not we always use the received name rather than the feature name.

	feature_style: EB_FEATURE_EDITOR_TOKEN_STYLE
			-- Feature style to generate text for `associated_feature'.
		once
			create Result
			Result.disable_class
			Result.disable_comment
			Result.disable_value_for_constant
		ensure
			result_attached: Result /= Void
		end

invariant
	associated_feature_not_void: associated_feature /= Void

note
	copyright:	"Copyright (c) 1984-2013, Eiffel Software"
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

end -- class EB_FEATURE_FOR_COMPLETION
