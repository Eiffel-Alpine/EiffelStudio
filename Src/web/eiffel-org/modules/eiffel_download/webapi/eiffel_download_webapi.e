note
	description: "[
		{EIFFEL_DOWNLOAD_WEBAPI}.
		API to manage EiffelStudio for downloading.
		
		GET /api/downloads/              					: Get the latest EiffelStudio release for all platforms.
		GET /api/downloads/{release}    					: Get a release {release} of EiffelStudio for all platforms
		                                      					{release}: It could be an specific release like 17_05 or we can use
		                                     			 		all to retrieve all the releases.
		GET /api/downloads/{release}?platform={platforms}   : Get a release {release} of EiffelStudio for an specific platform {platform}
						                                      {release}: It could be an specific release like 17_05 or we can use
						                                      all to retrieve all the releases. 
						                                      {platform}: it could be an specific platforms lik win or we can use all to 
						                                      retrieve all the platforms.
	   POST /api/downloads/					                : Upload a new EiffelStudio download configuration file for an specific release.
	                                                          The file should be a JSON file using an specific format. Like
	                                                          this
	                                                          {
	                                                           "name":"13.11", 
	                                                           "files":
	                                                          		[
																	 {
																		"name":"Eiffel_13.11_gpl_93542-macosx-x86-64.tar.bz2", 
																		"size":67432962, 
																		"sha256":"073da134c26ca9f5fc2bdf9aa730e5b33ba7e22d97f46db73d88e5748b288e28", 
																		"version":"13_11", 
																		"major":"13", 
																		"minor":"11", 
																		"revision":93542, 
																		"platform":"macosx-x86-64"
																	 }
																	]
																}                       
						                                                                           
		DELETE /api/download/{release}						: Delete a release download configuration file.	It's not possible to use all as valid release parameter.
		
		GET /api/downloads/channel/beta                     : Get the latest intermediate release

	]"
	date: "$Date$"
	revision: "$Revision$"

class
	EIFFEL_DOWNLOAD_WEBAPI

inherit
	CMS_MODULE_WEBAPI [EIFFEL_DOWNLOAD_MODULE]
		redefine
			permissions,
			filters
		end

create
	make

feature -- Security

	permissions: LIST [READABLE_STRING_8]
			-- List of permission ids, used by this module, and declared.
		do
			Result := Precursor
			Result.force ("update download")
			Result.force ("view downloads")
			Result.force ("delete download")
		end

feature {NONE} -- Router/administration

	setup_webapi_router (a_router: WSF_ROUTER; a_api: CMS_API)
			-- <Precursor>
		local
			l_root: CMS_ROOT_WEBAPI_HANDLER
		do
			create l_root.make (a_api)
			l_root.set_router (a_router)
			a_router.handle ("/downloads/{release}", create {EIFFEL_DOWNLOAD_WEBAPI_HANDLER}.make (a_api), a_router.methods_get_put_delete)
			a_router.handle ("/downloads/", create {EIFFEL_DOWNLOAD_WEBAPI_HANDLER}.make (a_api), a_router.methods_get_post)
			a_router.handle ("/downloads/channel/beta", create {EIFFEL_DOWNLOAD_WEBAPI_HANDLER}.make (a_api), a_router.methods_get)
		end

feature -- Access: filter

	filters (a_api: CMS_API): detachable LIST [WSF_FILTER]
			-- Possibly list of Filter's module.
		do
			create {ARRAYED_LIST [WSF_FILTER]} Result.make (1)
			Result.extend (create {CMS_BASIC_WEBAPI_AUTH_FILTER}.make (a_api))
		end

end
