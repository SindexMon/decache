Set fso = CreateObject("Scripting.FileSystemObject")
Set objFile = fso.GetFile(fso.OpenTextFile(WScript.Arguments(1), 1).ReadLine)

timeDiff = Abs(DateDiff("s", WScript.Arguments(0), objFile.DateLastModified))

If TimeDiff < (3600 * 1.5) Then
  ' Confirmed if this is the only matching video
  WScript.Echo 1
ElseIf TimeDiff < (86400 / 2 + 3600 / 2) Then
  ' Likely given time zone discrepancies
  WScript.Echo 2
Else
  ' Not within range at all
  WScript.Echo 3
End If