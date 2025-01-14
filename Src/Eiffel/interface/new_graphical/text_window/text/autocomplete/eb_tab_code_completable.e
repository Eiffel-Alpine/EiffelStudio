note
	description: "Object that is able to auto complete features or classes. Supports tab selecting function."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	author: "$Author$"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	EB_TAB_CODE_COMPLETABLE

inherit
	CODE_COMPLETABLE
		rename
			complete_from_window as old_complete_from_window
		redefine
			show_completion_list,
			choices,
			possibilities_provider,
			initialize_code_complete,
			on_key_pressed,
			on_char
		end

	EB_SHARED_PREFERENCES
		export
			{NONE} all
		end

	EB_SHARED_WINDOW_MANAGER

	EB_TOKEN_TOOLKIT
		export
			{NONE} all
		end

feature -- Initialize

	initialize_code_complete
			-- Initialize code completion
		do
			Precursor {CODE_COMPLETABLE}
			set_completing_feature (true)
			set_save_list_position_action (agent save_window_position)
			create focus_back_actions
		end

feature -- Access

	choices: EB_CODE_COMPLETION_WINDOW
			-- Completion choice window for show feature and class completion options.
		once
			create Result.make
		end

	possibilities_provider: EB_COMPLETION_POSSIBILITIES_PROVIDER
			-- Possibilities provider

	focus_back_actions: attached EV_NOTIFY_ACTION_SEQUENCE
			-- Called after focus is set back to code completable when necessary.

feature {NONE} -- Access

	current_token_in_line (a_line: like current_line): EDITOR_TOKEN
			-- Token at or behind cursor position
		require
			a_line_attached: a_line /= Void
		deferred
		ensure
			current_token_in_line_not_void: Result /= Void
		end

	selection_start_token_in_line (a_line: like current_line) : EDITOR_TOKEN
			-- Start token in the selection.
		require
			has_selection: has_selection
		deferred
		ensure
			selection_start_token_in_line_not_void: Result /= Void
		end

	selection_end_token_in_line (a_line: like current_line) : EDITOR_TOKEN
			-- Token after end of selection.
		require
			has_selection: has_selection
		deferred
		ensure
			selection_end_token_in_line_not_void: Result /= Void
		end

	current_line : EDITOR_LINE
			-- Line of current cursor.
			-- Every query is not guarenteed the same object.
		deferred
		ensure
			current_line_not_void: Result /= Void
		end

	current_char: CHARACTER_32
			-- Current character, to the right of the cursor.
		deferred
		end

	context_menu_factory: EB_CONTEXT_MENU_FACTORY
			-- Dev window
		do
			if window_manager.last_focused_development_window /= Void then
				Result := window_manager.last_focused_development_window.menus.context_menu_factory
			end
		end

feature -- Status Change

	set_discard_feature_signature (a_b: like discard_feature_signature)
			-- Set `discard_feature_signature' with `a_b'
		do
			discard_feature_signature := a_b
		ensure
			discard_feature_signature_set: discard_feature_signature = a_b
		end

	set_completing_feature (a_completing_feature: BOOLEAN)
			-- Set `completing_feature' with `a_completing_feature'.
		do
			completing_feature := a_completing_feature
		ensure
			completing_feature_set: completing_feature = a_completing_feature
		end

feature -- Status report

	has_selection: BOOLEAN
			-- Does current have a selection?
		deferred
		end

	allow_tab_selecting: BOOLEAN
			-- Allow tab selecting?
		deferred
		end

	is_editable: BOOLEAN
			-- Is editable?
		deferred
		end

	discard_feature_signature: BOOLEAN
			-- Discard feature signature?

	completing_feature: BOOLEAN
			-- Completing feature? Otherwise completing classes.

	need_tabbing: BOOLEAN
			-- Need tabbing after completion?
			-- If false, tabbing is automatically triggered.

feature {NONE} -- Status report

	end_of_line: BOOLEAN
			-- Is cursor at the end of the line.
		deferred
		end

	start_of_line (a_token: EDITOR_TOKEN; a_line: like current_line): BOOLEAN
			-- Is `a_token' start of `a_line'?
		do
			if a_token /= Void then
				if a_token.previous = Void or else a_token.previous.is_margin_token then
					Result := true
				end
			end
		end

feature -- Cursor

	go_right_char
			-- Go to right character.
		deferred
		end

	go_to_end_of_selection
			-- Move cursor to the end of selection
		require
			has_selection: has_selection
		deferred
		end

	go_to_start_of_line
			-- Move cursor to the start of a line
			-- where tab switching to next feature argument should function.
		deferred
		end

	go_to_end_of_line
			-- Move cursor to the start of a line.
		deferred
		end

	go_to_start_of_selection
			-- Move cursor to the start of the selection if possible.
		require
			has_selection: has_selection
		deferred
		end

	move_cursor_to (a_token: EDITOR_TOKEN; a_line: like current_line)
			-- Move cursor to `a_token' which is in `a_line'.
		require
			a_token_attached: a_token /= Void
			a_line_attached: a_line /= Void
		deferred
		end

	save_cursor
			-- Save cursor position for retrieving.
		deferred
		end

	retrieve_cursor
			-- Retrieve cursor position from saving.
		deferred
		end

	place_post_cursor
			-- Place cursor after completion
		do
			tab_action
		end

feature -- Selection

	disable_selection
			-- Disable selection
		deferred
		end

	show_possible_selection
			-- Show possible selection
		deferred
		end

	select_region_between_token (a_start_token: EDITOR_TOKEN; a_start_line: like current_line; a_end_token: EDITOR_TOKEN; a_end_line: like current_line)
			-- Select from the start position of `a_start_token' to the start position of `a_end_token'.
		deferred
		end

feature -- Tab actions

	tab_action
			-- Process push on tab key when in auto_complete mode.
			-- Select the closest argument of a feature.
		local
			l_line: like current_line
			l_cur_token, l_end_token, l_start_token, l_save_token: EDITOR_TOKEN
			l_found_start: BOOLEAN
			l_selected: BOOLEAN
			l_stop, l_is_start, l_jumped: BOOLEAN
		do
			l_line := current_line
			l_save_token := current_token_in_line (l_line)

			if has_selection then
					-- Seek "(", ",", or ";" token in the selection.
					-- If not, go to end of selection.
				l_cur_token := find_selection_start_in_selection (l_line)
				if l_cur_token = Void then
					go_to_end_of_selection
				end
			elseif end_of_line then
				go_to_start_of_line
				l_jumped := true
			else
				if not between_separator (current_token_in_line (l_line), l_line) and not separator_following (l_line) then
					l_cur_token := find_previous_start_token (l_line)
				end
			end
			if l_cur_token = Void then
				l_cur_token := current_token_in_line (l_line)
			end
			if l_jumped and then start_of_line (l_cur_token, l_line) and then between_separator (l_cur_token, l_line) then
				l_stop := true
			end
			if not l_stop then
					-- Search possible arguments separator.
				from
					if l_cur_token = Void then
						l_cur_token := current_token_in_line (l_line)
					end
				until
					start_of_line (l_cur_token, l_line) or token_equal (l_cur_token, "(") or token_equal (l_cur_token, ",") or token_equal (l_cur_token, ";") or l_cur_token = l_line.eol_token
				loop
					if token_equal (l_cur_token, "[") then
						l_cur_token := skip_pairs (l_cur_token, l_line, "[", "]")
					elseif token_equal (l_cur_token, "{") then
						l_cur_token := skip_pairs (l_cur_token, l_line, "{", "}")
					end
					if l_cur_token /= l_line.eol_token then
						l_cur_token := l_cur_token.next
					end
				end
				if start_of_line (l_cur_token, l_line) then
					l_is_start := true
				end
					-- Discard blank tokens.
				from
				until
					l_cur_token.next = Void or else l_cur_token.next.is_text or l_cur_token.next = l_line.eol_token
				loop
					l_cur_token := l_cur_token.next
				end
				if l_cur_token /= l_line.eol_token then
					if l_cur_token.next /= l_line.eol_token then
						if not l_is_start then
							l_cur_token := l_cur_token.next
						elseif between_separator (l_cur_token, l_line) then
							l_cur_token := l_cur_token.next
						end
						l_start_token := l_cur_token
						l_found_start := true
							l_end_token := find_end_token (l_start_token, l_line, not l_is_start)
							if l_end_token = Void then
								l_end_token := l_line.eol_token
							end
						select_region_between_token (l_start_token, l_line, l_end_token, l_line)
						show_possible_selection
						l_selected := true
					else
						go_to_end_of_line
						l_selected := true
					end
				else
					go_to_end_of_line
					l_selected := true
				end
				if not l_selected then
					move_cursor_to (l_save_token, l_line)
				end
			end
		end

	shift_tab_action
			-- Backward `tab_action'
		local
			l_line: like current_line
			l_end_token, l_start_token, l_save_token: EDITOR_TOKEN
			l_found_start: BOOLEAN
			l_jumped: BOOLEAN
		do
			l_line := current_line
			l_save_token := current_token_in_line (l_line)

			if has_selection then
				go_to_start_of_selection
			end
			if end_of_line then
				l_start_token := l_line.eol_token
			else
				l_start_token := find_previous_start_token (l_line)
			end
			if l_start_token /= Void then
				move_cursor_to (l_start_token, l_line)
				l_start_token := find_previous_start_token (l_line)
				if l_start_token = Void then
					l_start_token := l_line.first_token
					l_found_start := true
				else
					move_cursor_to (l_start_token, l_line)
				end
			else
				go_to_end_of_line
				l_jumped := true
			end

			if l_jumped then
				l_start_token := find_previous_start_token (l_line)
			end
			if l_start_token /= Void then
					-- Discard blank tokens.
				from
				until
					l_found_start or l_start_token.next = Void or else l_start_token.next.is_text or l_start_token.next = l_line.eol_token
				loop
					l_start_token := l_start_token.next
				end
				if not l_found_start then
					l_start_token := l_start_token.next
				end
				l_end_token := find_end_token (l_start_token, l_line, true)
				if l_end_token = Void then
					l_end_token := l_line.eol_token
				end
				select_region_between_token (l_start_token, l_line, l_end_token, l_line)
				show_possible_selection
			else
				move_cursor_to (l_save_token, l_line)
			end
		end

 	handle_tab_action (a_backwards: BOOLEAN)
 			-- Handle tab action.
 		do
 			if a_backwards then
 				tab_action
 			else
 				shift_tab_action
 			end
 		end

feature -- Action handlers

	on_key_pressed (a_key: EV_KEY)
			-- If `a_key' can activate text completion, activate it.
		do
			if not is_completing then
				if a_key.code = {EV_KEY_CONSTANTS}.key_tab and allow_tab_selecting and then not shifted_key then
					handle_tab_action (false)
				elseif a_key.code = {EV_KEY_CONSTANTS}.key_tab and allow_tab_selecting and then shifted_key then
					handle_tab_action (true)
				else
					Precursor {CODE_COMPLETABLE}(a_key)
				end
			end
		end

	on_char (character_string: STRING_32)
			-- If `a_key' can activate text completion, activate it.
		do
			if not is_completing and then character_string.count = 1 then
				if is_char_activator_character (character_string.item (1)) and completing_feature then
					trigger_completion
					debug ("Auto_completion")
						print ("Completion triggered.%N")
					end
				else
					block_completion
					debug ("Auto_completion")
						print ("Completion blocked.%N")
					end
				end
			end
		end

feature {CODE_COMPLETION_WINDOW} -- Code complete from window

	complete_feature_from_window (cmp: STRING_32; is_feature_signature: BOOLEAN; appended_character: CHARACTER_32; remainder: INTEGER; a_continue_completion: BOOLEAN)
			-- Insert `cmp' in the editor and switch to completion mode.
			-- If `is_feature_signature' then try to complete arguments and remove the type.
			-- `appended_character' is a character that should be appended after the feature. '%U' if none.
		local
			completed: STRING_32
			ind: INTEGER
			lp: INTEGER
		do
			if is_editable then
				if is_feature_signature then
					completed := cmp.twin
					ind := completed.last_index_of (':', completed.count)
					lp := completed.last_index_of (')', completed.count)
					if ind > 0 and ind > lp then
						completed.keep_head (ind - 1)
					end
					if discard_feature_signature and completed.has ('(') then
						check
							complete_is_not_preceded_with_open_brace: completed.index_of ('(', 1) - 2 >= 0
						end
						completed.keep_head (completed.index_of ('(', 1) - 2)
					end
				else
					completed := cmp
				end
				if completed.is_empty then
					if appended_character /= '%U' then
						insert_char (appended_character)
					end
				else
					complete_feature_call (completed, is_feature_signature, appended_character, remainder, a_continue_completion)
					if is_feature_signature then
						if need_tabbing or else completed.last_index_of (')',completed.count) = completed.count then
							if not a_continue_completion then
								place_post_cursor
							end
						end
					end
				end
				refresh
			end
		end

	complete_class_from_window (completed: STRING_32; appended_character: CHARACTER_32; remainder: INTEGER)
			-- Insert `completed' in the editor.
		local
			i: INTEGER
		do
			if is_editable then
				if remainder > 0 then
					from
						i := 0
					until
						i = remainder
					loop
						delete_char
						i := i + 1
					end
				end
				if not completed.is_empty then
					insert_string (completed)
				end
				if appended_character /= '%U' then
					insert_char (appended_character)
				end
				refresh
			end
		end

	complete_feature_call (completed: STRING_32; is_feature_signature: BOOLEAN; appended_character: CHARACTER_32; remainder: INTEGER; a_continue_completion: BOOLEAN)
 			-- Finish completion process by inserting the completed expression.
		local
			i: INTEGER
			l_completed: STRING_32
		do
			l_completed := completed.twin
			if possibilities_provider.insertion /= Void and then not possibilities_provider.insertion.is_empty then --  valid_index (1) and then not click_tool.insertion.item (1).is_empty then
				if l_completed.item (1) = ' ' then
					back_delete_char
				end
			end
			if remainder > 0 then
				from
					i := 0
				until
					i = remainder
				loop
					delete_char
					i := i + 1
				end
			end
			l_completed.replace_substring_all (";", ",")
			l_completed.replace_substring_all ("#", "# ")
			insert_string (l_completed)
			if appended_character /= '%U' then
				insert_char (appended_character)
			end
		end

	complete_code_template_from_window (a_template: EB_TEMPLATE_FOR_COMPLETION)
			-- Insert template `a_template' and locals variables `a_locals' if any in the editor.
		do
			complete_template_call (a_template)
		end

	complete_template_call (a_template: EB_TEMPLATE_FOR_COMPLETION)
		do
		end

	post_focus_back
			-- Preparation before focus is set back.
		do
			focus_back_actions.call (Void)
		end

feature {NONE} -- Implementation

	show_completion_list
			-- Show completion window.
		do
			choices.show_bypassed_for_single_choice := False
			if completing_feature then
				choices.initialize_for_features
					(
						Current,
						name_part_to_be_completed,
						name_part_to_be_completed_remainder,
						possibilities_provider.completion_possibilities,
						completing_word
					)
			else
				choices.initialize_for_classes
					(
						Current,
						name_part_to_be_completed,
						name_part_to_be_completed_remainder,
						possibilities_provider.class_completion_possibilities
					)
			end
			if choices.is_displayed then
				choices.hide
			end
			block_focus_out_actions
			if choices.show_needed then
				position_completion_choice_window
				is_completing := True
				choices.set_context_menu_factory (context_menu_factory)
				choices.show
			end
		end

	save_window_position (x, y, w, h: INTEGER)
			-- Save current window position
		do
			if preferences.development_window_data.remember_completion_list_size then
				preferences.development_window_data.save_completion_list_size (w, h)
			end
		end

	between_separator (a_token: EDITOR_TOKEN; a_line: like current_line) : BOOLEAN
			-- Is cursor before `a_token' between separators?
		require
			a_token_attached: a_token /= Void
			a_line_attached: a_line /= Void
		local
			l_cur_token: EDITOR_TOKEN
		do
			l_cur_token := a_token.previous
			Result := l_cur_token = Void or else start_of_line (l_cur_token, a_line) or token_equal (l_cur_token, "(") or token_equal (l_cur_token, ")") or token_equal (l_cur_token, ",") or token_equal (l_cur_token, ";") or l_cur_token = a_line.eol_token
			l_cur_token := a_token
			Result := Result and (l_cur_token = Void or else token_equal (l_cur_token, "(") or token_equal (l_cur_token, ")") or token_equal (l_cur_token, ",") or token_equal (l_cur_token, ";") or l_cur_token = a_line.eol_token)
		end

	separator_following (a_line: like current_line) : BOOLEAN
			-- Is cursor before a separator?
		require
			a_line_attached: a_line /= Void
		local
			l_cur_token: EDITOR_TOKEN
		do
			l_cur_token := current_token_in_line (a_line)
			Result := token_equal (l_cur_token, ")") or token_equal (l_cur_token, ",") or token_equal (l_cur_token, ";") or l_cur_token = a_line.eol_token
		end

	skip_pairs (a_token: EDITOR_TOKEN; a_line: like current_line; a_left: STRING; a_right: STRING): EDITOR_TOKEN
			-- Skip tokens from `a_token' that are and between pairs of `a_left' and `a_right'.
			-- i.e "[INETEGER, STRING]" where `a_token' is "[", `a_left' is "[", `a_right' is "]", "]" is returned.
		require
			a_token_attached: a_token /= Void
			a_line_attached: a_line /= Void
			a_left_and_a_right_attached: a_left /= Void and a_right /= Void
			a_token_same_as_a_left: token_equal (a_token, a_left)
		local
			l_token: EDITOR_TOKEN
			l_pair_count: INTEGER
		do
			from
				l_token := a_token
				l_pair_count := 0
			until
				l_token = a_line.eol_token or l_token = Void or else (l_pair_count = 1 and token_equal (l_token, a_right))
			loop
				if token_equal (l_token, a_left) then
					l_pair_count := l_pair_count + 1
				elseif l_pair_count /= 0 and then token_equal (l_token, a_right) then
					l_pair_count := l_pair_count - 1
				end
				l_token := l_token.next
			end
			if l_token /= Void and l_token /= a_line.eol_token then
				Result := l_token
			else
				Result := a_line.eol_token
			end
		end

	skip_pairs_backward (a_token: EDITOR_TOKEN; a_line: like current_line; a_left: STRING; a_right: STRING): EDITOR_TOKEN
			-- Skip backwards tokens from `a_token' that are and between pairs of `a_left' and `a_right'.
			-- i.e "[INETEGER, STRING]" where `a_token' is "]", `a_left' is "[", `a_right' is "]", "[" is returned.
		require
			a_token_attached: a_token /= Void
			a_line_attached: a_line /= Void
			a_left_and_a_right_attached: a_left /= Void and a_right /= Void
			a_token_same_as_a_left: token_equal (a_token, a_right)
		local
			l_token: EDITOR_TOKEN
			l_pair_count: INTEGER
		do
			from
				l_token := a_token
				l_pair_count := 0
			until
				l_token = a_line.real_first_token or else l_token = Void or else (l_pair_count = 1 and token_equal (l_token, a_left))
			loop
				if token_equal (l_token, a_right) then
					l_pair_count := l_pair_count + 1
				elseif l_pair_count /= 0 and then token_equal (l_token, a_left) then
					l_pair_count := l_pair_count - 1
				end
				l_token := l_token.previous
			end
			if l_token /= Void and l_token /= a_line.real_first_token then
				Result := l_token
			else
				Result := a_line.real_first_token
			end
		end

	find_end_token (a_token: EDITOR_TOKEN; a_line: like current_line; a_know_right_brace: BOOLEAN): EDITOR_TOKEN
			-- Find end token from `a_token' in `a_line' for selection that is triggered by tab.
		local
			l_cur_token: EDITOR_TOKEN
			pair_counted: INTEGER
		do
			from
				l_cur_token := a_token
				pair_counted := 0
			until
				l_cur_token = Void or else (pair_counted = 0 and ((a_know_right_brace and token_equal (l_cur_token, ")")) or token_equal (l_cur_token, ",") or token_equal (l_cur_token, ";"))) or l_cur_token = a_line.eol_token
			loop
				if token_equal (l_cur_token, "(") then
					if not a_know_right_brace then
						l_cur_token := skip_pairs (l_cur_token, a_line, "(", ")")
					end
				elseif token_equal (l_cur_token, "[") then
					l_cur_token := skip_pairs (l_cur_token, a_line, "[", "]")
				elseif token_equal (l_cur_token, "{") then
					l_cur_token := skip_pairs (l_cur_token, a_line, "{", "}")
				end
				if token_equal (l_cur_token, "(") then
					pair_counted := pair_counted + 1
				elseif token_equal (l_cur_token, ")") then
					pair_counted := pair_counted - 1
				end
				l_cur_token := l_cur_token.next
			end
			Result := l_cur_token
		end

	find_previous_start_token (a_line: like current_line): EDITOR_TOKEN
			-- Find start token for selection caused by tab action.
		local
			l_cur_token: EDITOR_TOKEN
		do
			from
				l_cur_token := current_token_in_line (a_line).previous
			until
				l_cur_token = Void or else token_equal (l_cur_token, "(") or token_equal (l_cur_token, ",") or token_equal (l_cur_token, ";")
			loop
				if token_equal (l_cur_token, "]") then
					l_cur_token := skip_pairs_backward (l_cur_token, a_line, "[", "]")
				elseif token_equal (l_cur_token, "}") then
					l_cur_token := skip_pairs_backward (l_cur_token, a_line, "{", "}")
				end
				l_cur_token := l_cur_token.previous
			end
			Result := l_cur_token
		end

	find_selection_start_in_selection (a_line: like current_line): EDITOR_TOKEN
			-- Find in selection start token for selection caused by tab action.
		require
			has_selection: has_selection
		local
			l_cur_token, l_start_token, l_end_token: EDITOR_TOKEN
		do
			from
				l_start_token := selection_start_token_in_line (a_line)
				l_end_token := selection_end_token_in_line (a_line)
				l_cur_token := l_start_token
			until
				l_cur_token = Void or else l_cur_token = l_end_token or else token_equal (l_cur_token, "(")
			loop
				l_cur_token := l_cur_token.next
			end
			if l_cur_token /= Void and then l_cur_token /= l_end_token then
				Result := l_cur_token
			end
		end

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
