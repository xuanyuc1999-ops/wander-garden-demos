# 漫野田园 · 三版本完整 Demo

本分支集中保存三个独立游戏版本的**完整可编辑工程与 Windows/Web 成品包**。大文件使用 Git LFS，实际文件已随分支上传，不是仅列出本地路径或临时隧道链接。

| 版本 | 完整工程 | Windows | Web | 预览与说明 |
|---|---|---|---|---|
| 原版 · 低多边形田园 | [project](demos/01-original/project/) | [完整包](demos/01-original/builds/Windows.zip) | [完整包](demos/01-original/builds/Web.zip) | [目录](demos/01-original/) |
| 墨线赛璐璐童话 | [project](demos/02-ink-storybook/project/) | [完整包](demos/02-ink-storybook/builds/Windows.zip) | [完整包](demos/02-ink-storybook/builds/Web.zip) | [目录](demos/02-ink-storybook/) |
| 万圣节 · 南瓜月夜 | [project](demos/03-halloween/project/) | [完整包](demos/03-halloween/builds/Windows.zip) | [完整包](demos/03-halloween/builds/Web.zip) | [目录](demos/03-halloween/) |

## 完整下载

先安装 Git 和 Git LFS，然后执行：

```sh
git lfs install
git clone --single-branch --branch codex/wander-garden-three-demos https://github.com/xuanyuc1999-ops/awakening-garden.git wander-garden-demos
cd wander-garden-demos
git lfs pull
git lfs fsck
```

如使用 GitHub 页面下载，确认下载的是实际 LFS 内容；只有几行 `oid sha256` 的文件是指针，不能运行。
GitHub 的源码 ZIP 是否包含 LFS 对象取决于仓库设置；以上克隆方式可取得全部文件。

## 启动

Windows：解压对应 `builds/Windows.zip`，运行 EXE，保留同目录 PCK。
Web：解压 `builds/Web.zip` 后，在含 `index.html` 的目录运行 `python -m http.server 8000`，用浏览器打开本机8000端口。
编辑：Godot 4.7.2 导入该版本 `project/project.godot`，等待首次导入后 F5。

各版本工程包含运行依赖，不依赖此电脑的原工作区。无需 Lux3D/Meshy API key。
缓存、凭证、私有服务回执与无关项目未上传；完整交付文件清单与SHA256见 `files-manifest.json`。
已有源码压缩包与解压工程内容重复，本分支以解压后的完整工程管理，Windows/Web保留完整ZIP。

## 操作与范围

WASD移动、Shift慢跑、右键拖动视角、F开垦、E交互、B背包、J图鉴。
五区种植与宠物循环、32m区块外围；仍为可玩美术候选，用户美术验收待定。
验证范围见 [验证记录](docs/VERIFICATION.md)。各目录保留Godot与字体许可，生成/本地制作来源见工程资源清单。

此分支独立于默认 `main`；没有覆盖默认分支的苏醒园地项目。
