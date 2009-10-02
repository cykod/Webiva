#include "ruby.h"
#include "rubysig.h"
#include <signal.h>
#include <errno.h>

#define DISPLAY_ERRNO 	 		 1
#define DO_NOT_DISPLAY_ERRNO 0

VALUE rb_cSystemTimer;
sigset_t original_mask;
sigset_t sigalarm_mask;
struct sigaction original_signal_handler;
struct itimerval original_timer_interval;

static void clear_pending_sigalrm_for_ruby_threads();
static void log_debug(char*);
static void log_error(char*, int);
static void install_ruby_sigalrm_handler(VALUE);
static void restore_original_ruby_sigalrm_handler(VALUE);
static void restore_original_sigalrm_mask_when_blocked();
static void restore_original_timer_interval();
static void set_itimerval(struct itimerval *, int);

static int debug_enabled = 0;

static VALUE install_timer(VALUE self, VALUE seconds)
{
  struct itimerval timer_interval;

	/*
	 * Block SIG_ALRM for safe processing of SIG_ALRM configuration and save mask.
	 */
	if (0 != sigprocmask(SIG_BLOCK, &sigalarm_mask, &original_mask)) {
		log_error("install_timer: Could not block SIG_ALRM", DISPLAY_ERRNO);
		return Qnil;
	}
	clear_pending_sigalrm_for_ruby_threads();
	log_debug("install_timer: Succesfully blocked SIG_ALRM at O.S. level");
	
  /*
   * Save previous signal handler.
   */
	original_signal_handler.sa_handler = NULL;
  if (0 != sigaction(SIGALRM, NULL, &original_signal_handler)) {
		log_error("install_timer: Could not save existing handler for SIG_ALRM", DISPLAY_ERRNO);
		restore_original_sigalrm_mask_when_blocked();
		return Qnil;
  }
	log_debug("install_timer: Succesfully saved existing SIG_ALRM handler");

	/*
	 * Install Ruby Level SIG_ALRM handler
	 */
	install_ruby_sigalrm_handler(self);

  /*
   * Set new real time interval timer and save the original if any.
   */	
	set_itimerval(&original_timer_interval, 0);
  set_itimerval(&timer_interval, NUM2INT(seconds));
  if (0 != setitimer(ITIMER_REAL, &timer_interval, &original_timer_interval)) {
		log_error("install_timer: Could not install our own timer, timeout will not work", DISPLAY_ERRNO);
		restore_original_ruby_sigalrm_handler(self);
		restore_original_sigalrm_mask_when_blocked();
	  return Qnil;
  }
	log_debug("install_timer: Successfully installed timer");

  /*
   * Unblock SIG_ALRM
   */
	if (0 != sigprocmask(SIG_UNBLOCK, &sigalarm_mask, NULL)) {
		log_error("install_timer: Could not unblock SIG_ALRM, timeout will not work", DISPLAY_ERRNO);
		restore_original_timer_interval();
		restore_original_ruby_sigalrm_handler(self);
		restore_original_sigalrm_mask_when_blocked();		
	}
	log_debug("install_timer: Succesfully unblocked SIG_ALRM.");

	return Qnil;
}

static VALUE cleanup_timer(VALUE self, VALUE seconds)
{
	/*
	 * Block SIG_ALRM for safe processing of SIG_ALRM configuration.
	 */
	if (0 != sigprocmask(SIG_BLOCK, &sigalarm_mask, NULL)) {
		log_error("cleanup_timer: Could not block SIG_ALRM", errno);
	}
	clear_pending_sigalrm_for_ruby_threads();
	log_debug("cleanup_timer: Blocked SIG_ALRM");

	/*
	 * Install Ruby Level SIG_ALRM handler
	 */
	restore_original_ruby_sigalrm_handler(self);
	
	
	if (original_signal_handler.sa_handler == NULL) {
		log_error("cleanup_timer: Previous SIG_ALRM handler not initialized!", DO_NOT_DISPLAY_ERRNO);
	} else if (0 == sigaction(SIGALRM, &original_signal_handler, NULL)) {
		log_debug("cleanup_timer: Succesfully restored previous handler for SIG_ALRM");
  } else {
		log_error("cleanup_timer: Could not restore previous handler for SIG_ALRM", DISPLAY_ERRNO);
	}
	original_signal_handler.sa_handler = NULL;
	
	restore_original_timer_interval();	
	restore_original_sigalrm_mask_when_blocked();	
}

/*
 * Restore original timer the way it was originally set. **WARNING** Breaks original timer semantics
 *
 *   Not bothering to calculate how much time is left or if the timer already expired
 *   based on when the original timer was set and how much time is passed, just resetting 
 *   the original timer as is for the sake of simplicity.
 *
 */
static void restore_original_timer_interval() {
  if (0 != setitimer (ITIMER_REAL, &original_timer_interval, NULL)) {
		log_error("install_timer: Could not restore original timer", DISPLAY_ERRNO);
  }
	log_debug("install_timer: Successfully restored timer");	
}

static void restore_original_sigalrm_mask_when_blocked() 
{
	if (!sigismember(&original_mask, SIGALRM)) {
		sigprocmask(SIG_UNBLOCK, &sigalarm_mask, NULL);
		log_debug("cleanup_timer: Unblocked SIG_ALRM");
	} else {
		log_debug("cleanup_timer: No Need to unblock SIG_ALRM");
	}	
}

static void install_ruby_sigalrm_handler(VALUE self) {
  rb_thread_critical = 1;
	rb_funcall(self, rb_intern("install_ruby_sigalrm_handler"), 0);
	rb_thread_critical = 0;
}

static void restore_original_ruby_sigalrm_handler(VALUE self) {
  rb_thread_critical = 1;
	rb_funcall(self, rb_intern("restore_original_ruby_sigalrm_handler"), 0);
  rb_thread_critical = 0;
}


static VALUE debug_enabled_p(VALUE self) {
	return debug_enabled ? Qtrue : Qfalse;
}

static VALUE enable_debug(VALUE self) {
	debug_enabled = 1;
	return Qnil;
}

static VALUE disable_debug(VALUE self) {
	debug_enabled = 0;
	return Qnil;	
}

static void log_debug(char* message) 
{
	if (0 != debug_enabled) {
		printf("%s\n", message);
	}
	return;
}

static void log_error(char* message, int display_errno)
{
	fprintf(stderr, "%s: %s\n", message, display_errno ? strerror(errno) : "");
	return;
}

/*
 * The intent is to clear SIG_ALRM signals at the Ruby level (green threads),
 * eventually triggering existing SIG_ALRM handler as a courtesy.
 * 
 * As we cannot access trap_pending_list outside of signal.c our best fallback option
 * is to trigger all pending signals at the Ruby level (potentially triggering
 * green thread scheduling).
 */
static void clear_pending_sigalrm_for_ruby_threads()
{
	CHECK_INTS;
	log_debug("Succesfully triggered all pending signals at Green Thread level");
}

static void init_sigalarm_mask() 
{
	sigemptyset(&sigalarm_mask);
	sigaddset(&sigalarm_mask, SIGALRM);
	return;
}

static void set_itimerval(struct itimerval *value, int seconds) {
	value->it_interval.tv_usec = 0;
  value->it_interval.tv_sec = 0;
	value->it_value.tv_usec = 0;
  value->it_value.tv_sec = seconds; // (long int) 
	return;
}

void Init_system_timer_native() 
{
	init_sigalarm_mask();
  rb_cSystemTimer = rb_define_module("SystemTimer");
	rb_define_singleton_method(rb_cSystemTimer, "install_timer", 	install_timer, 1);
	rb_define_singleton_method(rb_cSystemTimer, "cleanup_timer", 	cleanup_timer, 0);
	rb_define_singleton_method(rb_cSystemTimer, "debug_enabled?", debug_enabled_p, 0);
	rb_define_singleton_method(rb_cSystemTimer, "enable_debug", 	enable_debug, 0);
	rb_define_singleton_method(rb_cSystemTimer, "disable_debug",	disable_debug, 0);
}
