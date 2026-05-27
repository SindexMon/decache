If WScript.Arguments(0) = 0 Then
  WScript.Echo MsgBox("We were unable to copy a file from your cache. This is usually because something else is using it." & vbNewLine & vbNewLine & "Try closing any browsers you have open." & vbNewLine & vbNewLine & "Do you want to try again?", 20, "Unable to copy file")
Else
  WScript.Echo 7
End If