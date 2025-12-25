Set sh = CreateObject("Shell.Application")

Set folder = sh.BrowseForFolder(0, WScript.Arguments(0), &H10, 17)

If Not folder Is Nothing Then
  WScript.Echo folder.Self.Path
End If