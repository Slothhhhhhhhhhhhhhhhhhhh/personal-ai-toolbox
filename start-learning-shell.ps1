[CmdletBinding()]
param(
    [string]$LogRoot = (Join-Path $PSScriptRoot "logs")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

if (-not (Test-Path -LiteralPath $LogRoot)) {
    New-Item -ItemType Directory -Path $LogRoot | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logPath = Join-Path $LogRoot ("session-" + $timestamp + ".txt")

try {
    Stop-Transcript | Out-Null
}
catch {
    # No active transcript is normal here.
}

Set-Location $PSScriptRoot
Start-Transcript -Path $logPath | Out-Null

function global:prompt {
    return "LEARNING PS $($executionContext.SessionState.Path.CurrentLocation)> "
}

function global:Invoke-LearningCheck {
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "CHECKPOINT $timestamp"
}

Set-Alias -Name check -Value Invoke-LearningCheck -Scope Global -Force

Write-Host ""
Write-Host "Learning shell ready."
Write-Host "Project folder: $PSScriptRoot"
Write-Host "Transcript: $logPath"
Write-Host ""
Write-Host "This is not a true security sandbox."
Write-Host "It is a logged practice shell so commands and output are saved for review."
Write-Host ""
Write-Host "Safe starter commands:"
Write-Host "  Get-Location"
Write-Host "  Get-ChildItem"
Write-Host "  .\toolbox.ps1 help"
Write-Host "  check"
Write-Host ""
Write-Host "Use 'check' as a quick checkpoint marker."
Write-Host "Then send 'check' in chat and I can inspect the transcript."
Write-Host ""
Write-Host "When you want to stop logging, run:"
Write-Host "  Stop-Transcript"
Write-Host ""
