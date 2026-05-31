Dim numUnver
If WScript.Arguments(0) = 1 Then
  numVer = "is " & WScript.Arguments(0) & " video"
Else
  numVer = "are " & WScript.Arguments(0) & " videos"
End If

ok = MsgBox("There " & numVer & " in the ""Unverified"" folder that must be manually reviewed." & vbNewLine & vbNewLine & "The contact information you provided has been added into each video's metadata. If a video appears to match its title, you may upload it directly via the Decache website:" & vbNewLine & vbNewLine & "https://sindexmon.github.io/decache/", 32, "Manual verification needed")