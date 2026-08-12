$ErrorActionPreference = 'Stop'
$installRoot = Join-Path $env:LOCALAPPDATA 'BillingActivityWatch'
$agentPath = Join-Path $installRoot 'activity-watch-agent.exe'
$configPath = Join-Path $installRoot 'activity-watch-agent.config.json'

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

$regExe = Join-Path $env:SystemRoot 'System32\reg.exe'
$fileClass = 'BillingActivityWatch.PairingFile'
$openCommand = '"{0}" pair --config "{1}" --bundle "%1"' -f $agentPath, $configPath
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

Write-Host 'Billing Activity Watch is installed. Return to ERP, create a new pairing file, and open it within 30 minutes.'
