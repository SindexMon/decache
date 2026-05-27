Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.OpenTextFile(WScript.Arguments(0), 1)
Set objFile2 = objFSO.CreateTextFile(WScript.Arguments(1), True)

keepWriting = 0
filename = ""

Do Until objFile.AtEndOfStream
  strLine = objFile.ReadLine
  If Left(strLine, 19) = "URL               :" Then
    keepWriting = 1
  ElseIf Left(strLine, 19) = "Cache Name        :" Or Left(strLine, 19) = "Full Path         :" Then
    objFile2.WriteLine strLine
    keepWriting = 0
  ElseIf Left(strLine, 19) = "Content Encoding  :" Then
    If keepWriting = 1 Then
      objFile2.WriteLine strLine
    End If

    keepWriting = 0
  ElseIf Left(strLine, 19) = "Filename          :" And keepWriting = 0 Then
    objFile2.WriteLine strLine
  End If

  If keepWriting = 1 Then
    objFile2.WriteLine strLine
  End If
Loop

objFile.Close