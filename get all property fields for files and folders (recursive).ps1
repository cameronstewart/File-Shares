#Source
# https://herringsfishbait.com/2015/04/03/powershell-getting-all-file-metadata-from-a-folder/


#LIST ALL AVAIBLE PROPERTIES FOR A FILE

# Example - Get Partial Metadata From All File in the Folder 
# Get-MetadataFromFolder h:\ | Select-Object -Property FullName, Tags

# Example - Get All Metadata From All File in the Folder 
# Get-MetadataFromFolder h:\ 

# Example - Get Partial Metadata From All File in the Folder AND SubFolders
# Process-SingleFolder h:\ | Select-Object -Property FullName, Tags, BaseName

# Example - Get Full Metadata From All File in the Folder AND SubFolders
# Process-SingleFolder h:\ 

# Example to Full Metadata From All File in the Folder AND SubFolders extract to CSV
# Process-SingleFolder h:\ | Export-CSV -Path h:\output.csv -NoTypeInformation


# Example to Partial Metadata (Common Fields) From All File in the Folder AND SubFolders extract to CSV 
# Process-SingleFolder h:\ | Select-Object -Property 'Name', 'Size', 'Item type', 'Date modified', 'Date created', 'Date accessed', 'Attributes', 'Offline status', 'Offline availability', 'Perceived type', 'Owner', 'Kind', 'Tags', 'Rating', 'Authors', 'Title', 'Subject', 'Categories', 'Comments', 'Copyright', 'Length', 'Bit rate', 'Protected', 'Dimensions', 'Company', 'File description', 'Program name', 'Computer', 'Content created', 'Last printed', 'Date last saved', 'Pages', 'Slides', 'Total editing time', 'Word count', 'Filename', 'File version', 'Bit depth', 'Horizontal resolution', 'Width', 'Vertical resolution', 'Height', 'Folder name', 'Folder path', 'Folder', 'Path', 'Type', 'Language', 'Link status', 'Link target', 'URL', 'Sharing status', 'Product name', 'Product version', 'Legal trademarks', 'Video compression', 'Data rate', 'Frame height', 'Frame rate', 'Frame width', 'Total bitrate' | Export-CSV -Path h:\output.csv -NoTypeInformation

[CmdletBinding()]
param
(
    [parameter(Mandatory=$True,ValueFromPipeline=$True)]
    [string[]]$Path
)
BEGIN
{
    function Get-MetadataFromFolder
    {
        param
        (
            [parameter(Mandatory=$True)]
            [string]$FolderPath,
            [string]$FileName=""
        )
        Write-Verbose "Processing $FolderPath"
        Write-Verbose "FileName : $FileName"
        $Shell=New-Object -ComObject Shell.Application
        $Folder=$Shell.namespace($FolderPath)
        #Build the list of files to process;  if the $FileName parameter is provided
        #only include any files with a matching filename
        if ($FileName -ne "")
        {
            $FileItems=$Folder.Items() | ? {$_.Path -eq $FileName}
        }else
        {
            $FileItems=$Folder.Items()
        }
        foreach ($FileItem in $FileItems)
        {
            #Only process files (not folders)
            if (Test-Path -PathType Leaf $FileItem.Path)
            {
                $Count=0
                $Object=New-Object PSObject
                $Object | Add-Member NoteProperty FullName $FileItem.Path
                #Get all the file detail items of the current file and add them to an object.
                while($Folder.getDetailsOf($Folder.Items, $Count) -ne "")
                {
 
                    $Object | Add-Member -Force NoteProperty ($Folder.getDetailsOf($Folder.Items, $Count)) ($Folder.getDetailsOf($FileItem, $Count))
                    $Count+=1
                }
                $Object
            }
        }
    }
    # Get the metadata for all the files in a folder then recursively call itself for every child folder.
    function Process-SingleFolder
    {
        param
        (
            [parameter(Mandatory=$True)]
            [string]$FolderPath
        )
        Write-Verbose "Processing Folder $FolderPath"
        Get-MetadataFromFolder $FolderPath
        GCI $FolderPath -Directory | % {Process-SingleFolder $_.FullName}
    }
}



PROCESS
{
    #Take all the paths passed from the pipeline.
    foreach ($SinglePath in $Path)
    {
        if (Test-Path -PathType Container $SinglePath)
        {
            Process-SingleFolder $SinglePath
        }elseif (Test-Path -PathType Leaf $SinglePath)
        {
            Write-Verbose "Processing File $SinglePath"
            $CurrentFile=Get-Item $SinglePath
            Get-MetadataFromFolder $CurrentFile.DirectoryName $CurrentFile.FullName
 
        }else
        {
            Write-Error "Invalid Path : $SinglePath"
        }
    }
}


