# File-Shares
File Share Analysis Tools

## FileNamePath Export with Hash.ps1
PowerShell Script to extract data for all files in a directory and export to csv.

Data includes 
* 'Path'
* 'Directory'
* 'IsDir'
* 'Name'
* 'CreationTime'
* 'LastAccessTime'
* 'LastWriteTime'
* 'Extension'
* 'BaseName'
* 'B'
* 'MD5'
* 'SHA1'
* Plus others

## Example Output

![Example Output](https://github.com/cameronstewart/File-Shares/blob/master/Sample%20Output.PNG)

## How to Run

1. Windows > Windows Powershell ISE
2. Paste Script into top part of the window
3. Modify 
    $SourcePath = "H:\DirToScans"
    $DestinationCSVPath = "H:\OutputFile.csv"
4. Run Script (F5)

![Running the Script](https://github.com/cameronstewart/File-Shares/blob/master/run%20file.png)
