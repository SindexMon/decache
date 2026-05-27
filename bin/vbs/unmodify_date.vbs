Set objShell = CreateObject("Shell.Application")
Set objFSO = CreateObject("Scripting.FileSystemObject")

Set objFile = objFSO.GetFile(objFSO.OpenTextFile(WScript.Arguments(0), 1).ReadLine)
Set objFolder = objShell.NameSpace(objFile.ParentFolder.Path)
Set objFolderItem = objFolder.ParseName(objFile.Name)

If WScript.Arguments(1) = "" Then
  WScript.Echo objFile.DateLastModified
ElseIf WScript.Arguments(2) = "1" Then
  objFolderItem.ModifyDate = WScript.Arguments(1)
Else
  Set oldFile = objFSO.GetFile(objFSO.OpenTextFile(WScript.Arguments(1), 1).ReadLine)
  objFolderItem.ModifyDate = oldFile.DateLastModified
End If