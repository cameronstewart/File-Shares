#Set-ExecutionPolicy Unrestricted
$SourcePath = "E:\Music"

$DestinationCSVPath = "e:\folders4.csv" #Destination for Temp CSV File
$CSVColumnOrder = 'Path', 'IsDIR', 'Directory', 'Parent', 'Name', 'CreationTime', 'LastAccessTime', 'LastWriteTime', 'Extension', 'BaseName', 'B', 'Root', 'IsReadOnly', 'Attributes', 'Owner', 'AccessToString', 'Group'#, #'MD5', #'SHA1' #Order in which columns in CSV Output are ordered
 
#FOLDERS ONLY
#$SourcePathFileOutput = Get-ChildItem $SourcePath -Recurse  | where {$_.PSIsContainer} 

#FILES AND FOLDERS
$SourcePathFileOutput = Get-ChildItem $SourcePath -Recurse 


$HashOutput = ForEach ($file in $SourcePathFileOutput){

Write-Output (New-Object -TypeName PSCustomObject -Property @{

Path = $file.FullName

IsDIR = $file.PSIsContainer

Directory = $File.DirectoryName

Parent = $file.Parent

Name = $File.Name

CreationTime = $File.CreationTime

LastAccessTime = $File.LastAccessTime

LastWriteTime = $File.LastWriteTime

Extension = $File.Extension

BaseName = $File.BaseName

B = $File.Length

Root = $file.Root

IsReadOnly = $file.IsReadOnly

Attributes = $file.Attributes

Owner = $acl.owner

AccessToString = $acl.accesstostring

Group = $acl.group

#MD5 = Get-FileHash $file.FullName -Algorithm MD5 | Select-Object -ExpandProperty Hash

#SHA1 = Get-FileHash $file.FullName -Algorithm SHA1 | Select-Object -ExpandProperty Hash


}) | Select-Object $CSVColumnOrder

}

 

$HashOutput | Export-Csv -NoTypeInformation -Path $DestinationCSVPath
