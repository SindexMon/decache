:: This program will print 1 if the user is allowed access to the directory/file, therefore allowing a for loop to proceed exactly once.
:: This essentially acts exactly like an if statement regarding the user's access to the file.
@echo off
setlocal enabledelayedexpansion

set "VAR_PATH=variables\"
set "IS_ADMIN=%~1"
set "SILENCE_ERRORS=%~2"

echo "%~dp0" | findstr /c:"&" >nul 2>nul
set "WILL_SUCCEED_ON_ADMIN=!errorlevel!"
set "RANDOM_BIT=!RANDOM!"
set result=1
set fallbackCount=0

:: Store the error message for when a file is being used
if not exist "!VAR_PATH!errinuse.var" (
  start /b cmd /c "((echo lock & ping 127.0.0.1 -n 6 > nul) > !VAR_PATH!hotgarbage!RANDOM_BIT!.var) & del !VAR_PATH!hotgarbage!RANDOM_BIT!.var"
  ping 127.0.0.1 -n 1 >nul 2>nul
  ren "!VAR_PATH!hotgarbage!RANDOM_BIT!.var" "coldgarbage!RANDOM_BIT!.var" >nul 2>"!VAR_PATH!errinuse.var"

  if exist "!VAR_PATH!coldgarbage!RANDOM_BIT!.var" (
    del "!VAR_PATH!coldgarbage!RANDOM_BIT!.var"
    del "!VAR_PATH!errinuse.var"
    set "errorInUse=The process cannot access the file because it is being used by another process."
  ) else (
    set /p errorInUse=< "!VAR_PATH!errinuse.var"
  )
) else (
  set /p errorInUse=< "!VAR_PATH!errinuse.var"
)

set /p filteredPath=< "!VAR_PATH!brokendir.var"

if exist "!filteredPath!" (
  if exist "!filteredPath!\" (
    set "pathType=dir"
    set "truthPath=!filteredPath!"
  ) else (
    set "pathType=file"
    echo !filteredPath!> "!VAR_PATH!exstorage.var"
    for /f "tokens=* delims=" %%c in ('cscript /nologo "vbs\cleanse_ex.vbs" "!VAR_PATH!exstorage.var" "0"') do set "truthPath=%%c"
    for %%f in ("!truthPath!") do (
      set "truthPath=%%~dpf"
    )
  )

  echo !truthPath!> "!VAR_PATH!brokendir.var"
  for /f %%n in ('cscript /nologo "vbs\indiv_check.vbs" "!VAR_PATH!brokendir.var"') do (
    :startCheck
    if "!pathType!" == "file" (
      set fileCanOpen=0
      echo !filteredPath!> "variables\hexfile.var"
      for /f %%z in ('cscript /nologo "vbs\hex.vbs" "variables\hexfile.var" 17 2^>nul') do (
        set result=%%z
        set fileCanOpen=1
      )

      if "!fileCanOpen!" == "0" (
        type "!filteredPath!" >nul 2>"!VAR_PATH!currenterr.var"
        if "!errorlevel!" == "0" (
          for /f %%c in ('cscript /nologo "vbs\error32.vbs" !SILENCE_ERRORS!') do if "%%c" == "6" (goto startCheck) else (exit /b 0)
        ) else (
          for /f "tokens=* delims=" %%e in ('type "!VAR_PATH!currenterr.var"') do (
            if "%%e" == "!errorInUse!" (
              for /f %%c in ('cscript /nologo "vbs\error32.vbs" !SILENCE_ERRORS!') do if "%%c" == "6" (goto startCheck) else (exit /b 0)
            ) else (
              goto midCheck
            )
          )
        )
      )
    ) else (
      dir /a:d "!filteredPath!" >nul 2>nul
      if "!errorlevel!" neq "0" goto midCheck
    )

    echo !result!
    exit /b 0

    :midCheck
    del "variables\lock.var" >nul 2>nul
    for /f %%e in ('cscript /nologo "vbs\perm_error.vbs" "!VAR_PATH!brokendir.var" !IS_ADMIN! !WILL_SUCCEED_ON_ADMIN! !SILENCE_ERRORS! !fallbackCount!') do (
      rem This will try and take ownership of the failing directory IF THE USER AGREES TO.
      rem The user will have to agree to TWO clear yes/no warning prompts.
      rem This WILL NOT DO ANYTHING if the user does not explicitly agree.

      if "%%e" == "6" (
        if "!truthPath:~-1!" == "\" (
          set "truthPath=!truthPath:~0,-1!"
        )

        takeown /f "!truthPath!" /r /d y >nul 2>nul
        icacls "!truthPath!" /grant "%USERNAME%:F" /t >nul 2>nul
        if "!errorlevel!" neq "0" (
          cacls "!truthPath!" /t /e /g "%USERNAME%:F" >nul 2>nul
        )

        set /a fallbackCount+=1
        goto startCheck
      )
    )
    echo locked> "variables\lock.var"
  )
)