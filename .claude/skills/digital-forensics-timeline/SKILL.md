---
name: digital-forensics-timeline
description: Build file system timelines and perform forensic analysis using metadata extraction and hash verification. Use when performing digital forensics, timeline analysis, evidence preservation, hash verification, or when the user mentions forensics, investigation, or timeline reconstruction.
allowed-tools: Read, Bash, Grep, Glob
---

# Digital Forensics Timeline Analysis

Build comprehensive file system timelines for forensic analysis using PowerShell metadata extraction and cryptographic verification.

## Overview

The File-Shares toolkit provides essential forensic capabilities:
- **Timeline reconstruction** using creation, modification, and access timestamps
- **Hash verification** for evidence integrity (MD5, SHA1, SHA256, SHA512)
- **Hierarchical tracking** with parent-child relationships for activity mapping
- **Metadata preservation** for comprehensive evidence documentation
- **Non-destructive analysis** - scripts only read data, never modify

## Prerequisites

### System Requirements
- Windows PowerShell 5.1 or higher
- Administrator rights (for accessing all user directories)
- Execution policy: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

### Forensic Best Practices
- **Write-blocker** - Use hardware write-blocker for evidence drives
- **Working copy** - Always work on forensic images, not original evidence
- **Documentation** - Log all commands, timestamps, and analyst actions
- **Chain of custody** - Maintain documented evidence handling procedures

## Forensic Workflow

### Step 1: Evidence Acquisition

**Scenario:** Analyze a suspect's user directory.

```powershell
# Extract complete file system metadata with hashes
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "E:\Evidence\suspect_drive\Users\suspect" `
    -OutputPath "E:\Forensics\Case_2025-001\timeline_with_hashes.csv" `
    -IncludeHash `
    -HashAlgorithm SHA256
```

**Output:** CSV with file paths, timestamps, sizes, and SHA256 hashes.

### Step 2: Timeline Construction

**Import and analyze timeline:**
```powershell
# Load timeline data
$timeline = Import-Csv "E:\Forensics\Case_2025-001\timeline_with_hashes.csv"

# Sort by creation time
$timeline | Sort-Object CreationTime |
    Select-Object CreationTime, Path, Bytes, SHA256 |
    Export-Csv "timeline_by_creation.csv"

# Sort by last write time (modification)
$timeline | Sort-Object LastWriteTime |
    Select-Object LastWriteTime, Path, Bytes, SHA256 |
    Export-Csv "timeline_by_modification.csv"

# Sort by last access time
$timeline | Sort-Object LastAccessTime |
    Select-Object LastAccessTime, Path, Bytes, SHA256 |
    Export-Csv "timeline_by_access.csv"
```

### Step 3: Temporal Analysis

**Find files created/modified during specific timeframe:**
```powershell
# Define investigation window
$startTime = Get-Date "2025-01-15 09:00:00"
$endTime = Get-Date "2025-01-15 17:00:00"

# Find files created during timeframe
$timeline | Where-Object {
    [DateTime]$_.CreationTime -ge $startTime -and
    [DateTime]$_.CreationTime -le $endTime
} | Export-Csv "files_created_during_incident.csv"

# Find files modified during timeframe
$timeline | Where-Object {
    [DateTime]$_.LastWriteTime -ge $startTime -and
    [DateTime]$_.LastWriteTime -le $endTime
} | Export-Csv "files_modified_during_incident.csv"
```

### Step 4: Hash Verification

**Verify file integrity:**
```powershell
# Create known-good hash baseline
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "C:\Windows\System32" `
    -OutputPath "system32_baseline.csv" `
    -IncludeHash `
    -HashAlgorithm SHA256

# Later, verify integrity by comparing hashes
$baseline = Import-Csv "system32_baseline.csv"
$current = Import-Csv "system32_current.csv"

# Find modified files
Compare-Object -ReferenceObject $baseline -DifferenceObject $current -Property Path, SHA256 |
    Where-Object {$_.SideIndicator -eq "=>"} |
    Export-Csv "modified_system_files.csv"
```

## Common Forensic Scenarios

### Incident Response: Malware Analysis

**Problem:** Malware was detected. Determine what was created/modified.

**Procedure:**
```powershell
# 1. Extract complete timeline
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "C:\Users\compromised_user" `
    -OutputPath "incident_timeline.csv" `
    -IncludeHash `
    -HashAlgorithm SHA256

# 2. Analyze timeline
$timeline = Import-Csv "incident_timeline.csv"

# 3. Find recently created files (last 24 hours)
$yesterday = (Get-Date).AddDays(-1)
$timeline | Where-Object {
    [DateTime]$_.CreationTime -gt $yesterday
} | Sort-Object CreationTime |
    Export-Csv "recent_files.csv"

# 4. Find executable files
$timeline | Where-Object {
    $_.Extension -match "\.exe|\.dll|\.bat|\.ps1|\.vbs|\.js"
} | Export-Csv "executable_files.csv"

# 5. Check hashes against known malware databases (VirusTotal, etc.)
$timeline | Where-Object {$_.SHA256 -ne ""} |
    Select-Object SHA256, Path |
    Export-Csv "hashes_for_lookup.csv"
```

### Data Exfiltration Investigation

**Problem:** Suspect may have copied sensitive files to USB drive.

**Procedure:**
```powershell
# 1. Extract metadata from suspect's directories
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "C:\Users\insider" `
    -OutputPath "insider_activity.csv" `
    -IncludeHash `
    -HashAlgorithm SHA256

# 2. Extract metadata from USB drive (if available)
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "E:\USB_Evidence" `
    -OutputPath "usb_contents.csv" `
    -IncludeHash `
    -HashAlgorithm SHA256

# 3. Compare hashes to find copied files
$insider = Import-Csv "insider_activity.csv"
$usb = Import-Csv "usb_contents.csv"

# Find matching hashes (files copied from system to USB)
$insider | Where-Object {
    $_.SHA256 -in $usb.SHA256
} | Export-Csv "files_copied_to_usb.csv"

# 4. Analyze access times (when files were accessed before copying)
$copied = Import-Csv "files_copied_to_usb.csv"
$copied | Sort-Object LastAccessTime |
    Select-Object LastAccessTime, Path, Bytes |
    Export-Csv "access_timeline.csv"
```

### Deleted File Recovery Analysis

**Problem:** Analyze when files were deleted (if file names still in MFT).

**Procedure:**
```powershell
# 1. Create baseline before incident
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "D:\SharedData" `
    -OutputPath "baseline_$(Get-Date -Format 'yyyy-MM-dd').csv" `
    -IncludeHash

# 2. Create comparison snapshot after incident
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "D:\SharedData" `
    -OutputPath "after_incident_$(Get-Date -Format 'yyyy-MM-dd').csv" `
    -IncludeHash

# 3. Find deleted files
$baseline = Import-Csv "baseline_*.csv"
$after = Import-Csv "after_incident_*.csv"

$baseline | Where-Object {
    $_.Path -notin $after.Path
} | Export-Csv "deleted_files.csv"
```

### User Activity Timeline

**Problem:** Reconstruct user's file system activity during specific period.

**Procedure:**
```powershell
# 1. Extract comprehensive timeline
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "C:\Users\subject" `
    -OutputPath "user_activity_timeline.csv" `
    -IncludeHash `
    -HashAlgorithm SHA256

# 2. Combine all timestamps for complete activity view
$timeline = Import-Csv "user_activity_timeline.csv"

# Create unified timeline with all activities
$activities = @()

foreach ($file in $timeline) {
    # Creation event
    $activities += [PSCustomObject]@{
        Timestamp = $file.CreationTime
        EventType = "Created"
        Path = $file.Path
        Size = $file.Bytes
        Hash = $file.SHA256
    }

    # Modification event (if different from creation)
    if ($file.LastWriteTime -ne $file.CreationTime) {
        $activities += [PSCustomObject]@{
            Timestamp = $file.LastWriteTime
            EventType = "Modified"
            Path = $file.Path
            Size = $file.Bytes
            Hash = $file.SHA256
        }
    }

    # Access event (if different from creation/modification)
    if ($file.LastAccessTime -ne $file.CreationTime -and
        $file.LastAccessTime -ne $file.LastWriteTime) {
        $activities += [PSCustomObject]@{
            Timestamp = $file.LastAccessTime
            EventType = "Accessed"
            Path = $file.Path
            Size = $file.Bytes
            Hash = $file.SHA256
        }
    }
}

# Sort by timestamp
$activities | Sort-Object Timestamp |
    Export-Csv "unified_activity_timeline.csv" -NoTypeInformation
```

## Hierarchical Relationship Analysis

**Use ID/PARENTID tracking to understand file organization:**

```powershell
$timeline = Import-Csv "forensic_timeline.csv"

# Find all files in specific directory (by PARENTID)
$directory_id = 42
$timeline | Where-Object {$_.PARENTID -eq $directory_id}

# Trace file to root (follow parent chain)
function Get-FilePath {
    param($FileID)

    $file = $timeline | Where-Object {$_.ID -eq $FileID}
    $path = @($file.Name)

    $current_parent = $file.PARENTID
    while ($current_parent -ne $null -and $current_parent -ne "") {
        $parent = $timeline | Where-Object {$_.ID -eq $current_parent}
        $path = @($parent.Name) + $path
        $current_parent = $parent.PARENTID
    }

    return ($path -join "\")
}

# Get full path for specific file
Get-FilePath -FileID 123
```

## Advanced Windows Metadata Forensics

**Extract comprehensive Windows properties for evidence:**

```powershell
# Get all Windows metadata (200+ properties)
.\get all property fields for files and folders (recursive).ps1 "E:\Evidence\suspect_documents" |
    Export-CSV "comprehensive_metadata.csv" -NoTypeInformation

# Analyze metadata
$metadata = Import-Csv "comprehensive_metadata.csv"

# Find documents with specific author
$metadata | Where-Object {$_.Author -match "suspect_name"}

# Find photos with GPS coordinates (location evidence)
$metadata | Where-Object {
    $_.Latitude -ne $null -or $_.Longitude -ne $null
} | Select-Object FullName, Latitude, Longitude, DateTaken

# Find Office documents modified by specific user
$metadata | Where-Object {$_.LastSavedBy -match "username"}
```

## Evidence Preservation

### Creating Forensic Reports

**Generate case documentation:**
```powershell
# 1. Extract timeline
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "E:\Evidence\Case_2025-001" `
    -OutputPath "CASE_2025-001_Timeline_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').csv" `
    -IncludeHash `
    -HashAlgorithm SHA256

# 2. Calculate hash of the report itself
$report = "CASE_2025-001_Timeline_*.csv"
Get-FileHash $report -Algorithm SHA256 |
    Export-Csv "CASE_2025-001_Report_Hash.csv"
```

**Documentation checklist:**
- [ ] Date and time of analysis
- [ ] Analyst name and credentials
- [ ] Case number and description
- [ ] Evidence source (drive, computer, user)
- [ ] Hash algorithm used
- [ ] Hash of report file itself
- [ ] Chain of custody documentation

### Hash Verification Best Practices

**Choose appropriate hash algorithm:**

| Algorithm | Speed | Security | Use Case |
|-----------|-------|----------|----------|
| MD5 | Fast | Weak | Quick duplicate detection (non-legal) |
| SHA1 | Medium | Deprecated | Legacy system compatibility |
| SHA256 | Medium | Strong | **Recommended for forensics** |
| SHA512 | Slow | Strongest | High-security evidence |

**Recommendation:** Use SHA256 for forensic work (industry standard, court-accepted).

```powershell
# Generate SHA256 hashes for evidence
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "E:\Evidence" `
    -OutputPath "evidence_hashes.csv" `
    -IncludeHash `
    -HashAlgorithm SHA256
```

## Performance Considerations

### Large Evidence Sets

**Problem:** Analyzing terabytes of data takes hours/days.

**Solutions:**
1. **Process in phases:**
   ```powershell
   # Phase 1: Quick metadata without hashes
   .\FileNamePath Export with Hash.ps1 `
       -SourcePath "E:\Evidence" `
       -OutputPath "quick_timeline.csv"

   # Phase 2: Hash only relevant files
   $relevant = Import-Csv "quick_timeline.csv" |
       Where-Object {[DateTime]$_.CreationTime -gt (Get-Date "2025-01-15")}

   # Hash only these specific files
   $relevant | ForEach-Object {
       Get-FileHash $_.Path -Algorithm SHA256
   }
   ```

2. **Target specific directories:**
   ```powershell
   # Focus on user data, not entire drive
   $userDirs = @(
       "Users\suspect\Documents",
       "Users\suspect\Downloads",
       "Users\suspect\Desktop"
   )

   foreach ($dir in $userDirs) {
       .\FileNamePath Export with Hash.ps1 `
           -SourcePath "E:\Evidence\$dir" `
           -OutputPath "timeline_$($dir -replace '\\','_').csv" `
           -IncludeHash
   }
   ```

## Troubleshooting

### Access Denied on Evidence Files
**Solution:** Run PowerShell as Administrator
```powershell
# Take ownership if necessary (document in case notes)
takeown /F "E:\Evidence" /R /D Y
icacls "E:\Evidence" /grant Administrators:F /T
```

### Hash Calculation Too Slow
**Expected:** Hashing large files is CPU-intensive
**Solution:**
- Hash only necessary files (filter by date/type first)
- Use faster algorithm for initial triage (MD5)
- Use SHA256 only for court evidence

### Timestamps Not in Local Time
**Issue:** Timestamps in CSV are UTC or system time
**Solution:**
```powershell
# Convert to local time for analysis
$timeline = Import-Csv "timeline.csv"
$timeline | ForEach-Object {
    $_.CreationTime = [DateTime]::Parse($_.CreationTime).ToLocalTime()
    $_.LastWriteTime = [DateTime]::Parse($_.LastWriteTime).ToLocalTime()
    $_.LastAccessTime = [DateTime]::Parse($_.LastAccessTime).ToLocalTime()
}
$timeline | Export-Csv "timeline_local_time.csv"
```

## Legal and Ethical Considerations

### Authorization
- ✅ **Always obtain proper authorization** before forensic analysis
- ✅ Document authorization in case file
- ✅ Respect scope limitations

### Evidence Handling
- ✅ Maintain chain of custody
- ✅ Document all commands executed
- ✅ Never modify original evidence
- ✅ Validate hashes at each transfer

### Privacy
- ✅ Handle PII (Personally Identifiable Information) appropriately
- ✅ Follow organizational data handling policies
- ✅ Protect evidence data with encryption

## Get Help

View detailed script help:
```powershell
Get-Help ".\FileNamePath Export with Hash.ps1" -Full
Get-Help ".\get all property fields for files and folders (recursive).ps1" -Full
```

## Next Steps

After forensic analysis:
1. **Generate reports** - Document findings for case file
2. **Hash verification** - Validate evidence integrity
3. **Permission analysis** - Use ntfs-permission-auditing skill for access investigation
4. **Metadata deep dive** - Use windows-metadata-extraction skill for comprehensive properties
5. **Present findings** - Create timeline visualizations for reports
