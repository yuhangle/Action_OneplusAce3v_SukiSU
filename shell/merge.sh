#!/bin/bash

# ==========================================
# 脚本名称: oplus_stitcher.sh
# 适用平台: OnePlus Ace 3V (SM7675)
# 作用: 将 msm-kernel 的厂商驱动缝合至 crDroid/Common 仓库
# ==========================================

# 1. 自动定位 msm-kernel 路径 (假设它在上一级目录)
MSM_PATH="$(realpath ../msm-kernel)"
CRD_PATH="$(pwd)"

if [ ! -d "$MSM_PATH/drivers/oplus" ] && [ ! -d "$MSM_PATH/drivers/soc/oplus" ]; then
    echo "❌ 错误: 找不到 msm-kernel 源码，请检查路径: $MSM_PATH"
    exit 1
fi

echo "🚀 开始缝合一加厂商驱动..."

# 2. 缝合驱动目录 (Drivers)
echo "📦 正在链接驱动目录..."

# 定义需要整体链接的厂商目录
# 逻辑：删除 crd 里的占位符，直接链向 msm-kernel 的真身
declare -a driver_dirs=(
    "drivers/misc/vibrator"
    "drivers/soc/oplus"
    "drivers/power/oplus"
)

for dir in "${driver_dirs[@]}"; do
    mkdir -p "$(dirname "$dir")"
    rm -rf "$dir"
    ln -sf "$MSM_PATH/$dir" "$dir"
    echo "   ✅ 已链接: $dir"
done

# 特殊处理：有些驱动在 base 下是散放的
mkdir -p drivers/base
ln -sf "$MSM_PATH/drivers/base/kernelFwUpdate" drivers/base/kernelFwUpdate
ln -sf "$MSM_PATH/drivers/base/touchpanel_notify" drivers/base/touchpanel_notify

# 3. 缝合头文件 (Includes)
echo "📑 正在链接头文件目录..."

# 整体链接 soc/oplus 头文件 (解决 olc.h, kernel_fb.h 等缺失)
mkdir -p include/soc
rm -rf include/soc/oplus
ln -sf "$MSM_PATH/include/soc/oplus" include/soc/oplus

# 补全 linux 目录下的特定厂商头文件
# 针对你之前报错的 pogo_common.h 和其他 oplus 相关 .h
if [ -f "$MSM_PATH/include/linux/pogo_common.h" ]; then
    ln -sf "$MSM_PATH/include/linux/pogo_common.h" include/linux/pogo_common.h
fi

# 批量补全 include/linux 下所有 oplus 开头的头文件
find "$MSM_PATH/include/linux/" -name "oplus*" -exec ln -sf {} include/linux/ \;

echo "✨ 缝合完成！"
echo "💡 现在你可以运行: make ... gki_defconfig && make ... -j\$(nproc)"
