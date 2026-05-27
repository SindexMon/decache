Set fso = CreateObject("Scripting.FileSystemObject")
Set pathVar = fso.OpenTextFile(WScript.Arguments(0), 1)
Set origFolder = fso.GetFolder(pathVar.ReadLine)

searchType = WScript.Arguments(1) ' 0 for folders, 1 for files
searchTerm = WScript.Arguments(2)

GetSubFolders origFolder, 1

Sub GetSubFolders(folder, folderLayer)
  On Error Resume Next
  crack = folder.SubFolders.Count
  
  fixedPath = Replace(folder.Path, "!", "^!", 1, -1, 1)
  If Right(fixedPath, 1) <> "\" Then
    fixedPath = fixedPath & "\"
  End If

  If Err.Number = 0 Then
    For Each oSubFolder In folder.SubFolders
      If (folder.Attributes And 1024) = 0 Then GetSubFolders oSubFolder, folderLayer + 1
    Next

    If searchTerm <> "" Then
      filePath = fso.BuildPath(folder.Path, searchTerm)

      If (searchType = 0 And fso.FolderExists(filePath)) Or (searchType = 1 And fso.FileExists(filePath)) Then
        WScript.Echo fixedPath
      End If
    End If
  ElseIf searchTerm = "" Then
    WScript.Echo fixedPath
  End If
End Sub