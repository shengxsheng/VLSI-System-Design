// Copyright (c) 2011-2021 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef _LENET_RTL_H_
#define _LENET_RTL_H_

#ifdef __KERNEL__
#include <linux/ioctl.h>
#include <linux/types.h>
#else
#include <sys/ioctl.h>
#include <stdint.h>
#ifndef __user
#define __user
#endif
#endif /* __KERNEL__ */

#include <esp.h>
#include <esp_accelerator.h>

struct lenet_rtl_access {
	struct esp_access esp;
	/* <<--regs-->> */
	unsigned scale_CONV2;
	unsigned scale_CONV3;
	unsigned scale_CONV1;
	unsigned scale_FC2;
	unsigned scale_FC1;
	unsigned src_offset;
	unsigned dst_offset;
};

#define LENET_RTL_IOC_ACCESS	_IOW ('S', 0, struct lenet_rtl_access)

#endif /* _LENET_RTL_H_ */
