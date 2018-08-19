/*
 * libdpkg - Debian packaging suite library routines
 * vercmp.c - comparison of version numbers
 *
 * Copyright © 1995 Ian Jackson <ian@chiark.greenend.org.uk>
 *
 * This is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2,
 * or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with dpkg; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#define order(x) ((x) == '~' ? -1 \
		: isdigit((x)) ? 0 \
		: !(x) ? 0 \
		: isalpha((x)) ? (x) \
		: (x) + 256)

static int verrevcmp(const char *val, const char *ref) {
    if (!val) val= "";
    if (!ref) ref= "";

    while (*val || *ref) {
        int first_diff= 0;

        while ( (*val && !isdigit(*val)) || (*ref && !isdigit(*ref)) ) {
            int vc= order(*val), rc= order(*ref);
            if (vc != rc) return vc - rc;
            val++; ref++;
        }

        while ( *val == '0' ) val++;
        while ( *ref == '0' ) ref++;
        while (isdigit(*val) && isdigit(*ref)) {
            if (!first_diff) first_diff= *val - *ref;
            val++; ref++;
        }
        if (isdigit(*val)) return 1;
        if (isdigit(*ref)) return -1;
        if (first_diff) return first_diff;
    }
    return 0;
}
