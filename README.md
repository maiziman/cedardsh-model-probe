<h1 align="center">CedarDSH Model Probe</h1>

<p align="center"><strong>Automatically detects reasoning and image support for custom DeepSeek Harness models.</strong></p>

<p align="center">
  <a href="https://github.com/maiziman/cedardsh-model-probe/releases/latest"><strong>Download the plugin</strong></a>
  · <a href="README.zh.md">中文说明</a>
</p>

## Install in CedarDSH Desktop

1. Download `CedarDSH-Model-Probe-Windows-v0.1.3.zip` from the latest release.
2. Put the ZIP in the CedarDSH Desktop folder, beside `CedarDSH-Desktop.exe` and `dsh.cmd`, then choose **Extract All**.
3. Close CedarDSH Desktop. Open the extracted plugin folder and double-click `Install-Model-Probe.cmd`.
4. Reopen `CedarDSH-Desktop.exe`.

That is all. There is no separate plugin window and no configuration file to edit. Add or save a custom OpenAI-compatible provider; the plugin works in the background. To verify installation, open **Settings → Plugins → Global Plugins** and search for `model-capabilities`.

Keep the extracted plugin folder if you want to use its one-click removal file later.

## What it does

- Reads capability metadata supplied by OpenRouter, Ollama, and compatible model endpoints.
- Detects supported reasoning levels and image input when a local endpoint omits that metadata.
- Keeps every capability setting that the user or provider set explicitly.
- Uses active test requests only for localhost and private-network endpoints by default.
- Does not modify the official DeepSeek Harness adapter, so DSH updates do not overwrite the plugin.

The active tests use a fixed arithmetic prompt and two generated 32 × 32 color images. They do not read or upload user files. Public endpoints remain metadata-only unless the user explicitly changes the probe policy.

## Remove

Close CedarDSH Desktop and double-click `Uninstall-Model-Probe.cmd` in the extracted plugin folder. Removing the plugin does not erase capabilities already saved in model settings.

## Manual installation

Advanced users can download the TGZ, place it beside `dsh.cmd`, and run:

```powershell
New-Item -ItemType Directory -Force .\dsh-home\profiles\web\plugin-packages | Out-Null
Copy-Item .\CedarDSH-Model-Probe-v0.1.3.tgz .\dsh-home\profiles\web\plugin-packages\
.\dsh.cmd plugin --profile web add "file:plugin-packages/CedarDSH-Model-Probe-v0.1.3.tgz" --offline --ignore-scripts
```

For a global DeepSeek Harness installation, use the official `dsh plugin --profile web add <package>` command.

## Compatibility

Version 0.1.3 is verified with DeepSeek Harness `0.1.2-alpha.2` from official tag `dsh-v0.1.2-alpha.2`. Harness is still in preview, so a future upstream change may require a plugin update.

## Advanced settings

The defaults discover metadata, actively test local endpoints, and test reasoning levels `low`, `high`, and `max`. Maintainers can override the `model-capabilities` row in the profile's `cordis.patch.yml`; see [`cordis.patch.yml`](cordis.patch.yml) for the complete defaults.

Run the local checks with:

```sh
npm test
npm pack --dry-run
```

## License

[MIT](LICENSE)
