param(
    [Parameter(Mandatory = $true)]
    [string]$LauncherPath
)

$ErrorActionPreference = 'Stop'
$installRoot = Join-Path $env:LOCALAPPDATA 'BillingActivityWatch'
$agentPath = Join-Path $installRoot 'activity-watch-agent.exe'
$configPath = Join-Path $installRoot 'activity-watch-agent.config.json'
$launcherTargetPath = Join-Path $installRoot 'BillingActivityWatch.exe'

if (-not (Test-Path -LiteralPath $LauncherPath -PathType Leaf)) {
    throw 'The Activity Watch launcher could not be found.'
}

New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
$runningAgents = @(Get-CimInstance Win32_Process -Filter "Name='activity-watch-agent.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.ExecutablePath -and [string]::Equals($_.ExecutablePath, $agentPath, [System.StringComparison]::OrdinalIgnoreCase) })
foreach ($process in $runningAgents) {
    Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
}
if ($runningAgents.Count -gt 0) {
    Start-Sleep -Milliseconds 500
}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'activity-watch-agent.exe') -Destination $agentPath -Force
Copy-Item -LiteralPath $LauncherPath -Destination $launcherTargetPath -Force

$regExe = Join-Path $env:SystemRoot 'System32\reg.exe'
$fileClass = 'BillingActivityWatch.PairingFile'
$openCommand = '"{0}" "%1"' -f $launcherTargetPath
$registryValues = @(
    @('HKCU\Software\Classes\.billingawpair', $fileClass),
    @('HKCU\Software\Classes\BillingActivityWatch.PairingFile', 'Billing Activity Watch pairing file'),
    @('HKCU\Software\Classes\BillingActivityWatch.PairingFile\shell\open\command', $openCommand)
)
foreach ($entry in $registryValues) {
    & $regExe ADD $entry[0] /ve /d $entry[1] /f | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Could not register Activity Watch pairing files (reg.exe exit code $LASTEXITCODE)."
    }
}

# Updating stops the installed process before replacing its executable. Resume
# an already-paired installation immediately instead of waiting for a new logon
# or requiring the Scheduled Task to be restarted manually.
if (Test-Path -LiteralPath $configPath -PathType Leaf) {
    Start-Process -FilePath $agentPath `
        -ArgumentList @('run', '--config', ('"{0}"' -f $configPath)) `
        -WindowStyle Hidden
}

Write-Host 'Billing Activity Watch is installed. Existing pairing resumes automatically; open a new pairing file only when connecting a new device.'
