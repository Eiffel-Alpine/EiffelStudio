class
	TEST2 [G -> ANY]

feature

	g is
		local
			t1: TEST1 [G]
			a: ANY
		do
			create t1
			a := t1.item
			if a /= Void then
				io.put_string (a.generating_type.name_32.as_string_8)
				io.put_new_line
			end
		end

end
