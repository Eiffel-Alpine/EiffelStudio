indexing

	description: "[
		Sequences of characters, accessible through integer indices 
		in a contiguous range.
		]"

	status: "See notice at end of class"
	date: "$Date$"
	revision: "$Revision$"

class STRING_32 inherit

	INDEXABLE [WIDE_CHARACTER, INTEGER]
		redefine
			copy, is_equal, out, prune_all,
			changeable_comparison_criterion
		end

	RESIZABLE [WIDE_CHARACTER]
		redefine
			copy, is_equal, out,
			changeable_comparison_criterion
		end

	HASHABLE
		redefine
			copy, is_equal, out
		end

	COMPARABLE
		redefine
			copy, is_equal, out
		end

	TO_SPECIAL [WIDE_CHARACTER]
		redefine
			copy, is_equal, out,
			item, infix "@", put, valid_index
		end

	STRING_HANDLER
		redefine
			copy, is_equal, out
		end

create
	make,
	make_empty,
	make_filled,
	make_from_string,
	make_from_c

convert
	as_string_8: {STRING_8}

feature -- Initialization

	make (n: INTEGER) is
			-- Allocate space for at least `n' characters.
		require
			non_negative_size: n >= 0
		do
			count := 0
			if n = 0 then
				area := empty_area
			else
				make_area (n + 1)
			end
		ensure
			empty_string: count = 0
			area_allocated: capacity >= n
		end

	make_empty is
			-- Create empty string.
		do
			make (0)
		ensure
			empty: count = 0
			area_allocated: capacity >= 0
		end

	make_filled (c: WIDE_CHARACTER; n: INTEGER) is
			-- Create string of length `n' filled with `c'.
		require
			valid_count: n >= 0
		do
			make (n)
			fill_character (c)
		ensure
			count_set: count = n
			filled: occurrences (c) = count
		end

	make_from_string (s: STRING_32) is
			-- Initialize from the characters of `s'.
			-- (Useful in proper descendants of class STRING_32,
			-- to initialize a string-like object from a manifest string.)
		require
			string_exists: s /= Void
		do
			if Current /= s then
				area := s.area.twin
				count := s.count
			end
		ensure
			not_shared_implementation: Current /= s implies not shared_with (s)
		end

	make_from_c (c_string: POINTER) is
			-- Initialize from contents of `c_string',
			-- a string created by some external C function
		require
			c_string_exists: c_string /= default_pointer
		local
			length: INTEGER
		do
			length := str_len (c_string)
			make_area (length + 1)
			area.base_address.memory_copy (c_string, length)
			count := length
		end

	from_c (c_string: POINTER) is
			-- Reset contents of string from contents of `c_string',
			-- a string created by some external C function.
		require
			c_string_exists: c_string /= default_pointer
		local
			length: INTEGER
		do
			length := str_len (c_string)
			if safe_capacity < length then
				make_area (length + 1)
			end
			area.base_address.memory_copy (c_string, length)
			count := length
		ensure
			no_zero_byte: not has ('%/0/')
			-- characters: for all i in 1..count, item (i) equals
			--			 ASCII character at address c_string + (i - 1)
			-- correct_count: the ASCII character at address c_string + count
			--			 is NULL
		end

	from_c_substring (c_string: POINTER; start_pos, end_pos: INTEGER) is
			-- Reset contents of string from substring of `c_string',
			-- a string created by some external C function.
		require
			c_string_exists: c_string /= default_pointer
			start_position_big_enough: start_pos >= 1
			end_position_big_enough: start_pos <= end_pos + 1
		local
			length: INTEGER
		do
			length := end_pos - start_pos + 1
			if safe_capacity < length then
				make_area (length + 1)
			end
				-- Make `area' the substring of `c_string'
				-- from `start_pos' .. `end_pos'.
			area.base_address.memory_copy (c_string + (start_pos - 1), end_pos - start_pos + 1)
			count := length
		ensure
			valid_count: count = end_pos - start_pos + 1
			-- characters: for all i in 1..count, item (i) equals
			--			 ASCII character at address c_string + (i - 1)
		end

	adapt (s: STRING_32): like Current is
			-- Object of a type conforming to the type of `s',
			-- initialized with attributes from `s'
		do
			create Result.make (0)
			Result.share (s)
		end

	remake (n: INTEGER) is
			-- Allocate space for at least `n' characters.
		obsolete
			"Use `make' instead"
		require
			non_negative_size: n >= 0
		do
			make (n)
		ensure
			empty_string: count = 0
			area_allocated: capacity >= n
		end

feature -- Access

	item, infix "@" (i: INTEGER): WIDE_CHARACTER is
			-- Character at position `i'
		do
			Result := area.item (i - 1)
		end

	item_code (i: INTEGER): INTEGER is
			-- Numeric code of character at position `i'
		require
			index_small_enough: i <= count
			index_large_enough: i > 0
		do
			Result := area.item (i - 1).code
		end

	hash_code: INTEGER is
			-- Hash code value
		do
			Result := internal_hash_code
			if Result = 0 then
				Result := hashcode ($area, count)
				internal_hash_code := Result
			end
		end

	False_constant: STRING is "false"
			-- Constant string "false"

	True_constant: STRING is "true"
			-- Constant string "true"

	shared_with (other: like Current): BOOLEAN is
			-- Does string share the text of `other'?
		do
			Result := (other /= Void) and then (area = other.area)
		end

	index_of (c: WIDE_CHARACTER; start: INTEGER): INTEGER is
			-- Position of first occurrence of `c' at or after `start';
			-- 0 if none.
		require
			start_large_enough: start >= 1
			start_small_enough: start <= count + 1
		local
			a: like area
			i, nb: INTEGER
		do
			nb := count
			if start <= nb then
				from
					i := start - 1
					nb := nb - 1
					a := area
				until
					i > nb or else a.item (i) = c
				loop
					i := i + 1
				end
				if i <= nb then
						-- We add +1 due to the area starting at 0 and not at 1.
					Result := i + 1
				end
			end
		ensure
			index_of_non_negative: Result >= 0
			correct_place: Result > 0 implies item (Result) = c
			-- forall x : start..Result, item (x) /= c
		end

	last_index_of (c: WIDE_CHARACTER; start_index_from_end: INTEGER): INTEGER is
			-- Position of last occurrence of `c'.
			-- 0 if none
		require
			start_index_small_enough: start_index_from_end <= count
			start_index_large_enough: start_index_from_end >= 1
		local
			a: like area
			i: INTEGER
		do
			from
				i := start_index_from_end - 1
				a := area
			until
				i < 0 or else a.item (i) = c
			loop
				i := i - 1
			end
				-- We add +1 due to the area starting at 0 and not at 1.
			Result := i + 1
		ensure
			last_index_of_non_negative: Result >= 0
			correct_place: Result > 0 implies item (Result) = c
			-- forall x : Result..last, item (x) /= c
		end

	substring_index_in_bounds (other: STRING_32; start_pos, end_pos: INTEGER): INTEGER is
			-- Position of first occurrence of `other' at or after `start_pos'
			-- and to or before `end_pos';
			-- 0 if none.
		require
			other_nonvoid: other /= Void
			other_notempty: not other.is_empty
			start_pos_large_enough: start_pos >= 1
			start_pos_small_enough: start_pos <= count
			end_pos_large_enough: end_pos >= start_pos
			end_pos_small_enough: end_pos <= count
		local
			a: ANY
		do
			a := other.area
			Result := str_str ($area, $a, end_pos, other.count, start_pos, 0)
		ensure
			correct_place: Result > 0 implies
				substring (Result, Result + other.count - 1).is_equal (other)
			-- forall x : start_pos..Result
			--	not substring (x, x+other.count -1).is_equal (other)
		end

	string: STRING_32 is
			-- New STRING having same character sequence as `Current'.
		do
			create Result.make (count)
			Result.append (Current)
		ensure
			string_not_void: Result /= Void
			string_type: Result.same_type ("")
			first_item: count > 0 implies Result.item (1) = item (1)
			recurse: count > 1 implies Result.substring (2, count).is_equal (
				substring (2, count).string)
		end

	substring_index (other: STRING_32; start_index: INTEGER): INTEGER is
			-- Index of first occurrence of other at or after start_index;
			-- 0 if none
		require
			other_not_void: other /= Void
			valid_start_index: start_index >= 1 and start_index <= count + 1
		local
			a: ANY
		do
			if other.is_empty then
				Result := start_index
			else
				if start_index <= count then
					a := other.area
					Result := str_str ($area, $a, count, other.count, start_index, 0)
				end
			end
		ensure
			valid_result: Result = 0 or else
				(start_index <= Result and Result <= count - other.count + 1)
			zero_if_absent: (Result = 0) =
				not substring (start_index, count).has_substring (other)
			at_this_index: Result >= start_index implies
				other.same_string (substring (Result, Result + other.count - 1))
			none_before: Result > start_index implies
				not substring (start_index, Result + other.count - 2).has_substring (other)
		end

	fuzzy_index (other: STRING_32; start: INTEGER; fuzz: INTEGER): INTEGER is
			-- Position of first occurrence of `other' at or after `start'
			-- with 0..`fuzz' mismatches between the string and `other'.
			-- 0 if there are no fuzzy matches
		require
			other_exists: other /= Void
			other_not_empty: not other.is_empty
			start_large_enough: start >= 1
			start_small_enough: start <= count
			acceptable_fuzzy: fuzz <= other.count
		local
			a: ANY
		do
			a := other.area
			Result := str_str ($area, $a, count, other.count, start, fuzz)
		end

feature -- Measurement

	capacity: INTEGER is
			-- Allocated space
		do
			if area /= Void then
				Result := safe_capacity
			end
		end

	count: INTEGER
			-- Actual number of characters making up the string

	occurrences (c: WIDE_CHARACTER): INTEGER is
			-- Number of times `c' appears in the string
		local
			counter, nb: INTEGER
			a: SPECIAL [WIDE_CHARACTER]
		do
			from
				counter := 0
				nb := count - 1
				a := area
			until
				counter > nb
			loop
				if a.item (counter) = c then
					Result := Result + 1
				end
				counter := counter + 1
			end
		end

	index_set: INTEGER_INTERVAL is
			-- Range of acceptable indexes
		do
			create Result.make (1, count)
		ensure then
			Result.count = count
		end

feature -- Comparison

	is_equal (other: like Current): BOOLEAN is
			-- Is string made of same character sequence as `other'
			-- (possibly with a different capacity)?
		local
			o_area: like area
		do
			if other = Current then
				Result := True
			elseif count = other.count then
				o_area := other.area
				Result := str_strict_cmp ($area, $o_area, count) = 0
			end
		end

	same_string (other: STRING_32): BOOLEAN is
			-- Do `Current' and `other' have same character sequence?
		require
			other_not_void: other /= Void
		do
			Result := string.is_equal (other.string)
		ensure
			definition: Result = string.is_equal (other.string)
		end

	infix "<" (other: like Current): BOOLEAN is
			-- Is string lexicographically lower than `other'?
		local
			other_area: like area
			other_count: INTEGER
			current_count: INTEGER
		do
			if other /= Current then
				other_area := other.area
				other_count := other.count
				current_count := count
				if other_count = current_count then
					Result := str_strict_cmp ($other_area, $area, other_count) > 0
				else
					if current_count < other_count then
						Result := str_strict_cmp ($other_area, $area, current_count) >= 0
					else
						Result := str_strict_cmp ($other_area, $area, other_count) > 0
					end
				end
			end
		end

feature -- Status report

	has (c: WIDE_CHARACTER): BOOLEAN is
			-- Does string include `c'?
		local
			counter: INTEGER
		do
			if not is_empty then
				from
					counter := 1
				until
					counter > count or else (item (counter) = c)
				loop
					counter := counter + 1
				end
				Result := (counter <= count)
			end
		end

	has_substring (other: STRING_32): BOOLEAN is
			-- Does `Current' contain `other'?
		require
			other_not_void: other /= Void
		do
			if other.count <= count then
				Result := substring_index (other, 1) > 0
			end
		end

	extendible: BOOLEAN is True
			-- May new items be added? (Answer: yes.)

	prunable: BOOLEAN is
			-- May items be removed? (Answer: yes.)
		do
			Result := True
		end

	valid_index (i: INTEGER): BOOLEAN is
			-- Is `i' within the bounds of the string?
		do
			Result := (i > 0) and (i <= count)
		end

	changeable_comparison_criterion: BOOLEAN is False

	is_integer: BOOLEAN is
			-- Does `Current' represent an INTEGER?
		local
			l_c: CHARACTER
			l_area: like area
			i, nb, l_state: INTEGER
		do
				-- l_state = 0 : waiting sign or first digit.
				-- l_state = 1 : sign read, waiting first digit.
				-- l_state = 2 : in the number.
				-- l_state = 3 : trailing white spaces
				-- l_state = 4 : error state.
			from
				l_area := area
				i := 0
				nb := count - 1
			until
				i > nb or l_state > 3
			loop
				l_c := l_area.item (i).to_character_8
				i := i + 1
				inspect l_state
				when 0 then
						-- Let's find beginning of an integer, if any.
					if l_c.is_digit then
						l_state := 2
					elseif l_c = '-' or l_c = '+' then
						l_state := 1
					elseif l_c = ' ' then
					else
						l_state := 4
					end
				when 1 then
						-- Let's find first digit after sign.
					if l_c.is_digit then
						l_state := 2
					else
						l_state := 4
					end
				when 2 then
						-- Let's find another digit or end of integer.
					if l_c.is_digit then
					elseif l_c = ' ' then
						l_state := 3
					else
						l_state := 4
					end
				when 3 then
						-- Consume remaining white space.
					if l_c /= ' ' then
						l_state := 4
					end
				end
			end
			Result := l_state = 2 or l_state = 3
		ensure
			syntax_and_range:
				-- Result is true if and only if the following two
				-- conditions are satisfied:
				--
				-- 1. In the following BNF grammar, the value of
				--	Current can be produced by "Integer_literal":
				--
				-- Integer_literal = [Space] [Sign] Integer [Space]
				-- Space 	= " " | " " Space
				-- Sign		= "+" | "-"
				-- Integer	= Digit | Digit Integer
				-- Digit	= "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"
				--
				-- 2. The integer value represented by Current
				--	is within the range that can be represented
				--	by an instance of type INTEGER.
		end

	is_real: BOOLEAN is
			-- Does `Current' represent a REAL?
		do
			Result := str_isr ($area, count)
		ensure
			syntax_and_range:
				-- 'result' is True if and only if the following two
				-- conditions are satisfied:
				--
				-- 1. In the following BNF grammar, the value of
				--	'Current' can be produced by "Real_literal":
				--
				-- Real_literal	= Mantissa [Exponent_part]
				-- Exponent_part = "E" Exponent
				--				 | "e" Exponent
				-- Exponent		= Integer_literal
				-- Mantissa		= Decimal_literal
				-- Decimal_literal = Integer_literal ["." Integer]
				-- Integer_literal = [Sign] Integer
				-- Sign			= "+" | "-"
				-- Integer		= Digit | Digit Integer
				-- Digit		= "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"
				--
				-- 2. The numerical value represented by 'Current'
				--	is within the range that can be represented
				--	by an instance of type REAL.
		end

	is_double: BOOLEAN is
			-- Does `Current' represent a DOUBLE?
		do
			Result := str_isd ($area, count)
		ensure
			syntax_and_range:
				-- 'result' is True if and only if the following two
				-- conditions are satisfied:
				--
				-- 1. In the following BNF grammar, the value of
				--	'Current' can be produced by "Real_literal":
				--
				-- Real_literal	= Mantissa [Exponent_part]
				-- Exponent_part = "E" Exponent
				--				 | "e" Exponent
				-- Exponent		= Integer_literal
				-- Mantissa		= Decimal_literal
				-- Decimal_literal = Integer_literal ["." Integer]
				-- Integer_literal = [Sign] Integer
				-- Sign			= "+" | "-"
				-- Integer		= Digit | Digit Integer
				-- Digit		= "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"
				--
				-- 2. The numerical value represented by 'Current'
				--	is within the range that can be represented
				--	by an instance of type DOUBLE.
		end

	is_boolean: BOOLEAN is
			-- Does `Current' represent a BOOLEAN?
		local
			s: STRING_32
		do
			s := twin
			s.right_adjust
			s.left_adjust
			s.to_lower
			Result := s.is_equal (True_constant) or else s.is_equal (False_constant)
		end

feature -- Element change

	set (t: like Current; n1, n2: INTEGER) is
			-- Set current string to substring of `t' from indices `n1'
			-- to `n2', or to empty string if no such substring.
		require
			argument_not_void: t /= Void
		local
			s: STRING_32
		do
			s := t.substring (n1, n2)
			area := s.area
			count := s.count
			internal_hash_code := 0
		ensure
			is_substring: is_equal (t.substring (n1, n2))
		end

	copy (other: like Current) is
			-- Reinitialize by copying the characters of `other'.
			-- (This is also used by `twin'.)
		local
			old_area: like area
		do
			if other /= Current then
				old_area := area
				standard_copy (other)
					-- Note: <= is needed as all Eiffel string should have an
					-- extra character to insert null character at the end.
				if old_area = Void or else old_area.count <= count then
					area := area.standard_twin
				else
					old_area.base_address.memory_copy ($area, count)
					area := old_area
				end
				internal_hash_code := 0
			end
		ensure then
			new_result_count: count = other.count
			-- same_characters: For every `i' in 1..`count', `item' (`i') = `other'.`item' (`i')
		end

	subcopy (other: like Current; start_pos, end_pos, index_pos: INTEGER) is
			-- Copy characters of `other' within bounds `start_pos' and
			-- `end_pos' to current string starting at index `index_pos'.
		require
			other_not_void: other /= Void
			valid_start_pos: other.valid_index (start_pos)
			valid_end_pos: other.valid_index (end_pos)
			valid_bounds: (start_pos <= end_pos) or (start_pos = end_pos + 1)
			valid_index_pos: valid_index (index_pos)
			enough_space: (count - index_pos) >= (end_pos - start_pos)
		local
			other_area: like area
			start0, end0, index0: INTEGER
		do
			other_area := other.area
			start0 := start_pos - 1
			end0 := end_pos - 1
			index0 := index_pos - 1
			spsubcopy ($other_area, $area, start0, end0, index0)
			internal_hash_code := 0
		ensure
			-- copied: forall `i' in 0 .. (`end_pos'-`start_pos'),
			--	 item (index_pos + i) = old other.item (start_pos + i)
		end

	replace_substring (s: STRING_32; start_index, end_index: INTEGER) is
			-- Replace characters from `start_index' to `end_index' with `s'.
		require
			string_not_void: s /= Void
			valid_start_index: 1 <= start_index
			valid_end_index: end_index <= count
			meaningfull_interval: start_index <= end_index + 1
		local
			new_size, substring_size: INTEGER
			s_area: like area
		do
			substring_size := end_index - start_index + 1
			new_size := s.count + count - substring_size
			if new_size > safe_capacity then
				resize (new_size + additional_space)
			end
			s_area := s.area
			str_replace ($area, $s_area, count, s.count, start_index, end_index)
			count := new_size
			internal_hash_code := 0
		ensure
			new_count: count = old count + old s.count - end_index + start_index - 1
			replaced: is_equal (old (substring (1, start_index - 1) +
				s + substring (end_index + 1, count)))
		end

	replace_substring_all (original, new: like Current) is
			-- Replace every occurrence of `original' with `new'.
		require
			original_exists: original /= Void
			new_exists: new /= Void
			original_not_empty: not original.is_empty
		local
			change_pos: INTEGER
		do
			if not is_empty then
				from
					change_pos := substring_index (original, 1)
				until
					change_pos = 0
				loop
					replace_substring (new, change_pos, change_pos + original.count - 1)
					if change_pos + new.count <= count then
						change_pos := substring_index (original, change_pos + new.count)
					else
						change_pos := 0
					end
				end
				internal_hash_code := 0
			end
		end

	replace_blank is
			-- Replace all current characters with blanks.
		do
			fill_with (' ')
		ensure
			same_size: (count = old count) and (capacity >= old capacity)
			-- all_blank: For every `i' in 1..`count, `item' (`i') = `Blank'
		end

	fill_blank is
			-- Fill with `capacity' blank characters.
		do
			fill_character (' ')
		ensure
			filled: full
			same_size: (count = capacity) and (capacity = old capacity)
			-- all_blank: For every `i' in 1..`capacity', `item' (`i') = `Blank'
		end

	fill_with (c: WIDE_CHARACTER) is
			-- Replace every character with `c'.
		do
			area.base_address.memory_set (c.code, count)
			internal_hash_code := 0
		ensure
			same_count: (count = old count) and (capacity >= old capacity)
			filled: occurrences (c) = count
		end

	replace_character (c: WIDE_CHARACTER) is
			-- Replace every character with `c'.
		obsolete
			"ELKS 2001: use `fill_with' instead'"
		do
			fill_with (c)
		ensure
			same_count: (count = old count) and (capacity >= old capacity)
			filled: occurrences (c) = count
		end

	fill_character (c: WIDE_CHARACTER) is
			-- Fill with `capacity' characters all equal to `c'.
		local
			l_cap: like safe_capacity
		do
			l_cap := safe_capacity
			area.base_address.memory_set (c.code, l_cap)
			count := l_cap
			internal_hash_code := 0
		ensure
			filled: full
			same_size: (count = capacity) and (capacity = old capacity)
			-- all_char: For every `i' in 1..`capacity', `item' (`i') = `c'
		end

	head (n: INTEGER) is
			-- Remove all characters except for the first `n';
			-- do nothing if `n' >= `count'.
		obsolete
			"ELKS 2001: use `keep_head' instead'"
		require
			non_negative_argument: n >= 0
		do
			keep_head (n)
		ensure
			new_count: count = n.min (old count)
			-- first_kept: For every `i' in 1..`n', `item' (`i') = old `item' (`i')
		end

	keep_head (n: INTEGER) is
			-- Remove all characters except for the first `n';
			-- do nothing if `n' >= `count'.
		require
			non_negative_argument: n >= 0
		do
			if n < count then
				count := n
				internal_hash_code := 0
			end
		ensure
			new_count: count = n.min (old count)
			-- first_kept: For every `i' in 1..`n', `item' (`i') = old `item' (`i')
		end

	tail (n: INTEGER) is
			-- Remove all characters except for the last `n';
			-- do nothing if `n' >= `count'.
		obsolete
			"ELKS 2001: use `keep_tail' instead'"
		require
			non_negative_argument: n >= 0
		do
			keep_tail (n)
		ensure
			new_count: count = n.min (old count)
		end

	keep_tail (n: INTEGER) is
			-- Remove all characters except for the last `n';
			-- do nothing if `n' >= `count'.
		require
			non_negative_argument: n >= 0
		local
			i, j: INTEGER
		do
			if n < count then
				from
					j := (count - n)
					i := 0
				until
					i = n
				loop
					area.put (area.item (j), i)
					i := i + 1
					j := j + 1
				end
				count := n
				internal_hash_code := 0
			end
		ensure
			new_count: count = n.min (old count)
		end

	left_adjust is
			-- Remove leading whitespace.
		do
			count := str_left ($area, count)
			internal_hash_code := 0
		ensure
			new_count: (count /= 0) implies
				((item (1) /= ' ') and
				 (item (1) /= '%T') and
				 (item (1) /= '%R') and
				 (item (1) /= '%N'))
		end

	right_adjust is
			-- Remove trailing whitespace.
		do
			count := str_right ($area, count)
			internal_hash_code := 0
		ensure
			new_count: (count /= 0) implies
				((item (count) /= ' ') and
				 (item (count) /= '%T') and
				 (item (count) /= '%R') and
				 (item (count) /= '%N'))
		end

	share (other: like Current) is
			-- Make current string share the text of `other'.
			-- Subsequent changes to the characters of current string
			-- will also affect `other', and conversely.
		require
			argument_not_void: other /= Void
		do
			area := other.area
			count := other.count
			internal_hash_code := 0
		ensure
			shared_count: other.count = count
			-- sharing: For every `i' in 1..`count', `Result'.`item' (`i') = `item' (`i')
		end

	put (c: WIDE_CHARACTER; i: INTEGER) is
			-- Replace character at position `i' by `c'.
		do
			area.put (c, i - 1)
			internal_hash_code := 0
		end

	precede, prepend_character (c: WIDE_CHARACTER) is
			-- Add `c' at front.
		do
			if count = safe_capacity then
				resize (count + additional_space)
			end
			str_cprepend ($area, c, count)
			count := count + 1
			internal_hash_code := 0
		ensure
			new_count: count = old count + 1
		end

	prepend (s: STRING_32) is
			-- Prepend a copy of `s' at front.
		require
			argument_not_void: s /= Void
		local
			new_size: INTEGER
			s_area: like area
		do
			new_size := count + s.count
			if new_size > safe_capacity then
				resize (new_size + additional_space)
			end
			s_area := s.area
			str_insert ($area, $s_area, count, s.count, 1)
			count := new_size
			internal_hash_code := 0
		ensure
			new_count: count = old count + s.count
		end

	prepend_boolean (b: BOOLEAN) is
			-- Prepend the string representation of `b' at front.
		do
			prepend (b.out)
		end

	prepend_double (d: DOUBLE) is
			-- Prepend the string representation of `d' at front.
		do
			prepend (d.out)
		end

	prepend_integer (i: INTEGER) is
			-- Prepend the string representation of `i' at front.
		do
			prepend (i.out)
		end

	prepend_real (r: REAL) is
			-- Prepend the string representation of `r' at front.
		do
			prepend (r.out)
		end

	prepend_string (s: STRING_32) is
			-- Prepend a copy of `s', if not void, at front.
		do
			if s /= Void then
				prepend (s)
			end
		end

	append (s: STRING_32) is
			-- Append a copy of `s' at end.
		require
			argument_not_void: s /= Void
		local
			new_size: INTEGER
			s_area: like area
		do
			new_size := s.count + count
			if new_size > safe_capacity then
				resize (new_size + additional_space)
			end
			s_area := s.area;
			area.item_address (count).memory_copy ($s_area, s.count)
			count := new_size
			internal_hash_code := 0
		ensure
			new_count: count = old count + old s.count
			-- appended: For every `i' in 1..`s'.`count', `item' (old `count'+`i') = `s'.`item' (`i')
		end

	infix "+" (s: STRING_32): STRING_32 is
			-- Append a copy of 's' at the end of a copy of Current,
			-- Then return the Result.
		require
			argument_not_void: s /= Void
		do
			create Result.make (count + s.count)
			Result.append_string (Current)
			Result.append_string (s)
		ensure
			Result_exists: Result /= Void
			new_count: Result.count = count + s.count
		end

	append_string (s: STRING_32) is
			-- Append a copy of `s', if not void, at end.
		do
			if s /= Void then
				append (s)
			end
		end

	append_integer (i: INTEGER) is
			-- Append the string representation of `i' at end.
		local
			l_value: INTEGER
			l_starting_index, l_ending_index: INTEGER
			l_temp: WIDE_CHARACTER
			l_area: like area
		do
			if i = 0 then
				append_character ('0')
			else
					-- Extract integer value digit by digit from right to left.
				from
					l_starting_index := count
					if i < 0 then
						append_character ('-')
						l_starting_index := l_starting_index + 1
						l_value := -i
							-- Special case for minimum integer value as negating it
							-- as no effect.
						if l_value = feature {INTEGER_REF}.Min_value then
							append_character ((-(l_value \\ 10) + 48).to_character)
							l_value := -(l_value // 10)
						end
					else
						l_value := i
					end
				until
					l_value = 0
				loop
					append_character (((l_value \\ 10)+ 48).to_character)
					l_value := l_value // 10
				end

					-- Now put digits in correct order from left to right.
				from
					l_ending_index := count - 1
					l_area := area
				until
					l_starting_index >= l_ending_index
				loop
					l_temp := l_area.item (l_starting_index)
					l_area.put (l_area.item (l_ending_index), l_starting_index)
					l_area.put (l_temp, l_ending_index)
					l_ending_index := l_ending_index - 1
					l_starting_index := l_starting_index + 1
				end
			end
		end

	append_real (r: REAL) is
			-- Append the string representation of `r' at end.
		do
			append (r.out)
		end

	append_double (d: DOUBLE) is
			-- Append the string representation of `d' at end.
		do
			append (d.out)
		end

	append_character, extend (c: WIDE_CHARACTER) is
			-- Append `c' at end.
		local
			current_count: INTEGER
		do
			current_count := count
			if current_count = safe_capacity then
				resize (current_count + additional_space)
			end
			area.put (c, current_count)
			count := current_count + 1
			internal_hash_code := 0
		ensure then
			item_inserted: item (count) = c
			new_count: count = old count + 1
		end

	append_boolean (b: BOOLEAN) is
			-- Append the string representation of `b' at end.
		do
			append (b.out)
		end

	insert (s: STRING_32; i: INTEGER) is
			-- Add `s' to left of position `i' in current string.
		obsolete
			"ELKS 2001: use `insert_string' instead"
		require
			string_exists: s /= Void
			index_small_enough: i <= count + 1
			index_large_enough: i > 0
		do
			insert_string (s, i)
		ensure
			inserted: is_equal (old substring (1, i - 1)
				+ old (s.twin) + old substring (i, count))
		end

	insert_string (s: STRING_32; i: INTEGER) is
			-- Insert `s' at index `i', shifting characters between ranks
			-- `i' and `count' rightwards.
		require
			string_exists: s /= Void
			valid_insertion_index: 1 <= i and i <= count + 1
		local
			new_size: INTEGER
			s_area: like area
		do
			new_size := s.count + count
			if new_size > safe_capacity then
				resize (new_size + additional_space)
			end
			s_area := s.area
			str_insert ($area, $s_area, count, s.count, i)
			count := new_size
			internal_hash_code := 0
		ensure
			inserted: is_equal (old substring (1, i - 1)
				+ old (s.twin) + old substring (i, count))
		end

	insert_character (c: WIDE_CHARACTER; i: INTEGER) is
			-- Insert `c' at index `i', shifting characters between ranks
			-- `i' and `count' rightwards.
		require
			valid_insertion_index: 1 <= i and i <= count + 1
		local
			new_size: INTEGER
		do
			new_size := count + 1
			if new_size > safe_capacity then
				resize (new_size + additional_space)
			end
			str_insert ($area, $c, count, 1, i)
			count := new_size
			internal_hash_code := 0
		ensure
			new_count: count = old count + 1
		end

feature -- Removal

	remove (i: INTEGER) is
			-- Remove `i'-th character.
		require
			index_small_enough: i <= count
			index_large_enough: i > 0
		do
			str_rmchar ($area, count, i)
			count := count - 1
			internal_hash_code := 0
		ensure
			new_count: count = old count - 1
		end

	remove_head (n: INTEGER) is
			-- Remove first `n' characters;
			-- if `n' > `count', remove all.
		require
			n_non_negative: n >= 0
		do
			if n > count then
				count := 0
				internal_hash_code := 0
			else
				keep_tail (count - n)
			end
		ensure
			removed: is_equal (old substring (n.min (count) + 1, count))
		end

	remove_substring (start_index, end_index: INTEGER) is
			-- Remove all characters from `start_index'
			-- to `end_index' inclusive.
		require
			valid_start_index: 1 <= start_index
			valid_end_index: end_index <= count
			meaningful_interval: start_index <= end_index + 1
		local
			i: INTEGER
		do
			from
				i := 0
			until
				i > end_index - start_index
			loop
				remove (start_index)
				i := i + 1
			end
		ensure
			removed: is_equal (old substring (1, start_index - 1) +
					old substring (end_index + 1, count))
		end

	remove_tail (n: INTEGER) is
			-- Remove last `n' characters;
			-- if `n' > `count', remove all.
		require
			n_non_negative: n >= 0
		local
			l_count: INTEGER
		do
			l_count := count
			if n > l_count then
				count := 0
				internal_hash_code := 0
			else
				keep_head (l_count - n)
			end
		ensure
			removed: is_equal (old substring (1, count - n.min (count)))
		end

	prune (c: WIDE_CHARACTER) is
			-- Remove first occurrence of `c', if any.
		require else
			True
		local
			counter: INTEGER
		do
			from
				counter := 1
			until
				counter > count or else (item (counter) = c)
			loop
				counter := counter + 1
			end
			if counter <= count then
				remove (counter)
			end
		end

	prune_all (c: WIDE_CHARACTER) is
			-- Remove all occurrences of `c'.
		require else
			True
		do
			count := str_rmall ($area, c, count)
			internal_hash_code := 0
		ensure then
			changed_count: count = (old count) - (old occurrences (c))
			-- removed: For every `i' in 1..`count', `item' (`i') /= `c'
		end

	prune_all_leading (c: WIDE_CHARACTER) is
			-- Remove all leading occurrences of `c'.
		do
			from
			until
				is_empty or else item (1) /= c
			loop
				remove (1)
			end
		end

	prune_all_trailing (c: WIDE_CHARACTER) is
			-- Remove all trailing occurrences of `c'.
		do
			from
			until
				is_empty or else item (count) /= c
			loop
				remove (count)
			end
		end

	wipe_out is
			-- Remove all characters.
		do
			area := empty_area
			count := 0
			internal_hash_code := 0
		ensure then
			is_empty: count = 0
			empty_capacity: capacity = 0
		end

	clear_all is
			-- Reset all characters.
		do
			count := 0
			internal_hash_code := 0
		ensure
			is_empty: count = 0
			same_capacity: capacity = old capacity
		end

feature -- Resizing

	adapt_size is
			-- Adapt the size to accommodate `count' characters.
		do
			resize (count)
		end

	resize (newsize: INTEGER) is
			-- Rearrange string so that it can accommodate
			-- at least `newsize' characters.
			-- Do not lose any previously entered character.
		require
			new_size_non_negative: newsize >= 0
		local
			area_count: INTEGER
		do
			area_count := area.count
			if newsize >= area_count then
				if area_count = 1 then
					make_area (newsize + 1)
				else
					area := str_resize ($area, newsize + 1)
				end
			end
		end

	grow (newsize: INTEGER) is
			-- Ensure that the capacity is at least `newsize'.
		require else
			new_size_non_negative: newsize >= 0
		do
			if newsize > safe_capacity then
				resize (newsize)
			end
		end

feature -- Conversion

	as_string_8: STRING_8
			-- Convert `Current' as a STRING_8. If a code of `Current' is
			-- node a valid code for a STRING_8 it is replaced with the null
			-- character.
		local
			i, nb: INTEGER
			l_code: CHARACTER
		do
			if attached {STRING_8} Current as l_result then
				Result := l_result
			else
				nb := count
				create Result.make (nb)
				Result.set_count (nb)
				from
					i := 1
				until
					i > nb
				loop
					l_code := item (i).to_character_8
					Result.put (l_code, i)
					i := i + 1
				end
			end
		ensure
			as_string_8_not_void: Result /= Void
			identity: (conforms_to ("") and Result = Current) or (not conforms_to ("") and Result /= Current)
		end


	as_lower: like Current is
			-- New object with all letters in lower case.
		do
			Result := twin
			Result.to_lower
		ensure
			length: Result.count = count
			anchor: count > 0 implies Result.item (1) = item (1).as_lower
			recurse: count > 1 implies Result.substring (2, count).
				is_equal (substring (2, count).as_lower)
		end

	as_upper: like Current is
			-- New object with all letters in upper case
		do
			Result := twin
			Result.to_upper
		ensure
			length: Result.count = count
			anchor: count > 0 implies Result.item (1) = item (1).as_upper
			recurse: count > 1 implies Result.substring (2, count).
				is_equal (substring (2, count).as_upper)
		end

	left_justify is
			-- Left justify the string using
			-- the capacity as the width
		do
			str_ljustify ($area, count, safe_capacity)
			internal_hash_code := 0
		end

	center_justify is
			-- Center justify the string using
			-- the capacity as the width
		do
			str_cjustify ($area, count, safe_capacity)
			internal_hash_code := 0
		end

	right_justify is
			-- Right justify the string using
			-- the capacity as the width
		do
			str_rjustify ($area, count, safe_capacity)
			internal_hash_code := 0
		end

	character_justify (pivot: WIDE_CHARACTER; position: INTEGER) is
			-- Justify a string based on a `pivot'
			-- and the `position' it needs to be in
			-- the final string.
			-- This will grow the string if necessary
			-- to get the pivot in the correct place.
		require
			valid_position: position <= capacity
			positive_position: position >= 1
			pivot_not_space: pivot /= ' '
			not_empty: not is_empty
		do
			if index_of (pivot, 1) < position then
				from
					precede (' ')
				until
					index_of (pivot, 1) = position
				loop
					precede (' ')
				end
			elseif index_of (pivot, 1) > position then
				from
					remove (1)
				until
					index_of (pivot, 1) = position
				loop
					remove (1)
				end
			end
			from
			until
				count = safe_capacity
			loop
				extend (' ')
			end
			internal_hash_code := 0
		end

	to_lower
			-- Convert to lower case.
		do
			to_lower_area (area, 0, count - 1)
			internal_hash_code := 0
		end

	to_upper
			-- Convert to upper case.
		do
			to_upper_area (area, 0, count - 1)
			internal_hash_code := 0
		end

	to_integer: INTEGER is
			-- Integer value;
			-- for example, when applied to "123", will yield 123
		require
			is_integer: is_integer
		do
			Result := str_atoi ($area, count)
		end

	to_integer_64: INTEGER_64 is
			-- Integer value of type INTEGER_64;
			-- for example, when applied to "123", will yield 123
		require
			is_integer: is_integer
		local
			l_area: like area
			l_character: CHARACTER
			i, nb: INTEGER
			l_is_negative: BOOLEAN
		do
			from
				l_area := area
				nb := count - 1
			until
				i > nb
			loop
				l_character := l_area.item (i).to_character_8
				if l_character.is_digit then
					Result := (Result * 10) + l_character.code - 48
				elseif l_character = '-' then
					l_is_negative := True
				end
				i := i + 1
			end
			if l_is_negative then
				Result := - Result
			end
		end

	to_real: REAL is
			-- Real value;
			-- for example, when applied to "123.0", will yield 123.0
		require
			represents_a_real: is_real
		do
			Result := str_ator ($area, count)
		end

	to_double: DOUBLE is
			-- "Double" value;
			-- for example, when applied to "123.0", will yield 123.0 (double)
		require
			represents_a_double: is_double
		do
			Result := str_atod ($area, count)
		end

	to_boolean: BOOLEAN is
			-- Boolean value;
			-- "True" yields `True', "False" yields `False'
			-- (case-insensitive)
		require
			is_boolean: is_boolean
		local
			s: STRING_32
		do
			s := twin
			s.right_adjust
			s.left_adjust
			s.to_lower
			Result := s.is_equal (True_constant)
		end

	linear_representation: LINEAR [WIDE_CHARACTER] is
			-- Representation as a linear structure
		local
			temp: ARRAYED_LIST [WIDE_CHARACTER]
			i: INTEGER
		do
			create temp.make (safe_capacity)
			from
				i := 1
			until
				i > count
			loop
				temp.extend (item (i))
				i := i + 1
			end
			Result := temp
		end

	split (a_separator: WIDE_CHARACTER): LIST [STRING_32] is
			-- Split on `a_separator'.
		local
			l_list: ARRAYED_LIST [STRING_32]
			part: STRING_32
			i, j, c: INTEGER
		do
			c := count
				-- Worse case allocation: every character is a separator
			create l_list.make (c + 1)
			if c > 0 then
				from
					i := 1
				until
					i > c
				loop
					j := index_of (a_separator, i)
					if j = 0 then
							-- No separator was found, we will
							-- simply create a list with a copy of
							-- Current in it.
						j := c + 1
					end
					part := substring (i, j - 1)
					l_list.extend (part)
					i := j + 1
				end
				if j = c then
					check
						last_character_is_a_separator: item (j) = a_separator
					end
						-- A separator was found at the end of the string
					l_list.extend ("")
				end
			else
					-- Extend empty string, since Current is empty.
				l_list.extend ("")
			end
			Result := l_list
			check
				l_list.count = occurrences (a_separator) + 1
			end
		ensure
			Result /= Void
		end

	frozen to_c: ANY is
			-- A reference to a C form of current string.
			-- Useful only for interfacing with C software.
		local
			l_area: like area
		do
				--| `area' can be Void in some cases (e.g. during
				--| partial retrieval of objects).
			l_area := area
			if l_area /= Void then
				l_area.put ('%U', count)
				Result := l_area
			else
				Result := empty_area
			end
		end

	mirrored: like Current is
			-- Mirror image of string;
			-- result for "Hello world" is "dlrow olleH".
		do
			Result := twin
			if count > 0 then
				Result.mirror
			end
		ensure
			same_count: Result.count = count
			-- reversed: For every `i' in 1..`count', `Result'.`item' (`i') = `item' (`count'+1-`i')
		end

	mirror is
			-- Reverse the order of characters.
			-- "Hello world" -> "dlrow olleH".
		local
			a: like area
			c: WIDE_CHARACTER
			i, j: INTEGER
		do
			if count > 0 then
				from
					i := count - 1
					a := area
				until
					i <= j
				loop
					c := a.item (i)
					a.put (a.item (j), i)
					a.put (c, j)
					i := i - 1
					j := j + 1
				end
				internal_hash_code := 0
			end
		ensure
			same_count: count = old count
			-- reversed: For every `i' in 1..`count', `item' (`i') = old `item' (`count'+1-`i')
		end

feature {NONE} -- Conversion

	to_lower_area (a: like area; start_index, end_index: INTEGER)
			-- Replace all characters in `a' between `start_index' and `end_index'
			-- with their lower version when available.
		require
			a_not_void: a /= Void
			start_index_non_negative: start_index >= 0
			start_index_not_too_big: start_index <= end_index + 1
			end_index_valid: end_index < a.count
		do
		end

	to_upper_area (a: like area; start_index, end_index: INTEGER)
			-- Replace all characters in `a' between `start_index' and `end_index'
			-- with their upper version when available.
		require
			a_not_void: a /= Void
			start_index_non_negative: start_index >= 0
			start_index_not_too_big: start_index <= end_index + 1
			end_index_valid: end_index < a.count
		do
		end

feature -- Duplication

	substring (start_index, end_index: INTEGER): like Current is
			-- Copy of substring containing all characters at indices
			-- between `start_index' and `end_index'
		local
			other_area: like area
		do
			if (1 <= start_index) and (start_index <= end_index) and (end_index <= count) then
				create Result.make (end_index - start_index + 1)
				other_area := Result.area;
				other_area.base_address.memory_copy (
					area.item_address (start_index - 1), end_index - start_index + 1)
				Result.set_count (end_index - start_index + 1)
			else
				create Result.make (0)
			end
		ensure
			new_result_count: Result.count = end_index - start_index + 1 or Result.count = 0
			-- original_characters: For every `i' in 1..`end_index'-`start_index', `Result'.`item' (`i') = `item' (`start_index'+`i'-1)
		end

	multiply (n: INTEGER) is
			-- Duplicate a string within itself
			-- ("hello").multiply(3) => "hellohellohello"
		require
			meaningful_multiplier: n >= 1
		local
			s: STRING_32
			i: INTEGER
		do
			s := twin
			grow (n * count)
			from
				i := n
			until
				i = 1
			loop
				append (s)
				i := i - 1
			end
		end

feature -- Output

	out: STRING is
			-- Printable representation
		do
			create Result.make (count)
			Result.append (Current)
		end

feature {STRING_HANDLER} -- Implementation

	frozen set_count (number: INTEGER) is
			-- Set `count' to `number' of characters.
		require
			valid_count: 0 <= number and number <= capacity
		do
			count := number
			internal_hash_code := 0
		ensure
			new_count: count = number
		end

feature {NONE} -- Empty string implementation

	empty_area: SPECIAL [WIDE_CHARACTER] is
			-- Empty `area' used when calling `make (0)'.
		local
			old_area: like area
		once
			old_area := area
			make_area (1)
			Result := area
			area := old_area
		end

	safe_capacity: INTEGER is
			-- Allocated space
		require
			area_not_void: area /= Void
		do
			Result := area.count - 1
		end

	internal_hash_code: INTEGER
			-- Computed hash-code.

	frozen set_internal_hash_code (v: like internal_hash_code) is
			-- Set `internal_hash_code' with `v'.
		require
			v_nonnegative: v >= 0
		do
			internal_hash_code := v
		ensure
			internal_hash_code_set: internal_hash_code = v
		end

feature {NONE} -- Transformation

	correct_mismatch is
			-- Attempt to correct object mismatch during retrieve using `mismatch_information'.
		do
			-- Nothing to be done because we only added `internal_hash_code' that will
			-- be recomputed next time we query `hash_code'.
		end

feature {STRING_32} -- Implementation

	hashcode (c_string: POINTER; len: INTEGER): INTEGER is
			-- Hash code value of `c_string'
		external
			"C use %"eif_tools.h%""
		end

	str_str (c_str, o_str: POINTER; clen, olen, i, fuzzy: INTEGER): INTEGER is
			-- Forward search of `o_str' within `c_str' starting at `i'.
			-- Return the index within `c_str' where the pattern was
			-- located, 0 if not found.
			-- The 'fuzzy' parameter is the maximum allowed number of
			-- mismatches within the pattern. A 0 means an exact match.
		external
			"C use %"eif_eiffel.h%""
		end

	str_len (c_string: POINTER): INTEGER is
			-- Length of the C string: `c_string'
		external
			"C signature (char *): EIF_INTEGER use %"eif_str.h%""
		alias
			"strlen"
		end

	c_p_i: INTEGER is
			-- Number of characters per INTEGER
		obsolete
			"You now have to implement it yourself by inheriting from PLATFORM."
		do
				-- Example of implementation using features from PLATFORM
				-- Result := Integer_bits // Character_bits;
		end

	str_ljustify (c_string: POINTER; length, cap: INTEGER) is
			-- Left justify in a field of `capacity'
			-- the `c_string' of length `length'
		external
			"C signature (EIF_CHARACTER *, EIF_INTEGER, EIF_INTEGER) use %"eif_str.h%""
		end

	str_cjustify (c_string: POINTER; length, cap: INTEGER) is
			-- Center justify in a field of `capacity'
			-- the `c_string' of length `length'
		external
			"C signature (EIF_CHARACTER *, EIF_INTEGER, EIF_INTEGER) use %"eif_str.h%""
		end

	str_rjustify (c_string: POINTER; length, cap: INTEGER) is
			-- Right justify in a field of `capacity'
			-- the `c_string' of length `length'
		external
			"C signature (EIF_CHARACTER *, EIF_INTEGER, EIF_INTEGER) use %"eif_str.h%""
		end

	str_strict_cmp (this, other: POINTER; len: INTEGER): INTEGER is
			-- Compare `this' and `other' C strings
			-- for the first `len' characters.
			-- 0 if equal, < 0 if `this' < `other',
			-- > 0 if `this' > `other'
		external
			"C signature (char *, char *, size_t): EIF_INTEGER use <string.h>"
		alias
			"strncmp"
		end

	str_atoi (c_string: POINTER; length: INTEGER): INTEGER is
			-- Value of integer in `c_string'
		external
			"C signature (EIF_CHARACTER *, EIF_INTEGER): EIF_INTEGER use %"eif_str.h%""
		end

	str_ator (c_string: POINTER; length: INTEGER): REAL is
			-- Value of real in `c_string'
		external
			"C signature (EIF_CHARACTER *, EIF_INTEGER): EIF_REAL use %"eif_str.h%""
		end

	str_atod (c_string: POINTER; length: INTEGER): DOUBLE is
			-- Value of double in `c_string'
		external
			"C signature (EIF_CHARACTER *, EIF_INTEGER): EIF_DOUBLE use %"eif_str.h%""
		end

	str_isr (c_string: POINTER; length: INTEGER): BOOLEAN is
			-- Is is a real?
		external
			"C signature (EIF_CHARACTER *, EIF_INTEGER): EIF_BOOLEAN use %"eif_str.h%""
		end

	str_isd (c_string: POINTER; length: INTEGER): BOOLEAN is
			-- Is is a double?
		external
			"C signature (EIF_CHARACTER *, EIF_INTEGER): EIF_BOOLEAN use %"eif_str.h%""
		end

	str_cprepend (c_string: POINTER; c: WIDE_CHARACTER; length: INTEGER) is
			-- Prepend `c' to `c_string'.
		external
			"C signature (EIF_CHARACTER *, EIF_CHARACTER, EIF_INTEGER) use %"eif_str.h%""
		end

	str_insert (c_string, other_string: POINTER; c_length, other_length,
			position: INTEGER) is
			-- Insert `other_string' into `c_string' at `position'.
			-- Insertion occurs at the left of `position'.
		external
			"C signature (EIF_CHARACTER *, EIF_CHARACTER *, EIF_INTEGER, EIF_INTEGER, EIF_INTEGER) use %"eif_str.h%""
		end

	str_rmchar (c_string: POINTER; length, i: INTEGER) is
			-- Remove `i'-th character from `c_string'.
		external
			"C signature (EIF_CHARACTER *, EIF_INTEGER, EIF_INTEGER) use %"eif_str.h%""
		end

	str_replace (c_string, other_string: POINTER; c_length, other_length,
			star_post, end_pos: INTEGER) is
			-- Replace substring (`start_pos', `end_pos') from `c_string'
			-- by `other_string'.
		external
			"C signature (EIF_CHARACTER *, EIF_CHARACTER *, EIF_INTEGER, EIF_INTEGER, EIF_INTEGER, EIF_INTEGER) use %"eif_str.h%""
		end

	str_rmall (c_string: POINTER; c: WIDE_CHARACTER; length: INTEGER): INTEGER is
			-- Remove all occurrences of `c' in `c_string'.
			-- Return new number of character making up `c_string'
		external
			"C signature (EIF_CHARACTER *, EIF_CHARACTER, EIF_INTEGER): EIF_INTEGER use %"eif_str.h%""
		end

	str_left (c_string: POINTER; length: INTEGER): INTEGER is
			-- Remove all leading whitespace from `c_string'.
			-- Return the new number of characters making `c_string'
		external
			"C signature (EIF_CHARACTER *, EIF_INTEGER): EIF_INTEGER use %"eif_str.h%""
		end

	str_right (c_string: POINTER; length: INTEGER): INTEGER is
			-- Remove all trailing whitespace from `c_string'.
			-- Return the new number of characters making `c_string'
		external
			"C signature (EIF_CHARACTER *, EIF_INTEGER): EIF_INTEGER use %"eif_str.h%""
		end

	str_resize (a: POINTER; newsize: INTEGER): like area is
			-- Area which can accomodate
			-- at least `newsize' characters
		external
			"C use %"eif_malloc.h%""
		alias
			"sprealloc"
		end

	spsubcopy (source, target: POINTER; s, e, i: INTEGER) is
			-- Copy characters of `source' within bounds `s'
			-- and `e' to `target' starting at index `i'.
		external
			"C use %"eif_copy.h%""
		end

invariant
	extendible: extendible
	compare_character: not object_comparison
	index_set_has_same_count: index_set.count = count

indexing

	library: "[
			EiffelBase: Library of reusable components for Eiffel.
			]"

	status: "[
--| Copyright (c) 1993-2006 University of Southern California and contributors.
			For ISE customers the original versions are an ISE product
			covered by the ISE Eiffel license and support agreements.
			]"

	license: "[
			EiffelBase may now be used by anyone as FREE SOFTWARE to
			develop any product, public-domain or commercial, without
			payment to ISE, under the terms of the ISE Free Eiffel Library
			License (IFELL) at http://eiffel.com/products/base/license.html.
			]"

	source: "[
			Interactive Software Engineering Inc.
			ISE Building
			360 Storke Road, Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Electronic mail <info@eiffel.com>
			Customer support http://support.eiffel.com
			]"

	info: "[
			For latest info see award-winning pages: http://eiffel.com
			]"

end -- class STRING_32



