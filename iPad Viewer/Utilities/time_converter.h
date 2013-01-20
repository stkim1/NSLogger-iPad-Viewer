//
//  mktime64.h
//  TimeConversion
//
//  Created by Almighty Kim on 1/11/13.
//  Copyright (c) 2013 Colorful Glue. All rights reserved.
//
#include <sys/time.h>

static inline
uint64_t convert_timeval(struct timeval *tm)
{
	uint64_t time = 0;
	time = tm->tv_sec;
	time <<= 32;
	time |= tm->tv_usec;
	return time;
}

static inline
struct timeval convert_time64(uint64_t tm)
{
	uint32_t tv_sec = (uint32_t)(tm >> 32);
	uint32_t tv_usec = (uint32_t)tm;
	struct timeval time = {tv_sec,tv_usec};

	return time;
}