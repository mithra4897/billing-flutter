param(
    [Parameter(Mandatory = $true)]
    [string]$LauncherPath,
    [Parameter(Mandatory = $true)]
    [string]$InstallRoot,
    [string]$ErrorPath
)

$ErrorActionPreference = 'Stop'
trap {
    if (-not [string]::IsNullOrWhiteSpace($ErrorPath)) {
        try {
            $_ | Out-String | Set-Content -LiteralPath $ErrorPath -Encoding UTF8
        } catch {
            # Reporting the original installation error is best effort.
        }
    }
    exit 1
}

$agentPath = Join-Path $installRoot 'activity-watch-agent.exe'
$configPath = Join-Path $installRoot 'activity-watch-agent.config.json'
$launcherTargetPath = Join-Path $installRoot 'BillingActivityWatch.exe'

if (-not (Test-Path -LiteralPath $LauncherPath -PathType Leaf)) {
    throw 'The Activity Watch launcher could not be found.'
}

New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
$service = Get-Service -Name 'BillingActivityWatch' -ErrorAction SilentlyContinue
if ($service -and $service.Status -ne 'Stopped') {
    Stop-Service -Name $service.Name -Force -ErrorAction Stop
    $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Stopped, [TimeSpan]::FromSeconds(15))
}
$runningAgents = @(Get-CimInstance Win32_Process -Filter "Name='activity-watch-agent.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.ExecutablePath -and [string]::Equals($_.ExecutablePath, $agentPath, [System.StringComparison]::OrdinalIgnoreCase) })
foreach ($process in $runningAgents) {
    Stop-Process -Id $process.ProcessId -Force -ErrorAction Stop
}
if ($runningAgents.Count -gt 0) {
    $deadline = (Get-Date).AddSeconds(15)
    $remainingAgents = @()
    do {
        $remainingAgents = @(Get-CimInstance Win32_Process -Filter "Name='activity-watch-agent.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.ExecutablePath -and [string]::Equals($_.ExecutablePath, $agentPath, [System.StringComparison]::OrdinalIgnoreCase) })
        if ($remainingAgents.Count -eq 0) {
            break
        }
        Start-Sleep -Milliseconds 250
    } while ((Get-Date) -lt $deadline)
    if ($remainingAgents.Count -gt 0) {
        throw 'The existing Activity Watch process did not stop, so the update cannot safely replace its executable.'
    }
}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'activity-watch-agent.exe') -Destination $agentPath -Force
Copy-Item -LiteralPath $LauncherPath -Destination $launcherTargetPath -Force

$fileClass = 'BillingActivityWatch.PairingFile'
$openCommand = '"{0}" "%1"' -f $launcherTargetPath
$classesKey = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Software\Classes')
try {
    $extensionKey = $classesKey.CreateSubKey('.billingawpair')
    try { $extensionKey.SetValue('', $fileClass) } finally { $extensionKey.Dispose() }

    $fileClassKey = $classesKey.CreateSubKey($fileClass)
    try { $fileClassKey.SetValue('', 'Billing Activity Watch pairing file') } finally { $fileClassKey.Dispose() }

    $commandKey = $classesKey.CreateSubKey("$fileClass\shell\open\command")
    try { $commandKey.SetValue('', $openCommand) } finally { $commandKey.Dispose() }
} finally {
    $classesKey.Dispose()
}

# Updating stops the installed process before replacing its executable. Resume
# an already-paired installation immediately instead of waiting for a new logon
# or requiring the Scheduled Task to be restarted manually.
if ($service) {
    Start-Service -Name $service.Name -ErrorAction Stop
} elseif (Test-Path -LiteralPath $configPath -PathType Leaf) {
    Start-Process -FilePath $agentPath `
        -ArgumentList @('run', '--config', ('"{0}"' -f $configPath)) `
        -WindowStyle Hidden
}

Write-Host 'Billing Activity Watch is installed. Existing pairing resumes automatically; open a new pairing file only when connecting a new device.'
