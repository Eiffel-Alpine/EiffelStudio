/*-----------------------------------------------------------
"Automatically generated by the EiffelCOM Wizard."Added Record _userHBITMAP
	fContext: LONG
			-- No description available.
	u: typedef
			-- No description available.
	
-----------------------------------------------------------*/

#ifndef __ECOM_CONTROL_LIBRARY__USERHBITMAP_S_IMPL_H__
#define __ECOM_CONTROL_LIBRARY__USERHBITMAP_S_IMPL_H__

#include "eif_com.h"

#include "eif_eiffel.h"

#include "ecom_control_library__userHBITMAP_s.h"

#include "ecom_grt_globals_control_interfaces2.h"

#ifdef __cplusplus
extern "C" {
#endif



#ifdef __cplusplus

#define ccom_x_user_hbitmap_f_context(_ptr_) (EIF_INTEGER)(LONG)(((ecom_control_library::_userHBITMAP *)_ptr_)->fContext)

#define ccom_x_user_hbitmap_set_f_context(_ptr_, _field_) ((((ecom_control_library::_userHBITMAP *)_ptr_)->fContext) = (LONG)_field_)

#define ccom_x_user_hbitmap_u(_ptr_) (EIF_REFERENCE)(grt_ce_control_interfaces2.ccom_ce_record_x__midl_iwin_types_0007_union41 (((ecom_control_library::_userHBITMAP *)_ptr_)->u))

#define ccom_x_user_hbitmap_set_u(_ptr_, _field_) (memcpy (&(((ecom_control_library::_userHBITMAP *)_ptr_)->u), (ecom_control_library::__MIDL_IWinTypes_0007 *)_field_, sizeof (ecom_control_library::__MIDL_IWinTypes_0007)))

#endif
#ifdef __cplusplus
}
#endif

#endif