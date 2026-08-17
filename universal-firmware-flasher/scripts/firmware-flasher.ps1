[CmdletBinding()]
param(
    [string]$Config = 'firmware-flash.json',
    [string]$Target,
    [string]$Port,
    [int]$LogSeconds = 0,
    [string]$VerifyLog,
    [switch]$List,
    [switch]$NonInteractive,
    [switch]$NoBuild,
    [switch]$SkipLog,
    [switch]$SkipVerify,
    [switch]$VerifyOnly
)

$ErrorActionPreference = 'Stop'
$script:RunLogPath = $null
$script:WorkspaceRoot = $null

function Get-Value {
    param(
        [AllowNull()] [object]$Object,
        [Parameter(Mandatory)] [string]$Name,
        [AllowNull()] [object]$Default = $null
    )

    if ($null -eq $Object) { return $Default }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) { return $Default }
    return $property.Value
}

function Expand-Template {
    param(
        [AllowNull()] [object]$Value,
        [Parameter(Mandatory)] [hashtable]$Values
    )

    if ($null -eq $Value) { return $null }
    $result = [string]$Value
    foreach ($key in $Values.Keys) {
        $result = $result.Replace("{$key}", [string]$Values[$key])
    }
    return $result
}

function Resolve-WorkspacePath {
    param([AllowNull()] [string]$Path)

    if (-not $Path) { return $script:WorkspaceRoot }
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $script:WorkspaceRoot $Path))
}

function Write-RunLog {
    param([AllowNull()] [string]$Line)

    if ($script:RunLogPath) {
        Add-Content -LiteralPath $script:RunLogPath -Value $Line -Encoding UTF8
    }
}

function Find-Tool {
    param(
        [Parameter(Mandatory)] [string]$Name,
        [string]$Fallback
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -ne $command) { return $command.Source }
    if ($Fallback -and (Test-Path -LiteralPath $Fallback)) { return $Fallback }
    return $null
}

function Get-SerialPorts {
    try {
        return @([System.IO.Ports.SerialPort]::GetPortNames() |
            Sort-Object {
                if ($_ -match '\d+$') { [int]$Matches[0] } else { 0 }
            })
    } catch {
        return @()
    }
}

function Show-Header {
    Clear-Host
    Write-Host 'Universal firmware flasher' -ForegroundColor Cyan
    Write-Host 'Use Up/Down and Enter. Esc cancels.' -ForegroundColor DarkGray
    Write-Host
}

function Select-Menu {
    param(
        [Parameter(Mandatory)] [string]$Title,
        [Parameter(Mandatory)] [string[]]$Options
    )

    $selected = 0
    while ($true) {
        Show-Header
        Write-Host $Title -ForegroundColor White
        Write-Host
        for ($index = 0; $index -lt $Options.Count; $index++) {
            if ($index -eq $selected) {
                Write-Host ("  > {0}" -f $Options[$index]) -ForegroundColor Black -BackgroundColor Cyan
            } else {
                Write-Host ("    {0}" -f $Options[$index])
            }
        }

        $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        switch ($key.VirtualKeyCode) {
            38 { $selected = [Math]::Max(0, $selected - 1) }
            40 { $selected = [Math]::Min($Options.Count - 1, $selected + 1) }
            13 { return $selected }
            27 { return -1 }
            default {
                if ($key.Character -match '^[1-9]$') {
                    $number = [int][string]$key.Character - 1
                    if ($number -ge 0 -and $number -lt $Options.Count) { return $number }
                }
            }
        }
    }
}

function Select-SerialPort {
    while ($true) {
        $ports = @(Get-SerialPorts)
        $options = @($ports)
        if ($options.Count -eq 0) { $options += '(no COM ports detected)' }
        $options += 'Refresh port list'
        $options += 'Enter COM port manually'
        $options += 'Cancel'

        $choice = Select-Menu -Title 'Choose the serial port' -Options $options
        if ($choice -lt 0 -or $choice -eq $options.Count - 1) { return $null }
        if ($ports.Count -gt 0 -and $choice -lt $ports.Count) { return $ports[$choice] }

        $manualIndex = $ports.Count + 1
        if ($choice -eq $manualIndex) {
            $value = (Read-Host 'Enter a COM port such as COM8 (blank to cancel)').Trim().ToUpperInvariant()
            if (-not $value) { continue }
            if ($value -match '^COM\d+$') { return $value }
            Write-Host 'Invalid COM port.' -ForegroundColor Yellow
            [void](Read-Host 'Press Enter to continue')
        }
    }
}

function Normalize-CommandSpec {
    param(
        [Parameter(Mandatory)] [object]$Spec,
        [Parameter(Mandatory)] [hashtable]$Values
    )

    if ($Spec -is [string]) {
        return [pscustomobject]@{
            command = 'cmd.exe'
            args = @('/d', '/s', '/c', (Expand-Template $Spec $Values))
            cwd = '.'
        }
    }
    return $Spec
}

function Invoke-ConfiguredCommand {
    param(
        [Parameter(Mandatory)] [object]$Spec,
        [Parameter(Mandatory)] [hashtable]$Values,
        [Parameter(Mandatory)] [string]$Label
    )

    $commandSpec = Normalize-CommandSpec -Spec $Spec -Values $Values
    $commandName = [string](Get-Value $commandSpec 'command')
    if (-not $commandName) { throw "$Label has no command." }

    $command = Find-Tool -Name (Expand-Template $commandName $Values)
    if (-not $command) {
        $command = Expand-Template $commandName $Values
    }

    $arguments = @()
    $configuredArgs = Get-Value $commandSpec 'args' @()
    foreach ($argument in @($configuredArgs)) {
        $arguments += Expand-Template $argument $Values
    }

    $cwd = Resolve-WorkspacePath (Expand-Template (Get-Value $commandSpec 'cwd' '.') $Values)
    if (-not (Test-Path -LiteralPath $cwd -PathType Container)) {
        throw "$Label working directory does not exist: $cwd"
    }

    Write-Host
    Write-Host "[$Label] $command $($arguments -join ' ')" -ForegroundColor DarkCyan
    Write-RunLog "[$Label] $command $($arguments -join ' ')"

    $captured = [System.Collections.Generic.List[string]]::new()
    Push-Location $cwd
    try {
        & $command @arguments 2>&1 | ForEach-Object {
            $line = [string]$_
            [void]$captured.Add($line)
            Write-RunLog $line
            Write-Host $line
        }
        $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }
    } finally {
        Pop-Location
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = @($captured)
    }
}

function Confirm-Run {
    param(
        [Parameter(Mandatory)] [object]$TargetSpec,
        [string]$SelectedPort,
        [int]$Seconds
    )

    Write-Host
    Write-Host "Target: $(Get-Value $TargetSpec 'name' (Get-Value $TargetSpec 'id' 'unnamed'))" -ForegroundColor Yellow
    if ($SelectedPort) { Write-Host "COM port: $SelectedPort" -ForegroundColor Yellow }
    else { Write-Host 'COM port: not required' -ForegroundColor Yellow }
    Write-Host "Post-flash logging: $Seconds second(s)" -ForegroundColor Yellow
    Write-Host
    return ((Read-Host 'Build, flash, log, and verify? [y/N]').Trim() -match '^(y|yes)$')
}

function Test-VerificationRule {
    param(
        [Parameter(Mandatory)] [object]$Rule,
        [Parameter(Mandatory)] [string]$Text
    )

    $ignoreCase = [bool](Get-Value $Rule 'ignoreCase' $false)
    $regexOptions = [System.Text.RegularExpressions.RegexOptions]::None
    if ($ignoreCase) { $regexOptions = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase }

    $name = Get-Value $Rule 'name' 'unnamed check'
    $minMatches = [int](Get-Value $Rule 'minMatches' 1)
    $maxMatches = Get-Value $Rule 'maxMatches' $null
    $positiveCount = 0
    $hasPositive = $false

    $contains = Get-Value $Rule 'contains' $null
    if ($null -ne $contains) {
        $hasPositive = $true
        $comparison = if ($ignoreCase) {
            [System.StringComparison]::OrdinalIgnoreCase
        } else {
            [System.StringComparison]::Ordinal
        }
        if ($Text.IndexOf([string]$contains, $comparison) -ge 0) { $positiveCount = 1 }
    }

    $pattern = Get-Value $Rule 'regex' $null
    if ($null -ne $pattern) {
        $hasPositive = $true
        try {
            $positiveCount = [System.Text.RegularExpressions.Regex]::Matches($Text, [string]$pattern, $regexOptions).Count
        } catch {
            throw "Verification '$name' has an invalid regex: $pattern"
        }
    }

    $hasNegative = $false
    $negativeFailed = $false
    $notContains = Get-Value $Rule 'notContains' $null
    if ($null -ne $notContains) {
        $hasNegative = $true
        $comparison = if ($ignoreCase) {
            [System.StringComparison]::OrdinalIgnoreCase
        } else {
            [System.StringComparison]::Ordinal
        }
        $negativeFailed = $Text.IndexOf([string]$notContains, $comparison) -ge 0
    }

    $notPattern = Get-Value $Rule 'notRegex' $null
    if ($null -ne $notPattern) {
        $hasNegative = $true
        try {
            $negativeFailed = [System.Text.RegularExpressions.Regex]::IsMatch($Text, [string]$notPattern, $regexOptions)
        } catch {
            throw "Verification '$name' has an invalid notRegex: $notPattern"
        }
    }

    if (-not $hasPositive -and -not $hasNegative) {
        throw "Verification '$name' needs contains, regex, notContains, or notRegex."
    }

    $passed = $true
    if ($hasPositive -and $positiveCount -lt $minMatches) { $passed = $false }
    if ($null -ne $maxMatches -and $positiveCount -gt [int]$maxMatches) { $passed = $false }
    if ($negativeFailed) { $passed = $false }

    if ($passed) {
        Write-Host "VERIFY PASS: $name" -ForegroundColor Green
    } else {
        Write-Host "VERIFY FAIL: $name (matches=$positiveCount, required=$minMatches)" -ForegroundColor Red
    }
    return $passed
}

function Invoke-Verifications {
    param(
        [Parameter(Mandatory)] [object]$TargetSpec,
        [Parameter(Mandatory)] [hashtable]$Values,
        [string[]]$LogOutput = @(),
        [string[]]$FlashOutput = @()
    )

    $rules = @(Get-Value $TargetSpec 'verify' @())
    if ($rules.Count -eq 0) {
        Write-Host 'No verification rules configured.' -ForegroundColor Yellow
        return $true
    }

    $allPassed = $true
    foreach ($rule in $rules) {
        $source = (Get-Value $rule 'source' 'log').ToLowerInvariant()
        if ($source -eq 'log') {
            $text = ($LogOutput -join [Environment]::NewLine) -replace "`r`n?", "`n"
        } elseif ($source -eq 'flash') {
            $text = ($FlashOutput -join [Environment]::NewLine) -replace "`r`n?", "`n"
        } elseif ($source -eq 'command') {
            if (-not (Get-Value $rule 'command' $null)) {
                throw "Command verification '$(Get-Value $rule 'name' 'unnamed check')' has no command."
            }
            $result = Invoke-ConfiguredCommand -Spec $rule -Values $Values -Label "verify:$(Get-Value $rule 'name' 'command')"
            if ($result.ExitCode -ne 0) {
                Write-Host "VERIFY FAIL: command exited with $($result.ExitCode)" -ForegroundColor Red
                $allPassed = $false
            }
            $text = ($result.Output -join [Environment]::NewLine) -replace "`r`n?", "`n"
        } else {
            throw "Unknown verification source '$source'."
        }

        if (-not (Test-VerificationRule -Rule $rule -Text $text)) { $allPassed = $false }
    }
    return $allPassed
}

try {
    $configPath = if ([System.IO.Path]::IsPathRooted($Config)) {
        [System.IO.Path]::GetFullPath($Config)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Config))
    }
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        throw "Flash manifest not found: $configPath"
    }

    $manifest = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    $configDirectory = Split-Path -Parent $configPath
    $workspaceSpec = Get-Value $manifest 'workspace' '.'
    $script:WorkspaceRoot = [System.IO.Path]::GetFullPath((Join-Path $configDirectory $workspaceSpec))
    if (-not (Test-Path -LiteralPath $script:WorkspaceRoot -PathType Container)) {
        throw "Manifest workspace does not exist: $script:WorkspaceRoot"
    }

    $targets = @(Get-Value $manifest 'targets' @())
    if ($targets.Count -eq 0) { throw 'The flash manifest contains no targets.' }

    if ($List) {
        foreach ($item in $targets) {
            $ports = Get-Value $item 'port' $null
            $needsPort = [bool](Get-Value $ports 'flashRequired' $false) -or [bool](Get-Value $ports 'logRequired' $false)
            Write-Host ("{0}`t{1}{2}" -f (Get-Value $item 'id' 'unnamed'), (Get-Value $item 'name' ''), $(if ($needsPort) { ' [COM port]' } else { '' }))
        }
        exit 0
    }

    if (-not $Target) {
        if ($NonInteractive) { throw '-Target is required with -NonInteractive.' }
        $options = @($targets | ForEach-Object { "$(Get-Value $_ 'name' (Get-Value $_ 'id' 'unnamed')) [$(Get-Value $_ 'id' 'unnamed')]" })
        $choice = Select-Menu -Title 'Choose firmware target' -Options $options
        if ($choice -lt 0) { exit 0 }
        $Target = [string](Get-Value $targets[$choice] 'id')
    }

    $targetSpec = @($targets | Where-Object { (Get-Value $_ 'id' '') -eq $Target }) | Select-Object -First 1
    if ($null -eq $targetSpec) { throw "Unknown target '$Target'. Use -List to see configured targets." }

    $portSpec = Get-Value $targetSpec 'port' $null
    $portRequired = [bool](Get-Value $portSpec 'flashRequired' $false) -or [bool](Get-Value $portSpec 'logRequired' $false)
    if (-not $Port) { $Port = Get-Value $portSpec 'default' $null }
    if ($Port) {
        $Port = $Port.Trim().ToUpperInvariant()
        if ($Port -notmatch '^COM\d+$') { throw "Invalid COM port '$Port'." }
    } elseif ($portRequired) {
        if ($NonInteractive) { throw "Target '$Target' requires -Port in non-interactive mode." }
        $Port = Select-SerialPort
        if (-not $Port) { exit 0 }
    }

    $defaults = Get-Value $manifest 'defaults' $null
    $logSpec = Get-Value $targetSpec 'log' $null
    if ($LogSeconds -le 0) {
        $LogSeconds = [int](Get-Value $logSpec 'seconds' (Get-Value $defaults 'logSeconds' 10))
    }
    if ($LogSeconds -lt 0) { throw '-LogSeconds cannot be negative.' }

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $targetId = [string](Get-Value $targetSpec 'id' 'firmware')
    $safeTargetId = $targetId -replace '[^A-Za-z0-9._-]', '_'
    $logDirectory = Get-Value $logSpec 'directory' (Get-Value $defaults 'logDirectory' 'artifacts/flash-logs')
    $logDirectoryPath = Resolve-WorkspacePath $logDirectory
    New-Item -ItemType Directory -Force -Path $logDirectoryPath | Out-Null
    $runLogPath = Join-Path $logDirectoryPath "$safeTargetId-$timestamp.run.log"
    $deviceLogPath = Join-Path $logDirectoryPath "$safeTargetId-$timestamp.device.log"
    $script:RunLogPath = $runLogPath
    Set-Content -LiteralPath $runLogPath -Value "Universal firmware flasher; target=$targetId; timestamp=$timestamp" -Encoding UTF8

    $artifactSpec = Get-Value $targetSpec 'artifact' (Get-Value (Get-Value $targetSpec 'flash' $null) 'artifact' $null)
    $artifact = if ($artifactSpec) { Resolve-WorkspacePath (Expand-Template $artifactSpec @{}) } else { '' }
    $values = @{
        workspace = $script:WorkspaceRoot
        port = $Port
        targetId = $targetId
        targetName = (Get-Value $targetSpec 'name' $targetId)
        artifact = $artifact
        logSeconds = $LogSeconds
        runLog = $runLogPath
        logFile = $deviceLogPath
        timestamp = $timestamp
    }

    if (-not $NonInteractive -and -not $VerifyOnly) {
        if (-not (Confirm-Run -TargetSpec $targetSpec -SelectedPort $Port -Seconds $LogSeconds)) {
            Write-Host 'Cancelled.' -ForegroundColor Yellow
            exit 0
        }
    }

    $flashResult = [pscustomobject]@{ ExitCode = 0; Output = @() }
    $logResult = [pscustomobject]@{ ExitCode = 0; Output = @() }

    if ($VerifyOnly) {
        if (-not $VerifyLog) { throw '-VerifyLog is required with -VerifyOnly.' }
        $verifyPath = Resolve-WorkspacePath $VerifyLog
        if (-not (Test-Path -LiteralPath $verifyPath -PathType Leaf)) { throw "Verification log not found: $verifyPath" }
        $logResult = [pscustomobject]@{ ExitCode = 0; Output = @(Get-Content -LiteralPath $verifyPath) }
    } else {
        if (-not $NoBuild) {
            $buildSpec = Get-Value $targetSpec 'build' $null
            if ($buildSpec) {
                $buildResult = Invoke-ConfiguredCommand -Spec $buildSpec -Values $values -Label 'build'
                if ($buildResult.ExitCode -ne 0) { throw "Build failed with exit code $($buildResult.ExitCode)." }
            } else {
                Write-Host 'No build command configured; continuing.' -ForegroundColor Yellow
            }
        }

        $flashSpec = Get-Value $targetSpec 'flash' $null
        if (-not $flashSpec) { throw "Target '$Target' has no flash command." }
        $flashResult = Invoke-ConfiguredCommand -Spec $flashSpec -Values $values -Label 'flash'
        if ($flashResult.ExitCode -ne 0) { throw "Flash failed with exit code $($flashResult.ExitCode)." }

        $resetSpec = Get-Value $targetSpec 'reset' $null
        if ($resetSpec) {
            $resetResult = Invoke-ConfiguredCommand -Spec $resetSpec -Values $values -Label 'reset'
            if ($resetResult.ExitCode -ne 0) { throw "Reset failed with exit code $($resetResult.ExitCode)." }
        }

        if (-not $SkipLog -and $logSpec) {
            if ($LogSeconds -eq 0) { Write-Host 'Logging disabled because log seconds is zero.' -ForegroundColor Yellow }
            else {
                $logResult = Invoke-ConfiguredCommand -Spec $logSpec -Values $values -Label 'log'
                if ($logResult.ExitCode -ne 0) { throw "Post-flash logging failed with exit code $($logResult.ExitCode)." }
                Set-Content -LiteralPath $deviceLogPath -Value $logResult.Output -Encoding UTF8
            }
        } elseif (-not $SkipLog) {
            Write-Host 'No post-flash log command configured.' -ForegroundColor Yellow
        }
    }

    $verificationPassed = $true
    if (-not $SkipVerify) {
        $verificationPassed = Invoke-Verifications -TargetSpec $targetSpec -Values $values -LogOutput $logResult.Output -FlashOutput $flashResult.Output
        if (-not $verificationPassed) { throw 'One or more verification checks failed.' }
    }

    Write-Host
    Write-Host 'FLASH_RESULT=PASS' -ForegroundColor Green
    Write-Host "FLASH_RUN_LOG=$runLogPath"
    if (Test-Path -LiteralPath $deviceLogPath) { Write-Host "FLASH_DEVICE_LOG=$deviceLogPath" }
    exit 0
} catch {
    Write-Host
    Write-Host "FLASH_RESULT=FAIL" -ForegroundColor Red
    Write-Host "Flash workflow failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($script:RunLogPath) { Write-Host "FLASH_RUN_LOG=$script:RunLogPath" }
    exit 1
}
