Dim reg : Set reg = New RegExp
reg.Pattern = WScript.Arguments(0)
Dim matches, match
Set matches = reg.Execute(WScript.Arguments(1))
For Each match In matches
    WScript.Echo(match)
Next