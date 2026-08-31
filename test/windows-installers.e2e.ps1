param(
  [Parameter(Mandatory = $true)]
  [string]$PackagePath,
  [string]$DshVersion = '0.1.2-alpha.2'
)

$ErrorActionPreference = 'Stop'
$packageName = '@maiziman/dsh-model-capabilities'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$manifest = Get-Content -LiteralPath (Join-Path $repositoryRoot 'package.json') -Raw | ConvertFrom-Json
$version = [string]$manifest.version
$resolvedPackage = (Resolve-Path -LiteralPath $PackagePath).Path
$temporaryRoot = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { [System.IO.Path]::GetTempPath() }
$temporaryRoot = [System.IO.Path]::GetFullPath($temporaryRoot)
$testRoot = Join-Path $temporaryRoot "CedarDSH installer e2e $([guid]::NewGuid().ToString('N'))"
$appRoot = Join-Path $testRoot 'CedarDSH Desktop With Spaces'
$installerRoot = Join-Path $appRoot 'Model Probe Installer With Spaces'
$profileRoot = Join-Path $appRoot 'dsh-home\profiles\web'

function Assert-Condition {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

function Invoke-OneClickFile {
  param([string]$Path)
  $start = [System.Diagnostics.ProcessStartInfo]::new()
  $start.FileName = $env:ComSpec
  $start.Arguments = '/d /c call "%CEDARDSH_ONE_CLICK_PATH%"'
  $start.UseShellExecute = $false
  $start.Environment['CEDARDSH_ONE_CLICK_PATH'] = $Path
  $start.Environment['CEDARDSH_INSTALLER_TEST_MODE'] = '1'
  $start.RedirectStandardInput = $true
  $start.RedirectStandardOutput = $true
  $start.RedirectStandardError = $true
  $process = [System.Diagnostics.Process]::new()
  $process.StartInfo = $start
  if (-not $process.Start()) { throw "could not start $Path" }
  $stdout = $process.StandardOutput.ReadToEndAsync()
  $stderr = $process.StandardError.ReadToEndAsync()
  try {
    1..8 | ForEach-Object { $process.StandardInput.WriteLine() }
  } catch [System.IO.IOException] {
    # The script may close stdin after reporting an early failure.
  } finally {
    try {
      $process.StandardInput.Close()
    } catch [System.IO.IOException] {
      # The child already closed the pipe, so no input handle remains to release.
    }
  }
  $process.WaitForExit()
  $output = $stdout.GetAwaiter().GetResult() + $stderr.GetAwaiter().GetResult()
  if ($process.ExitCode -ne 0) {
    throw "$Path exited with $($process.ExitCode):`n$output"
  }
  return $output
}

function Read-ProfileManifest {
  return Get-Content -LiteralPath (Join-Path $profileRoot 'package.json') -Raw | ConvertFrom-Json
}

function Assert-Installed {
  $profile = Read-ProfileManifest
  $dependencyProperty = if ($null -ne $profile.dependencies) {
    $profile.dependencies.PSObject.Properties[$packageName]
  } else {
    $null
  }
  Assert-Condition ($null -ne $dependencyProperty) 'plugin dependency is missing from the profile manifest'
  $dependency = [string]$dependencyProperty.Value
  $normalizedDependency = $dependency.Replace('\', '/')
  Assert-Condition ($normalizedDependency -eq "file:plugin-packages/CedarDSH-Model-Probe-v$version.tgz") `
    "plugin dependency is not profile-relative: $dependency"
  $bundles = @($profile.dsh.profile.bundles | Where-Object { $_ -eq $packageName })
  Assert-Condition ($bundles.Count -eq 1) "expected one Bundle entry, found $($bundles.Count)"
  $installedManifest = Join-Path $profileRoot 'node_modules\@maiziman\dsh-model-capabilities\package.json'
  Assert-Condition (Test-Path -LiteralPath $installedManifest) 'installed plugin manifest is missing'
  $installed = Get-Content -LiteralPath $installedManifest -Raw | ConvertFrom-Json
  Assert-Condition ([string]$installed.version -eq $version) `
    "installed plugin version $($installed.version) does not match $version"
}

try {
  New-Item -ItemType Directory -Path (Join-Path $appRoot 'runtime'), (Join-Path $appRoot 'app'), $installerRoot | Out-Null
  Copy-Item -LiteralPath (Get-Command node).Source -Destination (Join-Path $appRoot 'runtime\node.exe')
  New-Item -ItemType File -Path (Join-Path $appRoot 'CedarDSH-Desktop.exe') | Out-Null

  npm install --ignore-scripts --no-package-lock --no-save --prefer-offline --prefix (Join-Path $appRoot 'app') "@deepseek-ai/dsh@$DshVersion"
  if ($LASTEXITCODE -ne 0) { throw "npm install failed with exit code $LASTEXITCODE" }

  @'
@echo off
setlocal
set "ROOT=%~dp0"
set "DSH_HOME=%ROOT%dsh-home"
set "PATH=%ROOT%runtime;%PATH%"
set "pnpm_config_cache_dir=%DSH_HOME%\pnpm-cache"
set "pnpm_config_state_dir=%DSH_HOME%\pnpm-state"
set "pnpm_config_store_dir=%DSH_HOME%\pnpm-store"
"%ROOT%runtime\node.exe" "%ROOT%app\node_modules\@deepseek-ai\dsh\lib\bin.js" %*
exit /b %ERRORLEVEL%
'@ | Set-Content -LiteralPath (Join-Path $appRoot 'dsh.cmd') -Encoding ascii

  $archiveName = "CedarDSH-Model-Probe-v$version.tgz"
  Copy-Item -LiteralPath $resolvedPackage -Destination (Join-Path $installerRoot $archiveName)
  Copy-Item -LiteralPath (Join-Path $repositoryRoot 'Install-Model-Probe.cmd') -Destination $installerRoot
  Copy-Item -LiteralPath (Join-Path $repositoryRoot 'Uninstall-Model-Probe.cmd') -Destination $installerRoot

  $installOutput = Invoke-OneClickFile (Join-Path $installerRoot 'Install-Model-Probe.cmd')
  Assert-Condition ($installOutput -match 'installed successfully') 'installer did not report success'
  Assert-Installed

  $packageCache = Join-Path $profileRoot 'plugin-packages'
  Set-Content -LiteralPath (Join-Path $packageCache 'CedarDSH-Model-Probe-v0.0.0.tgz') -Value 'stale archive'
  Invoke-OneClickFile (Join-Path $installerRoot 'Install-Model-Probe.cmd') | Out-Null
  Assert-Installed
  Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $packageCache 'CedarDSH-Model-Probe-v0.0.0.tgz'))) `
    'repeated installation did not remove the stale plugin archive'

  $removeOutput = Invoke-OneClickFile (Join-Path $installerRoot 'Uninstall-Model-Probe.cmd')
  Assert-Condition ($removeOutput -match 'removed successfully') 'uninstaller did not report success'
  $removedProfile = Read-ProfileManifest
  $removedDependency = if ($null -ne $removedProfile.dependencies) {
    $removedProfile.dependencies.PSObject.Properties[$packageName]
  } else {
    $null
  }
  Assert-Condition ($null -eq $removedDependency) `
    'uninstaller left the dependency in the profile manifest'
  Assert-Condition (@($removedProfile.dsh.profile.bundles | Where-Object { $_ -eq $packageName }).Count -eq 0) `
    'uninstaller left the Bundle in the profile manifest'
  Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $profileRoot 'node_modules\@maiziman\dsh-model-capabilities'))) `
    'uninstaller left the installed plugin directory'

  $secondRemoveOutput = Invoke-OneClickFile (Join-Path $installerRoot 'Uninstall-Model-Probe.cmd')
  Assert-Condition ($secondRemoveOutput -match 'already removed') 'repeated removal was not idempotent'
  Write-Host 'Windows one-click install, repeat install, uninstall, and repeat uninstall passed.'
} finally {
  if ((Test-Path -LiteralPath $testRoot) -and $env:CEDARDSH_KEEP_E2E -ne '1') {
    $resolvedTestRoot = [System.IO.Path]::GetFullPath($testRoot)
    $safePrefix = $temporaryRoot.TrimEnd('\') + '\'
    if (-not $resolvedTestRoot.StartsWith($safePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
      throw "refusing to remove test directory outside the temporary root: $resolvedTestRoot"
    }
    Remove-Item -LiteralPath $testRoot -Recurse -Force
  } elseif (Test-Path -LiteralPath $testRoot) {
    Write-Host "Kept Windows installer test directory: $testRoot"
  }
}
