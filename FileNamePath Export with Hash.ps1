$SourcePath = "g:\is"

$DestinationCSVPath = "h:\IS.csv" #Destination for Temp CSV File
$CSVColumnOrder = 'Path','Directory','Name','CreationTime','LastAccessTime','LastWriteTime','Extension','BaseName','B','MD5'#,'SHA1' #Order in which columns in CSV Output are ordered
 

$SourcePathFileOutput = Get-ChildItem $SourcePath -File -Recurse

$HashOutput = ForEach ($file in $SourcePathFileOutput){

Write-Output (New-Object -TypeName PSCustomObject -Property @{

Path = $file.FullName

Directory = $File.DirectoryName

Name = $File.Name

CreationTime = $File.CreationTime

LastAccessTime = $File.LastAccessTime

LastWriteTime = $File.LastWriteTime

Extension = $File.Extension

BaseName = $File.BaseName

B = $File.Length

MD5 = Get-FileHash $file.FullName -Algorithm MD5 | Select-Object -ExpandProperty Hash

#SHA1 = Get-FileHash $file.FullName -Algorithm SHA1 | Select-Object -ExpandProperty Hash

}) | Select-Object $CSVColumnOrder

}

 

$HashOutput | Export-Csv -NoTypeInformation -Path $DestinationCSVPath
