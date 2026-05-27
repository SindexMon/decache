Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.OpenTextFile(WScript.Arguments(0), 1)

With CreateObject("ADODB.Stream")
  .Type = 1
  .Open()
  .LoadFromFile(objFile.ReadLine)
  .Position = 0
  theBytes = .Read(WScript.Arguments(1))
End With

If IsNull(theBytes) Then
  hexHeader = "00"
Else
  hexHeader = ""
  For i = 1 To LenB(theBytes)
    hexHeader = hexHeader & Right("0" & Hex(AscB(MidB(theBytes, i, 1))), 2)
  Next
End If

WScript.Echo(hexHeader)