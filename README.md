# File-Shares

**Windows File System Analysis Tools**

A collection of PowerShell scripts for extracting comprehensive file system metadata, analyzing NTFS permissions, and generating detailed reports from Windows file shares and local directories.

## 🎯 Purpose

This toolkit is designed for Windows system administrators, IT auditors, and anyone needing detailed file system analysis on Windows platforms. Unlike network-focused share auditing tools, File-Shares specializes in **deep local metadata extraction** using Windows-specific features.

## 🚀 Quick Start

### Prerequisites
- Windows PowerShell 5.1 or higher
- Administrator rights (for full permission analysis)
- Execution policy allowing script execution

### Basic Usage

```powershell
# Export file metadata with hashes
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "C:\MyFolder" `
    -OutputPath "C:\Reports\files.csv" `
    -IncludeHash `
    -HashAlgorithm SHA256

# Export folder permissions
.\Folder Permissions.ps1 `
    -FolderPath "C:\Shares" `
    -OutputPath "C:\Reports\permissions.csv"

# Get comprehensive Windows metadata
.\get all property fields for files and folders (recursive).ps1 "C:\ImportantFiles"
```

## 📋 Scripts Overview

### 1. FileNamePath Export with Hash.ps1 ⭐

**Purpose:** Exports file and folder metadata with optional cryptographic hashes.

**Features:**
- Hierarchical parent-child relationship tracking (ID/PARENTID)
- Optional hash calculation (MD5, SHA1, SHA256, SHA512)
- Comprehensive timestamp extraction (creation, modification, access)
- Progress indicators for large directory trees
- Error logging for inaccessible files
- UTF-8 CSV export

**Output Fields:**
- Path, Name, IsDirectory
- ID, PARENTID, PARENTPATH (hierarchical relationships)
- CreationTime, LastAccessTime, LastWriteTime
- Extension, BaseName
- Bytes (file size)
- Hash (if -IncludeHash specified)

**Example:**
```powershell
.\FileNamePath Export with Hash.ps1 `
    -SourcePath "D:\FileShare" `
    -OutputPath "D:\Reports\inventory.csv" `
    -IncludeHash `
    -HashAlgorithm SHA256
```

**Help:**
```powershell
Get-Help ".\FileNamePath Export with Hash.ps1" -Full
```

---

### 2. Folder Permissions.ps1 ⭐

**Purpose:** Audits NTFS permissions and ACLs for compliance and security analysis.

**Features:**
- Recursive permission enumeration
- Captures users/groups, access rights, and inheritance
- Shows Allow/Deny permissions explicitly
- Optional file permission scanning
- Access denied error handling
- Progress tracking

**Output Fields:**
- Path, Name, IsDirectory
- Owner
- ADGroupOrUser (identity reference)
- AccessControlType (Allow/Deny)
- FileSystemRights (Read, Write, FullControl, etc.)
- IsInherited, InheritanceFlags, PropagationFlags

**Example:**
```powershell
.\Folder Permissions.ps1 `
    -FolderPath "C:\CompanyData" `
    -OutputPath "C:\Audit\permissions.csv"

# Include file permissions (slower)
.\Folder Permissions.ps1 `
    -FolderPath "C:\Sensitive" `
    -OutputPath "C:\Audit\detailed_permissions.csv" `
    -IncludeFiles
```

**Help:**
```powershell
Get-Help ".\Folder Permissions.ps1" -Full
```

---

### 3. get all property fields for files and folders (recursive).ps1

**Purpose:** Extracts **all available Windows metadata** using Shell.Application COM object.

**Features:**
- Accesses 200+ metadata properties
- Includes EXIF data, Office document properties, media tags, etc.
- Supports filtering by filename
- Pipeline-compatible
- Recursive directory traversal

**Unique Properties Extracted:**
- Camera make/model, GPS coordinates (photos)
- Authors, title, subject (Office documents)
- Bit rate, dimensions, duration (media files)
- And 200+ more Windows-specific properties

**Example:**
```powershell
# Get all metadata from all files
.\get all property fields for files and folders (recursive).ps1 "C:\Photos" |
    Export-CSV -Path "C:\metadata.csv" -NoTypeInformation

# Get partial metadata (specific fields)
.\get all property fields for files and folders (recursive).ps1 "C:\Documents" |
    Select-Object -Property FullName, Author, Title, Tags, DateCreated |
    Export-CSV -Path "C:\doc_metadata.csv" -NoTypeInformation
```

---

## 🔍 What Makes This Different?

### vs. Network Share Auditing Tools (PowerHuntShares, SMBeagle)
- **Focus:** Local file system deep analysis, not network scanning
- **Strength:** Windows-specific metadata extraction (Shell.Application)
- **Use Case:** Single-system comprehensive metadata inventory

### vs. Cross-Platform Tools (folderstats)
- **Platform:** Windows-optimized with native COM object access
- **Features:** NTFS permission analysis, Windows property extraction
- **Dependencies:** Zero external dependencies (pure PowerShell)

### vs. Content Analysis Tools (SMB-Data-Discovery)
- **Approach:** Metadata and permissions, not content scanning
- **Speed:** Faster for metadata-only analysis
- **Privacy:** Doesn't read file contents

## 📊 Sample Output

### File Metadata Export
```csv
Path,Name,ISDIR,ID,PARENTID,CreationTime,Bytes,SHA256
C:\Data\report.docx,report.docx,False,5,2,2025-01-15 10:30:00,45678,A1B2C3...
C:\Data\archive,archive,True,6,2,2024-12-01 08:15:00,,
```

### Permission Export
```csv
Path,Owner,ADGroupOrUser,AccessControlType,FileSystemRights,IsInherited
C:\Shares\Public,BUILTIN\Administrators,DOMAIN\Users,Allow,ReadAndExecute,True
C:\Shares\Private,DOMAIN\Admin,DOMAIN\Finance,Allow,FullControl,False
```

## ⚡ Performance Tips

1. **Hash Calculation:** Only use `-IncludeHash` when needed (significantly slower)
2. **Permissions:** Use `-IncludeFiles` only for detailed audits (10x slower)
3. **Progress:** Watch for "Access Denied" errors in error log files
4. **Large Datasets:** Process in batches by directory

## 🛡️ Security Considerations

**Data Sensitivity:**
- Permission exports may contain sensitive ACL information
- Hash values can identify specific file versions
- Review outputs before sharing externally

**Access Rights:**
- Some operations require Administrator privileges
- Access denied errors are logged separately
- Use dedicated audit accounts for compliance scanning

## 🐛 Troubleshooting

### "Access Denied" Errors
- **Solution:** Run PowerShell as Administrator
- **Check:** Error log files (*_errors.csv) for details

### "Execution Policy" Errors
- **Solution:** `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- **Alternative:** `powershell.exe -ExecutionPolicy Bypass -File "script.ps1"`

### Slow Hash Calculation
- **Normal:** Hashing is CPU-intensive and slow for large files
- **Solution:** Process smaller directory trees or remove `-IncludeHash`

### Out of Memory
- **Cause:** Processing millions of files
- **Solution:** Process subdirectories separately and combine results

## 📝 License

MIT License - See [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test your changes on Windows 10/11 and Windows Server
4. Submit a pull request

## 📚 Additional Resources

### Related Tools
- **PowerHuntShares** - Network share security auditing (AD environments)
- **SMBeagle** - Cross-platform SMB share scanning
- **folderstats** - Statistical file system analysis (Python)

### PowerShell Learning
- [PowerShell Gallery](https://www.powershellgallery.com/)
- [PowerShell Best Practices](https://poshcode.gitbook.io/powershell-practice-and-style/)

## 🎓 Use Cases

### IT Administration
- File server inventory and capacity planning
- Duplicate file detection (via hash comparison)
- Audit trail for compliance (SOX, HIPAA, GDPR)

### Digital Forensics
- Local system file timeline analysis
- Metadata extraction for evidence preservation
- Permission analysis for access investigations

### Data Migration
- Pre-migration file inventory
- Post-migration verification (hash comparison)
- Permission mapping documentation

### Archival
- Comprehensive metadata preservation
- Windows property extraction before cross-platform migration
- Long-term storage documentation

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/cameronstewart/File-Shares/issues)
- **Documentation:** See script help: `Get-Help .\script.ps1 -Full`

## 🔖 Version

**Current Version:** 2.0

**Changes in 2.0:**
- ✅ Fixed critical syntax errors
- ✅ Added parameter validation and error handling
- ✅ Enabled hash calculation with multiple algorithms
- ✅ Added progress indicators
- ✅ Added comment-based help to all scripts
- ✅ Improved error logging
- ✅ Added MIT license
- ✅ UTF-8 encoding for international character support

---

**⭐ If you find this useful, please star the repository!**
