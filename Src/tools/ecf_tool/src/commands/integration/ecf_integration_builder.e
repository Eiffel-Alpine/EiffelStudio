note
	description: "[
				Root class for ecf integration builder
			]"
	date: "$Date$"
	revision: "$Revision$"

class
	ECF_INTEGRATION_BUILDER

inherit
	LOCALIZED_PRINTER

	SHARED_EXECUTION_ENVIRONMENT

	CONF_ACCESS

create
	make

feature {NONE} -- Initialization

	make (args: ECF_INTEGRATION_APPLICATION_ARGUMENTS)
		local
			dirs: LIST [PATH]
		do
			create errors.make (0)
			create warnings.make (0)

			verbose := args.verbose

			if verbose then
				io.output.put_string ("Verbose=" + verbose.out + "%N")
			end

			dirs := args.directories
			if dirs.is_empty then
				io.output.put_string ("No directory are asked to be scanned.%N")
				if not args.execution_forced then
					io.output.put_string ("Do you want to update recursively this directory %N%T%"")
					localized_print (args.root_directory.name)
					io.output.put_string ("%" %N Continue (y|N)?")
					io.read_line
					io.last_string.left_adjust
					io.last_string.right_adjust
					io.last_string.to_lower
					if io.last_string.same_string ("y") then
						dirs.force (absolute_directory_path (args.root_directory))
					end
				end
			end

			excluded_directories := args.excluded_directories
			generate (dirs, args.output_ecf, agent (ia_p: PATH): BOOLEAN do Result := ia_p.name.ends_with (".ecf") end, args)


			if not warnings.is_empty then
				io.error.put_string ("[WARNING] " + warnings.count.out + " warnings occurred.")
				io.error.put_new_line
				across
					warnings as warn
				loop
					localized_print_error (warn.item)
					io.error.put_new_line
				end
			end

			if not errors.is_empty then
				io.error.put_string ("[ERROR] " + errors.count.out + " errors occurred.")
				io.error.put_new_line
				across
					errors as err
				loop
					localized_print_error (err.item)
					io.error.put_new_line
				end
			end
		end

	excluded_directories: detachable LIST [PATH]

	is_directory_excluded (p: PATH): BOOLEAN
		local
			dir: DIRECTORY
		do
			create dir.make_with_path (p)
			if dir.exists then
				if
					attached excluded_directories as l_excluded_dirs and then
					across l_excluded_dirs as d some d.item.canonical_path.same_as (p.canonical_path) end
				then
					if verbose then
						report_progress ({STRING_32} "Remove directory %""+ p.name +"%" from scope.")
					end
					Result := True
				end
			else
				Result := True
			end
		end

	generate (dirs: LIST [PATH]; a_output: PATH; a_cond: detachable FUNCTION [PATH, BOOLEAN]; args: ECF_INTEGRATION_APPLICATION_ARGUMENTS)
		local
			tb: like new_ecf_table
			dv: ECF_DIRECTORY_CUSTOM_ITERATOR
			p: PATH
--			root_p_name,
			p_name: READABLE_STRING_32
			utf: UTF_CONVERTER
			output: PLAIN_TEXT_FILE
			nb: INTEGER
			l_name: READABLE_STRING_8
			l_names: STRING_TABLE [INTEGER]
			conf_fac: CONF_PARSE_FACTORY
			conf: CONF_SYSTEM
			tgt: CONF_TARGET
			conf_lib: CONF_LIBRARY
			uuidgen: UUID_GENERATOR
			l_desc: STRING_32
			l_system_name: READABLE_STRING_8
		do
			tb := new_ecf_table
			if not dirs.is_empty then
				create dv.make (agent collect_ecf (?, a_cond, tb))
--				dv.set_directory_excluded_function (agent is_directory_excluded)
				across
					dirs as c
				loop
					if verbose then
						report_progress ({STRING_32} "Scanning %"" + c.item.name + {STRING_32} "%" for .ecf files ...")
					end
					dv.process_directory (absolute_directory_path (c.item))
				end
			end
			if verbose then
				report_progress ("Found " + tb.count.out + " .ecf files.")
			end
--			root_p_name := args.root_directory.canonical_path.name

			create conf_fac
			create uuidgen
			if
				attached a_output.entry as e and then
				attached e.name as l_output_name and then
				l_output_name.is_valid_as_string_8 and then
				not l_output_name.starts_with_general ("all")
			then
				l_system_name := "all_" + l_output_name.to_string_8
			else
				l_system_name := "all"
			end
			conf := conf_fac.new_system_with_file_name (a_output.name, l_system_name, uuidgen.generate_uuid)
			tgt := conf_fac.new_target (l_system_name, conf)
			tgt.set_root (conf_fac.new_root (Void, Void, Void, True))
			conf.add_target (tgt)

			conf.set_library_target (tgt)
			create l_desc.make_from_string_general ("All libraries from:%N")
			across
				dirs as ic
			loop
				l_desc.append_string_general (" - ")
				l_desc.append (ic.item.name)
				l_desc.append_string_general ("%N")
			end
			conf.set_description (l_desc)

			create l_names.make (tb.count)
			across
				tb as c
			loop
				if
					not c.item.is_redirection and then
					attached c.item.library_target as c_library_target
				then
					create p.make_from_string (c.key)
					p := p.canonical_path
					p_name := relative_path (p, a_output.parent).name

					l_name := c_library_target
					if attached c.item.name as c_name then
						l_name := c_name
					elseif attached c.item.uuid as c_uuid then
						l_name := c_uuid
					else
--						l_name := "unknown"
					end
					if l_names.has (l_name) then
						nb := l_names.item (l_name)
						nb := nb + 1
					else
						nb := 1
					end
					l_names.force (nb, l_name)
					if nb = 1 then
						conf_lib := conf_fac.new_library (l_name, utf.string_32_to_utf_8_string_8 (p_name), tgt)
					else
						conf_lib := conf_fac.new_library (l_name + "-" + nb.out, utf.string_32_to_utf_8_string_8 (p_name), tgt)
					end
					conf_lib.set_readonly (False)
					tgt.add_library (conf_lib)
				else

				end
			end

			create output.make_with_path (a_output)
			if not output.exists or else output.is_access_writable then
				conf.set_file_name (a_output.name)
				conf.store
			end
		end

feature -- Access

	new_ecf_table: STRING_TABLE [attached like path_details]
			-- Table of existing ecf inside `root_directory'
		do
			create Result.make (50)
		end

	verbose: BOOLEAN

	errors: ARRAYED_LIST [READABLE_STRING_GENERAL]
	warnings: ARRAYED_LIST [READABLE_STRING_GENERAL]


feature -- Basic operation

	collect_ecf (a_fn: PATH; a_cond: detachable FUNCTION [PATH, BOOLEAN]; a_tb: like new_ecf_table)
		local
			fn: STRING_GENERAL
			--lst: like segments_from_string
		do
			if a_cond = Void or else a_cond.item ([a_fn]) then
				if verbose then
					report_progress ({STRING_32} "Found %"" + a_fn.name + {STRING_32} "%" ")
				end
				fn := reduced_path (a_fn.name, 0)
				--lst := segments_from_string (a_fn)
				--append_segments_to_string (lst, fn)

				if attached path_details (fn) as d then
					a_tb.force (d, fn)
				end
			end
		end

	same_path (p1, p2: READABLE_STRING_GENERAL): BOOLEAN
		local
			s1, s2: STRING_32
		do
			create s1.make_from_string (p1.as_string_32)
			create s2.make_from_string (p2.as_string_32)
			s1.replace_substring_all ({STRING_32} "\", {STRING_32} "/")
			s2.replace_substring_all ({STRING_32} "\", {STRING_32} "/")
			Result := s1.same_string (s2)
		end

feature {NONE} -- Implementation

	report_warning (m: READABLE_STRING_GENERAL)
		do
			warnings.extend (m)
			if verbose then
				localized_print ({STRING_32} "[Warning] " + m.to_string_32)
				io.error.put_new_line
			end
		end

	report_progress (m: READABLE_STRING_GENERAL)
		do
			localized_print (m)
			io.output.put_new_line
		end

	report_error (m: READABLE_STRING_GENERAL)
		do
			errors.extend (m)
			if verbose then
				localized_print_error ({STRING_32} "[Error] " + m.to_string_32)
				io.error.put_new_line
			end
		end

	relative_path (a: PATH; b: PATH): PATH
		local
			a_lst, b_lst: LIST [PATH]
			done: BOOLEAN
		do
			a_lst := a.components
			b_lst := b.components
			create Result.make_empty
			from
				a_lst.start
				b_lst.start
			until
				a_lst.after or b_lst.after or done
			loop
				if a_lst.item.name.same_string (b_lst.item.name) then
					Result := Result.extended_path (a_lst.item)
					b_lst.remove
					a_lst.remove
				else
					done := True
				end
			end
			if Result.is_empty then
				Result := b
			else
				create Result.make_empty
					-- Remove filename
				b_lst.finish
				if not b_lst.before then
					b_lst.remove
				end
					-- put the ..
				across
					b_lst as c
				loop
					Result := Result.extended ("..")
				end
				across
					a_lst as c
				loop
					Result := Result.extended_path (c.item)
				end
			end
		end

	path_details (fn: READABLE_STRING_GENERAL): detachable TUPLE [name, uuid, library_target: detachable READABLE_STRING_8; segments: like segments_from_string; dir, file: READABLE_STRING_GENERAL; is_redirection: BOOLEAN]
		local
			f: RAW_FILE
			n,p: INTEGER
			l_line: STRING
			l_uuid, l_name, l_library_target: detachable READABLE_STRING_8
			l_is_redir: BOOLEAN
			l_dir: detachable READABLE_STRING_GENERAL
			l_file: detachable READABLE_STRING_GENERAL
			c_slash, c_bslash: NATURAL_32
			c: NATURAL_32
		do
			c_slash := ('/').natural_32_code
			c_bslash := ('\').natural_32_code
			from
				n := fn.count
			until
				n = 0 or l_dir /= Void
			loop
				c := fn.code (n)
				if c = c_slash or c = c_bslash then
					l_file := fn.substring (n + 1, fn.count)
					l_dir := fn.substring (1, n)
				else
				end
				n := n - 1
			end
			if l_dir = Void then
				l_dir := ""
			end
			if l_file /= Void then
				create f.make_with_name (fn)
				if f.exists and then f.is_readable then
					f.open_read
					from
						f.read_line
					until
						f.exhausted or (l_uuid /= Void and l_name /= Void and l_library_target /= Void)
					loop
						l_line := f.last_string
						if l_name = Void and then l_line.substring_index ("<redirection ", 1) > 0 then
							l_is_redir := True
						end
						if l_uuid = Void then
							p := l_line.substring_index ("uuid=%"", 1)
							if p > 0 then
								n := l_line.index_of ('"', p + 6)
								if n > p then
									l_uuid := l_line.substring (p + 6, n - 1)
								end
							end
						end
						if l_name = Void then
							p := l_line.substring_index ("name=%"", 1)
							if p > 0 then
								n := l_line.index_of ('"', p + 6)
								if n > p then
									l_name := l_line.substring (p + 6, n - 1)
								end
							end
						end
						if l_library_target = Void then
							p := l_line.substring_index ("library_target=%"", 1)
							if p > 0 then
								n := l_line.index_of ('"', p + 6)
								if n > p then
									l_library_target := l_line.substring (p + 6, n - 1)
								end
							end
						end

						f.read_line
					end
					f.close
					if l_uuid = Void then
--						check has_uuid: l_uuid /= Void end
						report_warning ("No UUID in %"" + fn.to_string_8 + "%"")
					end
					if l_name = Void then
--						check has_name: l_name /= Void end
						report_warning ("No name in %"" + fn.to_string_8 + "%"")
					end
					if l_library_target = Void then
--						check has_name: l_library_target /= Void end
						report_warning ("No library_target in %"" + fn.to_string_8 + "%"")
					end
				end
				Result := [l_name, l_uuid, l_library_target, segments_from_string (l_dir), l_dir, l_file, l_is_redir]
			end
		end

feature {NONE} -- Path manipulation

	reduced_path (fn: READABLE_STRING_GENERAL; a_depth: INTEGER): STRING_GENERAL
		local
			lst: like segments_from_string
		do
			create {STRING_32} Result.make (fn.count)
			lst := segments_from_string (fn)
			if a_depth > 0 then
				from
					lst.start
				until
					lst.count = a_depth
				loop
					lst.remove
				end
			end
			if fn.starts_with ("/") then
				Result.append ("/")
			end
			append_segments_to_string (lst, Result)
		end

	common_segment_count (p1, p2: detachable READABLE_STRING_GENERAL): INTEGER
			-- Number of segments common between p1 and p2 starting from the left.
		do
			if
				(p1 /= Void and then attached segments_from_string (p1) as lst_1) and
				(p2 /= Void and then attached segments_from_string (p2) as lst_2)
			then
				from
					lst_1.start
					lst_2.start
				until
					lst_1.off or lst_2.off
				loop
					if lst_1.item.same_string (lst_2.item) then
						Result := Result  + 1
					else
						lst_1.finish
						lst_2.finish
					end
					lst_1.forth
					lst_2.forth
				end
			end
		end

	append_segments_to_string (lst: LIST [READABLE_STRING_GENERAL]; s: STRING_GENERAL)
		do
			across
				lst as curs
			loop
				if
					not s.is_empty and then
					not s.ends_with ("/")
				then
					s.append ("/")
				end
				s.append (curs.item)
			end
		end

	segments_from_string (fn: READABLE_STRING_GENERAL): ARRAYED_LIST [READABLE_STRING_GENERAL]
		local
			c_slash, c_bslash: NATURAL_32
			i,p,n: INTEGER
			c: NATURAL_32
			lst: ARRAYED_LIST [READABLE_STRING_GENERAL]
		do
			c_slash := ('/').natural_32_code
			c_bslash := ('\').natural_32_code
			from
				create lst.make (2)
				i := 1
				p := 1
				n := fn.count
			until
				i > n
			loop
				c := fn.code (i)
				if c = c_slash or c = c_bslash then
					lst.extend (fn.substring (p, i - 1))
					p := i + 1
				end
				i := i + 1
			end
			if i > p then
				lst.extend (fn.substring (p, n))
			end
			from
				lst.start
			until
				lst.after
			loop
				if not lst.isfirst and then lst.item.same_string ("..") then
					lst.remove_left
					lst.remove
				elseif lst.item.same_string (".") then
					lst.remove
				else
					lst.forth
				end
			end
			Result := lst
		end

	absolute_directory_path (dn: PATH): PATH
		do
			create Result.make_from_string (reduced_path (dn.absolute_path.name, 0))
		end

note
	copyright: "Copyright (c) 1984-2018, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
