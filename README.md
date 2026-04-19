# packages-25.12 - node prebuilt

这个分支用于给 `lean` / `ImmortalWrt` 的 `25.12` 系列提供 `lang/node` 预编译支持，同时兼容 `ipk` / `apk` 两种上游预编译资产格式。

## 用法

```sh
rm -rf feeds/packages/lang/node
git clone https://github.com/jw10126121/feeds_packages_lang_node-prebuilt -b packages-25.12 feeds/packages/lang/node
```

## 方案说明

- 不再依赖 OpenWrt 官方下载目录里的现成 `node` / `node-npm` 预编译包
- 构建时直接下载你自己发布的 `node` / `node-npm` 预编译包
- 默认自动识别 `apk/ipk`
- `ImmortalWrt` 会尽量自动识别，`lean` 作为默认 flavor；也支持显式覆盖
- 版本、tag、默认 flavor/format、下载基地址统一在 [prebuilt.mk](prebuilt.mk) 维护

## 可选覆盖

如果你的构建环境不能可靠自动识别，可以显式传参：

```sh
make package/lang/node/compile V=s \
  NODE_PREBUILT_FLAVOR=immortalwrt \
  NODE_PREBUILT_FORMAT=apk
```

可用值：

- `NODE_PREBUILT_FLAVOR=lean` 或 `immortalwrt`
- `NODE_PREBUILT_FORMAT=ipk` 或 `apk`

## Release 约定

- Release 仓库：`jw10126121/feeds_packages_lang_node-prebuilt`
- Release tag：`packages-25.12-node-v<node-version>-r<release>`
- 资产文件名：
  - `node_<node-version>-r<release>_<arch_packages>_<flavor>.<format>`
  - `node-npm_<node-version>-r<release>_<arch_packages>_<flavor>.<format>`

其中：

- `<arch_packages>` 必须和 OpenWrt 构建时的 `ARCH_PACKAGES` 完全一致，例如 `aarch64_generic`
- `<flavor>` 目前约定为 `lean` 或 `immortalwrt`
- `<format>` 目前约定为 `ipk` 或 `apk`

## 维护方式

1. 发布新的预编译包前，先更新 [prebuilt.mk](prebuilt.mk)
2. 确保 GitHub Releases 下的 tag 和文件名与 `prebuilt.mk` 对齐
3. 其他项目接入时直接拉 `packages-25.12` 分支即可

## GitHub Actions

仓库内附带了一个手动触发的 workflow 草稿：

- [.github/workflows/release-node-prebuilt.yml](.github/workflows/release-node-prebuilt.yml)

它的目标是基于你提供的 `lean` / `ImmortalWrt` `25.12` SDK 构建 `node` / `node-npm`，再按 `flavor + format` 规则重命名并上传到指定 release。
