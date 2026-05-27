Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.OpenTextFile(WScript.Arguments(0), 1)

Do While Not objFile.AtEndOfStream
    strLine = objFile.ReadLine
    
    If InStr(strLine, "!") > 0 Then
      strLine = Replace(strLine, "^", "^^", 1, -1, 1)
    End If

    strLine = Replace(strLine, "!", "^!", 1, -1, 1)
    
    WScript.Echo strLine
Loop

objFile.Close