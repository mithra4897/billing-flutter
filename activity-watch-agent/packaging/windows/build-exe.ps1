param(
    [string]$OutputPath = (Join-Path $PSScriptRoot 'BillingActivityWatch-windows.exe')
)

$ErrorActionPreference = 'Stop'
$agentRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$stage = Join-Path $env:TEMP ('BillingActivityWatch-' + [guid]::NewGuid())
$cscCandidates = @(
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'),
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe')
)
$cscPath = $cscCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

if ((go env CGO_ENABLED).Trim() -ne '1') {
    throw 'A GCC-compatible Windows C toolchain is required for SQLCipher. Set CGO_ENABLED=1 and CC=gcc before running this script.'
}
if (-not $cscPath) {
    throw 'The Windows .NET Framework C# compiler was not found.'
}

try {
    New-Item -ItemType Directory -Path $stage | Out-Null
    $agentBinary = Join-Path $stage 'activity-watch-agent.exe'
    $installScript = Join-Path $stage 'install.ps1'
    $launcherSource = Join-Path $stage 'InstallerLauncher.cs'

    Push-Location $agentRoot
    go build -o $agentBinary .\cmd\activity-watch-agent
    if ($LASTEXITCODE -ne 0) {
        throw "Go failed to build the Activity Watch agent (exit code $LASTEXITCODE)."
    }
    Pop-Location

    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'install.ps1') -Destination $installScript
    @'
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

internal static class InstallerLauncher
{
    [STAThread]
    private static int Main(string[] arguments)
    {
        if (arguments.Length == 1 && arguments[0].EndsWith(".billingawpair", StringComparison.OrdinalIgnoreCase))
        {
            return Pair(arguments[0]);
        }

        string stage = Path.Combine(
            Path.GetTempPath(),
            "BillingActivityWatch-" + Guid.NewGuid().ToString("N"));

        try
        {
            Directory.CreateDirectory(stage);
            string agentPath = Path.Combine(stage, "activity-watch-agent.exe");
            string scriptPath = Path.Combine(stage, "install.ps1");
            ExtractResource("BillingActivityWatch.Agent", agentPath);
            ExtractResource("BillingActivityWatch.InstallScript", scriptPath);

            string systemDirectory = Environment.GetFolderPath(Environment.SpecialFolder.System);
            string powershell = Path.Combine(
                systemDirectory,
                @"WindowsPowerShell\v1.0\powershell.exe");
            var startInfo = new ProcessStartInfo
            {
                FileName = powershell,
                Arguments = "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File \"" + scriptPath + "\" -LauncherPath \"" + Assembly.GetExecutingAssembly().Location + "\"",
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
            };

            using (Process process = Process.Start(startInfo))
            {
                string output = process.StandardOutput.ReadToEnd();
                string errorOutput = process.StandardError.ReadToEnd();
                process.WaitForExit();
                if (process.ExitCode != 0)
                {
                    string detail = string.IsNullOrWhiteSpace(errorOutput)
                        ? output
                        : errorOutput;
                    throw new InvalidOperationException(
                        "The installation script failed with exit code " + process.ExitCode + "." +
                        (string.IsNullOrWhiteSpace(detail) ? "" : Environment.NewLine + detail.Trim()));
                }
            }

            MessageBox.Show(
                "Billing Activity Watch was installed. An existing pairing resumes automatically. Open a new pairing file only when connecting a new device.",
                "Billing Activity Watch",
                MessageBoxButtons.OK,
                MessageBoxIcon.Information);
            return 0;
        }
        catch (Exception error)
        {
            MessageBox.Show(
                error.Message,
                "Billing Activity Watch installation failed",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
            return 1;
        }
        finally
        {
            try
            {
                if (Directory.Exists(stage))
                {
                    Directory.Delete(stage, true);
                }
            }
            catch
            {
                // Installation has completed; temporary cleanup is best effort.
            }
        }
    }

    private static int Pair(string bundlePath)
    {
        string installRoot = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "BillingActivityWatch");
        string agentPath = Path.Combine(installRoot, "activity-watch-agent.exe");
        string configPath = Path.Combine(installRoot, "activity-watch-agent.config.json");
        if (!File.Exists(agentPath))
        {
            MessageBox.Show(
                "The Activity Watch agent is missing. Reinstall the agent, then download a new pairing file.",
                "Activity Watch setup failed",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
            return 1;
        }

        try
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = agentPath,
                Arguments = "pair --config \"" + configPath + "\" --bundle \"" + bundlePath + "\"",
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
            };
            string pairingOutput;
            using (Process process = Process.Start(startInfo))
            {
                string output = process.StandardOutput.ReadToEnd();
                string errorOutput = process.StandardError.ReadToEnd();
                process.WaitForExit();
                if (process.ExitCode != 0)
                {
                    string detail = string.IsNullOrWhiteSpace(errorOutput) ? output : errorOutput;
                    throw new InvalidOperationException(
                        "Activity Watch could not pair this computer." +
                        (string.IsNullOrWhiteSpace(detail) ? "" : Environment.NewLine + detail.Trim()));
                }
                pairingOutput = output;
            }
            bool startupWarning = pairingOutput.IndexOf(
                "Automatic background startup could not be configured:",
                StringComparison.Ordinal) >= 0;
            MessageBox.Show(
                startupWarning
                    ? "This computer is connected to Activity Watch, but Windows blocked automatic background startup. An administrator must configure the BillingActivityWatch scheduled task. Return to ERP and refresh Devices."
                    : "This computer is connected to Activity Watch. Return to ERP and refresh Devices.",
                startupWarning ? "Activity Watch startup needs attention" : "Billing Activity Watch",
                MessageBoxButtons.OK,
                startupWarning ? MessageBoxIcon.Warning : MessageBoxIcon.Information);
            return 0;
        }
        catch (Exception error)
        {
            MessageBox.Show(
                error.Message,
                "Activity Watch setup failed",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
            return 1;
        }
    }

    private static void ExtractResource(string resourceName, string outputPath)
    {
        Assembly assembly = Assembly.GetExecutingAssembly();
        using (Stream input = assembly.GetManifestResourceStream(resourceName))
        {
            if (input == null)
            {
                throw new InvalidOperationException("Missing installer resource: " + resourceName);
            }
            using (FileStream output = File.Create(outputPath))
            {
                input.CopyTo(output);
            }
        }
    }
}
'@ | Set-Content -Encoding Ascii $launcherSource

    $outputDirectory = Split-Path -Parent $OutputPath
    if ($outputDirectory) {
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    }
    & $cscPath `
        /nologo `
        /target:winexe `
        "/out:$OutputPath" `
        "/resource:$agentBinary,BillingActivityWatch.Agent" `
        "/resource:$installScript,BillingActivityWatch.InstallScript" `
        /reference:System.Windows.Forms.dll `
        $launcherSource
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $OutputPath)) {
        throw "The Windows installer launcher build failed (exit code $LASTEXITCODE)."
    }
    Write-Host "Created $OutputPath"
}
finally {
    if ((Get-Location).Path -eq $agentRoot.Path) { Pop-Location }
    Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
}
