With CreateObject("ADODB.Stream")
  .Type = 1
  .Open()
  .LoadFromFile(WScript.Arguments(0))
  .Position = 0
  theBytes = .Read(WScript.Arguments(1))
End With
hexHeader = ""
For i = 1 To LenB(theBytes)
  hexHeader = hexHeader ^& Right("0" ^& Hex(AscB(MidB(theBytes, i, 1))), 2)
Next
WScript.Echo(hexHeader)