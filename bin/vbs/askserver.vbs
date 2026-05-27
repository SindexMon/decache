numAssets = WScript.Arguments(0)
numVideos = WScript.Arguments(1)

If numAssets <> "0" Then
  Do
    assetStatement = numAssets & " pieces"
    fileStatement = "They"
    
    If numAssets = "1" Then
      assetStatement = numAssets & " piece"
      fileStatement = "It"
    End If

    ans = InputBox("Decache has verified " & assetStatement & " of lost media on your computer! " & fileStatement & " can be reviewed in the ""Verified"" folder." & vbNewLine & vbNewLine & "To send these files over immediately, enter something we can contact you with (e.g. an email; Discord username; anonymous), and press OK."  & vbNewLine & vbNewLine & "If you want to share these someplace else, press cancel.", "Success", "")
    ans = Replace(ans, "^", "^^")
    ans = Replace(ans, "!", "^!")

    If ans = "" Then
      x = MsgBox("To be clear: by not providing an identifier, you are stating that your verified files WILL NOT be sent over, and you intend to share them independently." & vbNewLine & vbNewLine & "If you understand, press YES. If you want to go back, press NO.", 52, "Confirmation needed")
    Else
      x = MsgBox("To be clear: you are sending over your verified files with the following identifier (our only way to contact you):"  & vbNewLine & vbNewLine & ans & vbNewLine & vbNewLine & "If you understand, press YES. If you want to go back, press NO.", 52, "Confirmation needed")
    End If
  Loop Until x = 6

  If ans <> "" Then
    pub = InputBox("If you want to be credited publicly, please enter an alternative name that you're okay with being shared." & vbNewLine & vbNewLine & "Otherwise, press cancel.", "Confirmation needed", "")
    pub = Replace(pub, "^", "^^")
    pub = Replace(pub, "!", "^!")

    If pub = "" Then
      pub = "none provided"
    End If

    If numVideos <> "0" Then
      sendVideos = MsgBox("Do you want to encrypt and send the IDs of the videos in your cache? This will allow us to contact you if a video you have now is added to Decache in the future." & vbNewLine & vbNewLine & "We will NOT be able to see any videos you watched without knowing the exact ID.", 36, "Confirmation needed")
    End If

    WScript.Echo ans
    WScript.Echo pub
    WScript.Echo sendVideos
  End If
ElseIf numVideos <> "0" Then
  username = InputBox("Decache was not able to verify any lost media on your computer." & vbNewLine & vbNewLine & "If you want to send over the IDs of the " & numVideos & " unrelated videos in your cache (in case one is added to Decache later on), enter something we can contact you through (e.g. an email; Discord username), and press OK." & vbNewLine & vbNewLine & "These IDs will be encrypted, meaning we cannot read them, but can check if a specific ID is included." & vbNewLine & vbNewLine & "Otherwise, press cancel.", "Success")
  username = Replace(username, "^", "^^")
  username = Replace(username, "!", "^!")

  If username <> "" Then
    WScript.Echo username
    WScript.Echo "none provided"
    WScript.Echo 6
  End If
Else
  poop = MsgBox("Decache was not able to verify any lost media on your computer.", 32, "Complete")
End If