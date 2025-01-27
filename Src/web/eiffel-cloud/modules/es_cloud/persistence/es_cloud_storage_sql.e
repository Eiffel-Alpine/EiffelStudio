note
	description: "Interface for accessing JWT token from the database."
	date: "$Date$"
	revision: "$Revision$"

class
	ES_CLOUD_STORAGE_SQL

inherit
	ES_CLOUD_STORAGE_I

	CMS_PROXY_STORAGE_SQL

	CMS_STORAGE_SQL_I

create
	make

feature -- Access

	plans: LIST [ES_CLOUD_PLAN]
		local
			pid: INTEGER
		do
			reset_error
			create {ARRAYED_LIST [ES_CLOUD_PLAN]} Result.make (0)
			sql_query (sql_select_plans, Void)
			sql_start
			if not has_error then
				from
					sql_start
				until
					sql_after or has_error
				loop
					if attached fetch_plan as pl then
						Result.force (pl)
					else
						check valid_record: False end
					end
					sql_forth
				end
			end
			sql_finalize_query (sql_select_plans)
		end

	plan (a_id: INTEGER): detachable ES_CLOUD_PLAN
		local
			l_params: STRING_TABLE [detachable ANY]
			pid: INTEGER
			l_name: detachable READABLE_STRING_32
			pl: ES_CLOUD_PLAN
		do
			reset_error
			create l_params.make (1)
			l_params.force (a_id, "pid")
			sql_query (sql_select_plan_by_id, l_params)
			sql_start
			if not has_error and not sql_after then
				Result := fetch_plan
				check valid_record: Result /= Void end
			end
			sql_finalize_query (sql_select_plan_by_id)
		end

	user_subscription (a_user: CMS_USER): detachable ES_CLOUD_PLAN_SUBSCRIPTION
		local
			l_params: STRING_TABLE [detachable ANY]
			pid: INTEGER
			l_name: detachable READABLE_STRING_32
			pl: ES_CLOUD_PLAN
		do
			reset_error
			create l_params.make (1)
			l_params.force (a_user.id, "uid")
			sql_query (sql_select_user_subscription, l_params)
			sql_start
			if not has_error and not sql_after then
				create pl.make ("free")
				pid := sql_read_integer_32 (1)
				check same_uid: sql_read_integer_64 (2) = a_user.id end
				create Result.make (a_user, pl)
				if attached sql_read_date_time (3) as dt then
					Result.set_creation_date (dt)
				else
					check has_creation_date: False end
				end
				Result.set_expiration_date (sql_read_date_time (4))
				Result.set_notes (sql_read_string_32 (5))
			end
			sql_finalize_query (sql_select_user_subscription)
			if Result /= Void then
				if pid > 0 and then attached plan (pid) as l_plan then
					Result.set_plan (l_plan)
				else
					check valid_record: False end
					Result := Void
				end
			end
		end

	user_installation (a_user: CMS_USER; a_installation_id: READABLE_STRING_GENERAL): detachable ES_CLOUD_INSTALLATION
		local
			l_params: STRING_TABLE [detachable ANY]
			iid: detachable READABLE_STRING_32
			l_name: detachable READABLE_STRING_32
		do
			reset_error
			create l_params.make (2)
			l_params.force (a_installation_id, "iid")
			l_params.force (a_user.id, "uid")
			sql_query (sql_select_user_installation, l_params)
			sql_start
			if not has_error and not sql_after then
				iid := sql_read_string_32 (1)
				if iid /= Void and then not iid.is_whitespace then
					check same_uid: sql_read_integer_64 (2) = a_user.id end
					create Result.make (iid, a_user)
					Result.set_info (sql_read_string_32 (3))
					Result.set_status (sql_read_integer_32 (4))
					Result.set_creation_date (sql_read_date_time (5))
					Result.set_access_date (sql_read_date_time (6))
				end
			end
			sql_finalize_query (sql_select_user_installation)
		end

	user_installations (a_user: CMS_USER): LIST [ES_CLOUD_INSTALLATION]
		local
			id: READABLE_STRING_GENERAL
			uid: INTEGER_64
			inst: ES_CLOUD_INSTALLATION
		do
			reset_error
			create {ARRAYED_LIST [ES_CLOUD_INSTALLATION]} Result.make (0)
			sql_query (sql_select_installations, Void)
			if not has_error then
				from
					sql_start
				until
					sql_after or has_error
				loop
					id := sql_read_string_32 (1)
					uid := sql_read_integer_64 (2)
					if
						id /= Void and then uid > 0
					then
						create inst.make (id, create {CMS_PARTIAL_USER}.make_with_id (uid))
						inst.set_info (sql_read_string_32 (3))
						inst.set_status (sql_read_integer_32 (4))
						inst.set_creation_date (sql_read_date_time (5))
						inst.set_access_date (sql_read_date_time (6))
						Result.force (inst)
					else
						check valid_record: False end
					end
					sql_forth
				end
			end
			sql_finalize_query (sql_select_installations)
		end

feature -- Change

	save_plan (a_plan: ES_CLOUD_PLAN)
		local
			l_params: STRING_TABLE [detachable ANY]
			pid: INTEGER
			l_name: detachable READABLE_STRING_32
			pl: ES_CLOUD_PLAN
			l_is_new: BOOLEAN
		do
			l_is_new := not a_plan.has_id

			reset_error
			if l_is_new then
				create l_params.make (3)
			else
				create l_params.make (4)
				l_params.force (a_plan.id, "pid")
			end
			l_params.force (a_plan.name, "name")
			l_params.force (a_plan.title, "title")
			l_params.force (a_plan.description, "description")
			if l_is_new then
				sql_insert (sql_insert_plan, l_params)
				sql_finalize_insert (sql_insert_plan)
			else
				sql_modify (sql_update_plan, l_params)
				sql_finalize_modify (sql_update_plan)
			end
		end

	save_subscription (sub: ES_CLOUD_PLAN_SUBSCRIPTION)
		local
			l_params: STRING_TABLE [detachable ANY]
			pid: INTEGER
			l_name: detachable READABLE_STRING_32
			pl: ES_CLOUD_PLAN
			l_is_new: BOOLEAN
		do
			l_is_new := user_subscription (sub.user) = Void

			reset_error
			create l_params.make (5)
			l_params.force (sub.plan.id, "pid")
			l_params.force (sub.user.id, "uid")
			l_params.force (sub.creation_date, "creation")
			l_params.force (sub.expiration_date, "expiration")
			l_params.force (sub.notes, "notes")
			if l_is_new then
				sql_insert (sql_insert_user_subscription, l_params)
				sql_finalize_insert (sql_insert_user_subscription)
			else
				sql_modify (sql_update_user_subscription, l_params)
				sql_finalize_modify (sql_update_user_subscription)
			end
		end

	discard_subscription (sub: ES_CLOUD_PLAN_SUBSCRIPTION)
		local
			l_params: STRING_TABLE [detachable ANY]
			pid: INTEGER
			l_name: detachable READABLE_STRING_32
			pl: ES_CLOUD_PLAN
			l_is_new: BOOLEAN
		do
			reset_error
			create l_params.make (1)
			l_params.force (sub.plan.id, "pid")
			l_params.force (sub.user.id, "uid")
			sql_delete (sql_delete_user_subscription, l_params)
			sql_finalize_delete (sql_delete_user_subscription)
		end

	save_installation (inst: ES_CLOUD_INSTALLATION)
		local
			l_params: STRING_TABLE [detachable ANY]
			pid: INTEGER
			l_name: detachable READABLE_STRING_32
			pl: ES_CLOUD_PLAN
			l_is_new: BOOLEAN
		do
			l_is_new := user_installation (inst.user, inst.installation_id) = Void

			reset_error
			create l_params.make (6)
			l_params.force (inst.installation_id, "iid")
			l_params.force (inst.user.id, "uid")
			l_params.force (inst.info, "info")
			l_params.force (1, "status")
			if attached inst.creation_date as dt then
				l_params.force (dt, "creation")
			else
				l_params.force (create {DATE_TIME}.make_now_utc, "creation")
			end
			l_params.force (create {DATE_TIME}.make_now_utc, "access")

			if l_is_new then
				sql_insert (sql_insert_installation, l_params)
				sql_finalize_insert (sql_insert_installation)
			else
				sql_modify (sql_update_installation, l_params)
				sql_finalize_modify (sql_update_installation)
			end
		end

	discard_installation (inst: ES_CLOUD_INSTALLATION)
		local
			l_params: STRING_TABLE [detachable ANY]
			pid: INTEGER
			l_name: detachable READABLE_STRING_32
			pl: ES_CLOUD_PLAN
			l_is_new: BOOLEAN
		do
			reset_error
			create l_params.make (1)
			l_params.force (inst.installation_id, "iid")
			l_params.force (if attached inst.user as u then u.id else {INTEGER_64} 0 end, "uid")
			sql_delete (sql_delete_installation, l_params)
			sql_finalize_delete (sql_delete_installation)
		end

feature {NONE} -- Fetcher

	fetch_plan: detachable ES_CLOUD_PLAN
		local
			pid: INTEGER
			l_name: READABLE_STRING_8
		do
			pid := sql_read_integer_32 (1)
			l_name := sql_read_string (2)
			if l_name /= Void then
				create Result.make_with_id_and_name (pid, l_name)
			else
				create Result.make_with_id_and_name (pid, "plan#" + pid.out)
			end
			Result.set_title (sql_read_string_32 (3))
			Result.set_description (sql_read_string_32 (4))
		end

feature {NONE} -- Queries: installations

	sql_select_user_installation: STRING = "SELECT iid, uid, info, status, creation, access FROM es_installations WHERE iid=:iid AND uid=:uid;"

	sql_select_installations: STRING = "SELECT iid, uid, info, status, creation, access FROM es_installations;"

	sql_insert_installation: STRING = "INSERT INTO es_installations (iid, uid, info, status, creation, access) VALUES (:iid, :uid, :info, :status, :creation, :access);"

	sql_update_installation: STRING = "UPDATE es_installations SET info=:info, status=:status, access=:access WHERE iid=:iid AND uid=:uid;"

	sql_delete_installation: STRING = "DELETE FROM es_installations WHERE iid=:iid AND uid=:uid;"

feature {NONE} -- Queries: plans	

	sql_select_plans: STRING = "SELECT pid, name, title, description FROM es_plans;"

	sql_select_plan_by_id: STRING = "SELECT pid, name, title, description FROM es_plans WHERE pid=:pid;"

	sql_insert_plan: STRING = "INSERT INTO es_plans (name, title, description) VALUES (:name, :title, :description);"

	sql_update_plan: STRING = "UPDATE es_plans SET name=:name, title=:title, description=:description WHERE pid=:pid;"

--	sql_delete_plan: STRING = "DELETE FROM es_plans WHERE pid=:pid;"

feature {NONE} -- Queries: subscriptions

	sql_select_user_subscription: STRING = "SELECT pid, uid, creation, expiration, notes FROM es_plan_subscriptions WHERE uid=:uid;"

	sql_insert_user_subscription: STRING = "INSERT INTO es_plan_subscriptions (pid, uid, creation, expiration, notes) VALUES (:pid, :uid, :creation, :expiration, :notes);"

	sql_update_user_subscription: STRING = "UPDATE es_plan_subscriptions SET pid=:pid, creation=:creation, expiration=:expiration, notes=:notes WHERE uid=:uid;"

	sql_delete_user_subscription: STRING = "DELETE FROM es_plan_subscriptions WHERE pid=:pid AND uid=:uid;"

note
	copyright: "2011-2017, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
