
--| Copyright (c) 1993-2006 University of Southern California and contributors.
--| All rights reserved.
--| Your use of this work is governed under the terms of the GNU General
--| Public License version 2.

class TEST1
feature

	prefix "not": INTEGER is
		do
		end
		
	prefix "###": INTEGER;
		
	infix "###" (b: BOOLEAN): INTEGER is
		once
		end
		
	infix "@free_operator" (b: like Current): like Current is
		external
			"C"
		alias
			"weasel"
		end
		
	my_feature (s: STRING) is
		do
		end
	
end
