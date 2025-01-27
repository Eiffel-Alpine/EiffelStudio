﻿note
	description: "[
		Visitor for Eiffel errors. Currently it visists only the node which are defined in the parser library.
		
		All the nodes defined by the Eiffel compiler are descendants of COMPILER_ERROR and are using dynamic binding
		for visiting. This is why there is some code duplication between the code in COMPILER_ERROR and in ERROR_TRACER
		for the display routines defined in COMPILER_ERROR.
		
		When a complete redesign of the error handling is done in the compiler, this code duplication should disappear.
		]"
	legal: "See notice at end of class."
	status: "See notice at end of class.";
	date: "$Date$"
	revision: "$Revision$"

class
	ERROR_TRACER

inherit
	ERROR_VISITOR

	EIFFEL_LAYOUT

	ERROR_CONTEXT_PRINTER
		export
			{NONE} all
		end

feature -- Display

	trace (a_text_formatter: TEXT_FORMATTER; a_error: ERROR)
			-- Display `a_error' in `a_text_formatter' using regular formatting.
		require
			text_formatter_not_void: a_text_formatter /= Void
			error_not_void: a_error /= Void
		do
			trace_with_style (a_text_formatter, a_error, normal)
		end

	trace_tersely (a_text_formatter: TEXT_FORMATTER; a_error: ERROR)
			-- Display `a_error' in `a_text_formatter' tersely in a single line.
		require
			text_formatter_not_void: a_text_formatter /= Void
			error_not_void: a_error /= Void
		do
			trace_with_style (a_text_formatter, a_error, single_line)
		end

	trace_context (a_text_formatter: TEXT_FORMATTER; a_error: ERROR)
			-- Display source context of `a_error' in `a_text_formatter'.
		require
			text_formatter_not_void: a_text_formatter /= Void
			error_not_void: a_error /= Void
		do
			trace_with_style (a_text_formatter, a_error, context)
		end

	trace_error_code (t: TEXT_FORMATTER; e: ERROR)
			-- Display a short error code of `e` in `t`.
		require
			t_attached: attached t
			e_attached: attached e
		local
			n: like {ERROR}.subcode
		do
			t.add_error (e, e.code)
			n := e.subcode
			if e.subcode /= 0 then
				t.add_char ('(')
				t.add_int (n)
				t.add_char (')')
			end
		end

feature {NONE} -- Display

	trace_with_style (a_text_formatter: TEXT_FORMATTER; a_error: ERROR; a_kind: INTEGER)
			-- Display `a_error' in `a_text_formatter'
		require
			text_formatter_not_void: a_text_formatter /= Void
			error_not_void: a_error /= Void
			valid_kind: a_kind = normal or a_kind = single_line or a_kind = context
		local
			retried: BOOLEAN
		do
			if not retried then
				type := a_kind
				text_formatter := a_text_formatter
				a_error.process (Current)
			end
			text_formatter := Void
			type := normal
		rescue
			retried := True
			retry
		end

feature -- Access

	normal: INTEGER = 0
			-- A tracing option to show full (potentially multi-line) error message.

	single_line: INTEGER = 1
			-- A tracing option to show brief single-line error message.

	context: INTEGER = 2
			-- A tracing option to show a context of an errot.

feature -- Processing

	process_bad_character (a_value: BAD_CHARACTER)
			-- Process object `a_value'.
		do
			process_syntax_error (a_value)
		end

	process_basic_gen_type_err (a_value: BASIC_GEN_TYPE_ERR)
			-- Process object `a_value'.
		do
			process_syntax_error (a_value)
		end

	process_error (a_value: ERROR)
			-- Process object `a_value'.
		do
			inspect type
			when normal then
				trace_error (text_formatter, a_value)
			when single_line then
				trace_single_line (text_formatter, a_value)
			when context then
				trace_primary_context (text_formatter, a_value)
			else

			end
		end

	process_string_extension (a_value: STRING_EXTENSION)
			-- Process object `a_value'.
		do
			process_syntax_error (a_value)
		end

	process_string_uncompleted (a_value: STRING_UNCOMPLETED)
			-- Process object `a_value'.
		do
			process_syntax_error (a_value)
		end

	process_syntax_error (a_value: SYNTAX_ERROR)
			-- Process object `a_value'.
		local
			l_msg: STRING
		do
			if type = normal then
				a_value.initialize_output
				text_formatter.add ("Syntax error at line ")
				text_formatter.add_int (a_value.line)
					-- Error happened in a class
				if attached {CLASS_C} a_value.associated_class as l_class1 then
					text_formatter.add (" in class ")
					text_formatter.add_class_syntax (a_value, l_class1, l_class1.class_signature)
				elseif a_value.file_name /= Void then
						-- `associated_class' May be void at degree 6 when parsing partial classes
					text_formatter.add (" in file ")
					text_formatter.add (a_value.file_name)
				end
				if a_value.error_message /= Void and then not a_value.error_message.is_empty then
					text_formatter.add_new_line
					text_formatter.add (a_value.error_message)
				end
				text_formatter.add_new_line
				l_msg := a_value.syntax_message
				if not l_msg.is_empty then
					text_formatter.add ("(")
					text_formatter.add (l_msg)
					text_formatter.add (")")
					text_formatter.add_new_line
				end
				if a_value.has_source_text then
					text_formatter.add_new_line
					display_line (text_formatter, a_value.previous_line_32)
					display_syntax_line (text_formatter, a_value.current_line_32, a_value)
					display_line (text_formatter, a_value.next_line_32)
				else
					text_formatter.add (" (source code is not available)")
					text_formatter.add_new_line
				end
			elseif type = context then
				if attached {CLASS_C} a_value.associated_class as l_class2 then
					if attached {TEXT_FORMATTER} text_formatter as l_formatter then
						print_context_class (l_formatter, l_class2)
					end
				elseif a_value.file_name /= Void then
					process_error (a_value)
				end
			elseif type = single_line then
				a_value.initialize_output
				if a_value.syntax_message /= Void and then not a_value.syntax_message.is_empty then
					text_formatter.add (a_value.syntax_message)
				else
					text_formatter.add ("Syntax error at line ")
					text_formatter.add_int (a_value.line)
					text_formatter.add (".")
				end
			end
		end

	process_syntax_warning (a_value: SYNTAX_WARNING)
			-- Process object `a_value'.
		local
			l_w: STRING_32
		do
			if type = normal then
				a_value.initialize_output

				text_formatter.add_error (a_value, "Obsolete")
				text_formatter.add (" syntax used at line ")
				text_formatter.add_int (a_value.line)
					-- Error happened in a class
				if attached {CLASS_C} a_value.associated_class as l_class1 then
					text_formatter.add (" in class ")
					text_formatter.add_class_syntax (a_value, l_class1, l_class1.class_signature)
				end
				l_w := a_value.warning_message_32
				if not l_w.is_empty then
					text_formatter.add_new_line
					text_formatter.add (l_w)
					text_formatter.add_new_line
				end
				text_formatter.add_new_line
				if a_value.has_source_text then
					display_line (text_formatter, a_value.previous_line_32)
					display_syntax_line (text_formatter, a_value.current_line_32, a_value)
					display_line (text_formatter, a_value.next_line_32)
				else
					text_formatter.add (" (source code is not available)")
					text_formatter.add_new_line
				end
			elseif type = single_line then
				a_value.initialize_output
				text_formatter.add ("Obsolete syntax: ")
				text_formatter.add (a_value.warning_message_32)
			elseif type = context then
				if attached {CLASS_C} a_value.associated_class as l_class2 then
					if attached {TEXT_FORMATTER} text_formatter as l_formatter then
						print_context_class (l_formatter, l_class2)
					end
				else
					trace_primary_context (text_formatter, a_value)
				end
			end
		end

	process_user_defined_error (a_value: USER_DEFINED_ERROR)
			-- Process object `a_value'.
		do
			if attached {COMPILER_ERROR} a_value as l_compiler_error then
				inspect type
				when normal then
					l_compiler_error.trace (text_formatter)
				when single_line then
					l_compiler_error.trace_single_line (text_formatter)
				when context then
					l_compiler_error.trace_primary_context (text_formatter)
				end
			else
				process_error (a_value)
			end
		end

	process_verbatim_string_uncompleted (a_value: VERBATIM_STRING_UNCOMPLETED)
			-- Process object `a_value'.
		do
			process_syntax_error (a_value)
		end

	process_viin (a_value: VIIN)
			-- Process object `a_value'.
		do
			if type = normal then
				print_error_message (text_formatter, a_value)
				a_value.initialize_output
				if attached {CLASS_C} a_value.associated_class as l_class then
					text_formatter.add ("Class: ")
					text_formatter.add_class_syntax (a_value, l_class, l_class.class_signature)
					text_formatter.add_new_line
				elseif a_value.file_name /= Void then
						-- `current_class' May be void at degree 6 when parsing partial classes
					text_formatter.add ("Error in file ")
					text_formatter.add (a_value.file_name)
					text_formatter.add_new_line
				end
				text_formatter.add ("Line: ")
				text_formatter.add_int (a_value.line)
					-- Error happened in a class
				text_formatter.add_new_line
				if a_value.has_source_text then
					display_line (text_formatter, a_value.previous_line_32)
					display_syntax_line (text_formatter, a_value.current_line_32, a_value)
					display_line (text_formatter, a_value.next_line_32)
				else
					text_formatter.add (" (source code is not available)")
					text_formatter.add_new_line
				end
			else
				process_error (a_value)
			end
		end

	process_vvok (a_value: VVOK)
			-- Process object `a_value'.
		do
			if type = normal then
				print_error_message (text_formatter, a_value)
				a_value.initialize_output
				if attached {CLASS_C} a_value.associated_class as l_class then
					text_formatter.add ("Class: ")
					text_formatter.add_class_syntax (a_value, l_class, l_class.class_signature)
					text_formatter.add_new_line
				elseif a_value.file_name /= Void then
						-- `current_class' May be void at degree 6 when parsing partial classes
					text_formatter.add ("Error in file ")
					text_formatter.add (a_value.file_name)
					text_formatter.add_new_line
				end
				text_formatter.add ("Line: ")
				text_formatter.add_int (a_value.line)
					-- Error happened in a class
				text_formatter.add_new_line
				if a_value.has_source_text then
					display_line (text_formatter, a_value.previous_line_32)
					display_syntax_line (text_formatter, a_value.current_line_32, a_value)
					display_line (text_formatter, a_value.next_line_32)
				else
					text_formatter.add (" (source code is not available)")
					text_formatter.add_new_line
				end
			else
				process_error (a_value)
			end
		end

feature {NONE} -- Type of display

	type: INTEGER
			-- Type of display requested.

	text_formatter: TEXT_FORMATTER

feature {NONE} -- Trace

	trace_error (a_text_formatter: TEXT_FORMATTER; a_error: ERROR)
			-- Display full error message in `a_text_formatter'.
		require
			valid_st: a_text_formatter /= Void;
			error_not_void: a_error /= Void
			is_defined: a_error.is_defined
		do
			print_error_message (a_text_formatter, a_error);
			if attached {COMPILER_ERROR} a_error as l_compiler_error then
				l_compiler_error.build_explain (a_text_formatter);
			end
		end;

	trace_single_line (a_text_formatter: TEXT_FORMATTER; a_error: ERROR)
			-- Display short error, single line message in `a_text_formatter'.
		require
			valid_st: a_text_formatter /= Void;
			error_not_void: a_error /= Void
			is_defined: a_error.is_defined
		do
			print_single_line_error_message (a_text_formatter, a_error)
		end

	trace_primary_context (a_text_formatter: TEXT_FORMATTER; a_error: ERROR)
			-- Build the primary context string so errors can be navigated to
		require
			valid_st: a_text_formatter /= Void
			error_not_void: a_error /= Void
			is_defined: a_error.is_defined
		do
			if a_error.has_associated_file then
				a_text_formatter.add_string (a_error.file_name)
			end
		end

feature {NONE} -- Line

	display_line (a_text_formatter: TEXT_FORMATTER; a_line: STRING_32)
			-- Display `a_line' in `a_text_formatter'. It translates `%T' accordingly to `a_text_formatter' specification
			-- which is to call `add_indent'.
		require
			st_not_void: a_text_formatter /= Void
		local
			i: INTEGER
			nb: INTEGER
			c: CHARACTER_32
		do
			if a_line /= Void then
				from
					nb := a_line.count
				until
					i = nb
				loop
					i := i + 1
					c := a_line.item (i)
					if c = '%T' then
						a_text_formatter.add (" ")
						a_text_formatter.add (" ")
						a_text_formatter.add (" ")
						a_text_formatter.add (" ")
					else
						a_text_formatter.add (create {STRING_32}.make_filled (c, 1))
					end
				end
				a_text_formatter.add_new_line
			end
		end

	display_syntax_line (a_text_formatter: TEXT_FORMATTER; a_line: STRING_32; a_error: ERROR)
			-- Display `a_line' which does like `display_line' but with an additional
			-- arrowed line that points out to `column' where syntax issue is located.
		require
			st_not_void: a_text_formatter /= Void
			a_line_not_void: a_line /= Void
			error_not_void: a_error /= Void
		local
			i, nb: INTEGER
			c: CHARACTER_32
			position, nb_tab: INTEGER
		do
			from
				nb := a_line.count
			until
				i = nb
			loop
				i := i + 1
				c := a_line.item (i)
				if c = '%T' then
					a_text_formatter.add (" ")
					a_text_formatter.add (" ")
					a_text_formatter.add (" ")
					a_text_formatter.add (" ")
					if i <= a_error.column then
						nb_tab := nb_tab + 1
					end
				else
					a_text_formatter.add (create {STRING_32}.make_filled (c, 1))
				end
			end
			a_text_formatter.add_new_line
			if a_error.column > 0 then
				position := (a_error.column - 1) + 3 * nb_tab
			else
				position := 3 * nb_tab
			end
			if position = 0 then
				a_text_formatter.add ("^---------------------------")
				a_text_formatter.add_new_line
			else
				from
					i := 1
				until
					i > position
				loop
					a_text_formatter.add ("-")
					i := i + 1
				end
				a_text_formatter.add ("^")
				a_text_formatter.add_new_line
			end
		end

feature {NONE} -- Implementation

	print_single_line_error_message (a_text_formatter: TEXT_FORMATTER; a_error: ERROR)
			-- Displays single line help in `a_text_formatter'.
		require
			valid_st: a_text_formatter /= Void
			error_not_void: a_error /= Void
		local
			l_file_name: PATH
			l_file: PLAIN_TEXT_FILE
			l_text, l_line: STRING
			l_stop: BOOLEAN
			i: INTEGER
		do
			l_file_name := eiffel_layout.error_path.extended ("short")
			if a_error.subcode /= 0 then
				l_file_name := l_file_name.extended (a_error.help_file_name + a_error.subcode.out)
			else
				l_file_name := l_file_name.extended (a_error.help_file_name)
			end
			create l_file.make_with_path (l_file_name)
			if l_file.exists then
				create l_text.make (255)
				from
					l_file.open_read
				until
					l_file.end_of_file or l_stop
				loop
					l_file.read_line;
					l_line := l_file.last_string
					l_stop := not l_text.is_empty and then not l_line.is_empty and then not l_line.item (1).is_space
					if not l_stop then
						l_line.prune_all_leading (' ')
						l_line.prune_all_trailing (' ')
						if not l_text.is_empty then
							l_text.append_character (' ')
						end
						l_text.append (l_line)
					end
				end
				l_file.close

					-- Remove error part
				i := l_text.index_of (':', 1)
				if i > 0 then
					l_text.keep_tail (l_text.count - i)
				end
				l_text.prune_all_leading (' ')
				l_text.prune_all_trailing (' ')
				if not l_text.is_empty then
					if l_text.item (l_text.count) /= '.' and then l_text.item (l_text.count).is_alpha_numeric then
							-- Append missing punctuation
						l_text.append_character ('.')
					end
					if l_text.item (1).is_alpha then
							-- Change initial character to upper case
						l_text.put (l_text.item (1).as_upper, 1)
					end
				end
			end

			if l_text = Void or else l_text.is_empty then
				l_text := once "Unable to retrieve error help information."
			end

			a_text_formatter.add (l_text)
		end

	print_error_message (a_text_formatter: TEXT_FORMATTER; a_error: ERROR)
			-- Display error in `a_text_formatter'.
		require
			valid_st: a_text_formatter /= Void
			error_not_void: a_error /= Void
		do
			a_text_formatter.add (a_error.error_string);
			a_text_formatter.add (" code: ");
			a_text_formatter.add_error (a_error, a_error.code);
			if a_error.subcode /= 0 then
				a_text_formatter.add ("(");
				a_text_formatter.add_int (a_error.subcode);
				a_text_formatter.add (")");
				a_text_formatter.add_new_line
			else
				a_text_formatter.add_new_line;
			end;
			print_short_help (a_text_formatter, a_error);
		end;

	frozen print_short_help (a_text_formatter: TEXT_FORMATTER; a_error: ERROR)
			-- Display help in `a_text_formatter'.
		require
			valid_st: a_text_formatter /= Void
			error_not_void: a_error /= Void
		local
			f_name: PATH
			file: PLAIN_TEXT_FILE
		do
			f_name := eiffel_layout.error_path.extended ("short")
			if a_error.subcode /= 0 then
				f_name := f_name.extended (a_error.help_file_name + a_error.subcode.out)
			else
				f_name := f_name.extended (a_error.help_file_name)
			end
			create file.make_with_path (f_name)
			if file.exists then
				from
					file.open_read
				until
					file.end_of_file
				loop
					file.read_line
					a_text_formatter.add (file.last_string.twin)
					a_text_formatter.add_new_line
				end
				file.close
			else
				a_text_formatter.add_new_line
				a_text_formatter.add ("No help available for this error")
				a_text_formatter.add_new_line
				a_text_formatter.add ("(cannot read file: ")
				a_text_formatter.add (f_name.name)
				a_text_formatter.add (")")
				a_text_formatter.add_new_line
				a_text_formatter.add_new_line
				a_text_formatter.add ("An error message should always be available.")
				a_text_formatter.add_new_line
				a_text_formatter.add ("Please contact ISE.")
				a_text_formatter.add_new_line
				a_text_formatter.add_new_line
			end
		end

feature {NONE} -- Implementation

	frozen print_context_of_error (a_context_class: CLASS_C; a_text_formatter: TEXT_FORMATTER; a_error: ERROR)
			-- Display the line number in `a_text_formatter'.
		require
			st_not_void: a_text_formatter /= Void
			a_context_class_not_void: a_context_class /= Void
			error_not_void: a_error /= Void
			valid_line: a_error.line > 0
		do
			a_error.initialize_output
			a_text_formatter.add ("Line: ")
			a_text_formatter.add (a_error.line.out)
			if a_context_class.lace_class.config_class.has_modification_date_changed then
				a_text_formatter.add (" (source code has changed)")
				a_text_formatter.add_new_line
			elseif not a_error.has_source_text then
				a_text_formatter.add (" (source code is not available)")
				a_text_formatter.add_new_line
			elseif a_error.line > 0 then
				a_text_formatter.add_new_line
				a_text_formatter.add ("  ")
				if attached a_error.previous_line_32 as l_line then
					if not l_line.is_empty then
						l_line.replace_substring_all ({STRING_32} "%T", {STRING_32} "  ")
					end
					a_text_formatter.add (l_line)
					a_text_formatter.add_new_line
				end
				a_text_formatter.add ("->")
				if attached a_error.current_line_32 as l_c_line and then not l_c_line.is_empty then
					l_c_line.replace_substring_all ({STRING_32} "%T", {STRING_32} "  ")
					a_text_formatter.add (l_c_line)
				end
				a_text_formatter.add_new_line
				if attached a_error.next_line_32 as l_n_line then
					a_text_formatter.add ("  ")
					if not l_n_line.is_empty then
						l_n_line.replace_substring_all ({STRING_32} "%T", {STRING_32} "  ")
					end
					a_text_formatter.add (l_n_line)
					a_text_formatter.add_new_line
				end
			end
		end

note
	copyright:	"Copyright (c) 1984-2017, Eiffel Software"
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
