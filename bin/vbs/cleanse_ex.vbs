Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.OpenTextFile(WScript.Arguments(0), 1)


If WScript.Arguments(1) = 1 Then
  burger = Replace(objFile.ReadAll, "%", "%%", 1, -1, 1)
  burger = Replace(burger, "&", "^&", 1, -1, 1)
  burger = Replace(burger, "!", "^^^^!", 1, -1, 1)
Else
  burger = objFile.ReadAll
  
  If InStr(burger, "!") > 0 Then
    burger = Replace(burger, "^", "^^^^", 1, -1, 1)
  End If

  burger = Replace(burger, "!", "^^^!", 1, -1, 1)
End If

WScript.Echo burger