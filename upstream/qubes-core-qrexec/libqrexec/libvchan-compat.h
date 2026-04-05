/*
 * Compatibility wrapper for Xen libvchan header naming.
 */

#pragma once

#if defined(__has_include)
# if __has_include(<libvchan.h>)
#  include <libvchan.h>
# elif __has_include(<libxenvchan.h>)
#  include <libxenvchan.h>
# else
#  error "Neither libvchan.h nor libxenvchan.h is available"
# endif
#else
# include <libvchan.h>
#endif
