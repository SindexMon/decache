Set reg = New RegExp
reg.Pattern = WScript.Arguments(0)

Dim strContent
If WScript.Arguments(2) = 0 Then
  strContent = WScript.Arguments(1)
Else
  Set objFSO = CreateObject("Scripting.FileSystemObject")
  Set objFile = objFSO.OpenTextFile(WScript.Arguments(1), 1)
  strContent = objFile.ReadAll
End If

Dim match
Set matches = reg.Execute(strContent)

For Each match In matches
  If match.SubMatches.Count > 0 Then
    For Each sMatch in match.SubMatches
      WScript.Echo(sMatch)
    Next
  Else
    WScript.Echo(match)
  End If
Next