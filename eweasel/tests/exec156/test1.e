
--| Copyright (c) 1993-2017 University of Southern California and contributors.
--| All rights reserved.
--| Your use of this work is governed under the terms of the GNU General
--| Public License version 2.

class TEST1 [G]
feature
	try is
		local
			z: like Current
		do
			x := create {like Current}
			io.put_string (x.generating_type.name_32.as_string_8)
			io.new_line
			
			io.put_string ((create {like Current}).generating_type.name_32.as_string_8)
			io.new_line
			
			create x
			io.put_string (x.generating_type.name_32.as_string_8)
			io.new_line
			
			z := create {like Current}
			io.put_string (z.generating_type.name_32.as_string_8)
			io.new_line
			
			create z
			io.put_string (z.generating_type.name_32.as_string_8)
			io.new_line
		end

	try2 is
		local
			z: ARRAY [like Current]
		do
			y := create {ARRAY [like Current]}.make_filled (Current, 1, 10)
			io.put_string (y.generating_type.name_32.as_string_8)
			io.new_line

			io.put_string ((create {ARRAY [like Current]}.make_filled (Current, 1, 10)).generating_type.name_32.as_string_8)
			io.new_line

			create y.make_filled (Current, 1, 10)
			io.put_string (y.generating_type.name_32.as_string_8)
			io.new_line

			z := create {ARRAY [like Current]}.make_filled (Current, 1, 10)
			io.put_string (z.generating_type.name_32.as_string_8)
			io.new_line
			
			create z.make_filled (Current, 1, 10)
			io.put_string (z.generating_type.name_32.as_string_8)
			io.new_line
		end

	x: like Current
	y: ARRAY [like Current]
	
end
