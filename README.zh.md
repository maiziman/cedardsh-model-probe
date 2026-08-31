<h1 align="center">CedarDSH Model Probe</h1>

<p align="center"><strong>自动识别 DeepSeek Harness 自定义模型是否支持思考与图像输入。</strong></p>

<p align="center">
  <a href="https://github.com/maiziman/cedardsh-model-probe/releases/latest"><strong>下载插件</strong></a>
  · <a href="README.md">English</a>
</p>

## 安装到 CedarDSH Desktop

1. 下载 `CedarDSH-Model-Probe-v0.1.2.tgz`，不要解压。
2. 把 TGZ 放进 CedarDSH Desktop 解压目录，也就是 `CedarDSH-Desktop.exe` 和 `dsh.cmd` 所在的文件夹。
3. 关闭 CedarDSH Desktop，在这个文件夹中打开终端，运行：

   ```powershell
   .\dsh.cmd plugin --profile web add ".\CedarDSH-Model-Probe-v0.1.2.tgz" --offline
   ```

4. 再次双击 `CedarDSH-Desktop.exe`。

安装完成。插件没有单独窗口，也不需要手动修改配置。在 CedarDSH Desktop 中添加或保存 OpenAI-compatible 自定义提供方后，插件会在后台自动工作。

如果使用全局安装的 DeepSeek Harness，把命令中的 `.\dsh.cmd` 换成 `dsh`。

## 它会做什么

- 读取 OpenRouter、Ollama 和兼容模型端点提供的能力信息。
- 局域网模型没有完整信息时，识别它支持的思考等级与图像输入。
- 保留用户或提供方已经明确设置的每个能力字段。
- 默认只对本机和私有网络地址发送主动测试请求。
- 不修改官方 DeepSeek Harness 适配器，因此升级 DSH 不会覆盖插件。

主动测试只使用一道固定算术题和两张程序生成的 32 × 32 纯色图片，不会读取或上传用户文件。公网端点默认只读取元数据，除非用户主动修改探测策略。

## 卸载

关闭 CedarDSH Desktop，在 `dsh.cmd` 所在文件夹中打开终端并运行：

```powershell
.\dsh.cmd plugin --profile web remove @maiziman/dsh-model-capabilities --offline
```

卸载不会删除已经保存到模型设置中的能力。

## 兼容性

v0.1.2 已通过官方标签 `dsh-v0.1.2-alpha.2` 的 DeepSeek Harness `0.1.2-alpha.2` 验证。Harness 仍处于预览阶段，未来上游结构变化时可能需要更新插件。

## 高级设置

默认配置会读取元数据、主动测试局域网端点，并检查 `low`、`high` 和 `max` 三个思考等级。维护者可在 profile 的 `cordis.patch.yml` 中覆盖 `model-capabilities` 行；完整默认值见 [`cordis.patch.yml`](cordis.patch.yml)。

本地检查：

```sh
npm test
npm pack --dry-run
```

## 许可证

[MIT](LICENSE)
