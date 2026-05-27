Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.OpenTextFile(WScript.Arguments(0), 1)

If WScript.Arguments(3) = 0 Then
  If WScript.Arguments(1) = 0 Then
    If WScript.Arguments(2) = 0 Then
      ok = MsgBox("You need administrative permissions to access the following folder:" & vbNewLine & vbNewLine & objFile.ReadLine & vbNewLine & vbNewLine & "Normally you should relaunch as administrator to read this directory, but an ampersand (&) is in your path. To launch as administrator, please first move the program or remove the ampersand(s) from any preceding folders. Otherwise, press OK.", 16, "Unable to scan folder")
    Else 
      ok = MsgBox("You need administrative permissions to access the following folder:" & vbNewLine & vbNewLine & objFile.ReadLine & vbNewLine & vbNewLine & "Please relaunch as administrator to read this directory. Otherwise, press OK.", 16, "Unable to scan folder")
    End If
  Else
    ok = MsgBox("You do not have permission to access the following folder:" & vbNewLine & vbNewLine & objFile.ReadLine & vbNewLine & vbNewLine & "This can be solved by running this script from the user in question (not on a backup), or manually changing the permissions of the folder to allow access." & vbNewLine & vbNewLine & "Do you want to try giving yourself access?", 20, "Unable to scan folder")
    If ok = 6 Then
      WScript.Echo MsgBox("WARNING:" & vbNewLine & vbNewLine & "Taking ownership of a folder owned by another user may have unintended consequences. Do not do this if the user in question intends to continue using the computer." & vbNewLine & vbNewLine & "Do you want to proceed?", 52, "Unable to scan folder")
    End If
  End If
ElseIf WScript.Arguments(3) = 2 And WScript.Arguments(4) = 0 Then ' Silence is on mode 2 and it's only been attempted one time
  WScript.Echo 6
Else
  WScript.Echo 7
End If