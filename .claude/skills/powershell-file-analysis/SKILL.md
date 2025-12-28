---
name: powershell-file-analysis
description: Learn PowerShell best practices for file system analysis, including parameter validation, error handling, progress tracking, and CSV export. Use when learning PowerShell, writing file analysis scripts, or when the user mentions PowerShell best practices, script development, or wants examples.
allowed-tools: Read, Bash, Grep, Glob
---

# PowerShell Best Practices for File Analysis

Learn production-ready PowerShell patterns through real-world file system analysis scripts. This skill teaches best practices demonstrated in the File-Shares toolkit.

## Overview

The File-Shares scripts demonstrate professional PowerShell development:
- **Comment-based help** for Get-Help integration
- **Parameter validation** with ValidateScript
- **Progress indicators** for user feedback
- **Comprehensive error handling** with try/catch
- **Structured output** using PSCustomObject
- **UTF-8 CSV export** for international character support
- **Clean, readable code** with consistent formatting

## Comment-Based Help

### Pattern: Complete Script Documentation

Every production script should include comment-based help for `Get-Help` integration.

**Example:**
```powershell
<#
.SYNOPSIS
    Brief one-line description of what the script does.

.DESCRIPTION
    Detailed explanation of script functionality, including
    how it works, what it processes, and what it outputs.

.PARAMETER ParameterName
    Description of the parameter, including valid values,
    constraints, and default behavior.

.EXAMPLE
    .\ScriptName.ps1 -Parameter "Value"

    Description of what this example does.

.EXAMPLE
    .\ScriptName.ps1 -Parameter "Value" -Switch

    Second example with different parameters.

.NOTES
    Author: Your Name
    Version: 1.0
    Requires: PowerShell 5.1 or higher

    Additional notes, warnings, or requirements.
#>
```

**Usage:**
```powershell
# Users can now access help
Get-Help .\ScriptName.ps1
Get-Help .\ScriptName.ps1 -Full
Get-Help .\ScriptName.ps1 -Examples
```

**Best Practices:**
- Always include .SYNOPSIS, .DESCRIPTION, .PARAMETER for each parameter
- Provide multiple .EXAMPLE blocks showing common usage patterns
- Include .NOTES for version, author, requirements, and warnings
- Keep examples realistic and runnable

## Parameter Validation

### Pattern: ValidateScript for Complex Validation

Use `ValidateScript` to ensure parameters meet requirements before script execution.

**Example: Validate Directory Exists**
```powershell
param(
    [Parameter(Mandatory=$true, HelpMessage="Root directory to scan")]
    [ValidateScript({
        if (Test-Path $_ -PathType Container) { $true }
        else { throw "Path '$_' does not exist or is not a directory." }
    })]
    [string]$SourcePath
)
```

**Example: Validate Parent Directory Exists**
```powershell
param(
    [Parameter(Mandatory=$true, HelpMessage="Output CSV file path")]
    [ValidateScript({
        $parent = Split-Path $_
        if ([string]::IsNullOrEmpty($parent)) { $parent = "." }
        if (Test-Path $parent -PathType Container) { $true }
        else { throw "Output directory '$parent' does not exist." }
    })]
    [string]$OutputPath
)
```

**Example: ValidateSet for Enumerated Values**
```powershell
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA512')]
    [string]$HashAlgorithm = 'MD5'
)
```

**Best Practices:**
- Use `ValidateScript` for complex validation logic
- Use `ValidateSet` for enumerated options
- Throw descriptive error messages that help users fix the issue
- Validate early - fail fast if parameters are invalid

## Error Handling

### Pattern: Try/Catch with Specific Exception Types

Catch specific exceptions to provide targeted error handling and logging.

**Example: Basic Try/Catch**
```powershell
try {
    $item = Get-Item $SourcePath -ErrorAction Stop
    # Process item
} catch {
    Write-Error "Failed to access source path: $SourcePath"
    Write-Error $_.Exception.Message
    exit 1
}
```

**Example: Specific Exception Handling**
```powershell
try {
    $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256 -ErrorAction Stop
    Add-Member -InputObject $Result -MemberType NoteProperty -Name SHA256 -Value $hash.Hash
} catch [System.UnauthorizedAccessException] {
    Add-Member -InputObject $Result -MemberType NoteProperty -Name SHA256 -Value "ACCESS_DENIED"
    $ErrorLog += [PSCustomObject]@{
        Path = $file.FullName
        Error = "Access denied"
        ErrorType = "Hash"
    }
} catch {
    Add-Member -InputObject $Result -MemberType NoteProperty -Name SHA256 -Value "ERROR"
    $ErrorLog += [PSCustomObject]@{
        Path = $file.FullName
        Error = $_.Exception.Message
        ErrorType = "Hash"
    }
}
```

**Example: Error Logging Pattern**
```powershell
# Initialize error log array
$ErrorLog = @()

# During processing, log errors
$ErrorLog += [PSCustomObject]@{
    Path = $item.FullName
    Error = $_.Exception.Message
    ErrorType = "Enumeration"
    Timestamp = Get-Date
}

# After processing, export error log
if ($ErrorLog.Count -gt 0) {
    $errorLogPath = $OutputPath -replace '\.csv$', '_errors.csv'
    $ErrorLog | Export-Csv -NoTypeInformation -Path $errorLogPath -Encoding UTF8
    Write-Host "WARNING: $($ErrorLog.Count) errors logged to $errorLogPath" -ForegroundColor Yellow
}
```

**Best Practices:**
- Always use `-ErrorAction Stop` in try blocks (converts non-terminating errors)
- Catch specific exceptions first, generic exceptions last
- Log errors for later analysis (don't just display)
- Provide actionable error messages
- Export error logs to separate CSV files

## Progress Indicators

### Pattern: Write-Progress for Long-Running Operations

Show progress during long operations to keep users informed.

**Example: Basic Progress**
```powershell
$totalItems = $allItems.Count
$processedItems = 0

foreach ($item in $allItems) {
    $processedItems++

    # Update progress every 100 items or on last item
    if ($processedItems % 100 -eq 0 -or $processedItems -eq $totalItems) {
        $percentComplete = [math]::Round(($processedItems / $totalItems) * 100, 2)
        Write-Progress -Activity "Scanning files and folders" `
            -Status "Processed $processedItems of $totalItems items ($percentComplete%)" `
            -PercentComplete $percentComplete
    }

    # Process item
}

# Clear progress when done
Write-Progress -Activity "Scanning files and folders" -Completed
```

**Best Practices:**
- Update progress periodically (not every iteration - too slow)
- Show both count and percentage
- Use descriptive activity names
- Always call `Write-Progress -Completed` when done
- For hash calculation (slow), update more frequently (every 50 items)

## Structured Output with PSCustomObject

### Pattern: Ordered Hashtables for Consistent CSV Export

Use `[pscustomobject]@{}` with ordered properties for predictable CSV column order.

**Example: Build Output Object**
```powershell
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

# Conditionally add properties
if ($IncludeHash) {
    Add-Member -InputObject $Result -MemberType NoteProperty -Name SHA256 -Value $hash.Hash
}
```

**Best Practices:**
- Use `[pscustomobject]@{}` for object creation
- Order properties logically (most important first)
- Use consistent property naming across scripts
- Use `Add-Member` for conditional properties
- Test CSV export to verify column order

## CSV Export Best Practices

### Pattern: UTF-8 Encoding with Error Handling

Always export with UTF-8 encoding for international character support.

**Example: Safe CSV Export**
```powershell
try {
    $list | Export-Csv -NoTypeInformation -Path $OutputPath -Encoding UTF8 -ErrorAction Stop
    Write-Host "SUCCESS: Exported $($list.Count) items to $OutputPath" -ForegroundColor Green
} catch {
    Write-Error "Failed to export CSV: $($_.Exception.Message)"
    exit 1
}
```

**Best Practices:**
- Always use `-NoTypeInformation` (removes type header)
- Always use `-Encoding UTF8` (supports international characters)
- Use `-ErrorAction Stop` with try/catch
- Verify export success before continuing
- Provide clear success/failure messages

## Performance Optimization Patterns

### Pattern: Minimize Object Property Lookups

Cache frequently accessed objects to improve performance.

**Example: Directory Index for Parent Lookups**
```powershell
# BAD: Slow - searches entire array for each item
foreach ($Current in $SourcePathFileOutput) {
    $parentID = ($SourcePathFileOutput | Where-Object {
        $_.PSIsContainer -and $_.FullName -eq $Current.PARENTPATH
    }).ID
}

# GOOD: Fast - pre-filter directories once
$DirOutput = $SourcePathFileOutput | Where-Object { $_.PSIsContainer }

foreach ($Current in $SourcePathFileOutput) {
    $parentID = ($DirOutput | Where-Object {
        $_.FullName -eq $Current.PARENTPATH
    }).ID
}
```

**Best Practices:**
- Filter/cache objects before loops
- Minimize `Where-Object` calls in inner loops
- Use hashtables for lookups when possible
- Avoid repeated file system calls

### Pattern: Batch Progress Updates

Update progress periodically, not on every iteration.

**Example:**
```powershell
# BAD: Updates progress on every item (slow)
foreach ($item in $items) {
    Write-Progress -Activity "Processing" -Status $item.Name
}

# GOOD: Updates progress every 100 items
$count = 0
foreach ($item in $items) {
    $count++
    if ($count % 100 -eq 0) {
        Write-Progress -Activity "Processing" -Status "Processed $count items"
    }
}
```

## User Feedback Patterns

### Pattern: Color-Coded Console Output

Use color to highlight different message types.

**Example:**
```powershell
# Informational - Cyan
Write-Host "Scanning directory: $SourcePath" -ForegroundColor Cyan

# Warning - Yellow
Write-Host "Warning: Hash calculation will be slow" -ForegroundColor Yellow

# Success - Green
Write-Host "SUCCESS: Exported $count items" -ForegroundColor Green

# Error - Red (use Write-Error for actual errors)
Write-Host "ERROR: Failed to process" -ForegroundColor Red
```

**Best Practices:**
- Cyan: Informational messages
- Yellow: Warnings (non-fatal)
- Green: Success confirmations
- Red: Errors (or use `Write-Error`)
- Use `Write-Verbose` for debug output

## Script Structure Template

### Pattern: Consistent Script Organization

Organize scripts with consistent structure for maintainability.

**Template:**
```powershell
<#
.SYNOPSIS
    Brief description
.DESCRIPTION
    Detailed description
.PARAMETER Param1
    Description
.EXAMPLE
    Example usage
.NOTES
    Author, version, requirements
#>

# Parameters block
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({...})]
    [string]$Parameter1,

    [Parameter(Mandatory=$false)]
    [switch]$SwitchParam
)

# Initialize variables
$results = @()
$errorLog = @()

# Main processing
Write-Host "Starting process..." -ForegroundColor Cyan

try {
    # Step 1: Initial processing
    Write-Host "Step 1..." -ForegroundColor Cyan

    # Step 2: Main loop with progress
    Write-Host "Step 2..." -ForegroundColor Cyan
    $total = $items.Count
    $current = 0

    foreach ($item in $items) {
        $current++

        # Progress
        if ($current % 100 -eq 0) {
            Write-Progress -Activity "Processing" `
                -Status "Processed $current of $total" `
                -PercentComplete (($current / $total) * 100)
        }

        try {
            # Process item
            $results += [pscustomobject]@{
                Property1 = $item.Value1
                Property2 = $item.Value2
            }
        } catch {
            # Log error
            $errorLog += [PSCustomObject]@{
                Item = $item.Name
                Error = $_.Exception.Message
            }
        }
    }

    Write-Progress -Activity "Processing" -Completed

    # Step 3: Export results
    Write-Host "Exporting results..." -ForegroundColor Cyan
    $results | Export-Csv -NoTypeInformation -Path $OutputPath -Encoding UTF8 -ErrorAction Stop
    Write-Host "SUCCESS: Exported $($results.Count) items" -ForegroundColor Green

    # Export errors if any
    if ($errorLog.Count -gt 0) {
        $errorPath = $OutputPath -replace '\.csv$', '_errors.csv'
        $errorLog | Export-Csv -NoTypeInformation -Path $errorPath -Encoding UTF8
        Write-Host "WARNING: $($errorLog.Count) errors logged" -ForegroundColor Yellow
    }

} catch {
    Write-Error "Fatal error: $($_.Exception.Message)"
    exit 1
}

# Summary
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total items: $($results.Count)" -ForegroundColor White
Write-Host "  Errors: $($errorLog.Count)" -ForegroundColor White
Write-Host ""
```

## Real-World Examples from File-Shares

### Example 1: Hierarchical ID Assignment

**Pattern:** Assign unique IDs to track parent-child relationships.

```powershell
# Initialize ID counter
$ID = 1

# Process parent directory first
$SourcePathFileOutput += Get-Item $SourcePath | ForEach-Object {
    $ParentPath = if ($_.PSIsContainer) { $_.parent.FullName } else { $_.DirectoryName }

    Add-Member -InputObject $_ -MemberType NoteProperty -Name "ID" -Value ($ID++) -Force
    Add-Member -InputObject $_ -MemberType NoteProperty -Name "PARENTPATH" -Value $ParentPath -Force
    $_
}

# Process all children
foreach ($item in $allItems) {
    $ParentPath = if ($item.PSIsContainer) { $item.parent.FullName } else { $item.DirectoryName }

    Add-Member -InputObject $item -MemberType NoteProperty -Name "ID" -Value ($ID++) -Force
    Add-Member -InputObject $item -MemberType NoteProperty -Name "PARENTPATH" -Value $ParentPath -Force

    $SourcePathFileOutput += $item
}

# Look up parent IDs
$DirOutput = $SourcePathFileOutput | Where-Object { $_.PSIsContainer }

$list = foreach ($Current in $SourcePathFileOutput) {
    $parentID = ($DirOutput | Where-Object { $_.FullName -eq $Current.PARENTPATH }).ID
    if ($parentID -eq $null) { $parentID = 0 }

    [pscustomobject]@{
        ID = $Current.ID
        PARENTID = $parentID
        Path = $Current.FullName
        # ... other properties
    }
}
```

**Usage:** Create graph-ready data with parent-child relationships for visualization or analysis.

### Example 2: Conditional Hash Calculation

**Pattern:** Optional expensive operations with progress tracking.

```powershell
param(
    [switch]$IncludeHash,
    [ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA512')]
    [string]$HashAlgorithm = 'MD5'
)

foreach ($file in $files) {
    $result = [pscustomobject]@{
        Path = $file.FullName
        Size = $file.Length
    }

    # Only calculate hash if requested
    if ($IncludeHash -and -not $file.PSIsContainer) {
        try {
            $hash = Get-FileHash -Path $file.FullName -Algorithm $HashAlgorithm -ErrorAction Stop
            Add-Member -InputObject $result -MemberType NoteProperty -Name $HashAlgorithm -Value $hash.Hash
        } catch {
            Add-Member -InputObject $result -MemberType NoteProperty -Name $HashAlgorithm -Value "ERROR"
        }
    }

    $result
}
```

**Usage:** Provide optional expensive operations users can enable with switches.

### Example 3: Error Logging Pattern

**Pattern:** Separate error log file for detailed error tracking.

```powershell
$ErrorLog = @()

# During processing
try {
    # ... process item
} catch {
    $ErrorLog += [PSCustomObject]@{
        Path = $item.FullName
        Error = $_.Exception.Message
        ErrorType = "Processing"
        Timestamp = Get-Date
    }
}

# After processing
if ($ErrorLog.Count -gt 0) {
    $errorLogPath = $OutputPath -replace '\.csv$', '_errors.csv'
    $ErrorLog | Export-Csv -NoTypeInformation -Path $errorLogPath -Encoding UTF8
    Write-Host "WARNING: $($ErrorLog.Count) errors. See $errorLogPath" -ForegroundColor Yellow
}
```

**Usage:** Provide detailed error information without cluttering main output.

## Common Patterns Summary

| Pattern | Use Case | Example |
|---------|----------|---------|
| ValidateScript | Complex parameter validation | Path existence, directory validation |
| ValidateSet | Enumerated values | Hash algorithms, file types |
| Try/Catch | Error handling | File access, hash calculation |
| Write-Progress | Long operations | File scanning, hash calculation |
| PSCustomObject | Structured output | CSV export, reporting |
| Add-Member | Conditional properties | Optional columns, calculated fields |
| Error logging | Error tracking | Separate _errors.csv file |
| ID assignment | Hierarchical data | Parent-child relationships |
| Color coding | User feedback | Cyan, Yellow, Green, Red |
| Comment-based help | Documentation | Get-Help integration |

## Get Help

View production examples:
```powershell
Get-Help ".\FileNamePath Export with Hash.ps1" -Full
Get-Help ".\Folder Permissions.ps1" -Full
```

## Resources

**PowerShell Documentation:**
- [about_Comment_Based_Help](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_comment_based_help)
- [about_Functions_Advanced_Parameters](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters)
- [about_Try_Catch_Finally](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_try_catch_finally)

**Best Practices Guides:**
- [PowerShell Practice and Style Guide](https://poshcode.gitbook.io/powershell-practice-and-style/)
- [The PowerShell Best Practices and Style Guide](https://github.com/PoshCode/PowerShellPracticeAndStyle)

## Next Steps

After learning PowerShell patterns:
1. **Apply to your scripts** - Use these patterns in your own PowerShell development
2. **Study the source** - Read the File-Shares scripts for complete examples
3. **Extend functionality** - Add features using these best practices
4. **Share knowledge** - Teach others these production-ready patterns
