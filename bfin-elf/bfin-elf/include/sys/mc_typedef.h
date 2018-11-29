/*
 * Copyright (C) 2012 Analog Devices Inc.  All rights reserved.
 *
 * Licensed under the Clear BSD license.
 * Please see COPYING.LIBGLOSS for details.
 */

#pragma once
#ifndef __NO_BUILTIN
#pragma system_header /* sys/mc_typedef.h */
#endif
/************************************************************************
 *
 * sys/mc_typedef.h
 *
 ************************************************************************/

/* Define testset_t. */

#ifndef _SYS_MC_TYPEDEF_H
#define _SYS_MC_TYPEDEF_H

#if !defined(__ADSPLPBLACKFIN__)
  typedef volatile unsigned char testset_t;
#elif defined(__WORKAROUND_TESTSET_ALIGN) || defined(__WORKAROUND_05000412)
  /* these workarounds require 32-bit aligned address */
  typedef volatile unsigned int testset_t;
#else
  typedef volatile unsigned short testset_t;
#endif

#endif /* _SYS_MC_TYPEDEF_H */
