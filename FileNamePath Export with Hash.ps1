<#
.SYNOPSIS
    Exports file and folder metadata with optional hash calculation to CSV.

.DESCRIPTION
    Recursively scans a directory and exports detailed file metadata including
    hierarchical parent-child relationships, timestamps, and optional MD5/SHA256 hashes
    to a CSV file for analysis.

.PARAMETER SourcePath
    The root directory to scan. Must be a valid directory path.

.PARAMETER OutputPath
    The CSV file path for export. Parent directory must exist.

.PARAMETER IncludeHash
    Switch to enable hash calculation (MD5 and SHA256). Warning: This significantly
    increases processing time for large files.

.PARAMETER HashAlgorithm
    Hash algorithm to use. Options: MD5, SHA1, SHA256, SHA512. Default is MD5.

.EXAMPLE
    .\FileNamePath Export with Hash.ps1 -SourcePath "C:\shares" -OutputPath "C:\reports\export.csv"

    Scans C:\shares and exports metadata without hashes.

.EXAMPLE
    .\FileNamePath Export with Hash.ps1 -SourcePath "C:\shares" -OutputPath "C:\export.csv" -IncludeHash

    Scans C:\shares and exports metadata including MD5 hashes.

.EXAMPLE
    .\FileNamePath Export with Hash.ps1 -SourcePath "C:\shares" -OutputPath "C:\export.csv" -IncludeHash -HashAlgorithm SHA256

    Scans C:\shares and exports metadata including SHA256 hashes.

.NOTES
    Author: Cameron Stewart
    Version: 2.0
    Requires: PowerShell 5.1 or higher

    WARNING: Hash calculation can be slow on large files. Use -IncludeHash only when needed.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage="Root directory to scan")]
    [ValidateScript({
        if (Test-Path $_ -PathType Container) { $true }
        else { throw "Path '$_' does not exist or is not a directory." }
    })]
    [string]$SourcePath,

    [Parameter(Mandatory=$true, HelpMessage="Output CSV file path")]
    [ValidateScript({
        $parent = Split-Path $_
        if ([string]::IsNullOrEmpty($parent)) { $parent = "." }
        if (Test-Path $parent -PathType Container) { $true }
        else { throw "Output directory '$parent' does not exist." }
    })]
    [string]$OutputPath,

    [Parameter(Mandatory=$false)]
    [switch]$IncludeHash,

    [Parameter(Mandatory=$false)]
    [ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA512')]
    [string]$HashAlgorithm = 'MD5'
)

# Initialize ID counter
$ID = 1

# Arrays to store results and errors
$SourcePathFileOutput = @()
$ErrorLog = @()

Write-Host "Scanning directory: $SourcePath" -ForegroundColor Cyan
Write-Host "Output file: $OutputPath" -ForegroundColor Cyan
if ($IncludeHash) {
    Write-Host "Hash algorithm: $HashAlgorithm (Warning: This will be slow for large files)" -ForegroundColor Yellow
}
Write-Host ""

# Process the parent directory
try {
    $SourcePathFileOutput += Get-Item $SourcePath -ErrorAction Stop | ForEach-Object {
        $ParentPath = if ($_.PSIsContainer) { $_.parent.FullName } else { $_.DirectoryName }

        Add-Member -InputObject $_ -MemberType NoteProperty -Name "ID" -Value ($ID++) -Force
        Add-Member -InputObject $_ -MemberType NoteProperty -Name "PARENTPATH" -Value $ParentPath -Force
        $_
    }
} catch {
    Write-Error "Failed to access source path: $SourcePath"
    Write-Error $_.Exception.Message
    exit 1
}

# Process all directories and files recursively
Write-Host "Enumerating files and folders..." -ForegroundColor Cyan
try {
    $allItems = @(Get-ChildItem $SourcePath -Recurse -Force -ErrorAction SilentlyContinue)
    $totalItems = $allItems.Count
    $processedItems = 0

    foreach ($item in $allItems) {
        $processedItems++

        # Progress indicator
        if ($processedItems % 100 -eq 0 -or $processedItems -eq $totalItems) {
            $percentComplete = [math]::Round(($processedItems / $totalItems) * 100, 2)
            Write-Progress -Activity "Scanning files and folders" `
                -Status "Processed $processedItems of $totalItems items ($percentComplete%)" `
                -PercentComplete $percentComplete
        }

        try {
            $ParentPath = if ($item.PSIsContainer) { $item.parent.FullName } else { $item.DirectoryName }

            Add-Member -InputObject $item -MemberType NoteProperty -Name "ID" -Value ($ID++) -Force
            Add-Member -InputObject $item -MemberType NoteProperty -Name "PARENTPATH" -Value $ParentPath -Force

            $SourcePathFileOutput += $item
        } catch {
            $ErrorLog += [PSCustomObject]@{
                Path = $item.FullName
                Error = $_.Exception.Message
                ErrorType = "Enumeration"
            }
            Write-Verbose "Failed to process: $($item.FullName) - $($_.Exception.Message)"
        }
    }

    Write-Progress -Activity "Scanning files and folders" -Completed
} catch {
    Write-Error "Failed to enumerate directory contents: $($_.Exception.Message)"
}

# List directories for parent ID lookup optimization
Write-Host "Building directory index..." -ForegroundColor Cyan
$DirOutput = $SourcePathFileOutput | Where-Object { $_.psiscontainer }

# Process output results with optional hash calculation
Write-Host "Generating output data..." -ForegroundColor Cyan
$totalToProcess = $SourcePathFileOutput.Count
$currentProcessed = 0

$list = foreach ($Current in $SourcePathFileOutput) {
    $currentProcessed++

    # Progress indicator for hash calculation
    if ($IncludeHash -and ($currentProcessed % 50 -eq 0 -or $currentProcessed -eq $totalToProcess)) {
        $percentComplete = [math]::Round(($currentProcessed / $totalToProcess) * 100, 2)
        Write-Progress -Activity "Processing files (calculating hashes)" `
            -Status "Processed $currentProcessed of $totalToProcess files ($percentComplete%)" `
            -PercentComplete $percentComplete
    }

    # Build base result object
    $Result = [pscustomobject]@{
        Path = $Current.FullName
        Name = $Current.Name
        ISDIR = $Current.psiscontainer
        ID = $Current.ID
        PARENTID = ($DirOutput | Where-Object { $_.FullName -eq $Current.PARENTPATH }).ID
        PARENTPATH = $Current.PARENTPATH
        ParentName = $Current.Parent
        CreationTime = $Current.CreationTime
        LastAccessTime = $Current.LastAccessTime
        LastWriteTime = $Current.LastWriteTime
        Extension = $Current.Extension
        BaseName = $Current.BaseName
        Bytes = $Current.Length
    }

    # Calculate hash if requested and item is a file (not a directory)
    if ($IncludeHash -and -not $Current.PSIsContainer) {
        try {
            $hash = Get-FileHash -Path $Current.FullName -Algorithm $HashAlgorithm -ErrorAction Stop
            Add-Member -InputObject $Result -MemberType NoteProperty -Name $HashAlgorithm -Value $hash.Hash
        } catch [System.UnauthorizedAccessException] {
            Add-Member -InputObject $Result -MemberType NoteProperty -Name $HashAlgorithm -Value "ACCESS_DENIED"
            $ErrorLog += [PSCustomObject]@{
                Path = $Current.FullName
                Error = "Access denied"
                ErrorType = "Hash"
            }
        } catch {
            Add-Member -InputObject $Result -MemberType NoteProperty -Name $HashAlgorithm -Value "ERROR"
            $ErrorLog += [PSCustomObject]@{
                Path = $Current.FullName
                Error = $_.Exception.Message
                ErrorType = "Hash"
            }
            Write-Verbose "Failed to hash $($Current.FullName): $($_.Exception.Message)"
        }
    } elseif ($IncludeHash) {
        # Directory - no hash
        Add-Member -InputObject $Result -MemberType NoteProperty -Name $HashAlgorithm -Value $null
    }

    # Initialize parent root
    if ($Result.PARENTID -eq $null) { $Result.PARENTID = 0 }

    # Send result to output
    $Result
}

Write-Progress -Activity "Processing files" -Completed

# Export to CSV
Write-Host "Exporting to CSV: $OutputPath" -ForegroundColor Cyan
try {
    $list | Export-Csv -NoTypeInformation -Path $OutputPath -Encoding UTF8 -ErrorAction Stop
    Write-Host "SUCCESS: Exported $($list.Count) items to $OutputPath" -ForegroundColor Green
} catch {
    Write-Error "Failed to export CSV: $($_.Exception.Message)"
    exit 1
}

# Export error log if there were errors
if ($ErrorLog.Count -gt 0) {
    $errorLogPath = $OutputPath -replace '\.csv$', '_errors.csv'
    $ErrorLog | Export-Csv -NoTypeInformation -Path $errorLogPath -Encoding UTF8
    Write-Host "WARNING: Encountered $($ErrorLog.Count) errors. See $errorLogPath for details." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total items processed: $($list.Count)" -ForegroundColor White
Write-Host "  Files: $(($list | Where-Object { -not $_.ISDIR }).Count)" -ForegroundColor White
Write-Host "  Directories: $(($list | Where-Object { $_.ISDIR }).Count)" -ForegroundColor White
if ($IncludeHash) {
    Write-Host "  Hash algorithm: $HashAlgorithm" -ForegroundColor White
}
if ($ErrorLog.Count -gt 0) {
    Write-Host "  Errors: $($ErrorLog.Count)" -ForegroundColor Yellow
}
Write-Host ""
