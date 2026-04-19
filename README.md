# packages-25.12 - node prebuilt

这个分支用于给 `lean` / `OpenWrt` / `ImmortalWrt` 的 `25.12` 系列提供 `lang/node` 预编译支持，同时兼容 `ipk` / `apk` 两种上游预编译资产格式。

## 先后顺序

是的，应该先把你自己的 `node` / `node-npm` 预编译包构建并发布出来。

原因很简单：

- 这个 `packages-25.12` 分支本身只是“下载并重组你发布好的预编译包”
- 它不是从源码现编 Node.js，也不是从 OpenWrt 官方二进制仓库兜底下载
- 所以如果 release 里还没有对应架构的预编译资产，别的仓库即使接入这个分支，也没法成功编译 `lang/node`

建议顺序：

1. 先为 `OpenWrt` / `ImmortalWrt` 的主流 `ARCH_PACKAGES` 构建并发布 `node` / `node-npm`
2. 确认 release 资产命名符合本文档约定
3. `lean` 如果暂时没有自己独立的一套预编译资产，可以先复用 `openwrt` flavor 作为回退
4. 再在其他仓库里接入这个 `packages-25.12` 分支

## 用法

```sh
rm -rf feeds/packages/lang/node
git clone https://github.com/jw10126121/feeds_packages_lang_node-prebuilt -b packages-25.12 feeds/packages/lang/node
```

## 方案说明

- 不再依赖 OpenWrt 官方下载目录里的现成 `node` / `node-npm` 预编译包
- 构建时直接下载你自己发布的 `node` / `node-npm` 预编译包
- 默认自动识别 `apk/ipk`
- `ImmortalWrt` 会尽量自动识别，其他环境默认按 `lean` 处理
- 当 `lean` 对应资产不存在时，会自动回退尝试 `openwrt` flavor
- 版本、tag、默认 flavor/format、下载基地址统一在 [prebuilt.mk](prebuilt.mk) 维护

## 可选覆盖

如果你的构建环境不能可靠自动识别，可以显式传参：

```sh
make package/lang/node/compile V=s \
  NODE_PREBUILT_FLAVOR=immortalwrt \
  NODE_PREBUILT_FORMAT=apk
```

可用值：

- `NODE_PREBUILT_FLAVOR=openwrt`、`lean` 或 `immortalwrt`
- `NODE_PREBUILT_FALLBACK_FLAVOR=openwrt`、`lean`、`immortalwrt` 或空
- `NODE_PREBUILT_FORMAT=ipk` 或 `apk`

注意：这两个参数是“消费预编译包时”的覆盖手段，不是生成 release 资产时的架构批量配置。

## Release 约定

- Release 仓库：`jw10126121/feeds_packages_lang_node-prebuilt`
- Release tag：`packages-25.12-node-v<node-version>-r<release>`
- 资产文件名：
  - `node_<node-version>-r<release>_<arch_packages>_<flavor>.<format>`
  - `node-npm_<node-version>-r<release>_<arch_packages>_<flavor>.<format>`

其中：

- `<arch_packages>` 必须和 OpenWrt 构建时的 `ARCH_PACKAGES` 完全一致，例如 `aarch64_generic`
- `<flavor>` 目前约定为 `openwrt`、`lean` 或 `immortalwrt`
- `<format>` 目前约定为 `ipk` 或 `apk`

## 维护方式

1. 发布新的预编译包前，先更新 [prebuilt.mk](prebuilt.mk)
2. 在 [ci/sdk-manifest.json](ci/sdk-manifest.json) 里，为 `openwrt` / `immortalwrt` 的每个主流 `ARCH_PACKAGES` 填一个可用的代表性 SDK URL
3. 先运行 workflow 构建 `openwrt` / `immortalwrt` 预编译包
4. 如果未来拿到 `lean` 自己的稳定 SDK，再补 `lean` 专用资产
5. 确保 GitHub Releases 下的 tag 和文件名与 `prebuilt.mk` 对齐
6. 其他项目接入时直接拉 `packages-25.12` 分支即可

## 主流架构清单

workflow 不再要求你手工传 `arch_packages`，而是直接读取 [ci/sdk-manifest.json](ci/sdk-manifest.json)。

当前默认主流 `ARCH_PACKAGES` 清单是：

- `aarch64_generic`
- `x86_64`
- `i386_pentium4`
- `arm_cortex-a7_neon-vfpv4`
- `arm_cortex-a53`
- `arm_arm1176jzf-s_vfp`
- `mipsel_24kc`

你后面如果还想扩展更多架构，直接在 `ci/sdk-manifest.json` 里继续加即可。

## SDK URL 说明

`ARCH_PACKAGES` 本身不能唯一推出 SDK 下载地址，所以这里采用“每个主流 `ARCH_PACKAGES` 对应一个代表性 SDK URL”的维护方式。

也就是说，你需要在 `ci/sdk-manifest.json` 里手工维护类似这种映射关系：

- `aarch64_generic -> 某个能产出 aarch64_generic 包的 25.12 SDK`
- `x86_64 -> 某个能产出 x86_64 包的 25.12 SDK`

只要这个 SDK 最终构建出来的包文件名后缀是目标 `ARCH_PACKAGES`，就可以作为该架构的代表性 SDK。

对于 `openwrt` 官方 SDK，可以从 `https://downloads.openwrt.org/releases/25.12.0/targets/<target>/<subtarget>/` 这类目录获取。
例如 `x86_64` 的官方 SDK 页面里就能看到：

- [openwrt-sdk-25.12.0-x86-64_gcc-14.3.0_musl.Linux-x86_64.tar.zst](https://downloads.openwrt.org/releases/25.12.0/targets/x86/64/openwrt-sdk-25.12.0-x86-64_gcc-14.3.0_musl.Linux-x86_64.tar.zst)

这说明官方 OpenWrt 是“能用的”，但它是按 `target/subtarget` 分散发布的，不是一个统一总 SDK 地址。

如果你的目标是：

- `ImmortalWrt`：优先使用 `immortalwrt` 自己的 SDK
- `lean`：在拿不到 lean 专属 SDK 之前，先让 `lean -> openwrt` 自动回退

## GitHub Actions

仓库内附带了一个手动触发的 workflow 草稿：

- [.github/workflows/release-node-prebuilt.yml](.github/workflows/release-node-prebuilt.yml)

它现在会：

- 读取 [ci/sdk-manifest.json](ci/sdk-manifest.json)
- 按 `openwrt`、`lean` 或 `immortalwrt` 批量遍历主流 `ARCH_PACKAGES`
- 对每个架构下载对应 SDK、构建 `node` / `node-npm`
- 自动识别产物是 `ipk` 还是 `apk`
- 再按 `flavor + format + arch_packages` 规则重命名并上传到指定 release
