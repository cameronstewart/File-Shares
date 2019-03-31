#Set-ExecutionPolicy Unrestricted$ID=1

$SourcePath="C:\users\username"
$DestinationCSVPath = "C:\Users\users\export.csv"

$SourcePathFileOutput=@()

#for have the parent dir
$SourcePathFileOutput += Get-Item $SourcePath | %{
$ParentPath=if ($_.PSIsContainer){$_.parent.FullName}else{$_.DirectoryName}

Add-Member -InputObject $_ -MemberType NoteProperty -Name "ID" -Value ($ID++)
Add-Member -InputObject $_ -MemberType NoteProperty -Name "PARENTPATH" -Value $ParentPath
$_
}

#for have all directory and file
$SourcePathFileOutput += Get-ChildItem $SourcePath -Recurse | %{
$ParentPath=if ($_.PSIsContainer){$_.parent.FullName}else{$_.DirectoryName}

Add-Member -InputObject $_ -MemberType NoteProperty -Name "ID" -Value ($ID++)
Add-Member -InputObject $_ -MemberType NoteProperty -Name "PARENTPATH" -Value $ParentPath
$_
}

#List dir for optimise 
$DirOutput=$SourcePathFileOutput | where {$_.psiscontainer}

#for output result (add all properties you want)
$list=foreach ($Current in $SourcePathFileOutput)
{
$Result=[pscustomobject]@{
    Path = $Current.FullName
    Name = $Current.Name
    ISDIR=$Current.psiscontainer
    ID=$Current.ID
    PARENTID=($DirOutput | where {$_.FullName -eq $Current.PARENTPATH}).ID
    PARENTPATH=$Current.PARENTPATH
    ParentName = $Current.Parent
    #FileCount = (GCI $Current.FullName -Recurse).Count
    CreationTime = $Current.CreationTime
    LastAccessTime = $Current.LastAccessTime
    LastWriteTime = $Current.LastWriteTime
    Extension = $Current.Extension
    BaseName = $Current.BaseName
    B = $Current.Length        
    #MD5 = Get-FileHash $Current.FullName -Algorithm MD5 | Select-Object -ExpandProperty Hash
}

#Initialise parent root
if ($Result.PARENTID -eq $null) {$Result.PARENTID=0}

#send result on output
$Result
} 

$list | export-csv -NoTypeInformation –append –path $DestinationCSVPath
