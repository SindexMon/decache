Set sh = CreateObject("Shell.Application")

Set folder = sh.BrowseForFolder(0, WScript.Arguments(0), &H10, 17)

If Not folder Is Nothing Then
  folderPath = folder.Self.Path

  If InStr(folderPath, "!") > 0 Then
    folderPath = Replace(folderPath, "^", "^^", 1, -1, 1)
  End If

  WScript.Echo Replace(folderPath, "!", "^!", 1, -1, 1)
End If