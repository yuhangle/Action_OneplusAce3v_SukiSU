# 用于一加ace3v和小米平板4的内核自动构建

## 支持的设备：
- 一加ace3v（仅在Crdroid 12和13系统得到测试，维护sm8650仓库的内核；一加官方内核暂不维护，因为我只有一台，且刷了Crdroid）

- 小米平板4（仅测试过pix106的Lineage 24，不支持安卓16及以下，有需要自行改内核源码分支）


`目前支持使用BakaSU，添加了BBG分区保护，DriodSpaces支持，开启一些额外的配置。`  

使用请fork项目，然后在action处构建  
首次构建耗时30分钟左右，二次构建耗时会短一些。

## 实现的功能

### 一加ace3v
- BakaSU集成
- Susfs集成
- ZRAM相关：lz4 1.10.0算法移植(原补丁来自 [Xiaomichael](https://github.com/Xiaomichael/kernel_patches) ) ; zstd 1.5.7算法移植(补丁来自上游内核移植) ; lz4kd算法移植(原补丁来自 [ShirkNeko](https://github.com/ShirkNeko/SukiSU_patch.git)) ; Zram backend api & 词典 移植(来自上游6.14内核) ; Zram多压缩流 + 重压缩移植(来自上游内核)
- DroidSpaces容器配置开启
- Mountify模块所需要的tmpfs配置开启

### 小米平板4
- BakaSU集成
- Susfs集成
- DroidSpaces容器配置开启
