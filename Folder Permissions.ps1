<#
.SYNOPSIS
    Exports folder permissions and ACLs to CSV for audit purposes.

.DESCRIPTION
    Recursively scans a directory structure and exports comprehensive NTFS permission
    information including identity references (users/groups), access rights, inheritance,
    and access control type (Allow/Deny) to a CSV file.

.PARAMETER FolderPath
    The root directory to scan for permissions. Must be a valid directory path.

.PARAMETER OutputPath
    The CSV file path for permission export. Parent directory must exist.

.PARAMETER IncludeFiles
    Switch to include file permissions in addition to folder permissions.
    WARNING: This can significantly increase processing time and output size.

.EXAMPLE
    .\Folder Permissions.ps1 -FolderPath "C:\shares" -OutputPath "C:\reports\permissions.csv"

    Scans C:\shares and exports folder permissions only.

.EXAMPLE
    .\Folder Permissions.ps1 -FolderPath "C:\shares" -OutputPath "C:\permissions.csv" -IncludeFiles

    Scans C:\shares and exports both folder and file permissions.

.NOTES
    Author: Cameron Stewart
    Version: 2.0
    Requires: PowerShell 5.1 or higher, Administrator rights for full ACL access

    WARNING: Some folders may be inaccessible due to permissions. Errors are logged separately.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage="Root directory to scan for permissions")]
    [ValidateScript({
        if (Test-Path $_ -PathType Container) { $true }
        else { throw "Path '$_' does not exist or is not a directory." }
    })]
    [string]$FolderPath,

    [Parameter(Mandatory=$true, HelpMessage="Output CSV file path")]
    [ValidateScript({
        $parent = Split-Path $_
        if ([string]::IsNullOrEmpty($parent)) { $parent = "." }
        if (Test-Path $parent -PathType Container) { $true }
        else { throw "Output directory '$parent' does not exist." }
    })]
    [string]$OutputPath,

    [Parameter(Mandatory=$false)]
    [switch]$IncludeFiles
)

# Initialize arrays
$Report = @()
$ErrorLog = @()

Write-Host "Scanning folder permissions: $FolderPath" -ForegroundColor Cyan
Write-Host "Output file: $OutputPath" -ForegroundColor Cyan
if ($IncludeFiles) {
    Write-Host "Mode: Folders AND Files (Warning: This will be slower)" -ForegroundColor Yellow
} else {
    Write-Host "Mode: Folders only" -ForegroundColor White
}
Write-Host ""

# Get folders (and optionally files)
Write-Host "Enumerating items..." -ForegroundColor Cyan
try {
    if ($IncludeFiles) {
        $items = @(Get-ChildItem -Path $FolderPath -Recurse -Force -ErrorAction SilentlyContinue)
    } else {
        $items = @(Get-ChildItem -Directory -Path $FolderPath -Recurse -Force -ErrorAction SilentlyContinue)
    }

    $totalItems = $items.Count
    Write-Host "Found $totalItems items to process" -ForegroundColor White
    Write-Host ""
} catch {
    Write-Error "Failed to enumerate directory: $($_.Exception.Message)"
    exit 1
}

# Process each item
$processedItems = 0
foreach ($Item in $items) {
    $processedItems++

    # Progress indicator
    if ($processedItems % 10 -eq 0 -or $processedItems -eq $totalItems) {
        $percentComplete = [math]::Round(($processedItems / $totalItems) * 100, 2)
        Write-Progress -Activity "Scanning Permissions" `
            -Status "Processing: $($Item.FullName)" `
            -PercentComplete $percentComplete `
            -CurrentOperation "$processedItems of $totalItems items ($percentComplete%)"
    }

    try {
        $Acl = Get-Acl -Path $Item.FullName -ErrorAction Stop

        foreach ($Access in $Acl.Access) {
            $Properties = [ordered]@{
                'Path' = $Item.FullName
                'Name' = $Item.Name
                'IsDirectory' = $Item.PSIsContainer
                'Owner' = $Acl.Owner
                'ADGroupOrUser' = $Access.IdentityReference
                'AccessControlType' = $Access.AccessControlType  # Allow or Deny
                'FileSystemRights' = $Access.FileSystemRights
                'IsInherited' = $Access.IsInherited
                'InheritanceFlags' = $Access.InheritanceFlags
                'PropagationFlags' = $Access.PropagationFlags
            }

            $Report += New-Object -TypeName PSObject -Property $Properties
        }
    } catch [System.UnauthorizedAccessException] {
        $ErrorLog += [PSCustomObject]@{
            Path = $Item.FullName
            Error = "Access Denied"
            ErrorType = "UnauthorizedAccess"
        }
        Write-Verbose "Access denied: $($Item.FullName)"
    } catch {
        $ErrorLog += [PSCustomObject]@{
            Path = $Item.FullName
            Error = $_.Exception.Message
            ErrorType = "ACL"
        }
        Write-Verbose "Failed to get ACL for $($Item.FullName): $($_.Exception.Message)"
    }
}

Write-Progress -Activity "Scanning Permissions" -Completed

# Export results
Write-Host "Exporting permissions to CSV..." -ForegroundColor Cyan
try {
    $Report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
    Write-Host "SUCCESS: Exported $($Report.Count) ACL entries to $OutputPath" -ForegroundColor Green
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

# Display summary
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Items scanned: $totalItems" -ForegroundColor White
Write-Host "  ACL entries exported: $($Report.Count)" -ForegroundColor White
if ($IncludeFiles) {
    $folderCount = ($items | Where-Object { $_.PSIsContainer }).Count
    $fileCount = ($items | Where-Object { -not $_.PSIsContainer }).Count
    Write-Host "  Folders: $folderCount" -ForegroundColor White
    Write-Host "  Files: $fileCount" -ForegroundColor White
}
if ($ErrorLog.Count -gt 0) {
    Write-Host "  Errors (access denied): $($ErrorLog.Count)" -ForegroundColor Yellow
}
Write-Host ""
