numAssets = WScript.Arguments(0)
fileName = WScript.Arguments(1)

If numAssets = "1" Then
  WScript.Echo MsgBox("Your " & numAssets & " verified piece of lost media has been placed within the following file:" & vbNewLine & vbNewLine & fileName & vbNewLine & vbNewLine & "This file contains your entered identifier. You may upload it directly through the Decache website:" & vbNewLine & vbNewLine & "https://sindexmon.github.io/decache/" & vbNewLine & vbNewLine & "Do you want to open the site in your browser?", 36, "Notice")
ElseIf numAssets <> "0" Then
  WScript.Echo MsgBox("Your " & numAssets & " verified pieces of lost media have been placed within the following file:" & vbNewLine & vbNewLine & fileName & vbNewLine & vbNewLine & "This file contains your entered identifier. You may upload it directly through the Decache website:" & vbNewLine & vbNewLine & "https://sindexmon.github.io/decache/" & vbNewLine & vbNewLine & "Do you want to open the site in your browser?.", 36, "Notice")
Else
  WScript.Echo MsgBox("Your encrypted video IDs have been placed within the following file:" & vbNewLine & vbNewLine & fileName & vbNewLine & vbNewLine & "This file contains your entered identifier. You may upload it directly through the Decache website:" & vbNewLine & vbNewLine & "https://sindexmon.github.io/decache/" & vbNewLine & vbNewLine & "Do you want to open the site in your browser?.", 36, "Notice")
End If