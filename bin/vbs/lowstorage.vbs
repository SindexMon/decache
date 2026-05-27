bytes = WScript.Arguments(0)

If bytes < 1000 Then
  bytes = Round(WScript.Arguments(0), 2) & " B"
ElseIf bytes < 1000000 Then
  bytes = Round(WScript.Arguments(0) / 1000, 2) & " KB"
ElseIf bytes < 1000000000 Then
  bytes = Round(WScript.Arguments(0) / 1000000, 2) & " MB"
Else
  bytes = Round(WScript.Arguments(0) / 1000000000, 2) & " GB"
End If

WScript.Echo MsgBox("You don't have enough storage space to copy this file!" & vbNewLine & vbNewLine & "Please free up " & bytes & " to continue.", 16, "Unable to copy file")