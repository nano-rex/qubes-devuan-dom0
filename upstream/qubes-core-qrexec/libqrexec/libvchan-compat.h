/*
 * Compatibility wrapper for Xen libvchan header naming and API shape.
 */

#pragma once

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#if defined(__has_include)
# if __has_include(<libxenvchan.h>)
#  include <libxenvchan.h>
#  include <xenstore.h>

typedef int EVTCHN;
typedef struct libxenvchan libvchan_t;

#  ifndef VCHAN_DISCONNECTED
#   define VCHAN_DISCONNECTED 0
#  endif
#  ifndef VCHAN_CONNECTED
#   define VCHAN_CONNECTED 1
#  endif
#  ifndef VCHAN_WAITING
#   define VCHAN_WAITING 2
#  endif

static inline int qubes_libvchan_self_domid(void)
{
    struct xs_handle *xs;
    char *val;
    unsigned int len = 0;
    int domid = -1;

    xs = xs_open(0);
    if (!xs)
        return -1;

    val = xs_read(xs, XBT_NULL, "domid", &len);
    if (val) {
        domid = atoi(val);
        free(val);
    }
    xs_close(xs);
    return domid;
}

static inline char *qubes_libvchan_xs_path(int server_domid, int client_domid, int port)
{
    char *path;
    if (asprintf(&path, "/local/domain/%d/data/vchan/%d/%d", server_domid, client_domid, port) < 0)
        return NULL;
    return path;
}

static inline libvchan_t *libvchan_server_init(int domain, int port, size_t read_min, size_t write_min)
{
    int self_domid = qubes_libvchan_self_domid();
    char *xs_path;
    libvchan_t *ret;

    if (self_domid < 0)
        return NULL;

    xs_path = qubes_libvchan_xs_path(self_domid, domain, port);
    if (!xs_path)
        return NULL;

    ret = libxenvchan_server_init(NULL, domain, xs_path, read_min, write_min);
    free(xs_path);
    return ret;
}

static inline libvchan_t *libvchan_client_init(int domain, int port)
{
    int self_domid = qubes_libvchan_self_domid();
    char *xs_path;
    libvchan_t *ret;

    if (self_domid < 0)
        return NULL;

    xs_path = qubes_libvchan_xs_path(domain, self_domid, port);
    if (!xs_path)
        return NULL;

    ret = libxenvchan_client_init(NULL, domain, xs_path);
    free(xs_path);
    return ret;
}

static inline libvchan_t *libvchan_client_init_async(int domain, int port, EVTCHN *wait_fd)
{
    libvchan_t *ret = libvchan_client_init(domain, port);
    if (ret && wait_fd)
        *wait_fd = libxenvchan_fd_for_select(ret);
    return ret;
}

static inline int libvchan_client_init_async_finish(libvchan_t *ctrl, bool blocking)
{
    if (!ctrl)
        return -1;
    ctrl->blocking = blocking;
    return libxenvchan_is_open(ctrl) == VCHAN_CONNECTED ? 0 : 1;
}

#  define libvchan_write libxenvchan_write
#  define libvchan_send libxenvchan_send
#  define libvchan_read libxenvchan_read
#  define libvchan_recv libxenvchan_recv
#  define libvchan_wait libxenvchan_wait
#  define libvchan_close libxenvchan_close
#  define libvchan_fd_for_select libxenvchan_fd_for_select
#  define libvchan_is_open libxenvchan_is_open
#  define libvchan_data_ready libxenvchan_data_ready
#  define libvchan_buffer_space libxenvchan_buffer_space
# elif __has_include(<libvchan.h>)
#  include <libvchan.h>
# else
#  error "Neither libvchan.h nor libxenvchan.h is available"
# endif
#else
# include <libvchan.h>
#endif
