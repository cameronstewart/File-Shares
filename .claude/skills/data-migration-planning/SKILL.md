---
name: data-migration-planning
description: Plan and verify data migrations using baseline inventories, hash verification, and metadata preservation. Use when planning file server migrations, cloud migrations, platform transitions, or when the user mentions migration, data transfer, or baseline verification.
allowed-tools: Read, Bash, Grep, Glob
---

# Data Migration Planning and Verification

Plan, document, and verify data migrations using PowerShell inventory tools with hash verification and metadata preservation.

## Overview

File server migrations are high-risk operations. The File-Shares toolkit provides:
- **Pre-migration baseline** - Complete inventory with cryptographic hashes
- **Post-migration verification** - Hash comparison confirms 100% data integrity
- **Metadata preservation** - Document Windows properties before cross-platform migration
- **Permission mapping** - NTFS ACL documentation for permission restoration
- **Hierarchical tracking** - Parent-child relationships for folder structure verification

## Migration Planning Workflow

### Phase 1: Assessment and Planning

**Objective:** Understand current state and plan migration approach.

#### Step 1.1: Initial Inventory

```powershell
# Quick inventory without hashes (fast)
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "F:\OldFileServer" `
    -OutputPath "inventory_quick.csv"

# Analyze size and scope
$inventory = Import-Csv "inventory_quick.csv"

Write-Host "Total files: $(($inventory | Where-Object {$_.ISDIR -eq 'False'}).Count)"
Write-Host "Total folders: $(($inventory | Where-Object {$_.ISDIR -eq 'True'}).Count)"

$totalBytes = ($inventory | Where-Object {$_.ISDIR -eq 'False'} | Measure-Object -Property Bytes -Sum).Sum
Write-Host "Total size: $([math]::Round($totalBytes / 1GB, 2)) GB"
```

#### Step 1.2: Identify Challenges

```powershell
# Find large files (>1GB) that need special handling
$inventory | Where-Object {
    [int64]$_.Bytes -gt 1GB
} | Select-Object Path, Bytes |
    Export-Csv "large_files.csv"

# Find deeply nested paths (>260 characters - Windows path limit)
$inventory | Where-Object {
    $_.Path.Length -gt 260
} | Export-Csv "long_paths.csv"

# Find special characters in filenames (may cause issues)
$inventory | Where-Object {
    $_.Name -match '[<>:"/\\|?*]'
} | Export-Csv "special_characters.csv"
```

#### Step 1.3: Permission Documentation

```powershell
# Document current NTFS permissions
.\Folder Permissions.ps1 `
    -FolderPath "F:\OldFileServer" `
    -OutputPath "pre_migration_permissions.csv"
```

### Phase 2: Pre-Migration Baseline

**Objective:** Create cryptographic baseline for post-migration verification.

#### Step 2.1: Generate Baseline with Hashes

```powershell
# Create baseline inventory with SHA256 hashes
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "F:\OldFileServer" `
    -OutputPath "pre_migration_baseline_$(Get-Date -Format 'yyyy-MM-dd').csv" `
    -IncludeHash `
    -HashAlgorithm SHA256
```

**Critical:** This baseline is your verification reference. Protect it:
- Store on separate media
- Create multiple copies
- Calculate hash of the baseline file itself
- Document creation date/time and analyst name

#### Step 2.2: Preserve Windows Metadata

```powershell
# Extract comprehensive Windows metadata (before migrating to Linux/cloud)
.\get all property fields for files and folders (recursive).ps1 "F:\OldFileServer" |
    Export-CSV "windows_metadata_preservation_$(Get-Date -Format 'yyyy-MM-dd').csv" -NoTypeInformation
```

**Why this matters:**
- Cloud storage doesn't preserve EXIF data
- Linux doesn't preserve Office document properties
- SharePoint Online may strip metadata
- This is your only record of original Windows properties

#### Step 2.3: Verify Baseline Integrity

```powershell
# Hash the baseline file itself
Get-FileHash "pre_migration_baseline_*.csv" -Algorithm SHA256 |
    Export-Csv "baseline_file_hash.csv"
```

### Phase 3: Migration Execution

**Objective:** Perform actual data transfer.

**Migration tools (choose based on scenario):**

| Tool | Best For | Preserves Permissions | Cross-Platform |
|------|----------|----------------------|----------------|
| Robocopy | Windows to Windows | ✅ Yes | ❌ No |
| rsync | Linux to Linux | ✅ Yes | ✅ Yes |
| AWS S3 sync | Cloud migration | ⚠️ Partial | ✅ Yes |
| Azure AzCopy | Azure migration | ⚠️ Partial | ✅ Yes |
| rclone | Multi-cloud | ⚠️ Partial | ✅ Yes |

#### Example: Windows to Windows (Robocopy)

```powershell
# Robocopy with full ACL preservation
robocopy "F:\OldFileServer" "G:\NewFileServer" /E /COPYALL /R:3 /W:5 /LOG:migration_log.txt /TEE

# Parameters explained:
# /E - Copy subdirectories including empty ones
# /COPYALL - Copy all file info (data, attributes, timestamps, NTFS ACLs, owner, auditing)
# /R:3 - Retry 3 times on failures
# /W:5 - Wait 5 seconds between retries
# /LOG - Create detailed log file
# /TEE - Output to console and log file
```

#### Example: Windows to Linux/Cloud

```powershell
# Use rsync or cloud-specific tools
# IMPORTANT: Permissions will NOT transfer - use permission documentation from Phase 1
```

### Phase 4: Post-Migration Verification

**Objective:** Prove 100% data integrity and completeness.

#### Step 4.1: Generate Post-Migration Inventory

```powershell
# Create post-migration inventory with same parameters
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "G:\NewFileServer" `
    -OutputPath "post_migration_verification_$(Get-Date -Format 'yyyy-MM-dd').csv" `
    -IncludeHash `
    -HashAlgorithm SHA256
```

#### Step 4.2: Compare Baselines

```powershell
# Load both inventories
$pre = Import-Csv "pre_migration_baseline_*.csv"
$post = Import-Csv "post_migration_verification_*.csv"

# Basic counts
Write-Host "Pre-migration files: $(($pre | Where-Object {$_.ISDIR -eq 'False'}).Count)"
Write-Host "Post-migration files: $(($post | Where-Object {$_.ISDIR -eq 'False'}).Count)"

# Compare hashes to verify integrity
$preHashes = $pre | Where-Object {$_.SHA256 -ne ""} | Select-Object -ExpandProperty SHA256
$postHashes = $post | Where-Object {$_.SHA256 -ne ""} | Select-Object -ExpandProperty SHA256

# Find files in pre but not in post (missing files)
$missing = $pre | Where-Object {$_.SHA256 -notin $postHashes} |
    Select-Object Path, Bytes, SHA256

if ($missing.Count -gt 0) {
    Write-Host "WARNING: $($missing.Count) files missing!" -ForegroundColor Red
    $missing | Export-Csv "MISSING_FILES.csv"
} else {
    Write-Host "SUCCESS: All files migrated successfully" -ForegroundColor Green
}

# Find files in post but not in pre (unexpected files)
$unexpected = $post | Where-Object {$_.SHA256 -notin $preHashes} |
    Select-Object Path, Bytes, SHA256

if ($unexpected.Count -gt 0) {
    Write-Host "WARNING: $($unexpected.Count) unexpected files found!" -ForegroundColor Yellow
    $unexpected | Export-Csv "UNEXPECTED_FILES.csv"
}
```

#### Step 4.3: Verify File Counts

```powershell
# Compare file type distributions
function Get-FileTypeStats {
    param($Inventory)

    $files = $Inventory | Where-Object {$_.ISDIR -eq 'False'}

    $stats = $files | Group-Object Extension |
        Select-Object @{N='Extension';E={$_.Name}},
                      @{N='Count';E={$_.Count}},
                      @{N='TotalBytes';E={($_.Group | Measure-Object -Property Bytes -Sum).Sum}} |
        Sort-Object Count -Descending

    return $stats
}

$preStats = Get-FileTypeStats -Inventory $pre
$postStats = Get-FileTypeStats -Inventory $post

# Export for comparison
$preStats | Export-Csv "pre_migration_file_types.csv"
$postStats | Export-Csv "post_migration_file_types.csv"

# Compare
Compare-Object -ReferenceObject $preStats -DifferenceObject $postStats -Property Extension, Count |
    Export-Csv "file_type_differences.csv"
```

#### Step 4.4: Verify Folder Structure

```powershell
# Compare folder hierarchies
$preFolders = $pre | Where-Object {$_.ISDIR -eq 'True'} | Select-Object -ExpandProperty Path
$postFolders = $post | Where-Object {$_.ISDIR -eq 'True'} | Select-Object -ExpandProperty Path

# Adjust paths for new location
$postFolders = $postFolders -replace "G:\\NewFileServer", "F:\\OldFileServer"

# Find missing folders
$missingFolders = $preFolders | Where-Object {$_ -notin $postFolders}

if ($missingFolders.Count -gt 0) {
    Write-Host "WARNING: $($missingFolders.Count) folders missing!" -ForegroundColor Red
    $missingFolders | Out-File "MISSING_FOLDERS.txt"
}
```

### Phase 5: Permission Restoration

**Objective:** Restore NTFS permissions on new server.

#### Step 5.1: Verify Current Permissions

```powershell
# Document post-migration permissions
.\Folder Permissions.ps1 `
    -FolderPath "G:\NewFileServer" `
    -OutputPath "post_migration_permissions.csv"
```

#### Step 5.2: Compare and Restore

```powershell
# Load permission inventories
$prePerm = Import-Csv "pre_migration_permissions.csv"
$postPerm = Import-Csv "post_migration_permissions.csv"

# Find permission discrepancies
# This requires manual analysis and restoration using icacls or PowerShell
# See NTFS permission auditing skill for detailed ACL management
```

## Common Migration Scenarios

### Scenario 1: Windows to Windows (Same Domain)

**Approach:** Use Robocopy with /COPYALL

**Advantages:**
- ✅ Preserves NTFS permissions
- ✅ Preserves timestamps
- ✅ Preserves alternate data streams
- ✅ Fast and reliable

**Verification:**
```powershell
# Pre-migration baseline
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "\\OldServer\Share" `
    -OutputPath "baseline.csv" `
    -IncludeHash

# Robocopy migration
robocopy "\\OldServer\Share" "\\NewServer\Share" /E /COPYALL /R:3 /W:5 /LOG:robocopy.log /TEE

# Post-migration verification
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "\\NewServer\Share" `
    -OutputPath "verification.csv" `
    -IncludeHash

# Compare hashes
# (Use comparison script from Phase 4.2)
```

### Scenario 2: Windows to SharePoint Online

**Approach:** Use SharePoint Migration Tool or Microsoft 365 migration tools

**Challenges:**
- ❌ NTFS permissions don't directly map to SharePoint
- ⚠️ Metadata may be stripped or modified
- ⚠️ File name restrictions (SharePoint has stricter limits)

**Pre-Migration:**
```powershell
# 1. Inventory with metadata preservation
.\get all property fields for files and folders (recursive).ps1 "F:\ShareToMigrate" |
    Export-CSV "windows_metadata_archive.csv" -NoTypeInformation

# 2. Baseline with hashes
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "F:\ShareToMigrate" `
    -OutputPath "pre_sharepoint_baseline.csv" `
    -IncludeHash

# 3. Document permissions for manual mapping
.\Folder Permissions.ps1 `
    -FolderPath "F:\ShareToMigrate" `
    -OutputPath "permissions_for_sharepoint_mapping.csv"
```

**Post-Migration:**
- Download from SharePoint and verify hashes
- Map NTFS groups to SharePoint groups manually
- Accept that some metadata will be lost (preserve in CSV archives)

### Scenario 3: Windows to AWS S3 / Azure Blob

**Approach:** Use AWS CLI, AzCopy, or rclone

**Challenges:**
- ❌ No NTFS permissions in object storage
- ⚠️ Metadata stored as object tags (limited)
- ⚠️ Folder structure simulated with key prefixes

**Pre-Migration:**
```powershell
# Full metadata preservation (critical for cloud migrations)
.\get all property fields for files and folders (recursive).ps1 "F:\DataToCloud" |
    Export-CSV "metadata_for_cloud_$(Get-Date -Format 'yyyy-MM-dd').csv" -NoTypeInformation

# Baseline for verification
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "F:\DataToCloud" `
    -OutputPath "cloud_migration_baseline.csv" `
    -IncludeHash `
    -HashAlgorithm SHA256
```

**Post-Migration:**
```powershell
# Download from cloud to temp location
# Then verify hashes against baseline
```

### Scenario 4: Windows to Linux

**Approach:** Use rsync, scp, or Samba

**Challenges:**
- ❌ NTFS permissions don't map to POSIX permissions
- ⚠️ Windows metadata lost (EXIF, Office properties)
- ⚠️ Alternate data streams not preserved

**Critical Pre-Migration Step:**
```powershell
# Preserve ALL Windows metadata before migration
.\get all property fields for files and folders (recursive).ps1 "F:\WindowsData" |
    Export-CSV "windows_metadata_archive_$(Get-Date -Format 'yyyy-MM-dd').csv" -NoTypeInformation

# This is your ONLY record of Windows properties
# Store securely - data cannot be recovered from Linux
```

## Migration Checklist

### Pre-Migration
- [ ] Create quick inventory (no hashes)
- [ ] Analyze size, file count, and scope
- [ ] Identify challenges (long paths, special chars, large files)
- [ ] Document NTFS permissions
- [ ] Create baseline with cryptographic hashes (SHA256)
- [ ] Preserve Windows metadata (if migrating to non-Windows)
- [ ] Hash the baseline file itself
- [ ] Store baseline on separate media (multiple copies)
- [ ] Document baseline creation date/time and analyst

### During Migration
- [ ] Use appropriate tool (Robocopy, rsync, cloud tools)
- [ ] Enable detailed logging
- [ ] Monitor for errors
- [ ] Document start and end times
- [ ] Preserve migration logs

### Post-Migration
- [ ] Create post-migration inventory with hashes
- [ ] Compare file counts (pre vs. post)
- [ ] Compare hashes (verify 100% integrity)
- [ ] Verify folder structure
- [ ] Check file type distribution
- [ ] Document permissions on new system
- [ ] Map and restore permissions (if applicable)
- [ ] Spot-check files manually (open random samples)
- [ ] Document verification results
- [ ] Archive all inventories and reports

### Sign-Off
- [ ] Generate migration report
- [ ] Get stakeholder approval
- [ ] Document any discrepancies
- [ ] Archive baseline data for future reference
- [ ] Decommission old system (only after verification!)

## Performance Tips

### Large Migrations (>1TB)

**Problem:** Hashing terabytes of data takes days.

**Solution:**
```powershell
# 1. Quick inventory first (no hashes)
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "F:\LargeServer" `
    -OutputPath "inventory_quick.csv"

# 2. Migrate using fast tools (Robocopy)
robocopy "F:\LargeServer" "G:\NewServer" /E /COPYALL /R:3 /W:5 /MT:16 /LOG:migration.log

# 3. Hash only changed files after migration
# (Robocopy logs which files were copied vs. skipped)

# 4. Or hash in parallel batches
$folders = Get-ChildItem "F:\LargeServer" -Directory

$folders | ForEach-Object -Parallel {
    .\FileNamePath Export with Hash.ps1 `
        -SourcePath $_.FullName `
        -OutputPath "baseline_$($_.Name).csv" `
        -IncludeHash
} -ThrottleLimit 4
```

### Network Migrations

**Problem:** Network latency slows hash calculation over UNC paths.

**Solution:**
- Run scripts on the file server itself (local access)
- Use Robocopy with /MT for multi-threaded transfer
- Schedule during off-hours to reduce network contention

## Troubleshooting

### Hash Mismatches After Migration

**Symptom:** Post-migration hashes don't match pre-migration baseline.

**Causes:**
1. File was modified during migration (migration too slow, files still in use)
2. Transfer corruption (network issues, hardware failures)
3. Line ending conversion (text files, FTP in ASCII mode)

**Solutions:**
- Re-migrate affected files
- Use binary transfer modes
- Lock files during migration (maintenance window)
- Verify individual files manually

### Missing Files in Post-Migration Inventory

**Symptom:** File count lower after migration.

**Causes:**
1. Migration tool skipped files (long paths, special characters)
2. Permission issues (migration tool couldn't read files)
3. Files deleted between baseline and migration

**Solutions:**
- Review migration logs for errors
- Check "MISSING_FILES.csv" for patterns
- Re-migrate missing files manually
- Fix file names and re-migrate

### Permissions Not Preserved

**Symptom:** Post-migration permissions differ from baseline.

**Causes:**
1. Migration tool doesn't support ACL transfer (cross-platform)
2. Domain/account mapping issues
3. Different file system (NTFS → ext4 → SharePoint)

**Solutions:**
- Use permission documentation from Phase 1
- Manually map and restore permissions
- Accept limitations of destination platform

## Get Help

View detailed script help:
```powershell
Get-Help ".\FileNamePath Export with Hash.ps1" -Full
Get-Help ".\Folder Permissions.ps1" -Full
Get-Help ".\get all property fields for files and folders (recursive).ps1" -Full
```

## Next Steps

After migration:
1. **Archive documentation** - Store baselines, inventories, reports for future reference
2. **Decommission old system** - Only after successful verification!
3. **Monitor new system** - Watch for issues in first 30 days
4. **Update permissions** - Use ntfs-permission-auditing skill for ongoing compliance
5. **Metadata analysis** - Use windows-metadata-extraction skill for post-migration reports
