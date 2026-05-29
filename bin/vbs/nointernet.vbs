numAssets = WScript.Arguments(0)
fileName = WScript.Arguments(1)

x = MsgBox("Could not connect to the internet." & vbNewLine & vbNewLine & "If your connection appears to be working fine, there may be a problem with our servers." & vbNewLine & vbNewLine & "Would you like to retry?", 20, "No connection")

If x = 7 Then
  If numAssets = "1" Then
    x = MsgBox("Your " & numAssets & " verified piece of lost media has been placed within the following file, which can be found in the program's folder:" & vbNewLine & vbNewLine & fileName & vbNewLine & vbNewLine & "This file contains the contact information you provided. You may upload it directly through the Decache website, and we will be in touch if necessary:" & vbNewLine & vbNewLine & "https://sindexmon.github.io/decache/", 32, "Notice")
  ElseIf numAssets <> "0" Then
    x = MsgBox("Your " & numAssets & " verified pieces of lost media have been placed within the following file, which can be found in the program's folder:" & vbNewLine & vbNewLine & fileName & vbNewLine & vbNewLine & "This file contains the contact information you provided. You may upload it directly through the Decache website, and we will be in touch if necessary:" & vbNewLine & vbNewLine & "https://sindexmon.github.io/decache/", 32, "Notice")
  Else
    x = MsgBox("Your encrypted video IDs have been placed within the following file, which can be found in the program's folder:" & vbNewLine & vbNewLine & fileName & vbNewLine & vbNewLine & "This file contains the contact information you provided. You may upload it directly through the Decache website, and we will be in touch if necessary:" & vbNewLine & vbNewLine & "https://sindexmon.github.io/decache/", 32, "Notice")
  End If

  WScript.Echo 0
Else
  WScript.Echo 1
End If