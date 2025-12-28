---
name: windows-metadata-extraction
description: Extract comprehensive Windows file system metadata including EXIF data, Office properties, timestamps, and hashes. Use when working with Windows file analysis, metadata preservation, digital archiving, or when the user mentions file metadata, Windows properties, or Shell.Application.
allowed-tools: Read, Bash, Grep, Glob
---

# Windows Metadata Extraction

Extract comprehensive metadata from Windows file systems using native PowerShell scripts. This skill teaches you how to use the File-Shares toolkit for deep Windows metadata analysis.

## Overview

The File-Shares toolkit specializes in extracting **200+ Windows-specific file properties** that are unavailable in cross-platform tools. This includes:
- EXIF data (camera make/model, GPS coordinates)
- Office document properties (authors, title, subject)
- Media file metadata (bit rate, dimensions, duration)
- Windows-specific properties via Shell.Application COM object

## Prerequisites

Before extracting metadata, ensure:
- Windows PowerShell 5.1 or higher
- Administrator rights (for full system access)
- Execution policy allows script execution: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

## Available Scripts

### 1. FileNamePath Export with Hash.ps1

**Purpose:** Extract file/folder metadata with optional cryptographic hashes.

**Key Features:**
- Hierarchical parent-child tracking (ID/PARENTID for graph analysis)
- Multiple hash algorithms (MD5, SHA1, SHA256, SHA512)
- Comprehensive timestamps (creation, modification, access)
- Progress indicators for large datasets
- Error logging for inaccessible files

**Usage:**
```powershell
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "C:\MyFolder" `
    -OutputPath "C:\Reports\inventory.csv" `
    -IncludeHash `
    -HashAlgorithm SHA256
```

**Output Fields:**
- Path, Name, IsDirectory
- ID, PARENTID, PARENTPATH (hierarchical relationships)
- CreationTime, LastAccessTime, LastWriteTime
- Extension, BaseName, Bytes (file size)
- Hash (if -IncludeHash specified)

### 2. get all property fields for files and folders (recursive).ps1

**Purpose:** Extract **all available Windows metadata** using Shell.Application.

**Key Features:**
- Accesses 200+ metadata properties
- EXIF, Office, media tags
- Recursive directory traversal
- Pipeline-compatible output

**Usage:**
```powershell
# Extract all metadata to CSV
.\get all property fields for files and folders (recursive).ps1 "C:\Photos" |
    Export-CSV -Path "metadata.csv" -NoTypeInformation

# Extract specific fields
.\get all property fields for files and folders (recursive).ps1 "C:\Documents" |
    Select-Object FullName, Author, Title, Tags, DateCreated |
    Export-CSV -Path "doc_metadata.csv" -NoTypeInformation
```

## Common Use Cases

### Digital Archiving
**Problem:** Preserve Windows metadata before migrating to cloud/Linux.

**Solution:**
```powershell
# Extract comprehensive metadata for preservation
.\get all property fields for files and folders (recursive).ps1 "D:\Archive" |
    Export-CSV -Path "metadata_preservation.csv" -NoTypeInformation
```

**Why:** Cloud storage and Linux don't preserve Windows alternate streams, Office properties, or EXIF data.

### Duplicate Detection
**Problem:** Identify duplicate files across large datasets.

**Solution:**
```powershell
# Generate hash inventory
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "E:\FileServer" `
    -OutputPath "inventory_with_hashes.csv" `
    -IncludeHash `
    -HashAlgorithm SHA256

# Then use Excel/PowerShell to find duplicate hashes
Import-Csv inventory_with_hashes.csv | Group-Object Hash | Where-Object {$_.Count -gt 1}
```

### Pre-Migration Inventory
**Problem:** Document current state before migration.

**Solution:**
```powershell
# Create baseline inventory
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "F:\OldServer" `
    -OutputPath "pre_migration_baseline.csv" `
    -IncludeHash `
    -HashAlgorithm SHA256
```

**Post-Migration Verification:**
```powershell
# Create post-migration inventory
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "G:\NewServer" `
    -OutputPath "post_migration_verification.csv" `
    -IncludeHash `
    -HashAlgorithm SHA256

# Compare hashes to verify successful migration
```

## Performance Tips

1. **Hash Calculation:** Only use `-IncludeHash` when needed
   - Hashing is CPU-intensive and significantly slower
   - For large files (>1GB), expect significant delays

2. **Large Datasets:** Process in batches by directory
   - Processing millions of files can cause memory issues
   - Process subdirectories separately and combine results

3. **Progress Monitoring:** Watch for "Access Denied" errors
   - Errors are logged to separate error log files
   - Run as Administrator to minimize access issues

## Troubleshooting

### "Access Denied" Errors
**Solution:** Run PowerShell as Administrator
```powershell
# Check error log files (*_errors.csv) for details
```

### "Execution Policy" Errors
**Solution:** Temporarily bypass execution policy
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
# Or bypass for single execution:
powershell.exe -ExecutionPolicy Bypass -File "script.ps1"
```

### Slow Hash Calculation
**Expected behavior:** Hashing is CPU-intensive
**Solution:**
- Process smaller directory trees
- Remove `-IncludeHash` if hashes aren't required
- Use faster algorithms (MD5) for speed, SHA256 for security

### Out of Memory
**Cause:** Processing millions of files at once
**Solution:** Process subdirectories separately
```powershell
# Process each subdirectory individually
Get-ChildItem "C:\LargeShare" -Directory | ForEach-Object {
    .\FileNamePath Export with Hash.ps1 `
        -SourcePath $_.FullName `
        -OutputPath "output_$($_.Name).csv"
}
```

## Security Considerations

**Data Sensitivity:**
- Hash values can identify specific file versions
- Metadata may contain sensitive information (author names, GPS coordinates)
- Review outputs before sharing externally

**Access Rights:**
- Some operations require Administrator privileges
- Use dedicated audit accounts for compliance scanning
- Access denied errors are logged separately for review

## Get Help

View detailed help for any script:
```powershell
Get-Help ".\FileNamePath Export with Hash.ps1" -Full
Get-Help ".\get all property fields for files and folders (recursive).ps1" -Full
```

## What Makes This Different

**vs. Cross-Platform Tools (folderstats, Python libraries):**
- ✅ Access to 200+ Windows-specific properties via Shell.Application
- ✅ EXIF, Office, media metadata unavailable elsewhere
- ✅ Zero dependencies - pure PowerShell

**vs. Network Share Tools (PowerHuntShares, SMBeagle):**
- ✅ Deep local metadata extraction (not network scanning)
- ✅ Windows property access (not just file listings)
- ✅ Hierarchical relationship tracking

## Next Steps

After extracting metadata, consider:
1. **Permission Analysis:** Use the NTFS permission auditing skill for compliance
2. **Forensic Analysis:** Use the digital forensics timeline skill for investigations
3. **Migration Planning:** Use the data migration planning skill for file server moves
