<h1 align="center">CedarDSH Model Probe</h1>

<p align="center"><strong>自动识别 DeepSeek Harness 自定义模型是否支持思考与图像输入。</strong></p>

<p align="center">
  <a href="https://github.com/maiziman/cedardsh-model-probe/releases/latest"><strong>下载插件</strong></a>
  · <a href="README.md">English</a>
</p>

## 安装到 CedarDSH Desktop

1. 从最新 Release 下载 `CedarDSH-Model-Probe-Windows-v0.1.3.zip`。
2. 把 ZIP 放进 `CedarDSH-Desktop.exe` 和 `dsh.cmd` 所在文件夹，选择“全部解压”。
3. 关闭 CedarDSH Desktop，打开解压出的插件文件夹，双击 `Install-Model-Probe.cmd`。
4. 再次双击 `CedarDSH-Desktop.exe`。

安装完成。插件没有单独窗口，也不需要手动修改配置。添加或保存 OpenAI-compatible 自定义提供方后，插件会在后台自动工作。可以进入“设置 → 插件 → 全局插件”，搜索 `model-capabilities` 确认安装状态。

请保留解压出的插件文件夹，之后可直接使用其中的一键卸载文件。

## 它会做什么

- 读取 OpenRouter、Ollama 和兼容模型端点提供的能力信息。
- 局域网模型没有完整信息时，识别它支持的思考等级与图像输入。
- 保留用户或提供方已经明确设置的每个能力字段。
- 默认只对本机和私有网络地址发送主动测试请求。
- 不修改官方 DeepSeek Harness 适配器，因此升级 DSH 不会覆盖插件。

主动测试只使用一道固定算术题和两张程序生成的 32 × 32 纯色图片，不会读取或上传用户文件。公网端点默认只读取元数据，除非用户主动修改探测策略。

## 卸载

关闭 CedarDSH Desktop，双击插件文件夹中的 `Uninstall-Model-Probe.cmd`。卸载不会删除已经保存到模型设置中的能力。

## 手动安装

熟悉命令行的用户可以下载 TGZ，把它放到 `dsh.cmd` 所在文件夹，然后运行：

```powershell
New-Item -ItemType Directory -Force .\dsh-home\profiles\web\plugin-packages | Out-Null
Copy-Item .\CedarDSH-Model-Probe-v0.1.3.tgz .\dsh-home\profiles\web\plugin-packages\
.\dsh.cmd plugin --profile web add "file:plugin-packages/CedarDSH-Model-Probe-v0.1.3.tgz" --offline --ignore-scripts
```

如果使用全局安装的 DeepSeek Harness，请使用官方的 `dsh plugin --profile web add <package>` 命令。

## 兼容性

v0.1.3 已通过官方标签 `dsh-v0.1.2-alpha.2` 的 DeepSeek Harness `0.1.2-alpha.2` 验证。Harness 仍处于预览阶段，未来上游结构变化时可能需要更新插件。

## 高级设置

默认配置会读取元数据、主动测试局域网端点，并检查 `low`、`high` 和 `max` 三个思考等级。维护者可在 profile 的 `cordis.patch.yml` 中覆盖 `model-capabilities` 行；完整默认值见 [`cordis.patch.yml`](cordis.patch.yml)。

本地检查：

```sh
npm test
npm pack --dry-run
```

## 许可证

[MIT](LICENSE)
