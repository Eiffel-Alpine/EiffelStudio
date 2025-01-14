note

	description:

		"Gexace commands"

	library: "Gobo Eiffel Ant"
	copyright: "Copyright (c) 2001-2018, Sven Ehrke and others"
	license: "MIT License"
	date: "$Date$"
	revision: "$Revision$"

class GEANT_GEXACE_COMMAND

inherit

	GEANT_COMMAND
		redefine
			make
		end

	KL_IMPORTED_BOOLEAN_ROUTINES
		export {NONE} all end

create

	make

feature {NONE} -- Initialization

	make (a_project: GEANT_PROJECT)
			-- Create a new 'gexace' command.
		local
			a_tester: UC_STRING_EQUALITY_TESTER
		do
			precursor (a_project)
			create defines.make_map (10)
			create a_tester
			defines.set_key_equality_tester (a_tester)
		end

feature -- Status report

	is_executable: BOOLEAN
			-- Can command be executed?
		do
			Result := BOOLEAN_.nxor (<<is_validate_executable,
				is_system_executable, is_library_executable>>)
		ensure then
			exclusive: Result implies BOOLEAN_.nxor (<<is_validate_executable,
				is_system_executable, is_library_executable>>)
		end

	is_validate_executable: BOOLEAN
			-- Can 'validate' command be execute?
		do
			Result := (validate_command and output_filename = Void)
		ensure
			validate_command: Result implies validate_command
			output_filename_void: Result implies output_filename = Void
		end

	is_system_executable: BOOLEAN
			-- Can 'system' command be executed?
		do
			Result := (attached system_command as l_system_command and then l_system_command.count > 0)
		ensure
			system_command_not_void_and_not_empty: Result implies attached system_command as l_system_command and then l_system_command.count > 0
		end

	is_library_executable: BOOLEAN
			-- Can 'library' command be executed?
		do
			Result := (attached library_command as l_library_command and then l_library_command.count > 0)
		ensure
			library_command_not_void_and_not_empty: Result implies attached library_command as l_library_command and then l_library_command.count > 0
		end

feature -- Access

	verbose: BOOLEAN
			-- Gexace '--verbose' command-line options

	system_command: detachable STRING
			-- System command compiler name

	library_command: detachable STRING
			-- Library command compiler name

	validate_command: BOOLEAN
			-- Validate command

	format: detachable STRING
			-- Eiffel config file format
			-- (e.g. ace, ecf, ...)

	xace_filename: detachable STRING
			-- xace filename

	output_filename: detachable STRING
			-- Output filename

	defines: DS_HASH_TABLE [STRING, STRING]
			-- Defined values from the command-line (--define option)

feature -- Setting

	set_verbose (b: BOOLEAN)
			-- Set `verbose' to `an_options'.
		do
			verbose := b
		ensure
			verbose_set: verbose = b
		end

	set_validate_command (b: BOOLEAN)
			-- Set `validate_command' to `b'.
		do
			validate_command := b
		ensure
			validate_command_set: validate_command = b
		end

	set_system_command (a_command: like system_command)
			-- Set `system_command' to `a_command'.
		require
			a_command_not_void: a_command /= Void
			a_command_not_empty: a_command.count > 0
		do
			system_command := a_command
		ensure
			system_command_set: system_command = a_command
		end

	set_library_command (a_command: like library_command)
			-- Set `library_command' to `a_command'.
		require
			a_command_not_void: a_command /= Void
			a_command_not_empty: a_command.count > 0
		do
			library_command := a_command
		ensure
			library_command_set: library_command = a_command
		end

	set_format (a_format: like format)
			-- Set `format' to `a_format'.
		require
			a_format_not_void: a_format /= Void
			a_format_not_empty: a_format.count > 0
		do
			format := a_format
		ensure
			format_set: format = a_format
		end

	set_xace_filename (a_filename: like xace_filename)
			-- Set `xace_filename' to `a_filename'.
		require
			a_filename_not_void: a_filename /= Void
			a_filename_not_empty: a_filename.count > 0
		do
			xace_filename := a_filename
		ensure
			xace_filename_set: xace_filename = a_filename
		end

	set_output_filename (a_filename: like output_filename)
			-- Set `output_filename' to `a_filename'.
		require
			a_filename_not_void: a_filename /= Void
			a_filename_not_empty: a_filename.count > 0
		do
			output_filename := a_filename
		ensure
			output_filename_set: output_filename = a_filename
		end

feature -- Execution

	execute
			-- Execute command.
		local
			cmd: STRING
			a_cursor: DS_HASH_TABLE_CURSOR [STRING, STRING]
			a_filename: STRING
		do
			create cmd.make (128)
			cmd.append_string ("gexace ")
				-- Add defines if they exist:
			if defines.count > 0 then
				cmd.append_string ("--define=%"")
				a_cursor := defines.new_cursor
				from a_cursor.start until a_cursor.after loop
					cmd := STRING_.appended_string (cmd, a_cursor.key)
					cmd.append_string ("=")
					cmd := STRING_.appended_string (cmd, a_cursor.item)
					a_cursor.forth
					if not a_cursor.after then
						cmd.append_string (" ")
					end
				end
				cmd.append_string ("%"")
			end
			if verbose then
				cmd.append_string (" --verbose")
			end
			if is_validate_executable then
				cmd.append_string (" --validate")
			else
				if is_system_executable and then attached system_command as l_system_command then
					cmd.append_string (" --system=%"")
					cmd := STRING_.appended_string (cmd, l_system_command)
					cmd.append_string ("%"")
				elseif is_library_executable and then attached library_command as l_library_command then
					cmd.append_string (" --library=%"")
					cmd := STRING_.appended_string (cmd, l_library_command)
					cmd.append_string ("%"")
				end
				if attached format as l_format and then not l_format.is_empty then
					cmd.append_string (" --format=%"")
					cmd := STRING_.appended_string (cmd, l_format)
					cmd.append_string ("%"")
				end
				if attached output_filename as l_output_filename then
					cmd.append_string (" --output=%"")
					a_filename := file_system.pathname_from_file_system (l_output_filename, unix_file_system)
					cmd := STRING_.appended_string (cmd, a_filename)
					cmd.append_string ("%"")
				end
			end
			if attached xace_filename as l_xace_filename then
				a_filename := file_system.pathname_from_file_system (l_xace_filename, unix_file_system)
				cmd.append_string (" ")
				cmd := STRING_.appended_string (cmd, a_filename)
			end
			project.trace (<<"  [gexace] ", cmd>>)
			execute_shell (cmd)
		end

invariant

	defines_not_void: defines /= Void
	no_void_define_name: not defines.has_void
	no_void_define_value: not defines.has_void_item

end
