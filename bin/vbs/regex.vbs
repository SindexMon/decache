Set reg = New RegExp
reg.Pattern = WScript.Arguments(0)

Dim strContent
If WScript.Arguments(2) = 1 Then
  Set objFSO = CreateObject("Scripting.FileSystemObject")
  Set objFile = objFSO.OpenTextFile(WScript.Arguments(1), 1)
  strContent = objFile.ReadAll
Else
  strContent = WScript.Arguments(1)
End If

If WScript.Arguments(2) = 2 Then
  reg.Global = True
  WScript.Echo reg.Replace(strContent, "")
Else
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
End If