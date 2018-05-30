# GET FOLDERS (ALL FIELDS)
Get-ChildItem -Path C:\ -Recurse -Directory -Force -ErrorAction SilentlyContinue | Select-Object FullName,BaseName,Creation | Export-Csv h:\exporttest.csv -NoTypeInformation

# GET FILES AND FOLDERS (ALL FIELDS)
Get-ChildItem -Path H:\ -Recurse -Force -ErrorAction SilentlyContinue | Export-Csv h:\exporttest.csv -NoTypeInformation
