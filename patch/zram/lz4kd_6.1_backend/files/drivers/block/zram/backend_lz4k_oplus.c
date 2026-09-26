// SPDX-License-Identifier: GPL-2.0-or-later

#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/vmalloc.h>

/* lib/lz4k_oplus/lz4k.h, reachable via zram's ccflags */
#include <lz4k.h>

#include "backend_lz4k_oplus.h"

struct lz4k_oplus_ctx {
	void *state;
};

static void lz4k_oplus_release_params(struct zcomp_params *params)
{
}

static int lz4k_oplus_setup_params(struct zcomp_params *params)
{
	return 0;
}

static void lz4k_oplus_destroy(struct zcomp_ctx *ctx)
{
	struct lz4k_oplus_ctx *zctx = ctx->context;

	if (!zctx)
		return;

	vfree(zctx->state);
	kfree(zctx);
}

static int lz4k_oplus_create(struct zcomp_params *params, struct zcomp_ctx *ctx)
{
	struct lz4k_oplus_ctx *zctx;

	zctx = kzalloc(sizeof(*zctx), GFP_KERNEL);
	if (!zctx)
		return -ENOMEM;

	ctx->context = zctx;
	/* the algorithm uses a fixed two page state buffer */
	zctx->state = vzalloc(2 * PAGE_SIZE);
	if (!zctx->state)
		goto error;

	return 0;

error:
	lz4k_oplus_destroy(ctx);
	return -ENOMEM;
}

static int lz4k_oplus_compress(struct zcomp_params *params,
			       struct zcomp_ctx *ctx, struct zcomp_req *req)
{
	struct lz4k_oplus_ctx *zctx = ctx->context;
	int ret;

	ret = lz4k_compress(zctx->state, req->src, req->dst, req->src_len,
			    req->dst_len);
	if (ret < 0)
		return -EINVAL;

	/* ret == 0 means incompressible: keep req->dst_len as is */
	if (ret)
		req->dst_len = ret;

	return 0;
}

static int lz4k_oplus_decompress(struct zcomp_params *params,
				 struct zcomp_ctx *ctx,
				 struct zcomp_req *req)
{
	int ret;

	ret = lz4k_decompress(req->src, req->dst, req->src_len, req->dst_len);
	if (ret <= 0)
		return -EINVAL;

	return 0;
}

const struct zcomp_ops backend_lz4k_oplus = {
	.compress	= lz4k_oplus_compress,
	.decompress	= lz4k_oplus_decompress,
	.create_ctx	= lz4k_oplus_create,
	.destroy_ctx	= lz4k_oplus_destroy,
	.setup_params	= lz4k_oplus_setup_params,
	.release_params	= lz4k_oplus_release_params,
	.name		= "lz4k_oplus",
};
