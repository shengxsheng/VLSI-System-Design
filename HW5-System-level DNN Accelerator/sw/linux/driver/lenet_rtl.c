// Copyright (c) 2011-2021 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#include <linux/of_device.h>
#include <linux/mm.h>

#include <asm/io.h>

#include <esp_accelerator.h>
#include <esp.h>

#include "lenet_rtl.h"

#define DRV_NAME	"lenet_rtl"

/* <<--regs-->> */
#define LENET_SCALE_CONV2_REG 0x50
#define LENET_SCALE_CONV3_REG 0x4c
#define LENET_SCALE_CONV1_REG 0x48
#define LENET_SCALE_FC2_REG 0x44
#define LENET_SCALE_FC1_REG 0x40

struct lenet_rtl_device {
	struct esp_device esp;
};

static struct esp_driver lenet_driver;

static struct of_device_id lenet_device_ids[] = {
	{
		.name = "SLD_LENET_RTL",
	},
	{
		.name = "eb_058",
	},
	{
		.compatible = "sld,lenet_rtl",
	},
	{ },
};

static int lenet_devs;

static inline struct lenet_rtl_device *to_lenet(struct esp_device *esp)
{
	return container_of(esp, struct lenet_rtl_device, esp);
}

static void lenet_prep_xfer(struct esp_device *esp, void *arg)
{
	struct lenet_rtl_access *a = arg;

	/* <<--regs-config-->> */
	iowrite32be(a->scale_CONV2, esp->iomem + LENET_SCALE_CONV2_REG);
	iowrite32be(a->scale_CONV3, esp->iomem + LENET_SCALE_CONV3_REG);
	iowrite32be(a->scale_CONV1, esp->iomem + LENET_SCALE_CONV1_REG);
	iowrite32be(a->scale_FC2, esp->iomem + LENET_SCALE_FC2_REG);
	iowrite32be(a->scale_FC1, esp->iomem + LENET_SCALE_FC1_REG);
	iowrite32be(a->src_offset, esp->iomem + SRC_OFFSET_REG);
	iowrite32be(a->dst_offset, esp->iomem + DST_OFFSET_REG);

}

static bool lenet_xfer_input_ok(struct esp_device *esp, void *arg)
{
	/* struct lenet_rtl_device *lenet = to_lenet(esp); */
	/* struct lenet_rtl_access *a = arg; */

	return true;
}

static int lenet_probe(struct platform_device *pdev)
{
	struct lenet_rtl_device *lenet;
	struct esp_device *esp;
	int rc;

	lenet = kzalloc(sizeof(*lenet), GFP_KERNEL);
	if (lenet == NULL)
		return -ENOMEM;
	esp = &lenet->esp;
	esp->module = THIS_MODULE;
	esp->number = lenet_devs;
	esp->driver = &lenet_driver;
	rc = esp_device_register(esp, pdev);
	if (rc)
		goto err;

	lenet_devs++;
	return 0;
 err:
	kfree(lenet);
	return rc;
}

static int __exit lenet_remove(struct platform_device *pdev)
{
	struct esp_device *esp = platform_get_drvdata(pdev);
	struct lenet_rtl_device *lenet = to_lenet(esp);

	esp_device_unregister(esp);
	kfree(lenet);
	return 0;
}

static struct esp_driver lenet_driver = {
	.plat = {
		.probe		= lenet_probe,
		.remove		= lenet_remove,
		.driver		= {
			.name = DRV_NAME,
			.owner = THIS_MODULE,
			.of_match_table = lenet_device_ids,
		},
	},
	.xfer_input_ok	= lenet_xfer_input_ok,
	.prep_xfer	= lenet_prep_xfer,
	.ioctl_cm	= LENET_RTL_IOC_ACCESS,
	.arg_size	= sizeof(struct lenet_rtl_access),
};

static int __init lenet_init(void)
{
	return esp_driver_register(&lenet_driver);
}

static void __exit lenet_exit(void)
{
	esp_driver_unregister(&lenet_driver);
}

module_init(lenet_init)
module_exit(lenet_exit)

MODULE_DEVICE_TABLE(of, lenet_device_ids);

MODULE_AUTHOR("Emilio G. Cota <cota@braap.org>");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("lenet_rtl driver");
