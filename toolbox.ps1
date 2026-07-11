[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Arguments,

    [string]$DataRoot = (Join-Path $PSScriptRoot "data")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$NotesRoot = Join-Path $DataRoot "notes"
$ExportsRoot = Join-Path $DataRoot "exports"

function Initialize-Storage {
    foreach ($path in @($NotesRoot, $ExportsRoot)) {
        if (-not (Test-Path -LiteralPath $path)) {
            New-Item -ItemType Directory -Path $path | Out-Null
        }
    }
}

function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $rootPath = (Resolve-Path -LiteralPath $PSScriptRoot).Path
    $targetPath = (Resolve-Path -LiteralPath $Path).Path
    $rootUri = New-Object System.Uri(($rootPath.TrimEnd('\') + '\'))
    $targetUri = New-Object System.Uri($targetPath)
    $relativeUri = $rootUri.MakeRelativeUri($targetUri)

    return [System.Uri]::UnescapeDataString($relativeUri.ToString()).Replace('/', '\')
}

function Get-NotePathForDate {
    param(
        [Parameter(Mandatory = $true)]
        [datetime]$Date
    )

    $yearRoot = Join-Path $NotesRoot $Date.ToString("yyyy")
    if (-not (Test-Path -LiteralPath $yearRoot)) {
        New-Item -ItemType Directory -Path $yearRoot | Out-Null
    }

    return Join-Path $yearRoot ($Date.ToString("yyyy-MM-dd") + ".md")
}

function Ensure-NoteHeader {
    param(
        [Parameter(Mandatory = $true)]
        [string]$NotePath,

        [Parameter(Mandatory = $true)]
        [datetime]$Date
    )

    if (-not (Test-Path -LiteralPath $NotePath)) {
        @(
            "# Daily Note - $($Date.ToString("yyyy-MM-dd"))"
            ""
            "## Entries"
            ""
        ) | Set-Content -LiteralPath $NotePath
    }
}

function Get-NoteFilesFromDays {
    param(
        [int]$Days = 7
    )

    if (-not (Test-Path -LiteralPath $NotesRoot)) {
        return @()
    }

    $cutoff = (Get-Date).Date.AddDays(-($Days - 1))

    return @(Get-ChildItem -Path $NotesRoot -Recurse -File -Filter *.md |
        Where-Object {
            $basename = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
            [datetime]$parsed = [datetime]::MinValue
            if ([datetime]::TryParseExact(
                    $basename,
                    "yyyy-MM-dd",
                    [System.Globalization.CultureInfo]::InvariantCulture,
                    [System.Globalization.DateTimeStyles]::None,
                    [ref]$parsed
                )) {
                return $parsed.Date -ge $cutoff
            }

            return $false
        } |
        Sort-Object Name)
}

function Get-EntryCount {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return @(
        Get-Content -LiteralPath $Path |
        Where-Object { $_ -match '^- \d{2}:\d{2} ' }
    ).Count
}

function Show-Help {
    @"
Personal AI Toolbox

Usage:
  .\toolbox.ps1 help
  .\toolbox.ps1 capture "your note here"
  .\toolbox.ps1 list
  .\toolbox.ps1 find terminal
  .\toolbox.ps1 export-week
  .\toolbox.ps1 review-week

Tips:
  - Add tags like #learning or #todo in your notes.
  - Use export-week before asking ChatGPT or Grok for a review.
"@ | Write-Output
}

function Invoke-Capture {
    $text = ($Arguments -join " ").Trim()
    if ([string]::IsNullOrWhiteSpace($text)) {
        $text = Read-Host "Enter a note"
    }

    if ([string]::IsNullOrWhiteSpace($text)) {
        throw "No note text provided."
    }

    $now = Get-Date
    $notePath = Get-NotePathForDate -Date $now
    Ensure-NoteHeader -NotePath $notePath -Date $now

    Add-Content -LiteralPath $notePath -Value "- $($now.ToString("HH:mm")) $text"

    Write-Output "Captured note in $(Get-RelativePath -Path $notePath)"
}

function Invoke-List {
    $files = @(Get-NoteFilesFromDays -Days 7)

    if ($files.Count -eq 0) {
        Write-Output "No notes found for the last 7 days."
        return
    }

    foreach ($file in $files) {
        $count = Get-EntryCount -Path $file.FullName
        Write-Output ("{0} ({1} entries)" -f (Get-RelativePath -Path $file.FullName), $count)
    }
}

function Invoke-Find {
    $pattern = ($Arguments -join " ").Trim()
    if ([string]::IsNullOrWhiteSpace($pattern)) {
        throw "Provide a search term. Example: .\toolbox.ps1 find terminal"
    }

    $rgCommand = Get-Command rg -ErrorAction SilentlyContinue
    if ($null -ne $rgCommand) {
        & $rgCommand.Source --line-number --color never --glob *.md -- $pattern $NotesRoot
        return
    }

    Get-ChildItem -Path $NotesRoot -Recurse -File -Filter *.md |
        Select-String -Pattern $pattern -CaseSensitive:$false -SimpleMatch
}

function Get-WeeklyTagCounts {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$Files
    )

    $tagCounts = @{}
    $tagPattern = '#[A-Za-z0-9_-]+'

    foreach ($file in $Files) {
        foreach ($line in Get-Content -LiteralPath $file.FullName) {
            foreach ($match in [regex]::Matches($line, $tagPattern)) {
                $tag = $match.Value.ToLowerInvariant()
                if (-not $tagCounts.ContainsKey($tag)) {
                    $tagCounts[$tag] = 0
                }

                $tagCounts[$tag] += 1
            }
        }
    }

    return $tagCounts
}

function Invoke-ExportWeek {
    $files = @(Get-NoteFilesFromDays -Days 7)

    if ($files.Count -eq 0) {
        Write-Output "No notes found for the last 7 days, so there is nothing to export."
        return
    }

    $today = Get-Date
    $exportPath = Join-Path $ExportsRoot ("week-ending-" + $today.ToString("yyyy-MM-dd") + ".md")

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# Weekly Notes Export")
    $lines.Add("")
    $lines.Add("Generated: $($today.ToString("yyyy-MM-dd HH:mm"))")
    $lines.Add("")

    foreach ($file in $files) {
        $lines.Add("## $([System.IO.Path]::GetFileNameWithoutExtension($file.Name))")
        $lines.Add("")
        foreach ($line in Get-Content -LiteralPath $file.FullName) {
            $lines.Add($line)
        }
        $lines.Add("")
    }

    $lines | Set-Content -LiteralPath $exportPath

    Write-Output "Created $(Get-RelativePath -Path $exportPath)"
    Write-Output "Next step: paste that file into ChatGPT or Grok with prompts/weekly-review.md"
}

function Invoke-ReviewWeek {
    $files = @(Get-NoteFilesFromDays -Days 7)

    if ($files.Count -eq 0) {
        Write-Output "No notes found for the last 7 days."
        return
    }

    $entryTotal = 0
    foreach ($file in $files) {
        $entryTotal += Get-EntryCount -Path $file.FullName
    }

    $tagCounts = Get-WeeklyTagCounts -Files $files

    Write-Output "Weekly review"
    Write-Output "-------------"
    Write-Output "Notes touched: $($files.Count)"
    Write-Output "Entries captured: $entryTotal"

    if ($tagCounts.Count -gt 0) {
        Write-Output "Top tags:"
        $tagCounts.GetEnumerator() |
            Sort-Object Value -Descending |
            Select-Object -First 5 |
            ForEach-Object {
                Write-Output ("  {0} ({1})" -f $_.Key, $_.Value)
            }
    }
    else {
        Write-Output "Top tags: none yet"
    }

    Write-Output "Files:"
    foreach ($file in $files) {
        $count = Get-EntryCount -Path $file.FullName
        Write-Output ("  {0} ({1} entries)" -f (Get-RelativePath -Path $file.FullName), $count)
    }
}

Initialize-Storage

switch ($Command.ToLowerInvariant()) {
    "help" { Show-Help }
    "capture" { Invoke-Capture }
    "list" { Invoke-List }
    "find" { Invoke-Find }
    "export-week" { Invoke-ExportWeek }
    "review-week" { Invoke-ReviewWeek }
    default { throw "Unknown command '$Command'. Run .\toolbox.ps1 help" }
}
