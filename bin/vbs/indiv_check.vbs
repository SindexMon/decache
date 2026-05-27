Set fso = CreateObject("Scripting.FileSystemObject")
Set file = fso.OpenTextFile(WScript.Arguments(0), 1)
folderName = file.ReadLine

If fso.FolderExists(folderName) Then
  Set folder = fso.GetFolder(folderName)
  
  If (folder.Attributes And 1024) = 0 Then
    WScript.Echo 1
  End If
End If