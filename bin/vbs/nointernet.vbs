numAssets = WScript.Arguments(0)
x = MsgBox("Could not connect to the internet." & vbNewLine & vbNewLine & "If your connection appears to be working fine, there may be a problem with our servers." & vbNewLine & vbNewLine & "Would you like to retry?", 20, "No connection")

If x = 7 Then
  If numAssets = "1" Then
    x = MsgBox("Your " & numAssets & " verified piece of lost media has been placed within the following file:" & vbNewLine & vbNewLine & "Assets.zip" & vbNewLine & vbNewLine & "This file contains your entered identifier. You may upload it directly through the Decache website.", 32, "Notice")
  ElseIf numAssets <> "0" Then
    x = MsgBox("Your " & numAssets & " verified pieces of lost media have been placed within the following file:" & vbNewLine & vbNewLine & "Assets.zip" & vbNewLine & vbNewLine & "This file contains your entered identifier. You may upload it directly through the Decache website.", 32, "Notice")
  End If

  WScript.Echo 0
Else
  WScript.Echo 1
End If