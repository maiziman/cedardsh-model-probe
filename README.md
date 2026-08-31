<h1 align="center">CedarDSH Model Probe</h1>

<p align="center"><strong>Automatically detects reasoning and image support for custom DeepSeek Harness models.</strong></p>

<p align="center">
  <a href="https://github.com/maiziman/cedardsh-model-probe/releases/latest"><strong>Download the plugin</strong></a>
  · <a href="README.zh.md">中文说明</a>
</p>

## Install in CedarDSH Desktop

1. Download `CedarDSH-Model-Probe-v0.1.2.tgz`. Do not extract it.
2. Put the TGZ in the CedarDSH Desktop folder, beside `CedarDSH-Desktop.exe` and `dsh.cmd`.
3. Close CedarDSH Desktop. Open Terminal in that folder and run:

   ```powershell
   .\dsh.cmd plugin --profile web add ".\CedarDSH-Model-Probe-v0.1.2.tgz" --offline
   ```

4. Double-click `CedarDSH-Desktop.exe` again.

That is all. There is no separate plugin window and no configuration file to edit. Add or save a custom OpenAI-compatible provider in CedarDSH Desktop; the plugin works in the background.

For a global DeepSeek Harness installation, run the same command with `dsh` instead of `.\dsh.cmd`.

## What it does

- Reads capability metadata supplied by OpenRouter, Ollama, and compatible model endpoints.
- Detects supported reasoning levels and image input when a local endpoint omits that metadata.
- Keeps every capability setting that the user or provider set explicitly.
- Uses active test requests only for localhost and private-network endpoints by default.
- Does not modify the official DeepSeek Harness adapter, so DSH updates do not overwrite the plugin.

The active tests use a fixed arithmetic prompt and two generated 32 × 32 color images. They do not read or upload user files. Public endpoints remain metadata-only unless the user explicitly changes the probe policy.

## Remove

Close CedarDSH Desktop, open Terminal beside `dsh.cmd`, and run:

```powershell
.\dsh.cmd plugin --profile web remove @maiziman/dsh-model-capabilities --offline
```

Removing the plugin does not erase capabilities that were already saved in your model settings.

## Compatibility

Version 0.1.2 is verified with DeepSeek Harness `0.1.2-alpha.2` from official tag `dsh-v0.1.2-alpha.2`. Harness is still in preview, so a future upstream change may require a plugin update.

## Advanced settings

The defaults discover metadata, actively test local endpoints, and test reasoning levels `low`, `high`, and `max`. Maintainers can override the `model-capabilities` row in the profile's `cordis.patch.yml`; see [`cordis.patch.yml`](cordis.patch.yml) for the complete defaults.

Run the local checks with:

```sh
npm test
npm pack --dry-run
```

## License

[MIT](LICENSE)
