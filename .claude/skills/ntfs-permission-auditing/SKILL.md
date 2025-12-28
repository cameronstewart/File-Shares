---
name: ntfs-permission-auditing
description: Audit NTFS permissions and ACLs for compliance and security analysis. Use when auditing file permissions, compliance reporting (SOX, HIPAA, GDPR), security assessments, or when the user mentions ACLs, NTFS permissions, or access rights.
allowed-tools: Read, Bash, Grep, Glob
---

# NTFS Permission Auditing

Audit NTFS permissions and Access Control Lists (ACLs) for compliance reporting and security analysis using PowerShell.

## Overview

The Folder Permissions script provides comprehensive NTFS permission auditing with:
- **Recursive ACL enumeration** for entire directory trees
- **Inheritance tracking** to understand permission propagation
- **Allow/Deny explicit display** for security analysis
- **Ownership information** for compliance documentation
- **CSV export** for analysis in Excel, databases, or SIEM tools

## Prerequisites

Before running permission audits:
- **Administrator rights** (required for reading ACLs)
- Windows PowerShell 5.1 or higher
- Execution policy: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

## Script: Folder Permissions.ps1

### Purpose
Audit NTFS permissions and ACLs for compliance and security analysis.

### Key Features
- Recursive permission enumeration across directory trees
- Captures users/groups, access rights, and inheritance flags
- Shows Allow/Deny permissions explicitly
- Optional file permission scanning (slower but comprehensive)
- Access denied error handling and logging
- Progress tracking for large audits

### Basic Usage

```powershell
# Audit folder permissions only (fast)
.\Folder Permissions.ps1 `
    -FolderPath "C:\CompanyData" `
    -OutputPath "C:\Audit\permissions.csv"

# Include file permissions (slower, more comprehensive)
.\Folder Permissions.ps1 `
    -FolderPath "C:\Sensitive" `
    -OutputPath "C:\Audit\detailed_permissions.csv" `
    -IncludeFiles
```

### Output Fields

The script generates CSV output with these columns:
- **Path** - Full path to folder/file
- **Name** - Folder/file name
- **IsDirectory** - True for folders, False for files
- **Owner** - Account that owns the object
- **ADGroupOrUser** - Identity reference (user/group with permissions)
- **AccessControlType** - Allow or Deny
- **FileSystemRights** - Specific rights (Read, Write, FullControl, Modify, etc.)
- **IsInherited** - Whether permission is inherited from parent
- **InheritanceFlags** - How permissions propagate to children
- **PropagationFlags** - Additional inheritance control

## Common Use Cases

### Compliance Auditing (SOX, HIPAA, GDPR)

**Problem:** Regulatory requirements mandate periodic access control reviews.

**Solution:**
```powershell
# Annual permission audit for compliance
.\Folder Permissions.ps1 `
    -FolderPath "E:\CompanyData" `
    -OutputPath "Q1_2025_Permissions_Audit.csv"
```

**Analysis:**
```powershell
# Load audit data
$audit = Import-Csv "Q1_2025_Permissions_Audit.csv"

# Find folders with explicit (non-inherited) permissions
$audit | Where-Object {$_.IsInherited -eq "False"}

# Find "Deny" permissions (unusual and often problematic)
$audit | Where-Object {$_.AccessControlType -eq "Deny"}

# Find FullControl permissions
$audit | Where-Object {$_.FileSystemRights -match "FullControl"}
```

**Documentation:** Save audit results as evidence of compliance reviews.

### Security Assessment

**Problem:** Identify overly permissive access rights or misconfigurations.

**Solution:**
```powershell
# Audit sensitive directories
.\Folder Permissions.ps1 `
    -FolderPath "C:\HR\Confidential" `
    -OutputPath "security_review.csv" `
    -IncludeFiles
```

**Red Flags to Look For:**
1. **Everyone group with Write access**
   ```powershell
   $audit | Where-Object {$_.ADGroupOrUser -match "Everyone" -and $_.FileSystemRights -match "Write|Modify|FullControl"}
   ```

2. **Users group with excessive rights**
   ```powershell
   $audit | Where-Object {$_.ADGroupOrUser -match "Users" -and $_.FileSystemRights -match "FullControl"}
   ```

3. **Deny permissions** (often indicate past security issues)
   ```powershell
   $audit | Where-Object {$_.AccessControlType -eq "Deny"}
   ```

### Access Investigation

**Problem:** User reports they can't access a file/folder they should have access to.

**Solution:**
```powershell
# Audit specific path
.\Folder Permissions.ps1 `
    -FolderPath "C:\Shares\Finance\Reports" `
    -OutputPath "access_investigation.csv" `
    -IncludeFiles
```

**Analysis:**
```powershell
# Find all permissions for specific user
$audit = Import-Csv "access_investigation.csv"
$audit | Where-Object {$_.ADGroupOrUser -match "username"}

# Check inheritance chain
$audit | Select-Object Path, IsInherited, InheritanceFlags | Format-Table
```

### Pre-Migration Documentation

**Problem:** Document current permissions before server migration.

**Solution:**
```powershell
# Create permission baseline
.\Folder Permissions.ps1 `
    -FolderPath "F:\OldFileServer" `
    -OutputPath "pre_migration_permissions.csv"
```

**Post-Migration Verification:**
```powershell
# Audit new server
.\Folder Permissions.ps1 `
    -FolderPath "G:\NewFileServer" `
    -OutputPath "post_migration_permissions.csv"

# Compare results to verify permission preservation
$pre = Import-Csv "pre_migration_permissions.csv"
$post = Import-Csv "post_migration_permissions.csv"

# Verify counts match
Write-Host "Pre-migration entries: $($pre.Count)"
Write-Host "Post-migration entries: $($post.Count)"
```

## Understanding Output Fields

### Access Control Type
- **Allow** - Permission grants access
- **Deny** - Permission explicitly blocks access (takes precedence over Allow)

### File System Rights
Common rights values:
- **Read** - View files and folder contents
- **Write** - Create new files and folders
- **Modify** - Read + Write + Delete
- **FullControl** - All rights including permission changes
- **ReadAndExecute** - Read + run executables
- **ListDirectory** - View folder contents (folders only)

### Inheritance Flags
- **None** - No inheritance (explicit permission on this object only)
- **ContainerInherit** - Subfolders inherit this permission
- **ObjectInherit** - Files inherit this permission
- **ContainerInherit, ObjectInherit** - Both files and folders inherit

### IsInherited
- **True** - Permission came from parent folder
- **False** - Permission explicitly set on this object (breaks inheritance)

## Performance Considerations

### Folder-Only vs. File-Level Auditing

**Folder-only (default):** Fast, suitable for most audits
```powershell
.\Folder Permissions.ps1 -FolderPath "C:\Data" -OutputPath "audit.csv"
```

**File-level (slower):** Comprehensive, use for detailed security reviews
```powershell
.\Folder Permissions.ps1 -FolderPath "C:\Data" -OutputPath "audit.csv" -IncludeFiles
```

**Performance impact:** File-level auditing is approximately 10x slower.

### Large Directory Trees

For very large file shares:
1. **Process in batches** by subdirectory
2. **Monitor progress** indicators during execution
3. **Check error logs** (*_errors.csv) for access denied issues

## Troubleshooting

### "Access Denied" Errors
**Symptom:** Many entries in error log file

**Solutions:**
1. Run PowerShell as Administrator
2. Use dedicated service account with audit privileges
3. Review error log to identify protected system folders

### Slow Execution
**Symptom:** Script runs for hours

**Causes:**
- File-level auditing enabled (`-IncludeFiles`)
- Very large directory tree
- Network shares with latency

**Solutions:**
- Remove `-IncludeFiles` if file-level detail not required
- Process subdirectories separately
- Run on local system rather than over network

### Missing Permissions
**Symptom:** Expected permissions don't appear in output

**Causes:**
- Permissions are inherited (check parent folders)
- Access denied on that specific path
- Script run without sufficient privileges

**Solutions:**
- Check inheritance chain manually: `Get-Acl "C:\Path" | Format-List`
- Run as Administrator
- Review error log file

## Security Best Practices

### Audit Account Setup
1. Create dedicated audit service account
2. Grant "List Folder / Read Data" on root of audit scope
3. Enable "Audit object access" in Group Policy
4. Log all audit activities

### Handling Audit Data
1. **Protect audit outputs** - CSV files contain sensitive ACL information
2. **Encrypt storage** - Store reports on encrypted volumes
3. **Access control** - Limit who can view audit results
4. **Retention policy** - Define how long to keep audit reports

### Regular Auditing Schedule
- **Quarterly audits** for compliance (SOX, HIPAA, GDPR)
- **Monthly audits** for high-security environments
- **Event-driven audits** after organizational changes

## Compliance Reporting

### SOX Compliance
**Requirement:** Document access controls to financial data

**Procedure:**
```powershell
.\Folder Permissions.ps1 `
    -FolderPath "E:\FinancialData" `
    -OutputPath "SOX_Audit_$(Get-Date -Format 'yyyy-MM').csv"
```

**Report:** Identify who has access to financial data, document in audit trail.

### HIPAA Compliance
**Requirement:** Document access controls to Protected Health Information (PHI)

**Procedure:**
```powershell
.\Folder Permissions.ps1 `
    -FolderPath "F:\PatientRecords" `
    -OutputPath "HIPAA_Audit_$(Get-Date -Format 'yyyy-MM').csv" `
    -IncludeFiles
```

**Analysis:** Verify minimum necessary access principle.

### GDPR Compliance
**Requirement:** Document who can access personal data

**Procedure:**
```powershell
.\Folder Permissions.ps1 `
    -FolderPath "G:\CustomerData" `
    -OutputPath "GDPR_Audit_$(Get-Date -Format 'yyyy-MM').csv"
```

**Report:** Maintain access logs as evidence of data protection measures.

## Advanced Analysis

### Find Permission Anomalies
```powershell
$audit = Import-Csv "permissions.csv"

# Find broken inheritance (explicit permissions)
$audit | Where-Object {$_.IsInherited -eq "False"} |
    Group-Object Path |
    Sort-Object Count -Descending

# Find users with FullControl
$audit | Where-Object {$_.FileSystemRights -match "FullControl"} |
    Group-Object ADGroupOrUser |
    Sort-Object Count -Descending

# Find Deny permissions (security red flag)
$audit | Where-Object {$_.AccessControlType -eq "Deny"}
```

### Generate Summary Reports
```powershell
$audit = Import-Csv "permissions.csv"

# Count permissions by user/group
$audit | Group-Object ADGroupOrUser |
    Select-Object Name, Count |
    Sort-Object Count -Descending |
    Export-Csv "permission_summary.csv"

# Count access types
$audit | Group-Object AccessControlType |
    Select-Object Name, Count |
    Format-Table
```

## Get Help

View detailed script help:
```powershell
Get-Help ".\Folder Permissions.ps1" -Full
```

## Next Steps

After auditing permissions:
1. **Remediate issues** - Fix overly permissive access
2. **Document findings** - Create compliance reports
3. **Automate audits** - Schedule regular permission reviews
4. **Metadata extraction** - Use windows-metadata-extraction skill for file inventory
5. **Migration planning** - Use data-migration-planning skill to preserve permissions during moves
