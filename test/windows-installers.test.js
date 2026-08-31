import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { describe, it } from 'node:test'

const PACKAGE_NAME = '@maiziman/dsh-model-capabilities'

async function script(name) {
  return readFile(new URL(`../${name}`, import.meta.url), 'utf8')
}

describe('Windows one-click scripts', () => {
  it('runs an end-to-end Windows release gate', async () => {
    const workflow = await readFile(new URL('../.github/workflows/release.yml', import.meta.url), 'utf8')
    assert.match(workflow, /validate-windows-installer:\s+runs-on: windows-latest/u)
    assert.match(workflow, /\.\/test\/windows-installers\.e2e\.ps1 -PackagePath \$asset/u)
    assert.match(workflow, /publish:\s+needs: validate-windows-installer/u)
  })

  it('installs the TGZ through a movable profile-relative file reference', async () => {
    const source = await script('Install-Model-Probe.cmd')
    assert.match(source, /set "PACKAGE_DIR=%PROFILE_DIR%\\plugin-packages"/u)
    assert.match(source, /copy \/Y "%PLUGIN_ARCHIVE%" "%PACKAGE_DIR%\\%PLUGIN_FILE%"/u)
    assert.match(source, /call "%APP_DIR%dsh\.cmd" plugin --profile web add "file:plugin-packages\/%PLUGIN_FILE%" --offline --ignore-scripts/u)
    assert.match(source, /Close CedarDSH Desktop and any CedarDSH window started from dsh\.cmd\./u)
    assert.match(source, /Press any key only after they are closed\./u)
    assert.match(source, /if \/I "%CEDARDSH_INSTALLER_TEST_MODE%"=="1" exit \/b 0/u)
    assert.match(source, new RegExp(PACKAGE_NAME.replaceAll('/', '\\/'), 'u'))
    assert.doesNotMatch(source, /taskkill/iu)
  })

  it('removes only the Bundle and keeps saved model settings', async () => {
    const source = await script('Uninstall-Model-Probe.cmd')
    assert.match(source, new RegExp(`call "%APP_DIR%dsh\\.cmd" plugin --profile web remove ${PACKAGE_NAME.replaceAll('/', '\\/')}`, 'u'))
    assert.doesNotMatch(source, /remove @maiziman\/dsh-model-capabilities --offline/u)
    assert.match(source, /Close CedarDSH Desktop and any CedarDSH window started from dsh\.cmd\./u)
    assert.match(source, /Press any key only after they are closed\./u)
    assert.match(source, /if \/I "%CEDARDSH_INSTALLER_TEST_MODE%"=="1" exit \/b 0/u)
    assert.match(source, /Previously saved model capability settings were kept\./u)
    assert.doesNotMatch(source, /settings\.yaml/iu)
    assert.doesNotMatch(source, /taskkill/iu)
  })
})
