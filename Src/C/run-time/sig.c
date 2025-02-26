/*
	description: "Signal handling and filtering."
	date:		"$Date$"
	revision:	"$Revision$"
	copyright:	"Copyright (c) 1985-2009, Eiffel Software."
	license:	"GPL version 2 see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options:	"Commercial license is available at http://www.eiffel.com/licensing"
	copying: "[
			This file is part of Eiffel Software's Runtime.
			
			Eiffel Software's Runtime is free software; you can
			redistribute it and/or modify it under the terms of the
			GNU General Public License as published by the Free
			Software Foundation, version 2 of the License
			(available at the URL listed under "license" above).
			
			Eiffel Software's Runtime is distributed in the hope
			that it will be useful,	but WITHOUT ANY WARRANTY;
			without even the implied warranty of MERCHANTABILITY
			or FITNESS FOR A PARTICULAR PURPOSE.
			See the	GNU General Public License for more details.
			
			You should have received a copy of the GNU General Public
			License along with Eiffel Software's Runtime; if not,
			write to the Free Software Foundation, Inc.,
			51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA
		]"
	source: "[
			 Eiffel Software
			 356 Storke Road, Goleta, CA 93117 USA
			 Telephone 805-685-1006, Fax 805-685-6869
			 Website http://www.eiffel.com
			 Customer support http://support.eiffel.com
		]"
*/

/*
doc:<file name="sig.c" header="eif_sig.h" version="$Id$" summary="Signal handling and filtering">
*/

#include "eif_portable.h"

#ifdef USE_BSD_SIGNALS
#define _BSD_SIGNALS /* Needed on some platform to get `sigsetmask' (e.g. sgi) */
#endif

#include "rt_except.h"
#include "rt_constants.h"
#include "rt_sig.h"
#include "rt_globals.h"
#include "rt_malloc.h"
#include <signal.h>
#include <errno.h>
#include <stdio.h>				/* For sprintf() */
#include <string.h>
#include "rt_globals_access.h"

#if !defined sigmask
#define sigmask(m)	(1<<((m)-1))
#endif

/* For debugging */
/*#define DEBUG 1 */		/**/
#define dprintf(n)		if (DEBUG & (n)) printf

/*
doc:	<attribute name="esig" return_type="Signal_t (*)(int) [EIF_NSIG]" export="private">
doc:		<summary>Array of signal handlers used by the run-time to dispatch signals as they arrive. The array is modified via class EXCEPTION. If no signal handler is provided, then the signal is delivered to the process after beeing reset to its default behaviour (of course, we do this only when the default behaviour is not SIG_IGN).</summary>
doc:		<access>Read/Write</access>
doc:		<indexing>By signal ID value</indexing>
doc:		<thread_safety>Not safe</thread_safety>
doc:		<synchronization>None</synchronization>
doc:		<fixme>It does not look like it is simply initialized once and then only read. So I'm in favor of adding a mutex for its access/update. Also is this really `public'?</fixme>
doc:	</attribute>
*/

rt_private Signal_t (*esig[EIF_NSIG])(int);	/* Array of signal handlers */

/*
doc:	<attribute name="sig_ign" return_type="char [EIF_NSIG]" export="private">
doc:		<summary>Records whether a signal is ignored by default or not. Some of these values where set during the initialization, others were hardwired.</summary>
doc:		<access>Read/Write</access>
doc:		<thread_safety>Not safe</thread_safety>
doc:		<synchronization>None</synchronization>
doc:		<fixme>Make it thread safe.</fixme>
doc:	</attribute>
*/

rt_private char sig_ign[EIF_NSIG];

/*
doc:	<attribute name="osig_ign" return_type="char [EIF_NSIG]" export="private">
doc:		<summary>Records original status of a signal to know whether by default a signal is ignored or not.</summary>
doc:		<access>Read/Write</access>
doc:		<thread_safety>Not safe</thread_safety>
doc:		<synchronization>None</synchronization>
doc:		<fixme>Make it thread safe.</fixme>
doc:	</attribute>
*/
rt_private char osig_ign[EIF_NSIG];

#ifndef EIF_THREADS

/*
doc:	<attribute name="esigblk" return_type="int" export="shared">
doc:		<summary>Global signal handler status. If set to 0, then signal handler is activated an normal processing occurs. Otherwise, signals are queued if they are not ignored, for later processing.</summary>
doc:		<access>Read/Write</access>
doc:		<thread_safety>Safe</thread_safety>
doc:		<synchronization>Per thread data.</synchronization>
doc:		<fixme>Does it really make sense to have per thread data here?</fixme>
doc:	</attribute>
*/
rt_shared int esigblk = 0;

/*
doc:	<attribute name="sig_stk" return_type="struct s_stack" export="shared">
doc:		<summary>The FIFO stack (circular buffer) used to record arrived signals while esigblk was set (for instance, while in the garbage collector). Initialized in `initsig'.</summary>
doc:		<access>Read/Write</access>
doc:		<thread_safety>Safe</thread_safety>
doc:		<synchronization>Per thread data.</synchronization>
doc:		<fixme>Does it really make sense to have per thread data here?</fixme>
doc:	</attribute>
*/
rt_shared struct s_stack sig_stk;


#ifdef HAS_SIGALTSTACK
/*
doc:	<attribute name="c_sig_stk" return_type="stack_t *" export="private">
doc:		<summary>Stack used for evaluation signal handlers.</summary>
doc:		<access>Read/Write once on initialization</access>
doc:		<thread_safety>Safe</thread_safety>
doc:		<synchronization>None</synchronization>
doc:	</attribute>
*/
rt_private stack_t *c_sig_stk;
#endif

#endif /* EIF_THREADS */

#ifdef EIF_VMS	/* signal handling control for CECIL: only on VMS for now */
rt_private struct ex_vect* esig_cecil_exvect;
rt_private int esig_cecil_call_nest_level;
#endif


/* Routine declarations */
rt_shared Signal_t ehandler(int sig);
rt_shared Signal_t exfpe(int sig);
rt_private Signal_t eiffel_signal_handler(int sig, int is_fpe);
rt_public char *signame(int sig);				/* Give English description of a signal */
rt_private int dangerous(int sig);			/* Is a given signal dangerous for us? */
rt_shared void esdpch(EIF_CONTEXT_NOARG);				/* Dispatch queued signals */
rt_shared void initsig(void);				/* Run-time initialization for trapping */
rt_private void spush(int sig);				/* Queue signal in a FIFO stack */
rt_private int spop(void);					/* Extract signals from queued stack */
rt_shared Signal_t (*rt_signal (int sig, Signal_t (*handler)(int)))(int); /* Install signal handler */

/* Compiled with -DTEST, we turn on DEBUG if not already done */
#ifdef TEST
#ifndef DEBUG
#define DEBUG	1		/* Highest debug level */
#endif
#endif

rt_shared Signal_t (*rt_signal (int sig, Signal_t (*handler)(int)))(int) 
{
#ifndef HAS_SIGACTION
	return signal(sig, handler);
#else
	RT_GET_CONTEXT
	struct sigaction action;
	struct sigaction old_action;
								
		/* Install new handler */
	memset(&action,0,sizeof(struct sigaction));
	action.sa_handler = handler;
		/* To avoid reseting the mask when entering the signal handler. */
	action.sa_flags = SA_NODEFER;
#ifdef HAS_SIGALTSTACK
	if ((sig == SIGSEGV) && (c_sig_stk)) {
		action.sa_flags |= SA_ONSTACK;
	}
#endif
	if (sigaction (sig, &action, &old_action) == -1) {
		if (sigaction (sig, NULL, &old_action) == -1) {
			return NULL;
		} else {
			return old_action.sa_handler;
			}
	} else {
		return old_action.sa_handler;
	}
#endif
}


/*
 * Signal handler routines.
 */

/*
doc:	<routine name="eiffel_signal_handler" export="private">
doc:		<summary>Catch all the signals that can be caught. If we are in a critical section we record the signal and it will be raised later. Otherwise we raise an exception corresponding to the signal. If `is_fpe' we handle it as if it was a floating point exception.</summary>
doc:		<param name="sig" type="int">Signal number being caught.</param>
doc:		<param name="is_fpe" type="int">Are we handling a floating point exception signal?</param>
doc:		<thread_safety>FIXME</thread_safety>
doc:		<synchronization>FIXME</synchronization>
doc:	</routine>
*/

rt_private Signal_t eiffel_signal_handler(int sig, int is_fpe)
{
	RT_GET_CONTEXT
	EIF_GET_CONTEXT
	Signal_t (*handler)(int);			/* The Eiffel signal handler routine */
	char *signal_name = NULL;

		/* Check if signal was caught in a non-Eiffel thread. In which case we wimply
		 * print out the signal number except if this is SIGINT or SIGBREAK which are
		 * usually the result of a user action to stop the process.
		 * This partially address bug#19000. */
#if defined(EIF_THREADS) || defined(EIF_WINDOWS)
#ifdef EIF_THREADS
	if (rt_globals == NULL)
#elif defined(EIF_WINDOWS)
		/* On Windows for a non-multithreaded program, if we are called from a different
		 * thread than the root one, we clearly cannot continue. */
	if (rt_root_thread_id != GetCurrentThreadId())
#endif
	{
#ifdef SIGBREAK
		if (sig != SIGINT && sig != SIGBREAK)
#else
		if (sig != SIGINT)
#endif
		{
			fprintf(stderr, "\nSignal caught %d while in a non-Eiffel thread.\n", sig);
		}
		exit(EXIT_FAILURE);
	}
#endif

	if (esigdefined(sig)) {
		signal_name = signame(sig);
	}

#ifndef HAS_SIGACTION

		/* On BSD systems (those with sigvec() facilities), we have to clear
		 * the signal mask for the signal received. That way, it is possible
		 * to use _setjmp and _longjmp for exception handling. If we did not
		 * reset the signal, either we would have to use setjmp/longjmp or
		 * we could only receive one occurrence of a signal--RAM.
		 */

#ifdef HAS_SIGSETMASK
	{
		int oldmask;	/* To get old signal mask */ /* %%ss moved from above */
		oldmask = sigsetmask(0xffffffff);	/* Fetch old signal mask */
		oldmask &= ~sigmask(sig);			/* Unblock signal */
		(void) sigsetmask(oldmask);			/* Resynchronize signal mask */
	}
#endif


#ifndef SIGNALS_KEPT
	{
		Signal_t (*old_handler)(int);

		/* Assume disposition of signal is SIG_DFL.
		   Reset disposition of signal to call
		   ISE's interrupt handler */

		if (is_fpe) {
			old_handler = signal(sig, exfpe);
		} else {
			old_handler = signal(sig, ehandler);
		}

		if (old_handler != SIG_DFL) {
			/* Oops - someone called `sigaction' to override
			   ISE's handler.  Their handler is still
			   the one to use, so restore it.
			 */
			signal(sig, old_handler);
		}
	}
#endif
#endif

	if (sig_ign[sig])				/* If signal is to be ignored */
		return;						/* Nothing to be done */

	if (esigblk) {					/* Signals are blocked */
		if (dangerous(sig)) {		/* Harmful signal in critical section */
			char panic_msg[1024] = "";
			memset(panic_msg, 0, 1024);
			strcat (panic_msg, "Unexpected harmful signal (");
			if (signal_name) {
					/* Check that we do not do a buffer overflow on `panic_msg'.
					 * We use 900 as value to avoid computing the above string
					 * length wich is clearly less than 124 wide. */
				if (strlen (signal_name) < 900) {
					strcat (panic_msg, signal_name);
				}
			} else {
				strcat (panic_msg, "Unknown signal");
			}
			strcat (panic_msg, ")");
			eif_panic(panic_msg);
		}
		spush(sig);					/* Record sig on FIFO stack */
		return;						/* That's all for now */
	}

	/* With BSD reliable signals, further instances of the signal we received
	 * are blocked until this function returns or a longjmp (not _longjmp) is
	 * issued (which restores the signal mask at the time setjmp was issued).
	 * Under USG, race condition may occur--RAM.
	 */

	handler = esig[sig];			/* Fetch signal handler's address */
	if (handler) {					/* There is a signal handler */
		esigblk++;					/* Queue further signals */
		exhdlr(MTC handler, sig);		/* Call handler */
		esigblk--;					/* Restore signal handling */
	} else {						/* Signal not caught -- raise exception */
		echsig = sig;				/* Signal's number */
		if (is_fpe) {
			eraise(signal_name, EN_FLOAT);		/* Raise a floating point exception */
		} else {
			eraise(signal_name, EN_SIG);			/* Operating system signal */
		}
	}
}

/*
doc:	<routine name="ehandler" export="private">
doc:		<summary>Small wrapper around `eiffel_signal_handler' to catch all signals but floating point exception.</summary>
doc:		<param name="sig" type="int">Signal number being caught.</param>
doc:		<thread_safety>FIXME</thread_safety>
doc:		<synchronization>FIXME</synchronization>
doc:	</routine>
*/

rt_shared Signal_t ehandler(int sig) {
		/* Handle all signals but floating point exception. */
	eiffel_signal_handler (sig, 0);
}

/*
doc:	<routine name="exfpe" export="private">
doc:		<summary>Small wrapper around `eiffel_signal_handler' to only catch floating point exception.</summary>
doc:		<param name="sig" type="int">Signal number being caught.</param>
doc:		<thread_safety>FIXME</thread_safety>
doc:		<synchronization>FIXME</synchronization>
doc:	</routine>
*/

rt_shared Signal_t exfpe(int sig) {
		/* Handle signals related to floating point exception */
	eiffel_signal_handler (sig, 1);
}

rt_shared void trapsig(Signal_t (*handler) (int))
                      		/* The signal handler provided */
{
	/* This routine is usually called only by the main() when something wrong
	 * happened. All the signals are trapped and redirected to the supplied
	 * handler. Only SIGQUIT, SIGINT and SIGTSTP receive a special treatment.
	 */

	int sig;						/* Signal number to be set */

	for (sig = 1; sig < EIF_NSIG; sig++)
#ifdef EIF_THREADS
	/* In Multi-threaded mode, we do not want to call
     * signal () on some specific signals.
	 */

	switch (sig) {
	
#ifdef EIF_DFLT_SIGUSR
		/* So far, used in Linux threads */
		case SIGUSR1:
			break;

		case SIGUSR2:
			break;
#endif /* EIF_DFLT_SIGUSR */

#ifdef EIF_DFLT_SIGPTRESCHED
		/* So far, used in Posix 1003.1c threads */
		case SIGPTRESCHED:
			break;
#endif /* EIF_DFLT_SIGPTRESCHED */

#ifdef EIF_DFLT_SIGPTINTR
		/* So far, used in Posix 1003.1c */
		case SIGPTINTR:
			break;
#endif /* EIF_DFLT_SIGPTINTR */

#ifdef EIF_DFLT_SIGRTMIN
		/* So far, used in Posix 1003.1b */
		case SIGRTMIN:
			break;
#endif /* EIF_DFLT_SIGRTMIN */

#ifdef EIF_DFLT_SIGRTMAX
		/* So far, used in Posix 1003.1b */
		case SIGRTMAX:
			break;
#endif /* EIF_DFLT_SIGRTMAX */

#ifdef EIF_DFLT_SIGWAITING 
		/* So far, used in solaris threads (SunOS 5.5+ and Unixware 2.0)
		 * On solaris 2.4, it is not used, which is a bug of the thread lib 
		 */
		case SIGWAITING:
			break;
#endif /* EIF_DFLT_SIGWAITING */

/*#ifdef VXWORKS
		case 34528:
			break;
*/
		default:
			if (esigdefined(sig)) {
				(void) rt_signal(sig, handler);	/* Ignore EINVAL errors */
			}
	}			
#else
		if (esigdefined(sig)) {
			(void) rt_signal(sig, handler);	/* Ignore EINVAL errors */
		}
#endif	/* EIF_THREADS */

	/* Do not catch SIGTSTP (stop signal from tty like ^Z under csh or ksh)
	 * otherwise job control will not be allowed. However, SIGSTOP is caught.
	 * Idem for continue signal SIGCONT.
	 */

#ifdef SIGTSTP
	(void) rt_signal(SIGTSTP, SIG_DFL);	/* Restore default behaviour */
#endif
#ifdef SIGCONT
	(void) rt_signal(SIGCONT, SIG_DFL);	/* Restore default behaviour */
#endif
}

rt_private int dangerous(int sig)
{
	/* Return true if the signal 'sig' is dangerous, false otherwise. A signal
	 * is thought as being dangerous if it may be caused by a corrupted memory
	 * or data segment.
	 */

	if (sig == 0) {						/* Dummy to enable 'else if' tests */
		return 0;
#ifdef SIGILL
	} else if (sig == SIGILL) {			/* Illegal instruction */
		return 1;
#endif
#ifdef SIGBUS
	} else if (sig == SIGBUS) {			/* Bus error */
		return 1;
#endif
#ifdef SIGSEGV
	} else if (sig == SIGSEGV) {		/* Segmentation violation */
		return 1;
#endif
#ifdef SIGFPE
	} else if (sig == SIGFPE) {		/* Segmentation violation */
		return 1;
#endif
#ifdef EIF_SGI
	/* Per man page documentation of `signal' on SGI:
	 * Signals raised by any instruction in the instruction stream, including
     * SIGFPE, SIGILL, SIGEMT, SIGBUS, and SIGSEGV, will cause infinite loops if
     * their handler returns.
	 *
	 * As a consequence we need to mark them dangerous. In addition to that we found out
	 * that `SIGTRAP' was also dangerous since it is used to catch division by zero and will
	 * also do an infinite loop.
	 *
	 * Note: we do not handle SIGFPE, SIGBUS, SIGSEGV, SIGILL here because already
	 * done above for non-SGI case.
	 */
	} else if ((sig == SIGEMT) || (sig == SIGTRAP)) {
		return 1;
#endif
	}

	return 0;			/* Signal is not dangerous for us */
}

/*
 * Dispatching queued signals.
 */

rt_shared void esdpch(EIF_CONTEXT_NOARG)
{
	/* Dispatches any pending signal in a FIFO manner as if the signal was
	 * being received now. We knwo the signal was not meant to be ignored,
	 * otherwise it would not have been queued.
	 */
	RT_GET_CONTEXT
	EIF_GET_CONTEXT
	Signal_t (*handler)(int);			/* The Eiffel signal handler routine */
	int sig;						/* Signal number to be sent */

	/* Note that all the signal queued here have their corresponding bit in
	 * the signal mask cleared, because the handler which queued them have
	 * returned since then--RAM.
	 */

	sig = spop();
	while (sig) {					/* While there are some buffered signals */
		handler = esig[sig];		/* Fetch signal handler's address */
		if (handler) {				/* There is a signal handler */
			esigblk++;				/* Queue further signals */
			exhdlr(MTC handler, sig);	/* Call handler */
			esigblk--;				/* Restore signal handling */
		} else {					/* Signal not caught -- raise exception */
			echsig = sig;			/* Signal's number */
			if (esigdefined(sig)) {
				eraise(signame(sig), EN_SIG);			/* Operating system signal */
			} else {
				eraise(NULL, EN_SIG);			/* Operating system signal */
			}
		}
		sig = spop();
	}
}

/*
 * Kernel signal interface.
 */

rt_shared Signal_t (*esignal(int sig, Signal_t (*func) (int)))(int)
        				/* Signal to handle */
                   		/* Handler to be associated with signal */
{
	/* Set-up a signal handler for a specific signal and return the previous
	 * handler. This routine behaves exactly as its kernel counterpart, except
	 * that it knows about the run-time data structures.
	 * NB: when signal handlers are installed via this interface, they are
	 * automatically reinstanciated by the run-time (although race conditions
	 * may occur if this is not done by the kernel).
	 */
	Signal_t (*oldfunc)(int);		/* Previous signal handler set */
	int ignored;				/* Ignore status for previous handler */

	if (sig >= EIF_NSIG)
		return ((Signal_t (*)(int)) -1); /* %%ss added cast int */

	oldfunc = esig[sig];		/* Get previous handler */
	ignored = sig_ign[sig];		/* Was signal ignored? */

	if (func == SIG_IGN)		/* Signal is to be ignored */
		sig_ign[sig] = 1;
	else if (func == SIG_DFL) {	/* Default behaviour to be restored */
		sig_ign[sig] = osig_ign[sig];
		esig[sig] = (Signal_t (*)(int)) 0; /* %%ss added cast int */
	} else {
		sig_ign[sig] = 0;		/* Do not ignore this signal */
		esig[sig] = func;		/* Signal handler to be called */
	}

	/* Now set up the return value we would expect from the kernel routine.
	 * If the signal was ignored, SIG_IGN is returned. If a null handler was
	 * present, SIG_DFL is returned. Otherwise return the handler's address.
	 */

	if (ignored)
		oldfunc = SIG_IGN;
	else if (oldfunc == (Signal_t (*)(int)) 0)
		oldfunc = SIG_DFL;

	return oldfunc;				/* Previous signal handler */
}

/*
 * Initialization section.
 */

rt_shared void initsig(void)
{
	/* This routine should be called by the main() of the Eiffel program to
	 * properly initialize signals. This code is thus executed only once
	 * and was made as short as possible--RAM.
	 */
	RT_GET_CONTEXT
	int sig;				/* To loop over the signals */
	Signal_t (*old)(int);	/* Old signal handler */

	/* Initialize the signal stack (circular buffer). The last read location is
	 * set to SIGSTACK - 1 (i.e. at the end of the array) while the first free
	 * location is 0 (i.e. first item in the array).
	 */
	sig_stk.s_min = SIGSTACK - 1,	/* Last read location */
	sig_stk.s_max = 0;				/* First free location */
	sig_stk.s_pending = '\0';		/* No signals pending yet */

#ifdef HAS_SIGALTSTACK
		/* To make sure that stack overflow are properly handled, we allocate
		 * a stack for signal handling where handler will be executed when
		 * receiving a SIGSEGV.
		 * By default we allocate 4 times the default SIGSTKSZ which has
		 * been shown to be enough. See eweasel test#excep016 as a test to
		 * see if this is good enough. */
	c_sig_stk = (stack_t *) eif_rt_xcalloc(sizeof(stack_t), 1);
	if (c_sig_stk) {
		c_sig_stk->ss_sp = eif_rt_xcalloc(SIGSTKSZ, 4);	
		if (c_sig_stk->ss_sp) {
			c_sig_stk->ss_flags = 0;
			c_sig_stk->ss_size = 4 * SIGSTKSZ;

			if (sigaltstack(c_sig_stk, NULL) != 0) {
				eif_rt_xfree(c_sig_stk->ss_sp);
				eif_rt_xfree(c_sig_stk);
				c_sig_stk = NULL;
			}
		} else {
			eif_rt_xfree (c_sig_stk);
			c_sig_stk = NULL;
		}
	}
#endif


#ifdef EIF_THREADS
	if (eif_thr_is_root()) {
#endif

	for (sig = 1; sig < EIF_NSIG; sig++) {
		old = SIG_IGN;
		/* Default to be ignored before handler installation,
		 * in order to avoid immediate signal handling after 
		 * handler installation, when flags have not been 
		 * correctly set. 
		 * See bug#10736. The following commands caused runtime panic on Solaris:
		 *  sh
		 *  cd /
		 *  cat /dev/null | ec
		 */
		sig_ign[sig] = 1; 

#ifdef EIF_THREADS
	/* In Multi-threaded mode, we do not want to call
     * signal () on some specific signals.
	 */
	switch (sig) {
	
#ifdef EIF_DFLT_SIGUSR
		/* So far, used in Linux threads */
		case SIGUSR1:
			break;

		case SIGUSR2:
			break;
#endif /* EIF_DFLT_SIGUSR */

#ifdef EIF_DFLT_SIGVTALARM
		/* So far, used in PCTHREADS (obsolete, anyway) */
		case SIGVTALRM:
			break;
#endif /* EIF_DFLT_SIGVTALARM */

#ifdef EIF_DFLT_SIGPTRESCHED
		/* So far, used in Posix 1003.1c threads */
		case SIGPTRESCHED:
			break;
#endif /* EIF_DFLT_SIGPTRESCHED */

#ifdef EIF_DFLT_SIGPTINTR
		/* So far, used in Posix 1003.1c */
		case SIGPTINTR:
			break;
#endif /* EIF_DFLT_SIGPTINTR */

#ifdef EIF_DFLT_SIGRTMIN
		/* So far, used in Posix 1003.1b */
		case SIGRTMIN:
			break;
#endif /* EIF_DFLT_SIGRTMIN */

#ifdef EIF_DFLT_SIGRTMAX
		/* So far, used in Posix 1003.1b */
		case SIGRTMAX:
			break;
#endif /* EIF_DFLT_SIGRTMAX */

#ifdef EIF_DFLT_SIGWAITING 
		/* So far, used in solaris threads (SunOS 5.5+ and Unixware 2.0)
		 * On solaris 2.4, it is not used, which is a bug of the thread lib 
		 */
		case SIGWAITING:
			break;
#endif /* EIF_DFLT_SIGWAITING */

/*#ifdef VXWORKS
		case 34528:
			break;
*/
#ifdef SIGPROF
		/* When profiling, we must not catch this signal.  */
		case SIGPROF:
			break;
#endif /* SIGPROF */

		default:
			if (esigdefined (sig) == (char) 1) 
				old = rt_signal(sig, ehandler);		/* Ignore EINVAL errors */
	}			
#else
		if (esigdefined (sig) == (char) 1) 
#ifdef SIGPROF
			if (sig != SIGPROF)
#endif
				old = rt_signal(sig, ehandler);		/* Ignore EINVAL errors */
#endif	/* EIF_THREADS */
		if (old == SIG_IGN)
			sig_ign[sig] = 1;			/* Signal was ignored by default */
		else
			sig_ign[sig] = 0;			/* Signal was not ignored */
		esig[sig] = (Signal_t (*)(int)) 0;	/* No Eiffel handler provided yet */ /* %%ss added cast int */
	}

	/* Hardwired defaults: ignore SIGCHLD (or SIGCLD), SIGIO, SIGURG, SIGCONT
	 * and SIGWINCH if they are defined. That is to say, the Eiffel run-time
	 * will not deliver these to the process if the user does not explicitely
	 * set a handler for them.
	 */

#ifdef SIGCHLD
	sig_ign[SIGCHLD] = 1;			/* Ignore death of a child */
	(void) rt_signal(SIGCHLD, SIG_DFL);		/* Restore the default value */
#endif
#ifdef SIGCLD
	sig_ign[SIGCLD] = 1;			/* Ignore death of a child */
#endif
#ifdef SIGIO
	sig_ign[SIGIO] = 1;				/* Ignore pending I/O on descriptor */
#endif
#ifdef SIGCONT
	sig_ign[SIGCONT] = 1;			/* Ignore continue after a stop */
#endif
#ifdef SIGURG
	sig_ign[SIGURG] = 1;			/* Ignore urgent condition on socket */
#endif
#ifdef SIGWINCH
	sig_ign[SIGWINCH] = 1;			/* Ignore window size change */
	(void) rt_signal(SIGWINCH, SIG_IGN);
#endif
#ifdef SIGTTIN
	sig_ign[SIGTTIN] = 1;			/* Ignore background input signal */
	(void) rt_signal(SIGTTIN, SIG_IGN);
#endif
#ifdef SIGTTOU
	sig_ign[SIGTTOU] = 1;			/* Ignore background output signal */
	(void) rt_signal(SIGTTOU, SIG_IGN);
#endif

	/* Do not catch SIGTSTP (stop signal from tty like ^Z under csh or ksh)
	 * otherwise job control will not be allowed. However, SIGSTOP is caught.
	 * Likewise, do not catch SIGCONT (continue signal for stopped process).
	 */

#ifdef SIGTSTP
	sig_ign[SIGTSTP] = 0;				/* Do not ignore that signal */
	(void) rt_signal(SIGTSTP, SIG_DFL);	/* Restore default behaviour */
#endif
#ifdef SIGCONT
	sig_ign[SIGCONT] = 0;				/* Do not ignore continue signal */
	(void) rt_signal(SIGCONT, SIG_DFL);	/* Restore default behaviour */
#endif

	/* It would not be wise to catch SIGTRAP: C debuggers may use this signal
	 * to do step-by-step execution and we do not want the Eiffel run-time
	 * to interfere with this particular low-level signal--RAM.
	 */

#ifdef SIGTRAP
	sig_ign[SIGTRAP] = 0;	/* Do not ignore Trap signal */
#	ifdef EIF_SGI
			/* On sgi, SIGTRAP is used as a Integer-Division-By-Zero signal */
		(void) rt_signal(SIGTRAP, exfpe);	
#	else
		(void) rt_signal(SIGTRAP, SIG_DFL);	/* Restore default behaviour */
#	endif /* EIF_SGI */
#endif

	/* Special treatment for SIGFPE -- always raise an Eiffel exception when
	 * it is caught (unless exception is explicitely ignored, but that's the
	 * handler's problem).
	 */

#ifdef SIGFPE
	sig_ign[SIGFPE] = 0;			/* Do not ignore a floating point signal */
	(void) rt_signal(SIGFPE, exfpe);	/* Raise an Eiffel exception when caught */
#endif

	/* Now save all the defaults in the special original status array, in order
	 * for the run-time to know what to do when a signal is restored to its
	 * "default" state.
	 */

	for (sig = 1; sig < EIF_NSIG; sig++)
		osig_ign[sig] = sig_ign[sig];
#ifdef EIF_THREADS
	}
#endif
}

/*
 * Eiffel signal's FIFO stack.
 */

rt_private void spush(int sig)
{
	/* Record a signal in the FIFO stack for deferred handling. If the buffer
	 * is full, we panic immediately (I chose to hardwire size, alas--RAM).
	 * As the writing in the structure can't be made atomic, unless there
	 * are BSD reliable signals out there, race conditions may occur and lead
	 * to duplicate signals and/or losses--RAM.
	 */
	RT_GET_CONTEXT
#ifndef HAS_SIGACTION
#ifdef HAS_SIGSETMASK
	 int oldmask;	/* To save old signal blocking mask */ /* %%ss addded #if ..#endif */
#endif
#endif

#ifdef DEBUG
	dprintf(1)("spush: max = %d, min = %d, signal = %d\n",
		sig_stk.s_max, sig_stk.s_min, sig);
#endif

	if (sig_stk.s_max == sig_stk.s_min)
		eif_panic(MTC "signal stack overflow");
	
	/* We do not stack multiple consecutive occurrences of the same signal (the
	 * kernel doesn't do that anyway), and "dangerous" signals raise a panic
	 * rather than being stacked if the default Eiffel handler is on.
	 */
	if (dangerous(sig) && esig[sig] == (Signal_t (*)(int)) 0) { /* %%ss added cast int */
		eif_panic(signame(sig));	/* Translate into English name and raise a run-time eif_panic */
	} else {
		int last = (sig_stk.s_max ? sig_stk.s_max : SIGSTACK) - 1;
		if (sig == sig_stk.s_buf[last])
			return;							/* Same signal already on top */
	}
#ifndef HAS_SIGACTION
#ifdef HAS_SIGSETMASK
	oldmask = sigsetmask(0xffffffff);		/* Block 31 signals */
#endif
#endif

	/* The following section is protected against being interrupted by other
	 * signals if HAS_SIGSETMASK is defined. Otherwise, it's time to pray--RAM.
	 */
	sig_stk.s_buf[sig_stk.s_max++] = (char) sig;	/* Signal < 128 */
	if (sig_stk.s_max >= SIGSTACK)			/* Reached the right end */
		sig_stk.s_max = 0;					/* Back to left end */

	sig_stk.s_pending = 1;				/* A signal is pending */

#ifndef HAS_SIGACTION
#ifdef HAS_SIGSETMASK
	(void) sigsetmask(oldmask);			/* Restore old mask */
#endif
#endif
}

rt_private int spop(void)
{
	/* Pops off a signal from the FIFO stack and returns its value. If the
	 * stack is empty, return 0.
	 */
	RT_GET_CONTEXT
	int newpos;		/* Position we'll go to if we read something */
	int cursig;					/* Current signal to be sent */

#ifndef HAS_SIGACTION
#ifdef HAS_SIGSETMASK
	int oldmask;				/* To save old signal blocking mask */ /* %%ss moved from above */
	oldmask = sigsetmask(0xffffffff);		/* Block 31 signals */
#endif
#endif

	/* The following section is protected against being interrupted by other
	 * signals if HAS_SIGSETMASK or HAS_SIGACTION is defined. Otherwise,
	 * nothing guaranteed--RAM.
	 */
	newpos = sig_stk.s_min + 1;	/* s_min is the last successfully read pos */
	if (newpos >= SIGSTACK)			/* If we overflow */
		newpos = 0;					/* Go back to the left end */

	if (sig_stk.s_max == newpos) {	/* Nothing to be read */
#ifndef HAS_SIGACTION
#ifdef HAS_SIGSETMASK
		(void) sigsetmask(oldmask);	/* Restore old mask */
#endif
#endif
		sig_stk.s_pending = 0;		/* No more pending signals */
		return 0;					/* Return end of stack condition */
	}
	
	/* Now update the stack structure and do not forget to "clear" the last
	 * signal on the stack (i.e. the one we are about to deal with). This is
	 * actually only important when that signal is the only pending one,
	 * because spush() makes sure we are not queuing two consecutives occurrences
	 * of the same signal, and the location checked is the one before s_max.
	 */

	sig_stk.s_min = newpos;			/* Update last read position */
	cursig = (int) sig_stk.s_buf[newpos];
	sig_stk.s_buf[newpos] = 0;		/* Clear "last" signal on stack */

#ifdef DEBUG
	dprintf(1)("spop: returning signal #%d\n", cursig);
#endif

#ifndef HAS_SIGACTION
#ifdef HAS_SIGSETMASK
	(void) sigsetmask(oldmask);		/* Restore old mask */
#endif
#endif

	return cursig;			/* Signal to be dealt with */
}

/*
 * Signal meaning (English description of a signal).
 */

struct sig_desc {			/* Signal description structure */
	int idx;				/* Index for Eiffel/C mapping */
	int s_num;				/* Signal number */
	char *s_desc;			/* English description */
};

/*
doc:	<attribute name="sig_name" return_type="struct sig_desc []" export="private">
doc:		<summary>The following array describes the signals. Instead of having a big switch and #ifdef'ed cases, it is best to have the structure sig_desc. True, we need a linear look-up to find the description, but many systems overload signals, so the switch statement would be quickly un-manageable--RAM.  Message limit is 28 char..., sorry (to get a nice execution stack).</summary>
doc:		<access>Read</access>
doc:		<thread_safety>Safe</thread_safety>
doc:		<synchronization>None since statically initialized.</synchronization>
doc:	</attribute>
*/
rt_private struct sig_desc sig_name[] = {
#ifdef SIGHUP
	{ 1, SIGHUP, "Hangup" },
#endif
#ifdef SIGINT
	{ 2, SIGINT, "Interrupt" },
#endif
#ifdef SIGQUIT
	{ 3, SIGQUIT, "Quit" },
#endif
#ifdef SIGILL
	{ 4, SIGILL, "Illegal instruction" },
#endif
#ifdef SIGTRAP
#	ifdef EIF_SGI
	{ 5, SIGTRAP, "Trace trap or Divide-by-zero" },
#	else
	{ 5, SIGTRAP, "Trace trap" },
#	endif	/* EIF_SGI */
#endif
#ifdef SIGABRT
	{ 6, SIGABRT, "Abort" },
#endif
#ifdef SIGIOT
	{ 7, SIGIOT, "IOT instruction" },
#endif
#ifdef SIGEMT
	{ 8, SIGEMT, "EMT instruction" },
#endif
#ifdef SIGFPE
	{ 9, SIGFPE, "Floating point exception" },
#endif
#ifdef SIGKILL
	{ 10, SIGKILL, "Terminator" },
#endif
#ifdef SIGBUS
	{ 11, SIGBUS, "Bus error" },
#endif
#ifdef SIGSEGV
	{ 12, SIGSEGV, "Segmentation violation" },
#endif
#ifdef SIGSYS
	{ 13, SIGSYS, "Bad argument to system call" },
#endif
#ifdef SIGPIPE
	{ 14, SIGPIPE, "Broken pipe" },
#endif
#ifdef SIGALRM
	{ 15, SIGALRM, "Alarm clock" },
#endif
#ifdef SIGTERM
	{ 16, SIGTERM, "Software termination" },
#endif
#ifdef SIGUSR1
	{ 17, SIGUSR1, "User-defined signal #1" },
#endif
#ifdef SIGUSR2
	{ 18, SIGUSR2, "User-defined signal #2" },
#endif
#ifdef SIGCHLD
	{ 19, SIGCHLD, "Death of a child" },
#endif
#ifdef SIGCLD
	{ 20, SIGCLD, "Death of a child" },
#endif
#ifdef SIGIO
	{ 21, SIGIO, "Pending I/O on a descriptor" },
#endif
#ifdef SIGPOLL
	{ 22, SIGPOLL, "Selectable event pending" },
#endif
#ifdef SIGTTIN
	{ 23, SIGTTIN, "Tty input from background" },
#endif
#ifdef SIGTTOU
	{ 24, SIGTTOU, "Tty output from background" },
#endif
#ifdef SIGSTOP
	{ 25, SIGSTOP, "Stop" },
#endif
#ifdef SIGTSTP
	{ 26, SIGTSTP, "Stop from tty" },
#endif
#ifdef SIGXCPU
	{ 27, SIGXCPU, "Cpu time limit exceeded" },
#endif
#ifdef SIGXFSZ
	{ 28, SIGXFSZ, "File size limit exceeded" },
#endif
#ifdef SIGVTALRM
	{ 29, SIGVTALRM, "Virtual time alarm" },
#endif
#ifdef SIGPWR
	{ 30, SIGPWR, "Power-fail" },
#endif
#ifdef SIGPROF
	{ 31, SIGPROF, "Profiling timer alarm" },
#endif
#ifdef SIGWINCH
	{ 32, SIGWINCH, "Window size changed" },
#endif
#ifdef SIGWIND
	{ 33, SIGWIND, "Window change" },
#endif
#ifdef SIGPHONE
	{ 34, SIGPHONE, "Line status change" },
#endif
#ifdef SIGLOST
	{ 35, SIGLOST, "Resource lost" },
#endif
#ifdef SIGURG
	{ 36, SIGURG, "Urgent condition on socket" },
#endif
#ifdef SIGCONT
	{ 37, SIGCONT, "Continue after stop" },
#endif
#ifdef SIGBREAK
	{ 38, SIGBREAK, "Ctrl-Break"},
#endif
	{ 39, 0, "Unknown signal" }
};

rt_public char *signame(int sig)
{
	/* Returns a description of a signal given its number. If sys_siglist[]
	 * is available and gives a non-null description, then use it. Otherwise
	 * use our own description as found in the sig_name array.
	 */

	int i;

#ifdef HAS_SYS_SIGLIST
	if (sig >= 0 && sig < EIF_NSIG && 0 < (unsigned int)strlen(sys_siglist[sig]))
		return (char *) sys_siglist[sig];
#endif

	for (i = 0; /*empty */; i++)
		if (sig == sig_name[i].s_num || 0 == sig_name[i].s_num)
			return sig_name[i].s_desc;
}

/*
 * Eiffel interface
 */

rt_public long esigmap(long int idx)
{
	/* C signal code for signal of index `idx' */

	int i;

	for (i = 0; /*empty */ ; i++)
		if (((int) idx) == sig_name[i].idx || 0 == sig_name[i].s_num)
			return (long) (sig_name[i].s_num);
}

rt_public char *esigname(long int sig)
{
	/* Returns a description of a signal given its number. If sys_siglist[]
	 * is available and gives a non-null description, then use it. Otherwise
	 * use our own description as found in the sig_name array.
	 * Same as `signame' with proper casting for Eiffel.
	 */

	return (signame((int) sig));
} 

rt_public long esignum(EIF_CONTEXT_NOARG)	/* %%zmt never called in C dir. */
{
	/* Number of last signal */
	EIF_GET_CONTEXT

	return (long) echsig;
}

rt_public void esigcatch(long int sig)
{
	/* Catch signal `sig'.
	 * Check that the signal is defined
	 */

	if (!(esigdefined(sig) == (char) 1))
		return;

	/* We may not change the status of SIGPROF because it is possible
	 * that we do (run-time) external profiling. Changing the catch
	 * status of this signal means that profiling stops.
	 */

#ifdef SIGPROF
	if (sig == SIGPROF)
		return;
#endif

	sig_ign[sig] = 0;
#ifdef SIGTTIN
	if (sig == SIGTTIN) {
		(void) rt_signal(SIGTTIN, SIG_DFL);	/* Ignore background input signal */
		return;
	}
#endif
#ifdef SIGTTOU
	if (sig == SIGTTOU) {
		(void) rt_signal(SIGTTOU, SIG_DFL);	/* Ignore background output signal */
		return;
	}
#endif
#ifdef SIGTSTP
	if (sig == SIGTSTP) {
		(void) rt_signal(SIGTSTP, SIG_DFL);	/* Restore default behaviour */
		return;
	}
#endif
#ifdef SIGCONT
	if (sig == SIGCONT) {
		(void) rt_signal(SIGCONT, SIG_DFL);	/* Restore default behaviour */
		return;
	}
#endif
#ifdef SIGTRAP
	if (sig == SIGTRAP) {
#	ifdef EIF_SGI
		(void) rt_signal(SIGTRAP, exfpe); 	/* Integer-Division-by-Zero on sgi */
#	else
		(void) rt_signal(SIGTRAP, SIG_DFL);	/* Restore default behaviour */
#	endif
		return;
	}
#endif
#ifdef SIGFPE
	if (sig == SIGFPE) {
		(void) rt_signal(SIGFPE, exfpe);		/* Raise an Eiffel exception when caught */
		return;
	}
#endif
}

rt_public void esigignore(long int sig)
{
	/* Ignore signal `sig'.
	 * Check that the signal is defined
     */

	if (!(esigdefined(sig) == (char) 1))
		return;

	/* We may not change the status of SIGPROF because it is possible
	 * that we do (run-time) external profiling. Changing the catch
	 * status of this signal means that profiling stops.
	 */

#ifdef SIGPROF
	if (sig == SIGPROF)
		return;
#endif

	sig_ign[sig] = 1;
#ifdef SIGTTIN
	if (sig == SIGTTIN) {
		(void) rt_signal(SIGTTIN, SIG_IGN);	
		return;
	}
#endif
#ifdef SIGTTOU
	if (sig == SIGTTOU) {
		(void) rt_signal(SIGTTOU, SIG_IGN);
		return;
	}
#endif
#ifdef SIGTSTP
	if (sig == SIGTSTP) {
		(void) rt_signal(SIGTSTP, SIG_IGN);
		return;
	}
#endif
#ifdef SIGCONT
	if (sig == SIGCONT) {
		(void) rt_signal(SIGCONT, SIG_IGN);
		return;
	}
#endif
#ifdef SIGTRAP
	if (sig == SIGTRAP) {
		(void) rt_signal(SIGTRAP, SIG_IGN);
		return;
	}
#endif
#ifdef SIGFPE
	if (sig == SIGFPE) {
		(void) rt_signal(SIGFPE, SIG_IGN);	
		return;
	}
#endif
}

rt_public char esigiscaught(long int sig)
{
	/* Is signal of number `sig' caught?
	 * Check that the signal is defined
     */

	if (esigdefined(sig) == (char) 1)
		return (char) ((sig_ign[sig] == 1)? 0: 1);
	else
		return (char) 0;
}

rt_public char esigdefined (long int sig)
{
	/* Id signal of number `sig' defined? */

	int i;

	if (sig < 1 || sig > EIF_NSIG-1)
		return (char) 0;
	for (i = 0; /*empty */; i++) {
		if ((int) sig == sig_name[i].s_num) 
			return (char) 1;
		else
			if (0 == sig_name[i].s_num)
				return (char) 0;
	}
}

void esigresall(void)
{
	/* Reset all the signals to their default handling */
	int sig;
	for (sig = 1; sig < EIF_NSIG; sig++)
#ifdef SIGPROF
		if (sig != SIGPROF)
			sig_ign[sig] = osig_ign[sig];
#else
		sig_ign[sig] = osig_ign[sig];
#endif
	
#ifdef SIGTTIN
	(void) rt_signal(SIGTTIN, SIG_IGN);/* Ignore background input signal */
#endif
#ifdef SIGTTOU
	(void) rt_signal(SIGTTOU, SIG_IGN);/* Ignore background output signal */
#endif
#ifdef SIGTSTP
	(void) rt_signal(SIGTSTP, SIG_DFL);	/* Restore default behaviour */
#endif
#ifdef SIGCONT
	(void) rt_signal(SIGCONT, SIG_DFL);	/* Restore default behaviour */
#endif
#ifdef SIGTRAP
#	ifdef EIF_SGI
		(void) rt_signal(SIGTRAP, exfpe);
#	else
		(void) rt_signal(SIGTRAP, SIG_DFL);	/* Restore default behaviour */
#	endif /* EIF_SGI */
#endif
#ifdef SIGFPE
	(void) rt_signal(SIGFPE, exfpe);	/* Raise an Eiffel exception when caught */
#endif
}

void esigresdef(long int sig)
{

	/* Reset signal `sig' to its default handling */
	if (!(esigdefined(sig) == (char) 1))
		return;

	/* We may not change the status of SIGPROF because it is possible
	 * that we do (run-time) external profiling. Changing the catch
	 * status of this signal means that profiling stops.
	 */

#ifdef SIGPROF
	if (sig == SIGPROF)
		return;
#endif

	sig_ign[sig] = osig_ign[sig];
#ifdef SIGTTIN
	if (sig == SIGTTIN) {
		(void) rt_signal(SIGTTIN, SIG_IGN);	/* Ignore background input signal */
		return;
	}
#endif
#ifdef SIGTTOU
	if (sig == SIGTTOU) {
	 	(void) rt_signal(SIGTTOU, SIG_IGN);	/* Ignore background output signal */
		return;
	}
#endif
#ifdef SIGTSTP
	if (sig == SIGTSTP) {
		(void) rt_signal(SIGTSTP, SIG_DFL);	/* Restore default behaviour */
		return;
	}
#endif
#ifdef SIGCONT
	if (sig == SIGCONT) {
		(void) rt_signal(SIGCONT, SIG_DFL);	/* Restore default behaviour */
		return;
	}
#endif
#ifdef SIGTRAP
	if (sig == SIGTRAP) {
#	ifdef EIF_SGI
		(void) rt_signal(SIGTRAP, exfpe);	/* Restore default behaviour */
#	else
		(void) rt_signal(SIGTRAP, SIG_DFL);	/* Restore default behaviour */
#	endif /* EIF_SGI */
		return;
	}
#endif
#ifdef SIGFPE
	if (sig == SIGFPE) {
		(void) rt_signal(SIGFPE, exfpe);		/* Raise an Eiffel exception when caught */
		return;
	}
#endif
}


#ifdef EIF_VMS	/* signal handling control for CECIL only on VMS for now */
void esig_cecil_register (struct ex_vect* exvp)
{
	esig_cecil_exvect = exvp;
}

void esig_cecil_enter (void)
{
	++esig_cecil_call_nest_level;
}

void esig_cecil_exit (void)
{
	--esig_cecil_call_nest_level;
}
#endif /* EIF_VMS */


#ifdef TEST

/* This section implements a set of tests for the signal handling package.
 * It should not be regarded as a model of C programming :-)
 * To run this, compile the file with -DTEST.
 */

struct eif_exception exdata;	/* Exception handling global flags */
rt_private int bufstate(void);	/* Print circular buffer state */

Signal_t test_handler(int sig)
{
	printf("test_handler: caught signal #%d\n", sig);
}

int main (void)
{
	printf("> Starting test for signal handling mechanism.\n");
	printf(">> Initializing signals.\n");
	initsig();
	printf(">> Installing test_handler.\n");
	esig[2] = test_handler;
	printf(">> Sending first signal #2.\n");
	kill(getpid(), 2);
	printf(">> Sending second signal #2.\n");
	kill(getpid(), 2);
	printf(">> Inhibing signals.\n");
	esigblk = 1;
	bufstate();
	printf(">> Sending signal #2.\n");
	kill(getpid(), 2);
	bufstate();
	printf(">> Sending signal #1.\n");
	kill(getpid(), 1);
	bufstate();
	printf(">> Restauring signal handling.\n");
	esigblk = 0;
	if (signal_pending) {
		printf(">> There are signal pending.\n");
	} else {
		printf(">> FAILED!! NO SIGNAL PENDING.\n");
		exit(1);
	}
	printf(">> Dispatching pending signals.\n");
	esdpch();
	bufstate();
	if (signal_pending) {
		printf(">> FAILED!! THERE IS A SIGNAL PENDING.\n");
		exit(1);
	} else {
		printf(">> There are no more signal pending.\n");
	}
#ifdef SIGCHLD
	printf(">> Sending ignored signal SIGCHLD.\n");
	kill(getpid(), SIGCHLD);
#else
	printf(">> Sending ignored signal SIGCLD.\n");
	kill(getpid(), SIGCLD);
#endif
	printf(">> Sending exception raising signal #1.\n");
	kill(getpid(), 1);
	printf("> End of tests.\n");

	return 0;
}

rt_private int bufstate(void)
{
	/* Give circular buffer state */

	printf(">>> Circular buffer: min = %d, max = %d\n",
		sig_stk.s_min, sig_stk.s_max);
}

/* Functions not provided here */
rt_public void eif_panic(char *s)
{
	printf("PANIC: %s\n", s);
	exit(1);
}

rt_public void xraise(int val)
{
	printf("xraise: exception code %d\n", val);
}

rt_public void exhdlr(Signal_t (*handler)(int), int sig)
{
	(handler)(sig);		/* Call handler */
}

#endif

/*
doc:</file>
*/
