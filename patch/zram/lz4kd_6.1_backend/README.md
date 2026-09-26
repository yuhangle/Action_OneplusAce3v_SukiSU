# zram lz4k / lz4kd / lz4k_oplus 后端（6.1，backend API 版）

来源：SukiSU_patch/other/zram 的 lz4k 系列（lz4k + lz4k_oplus + lz4kd.patch）。

适配说明：原补丁按 crypto 压缩框架集成（在 zcomp.c 里塞算法名字符串、Kconfig 依赖
CRYPTO_*），与本树已移植的 zram backend ops 架构不兼容。本版改为 backend 方式：
三个算法直接调用各自 lib 的 encode/decode，不经过 crypto，也不占用 CRYPTO_* 配置。

依赖：应用前，树里必须已经包含 zram backend API 移植
（drivers/block/zram/backend_*.c + ZRAM_BACKEND_* Kconfig，即 crd 16.0 的
commit e574328aca1a 及以后）。否则补丁里的 zram 部分不适用。

## 目录内容（分工：新增走 files/，修改走 patch）

- `files/` —— 28 个**新增文件**，与内核同层级路径：
  - lib/lz4k/、lib/lz4kd/、lib/lz4k_oplus/（算法库）
  - include/linux/lz4k.h、include/linux/lz4kd.h
  - crypto/lz4k.c、crypto/lz4kd.c（crypto 封装，默认不编译）
  - drivers/block/zram/backend_lz4k{,d}{,_oplus}.{c,h}（zram 后端）
- `lz4kd-6.1-backend.patch` —— 只含对 **9 个已有文件的修改**：
  - arch/arm64/configs/gki_defconfig（3 行 CONFIG_ZRAM_BACKEND_*_y）
  - crypto/Kconfig、crypto/Makefile（CRYPTO_LZ4K / CRYPTO_LZ4KD，默认不编译）
  - drivers/block/zram/Kconfig（ZRAM_BACKEND_* 与 ZRAM_DEF_COMP_* 选项）
  - drivers/block/zram/Makefile（三个 backend 对象 + oplus include 路径）
  - drivers/block/zram/zcomp.c（backends[] 注册三个后端）
  - lib/Kconfig、lib/Makefile（LZ4K/LZ4KD 库符号、source 并编译 lib/lz4k_oplus）
  - kernel/module/main.c（内建 zram/lzo/zsmalloc 加入模块黑名单）

## 应用（两步，缺一不可）

    cd <kernel>
    cp -r <本目录>/files/* .
    patch -p1 < <本目录>/lz4kd-6.1-backend.patch

- 只 patch：缺 lib/、backend_* 等新文件；
- 只 cp：缺 Kconfig/Makefile/zcomp.c/gki_defconfig 的接线。

## 算法与后端

| zram 算法名 | 后端文件 | 调用的 lib |
|---|---|---|
| lz4k | drivers/block/zram/backend_lz4k.c | lib/lz4k (lz4k_encode / lz4k_decode) |
| lz4kd | drivers/block/zram/backend_lz4kd.c | lib/lz4kd (lz4kd_encode / lz4kd_decode) |
| lz4k_oplus | drivers/block/zram/backend_lz4k_oplus.c | lib/lz4k_oplus (lz4k_compress / lz4k_decompress) |

## 使用

默认压缩算法未改动（仍为 lzo-rle）。两种切换方式：

- 编译期：defconfig 里加 `CONFIG_ZRAM_DEF_COMP_LZ4KD=y`
- 运行时：在设置 disksize 之前 `echo lz4kd > /sys/block/zram0/comp_algorithm`

## 备注

- crypto/lz4k.c、crypto/lz4kd.c 对 zram 已非必需，保留以兼容其他走 crypto 的使用方，
  默认不编译。
- 设备验证：comp_algorithm 列出 10 种算法，lz4k / lz4kd / lz4k_oplus 与其余算法
  64MB 写入->读回 md5 校验全部通过。
