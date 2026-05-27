:retryCopy
  set /p theFilePath=<"variables\sizecheck.var"
  if "!theFilePath:~-1!" == "\" (
    for /f "tokens=3 USEBACKQ" %%s in (`dir /-c /w ^| findstr /c:"File(s)"`) do set "realSize=%%s" 2>nul
  ) else (
    set "realSize=%~z1"
  )

  for /f "tokens=3 USEBACKQ" %%s in (`dir /-c /w`) do set "size=%%s" 2>nul
  set /a "size=!size!" 2>nul
  if !errorlevel! neq 1073750992 (
    if !size! geq 0 (
      if !size! lss !realSize! (
        set /a "space=!realSize! - !size!"
        cscript /nologo "vbs\lowstorage.vbs" "!space!"
        goto retryCopy
      )
    )
  )