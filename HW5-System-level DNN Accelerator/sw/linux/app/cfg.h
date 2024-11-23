// Copyright (c) 2011-2021 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef __ESP_CFG_000_H__
#define __ESP_CFG_000_H__

#include "libesp.h"
#include "lenet_rtl.h"

typedef int32_t token_t;

/* <<--params-def-->> */
#define SCALE_CONV2 8
#define SCALE_CONV3 8
#define SCALE_CONV1 8
#define SCALE_FC2 8
#define SCALE_FC1 8

/* <<--params-->> */
const int32_t scale_CONV2 = SCALE_CONV2;
const int32_t scale_CONV3 = SCALE_CONV3;
const int32_t scale_CONV1 = SCALE_CONV1;
const int32_t scale_FC2 = SCALE_FC2;
const int32_t scale_FC1 = SCALE_FC1;

#define NACC 1

struct lenet_rtl_access lenet_cfg_000[] = {
	{
		/* <<--descriptor-->> */
		.scale_CONV2 = SCALE_CONV2,
		.scale_CONV3 = SCALE_CONV3,
		.scale_CONV1 = SCALE_CONV1,
		.scale_FC2 = SCALE_FC2,
		.scale_FC1 = SCALE_FC1,
		.src_offset = 0,
		.dst_offset = 0,
		.esp.coherence = ACC_COH_NONE,
		.esp.p2p_store = 0,
		.esp.p2p_nsrcs = 0,
		.esp.p2p_srcs = {"", "", "", ""},
	}
};

esp_thread_info_t cfg_000[] = {
	{
		.run = true,
		.devname = "lenet_rtl.0",
		.ioctl_req = LENET_RTL_IOC_ACCESS,
		.esp_desc = &(lenet_cfg_000[0].esp),
	}
};

#endif /* __ESP_CFG_000_H__ */
