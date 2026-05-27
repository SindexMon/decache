@echo off
setlocal enabledelayedexpansion

set "VAR_PATH=..\variables\"
set CACHE_LIST=history.txt
set /p HISTORY_BIT=<"!VAR_PATH!historybit.var"
set videoId=
set historyApp=

if not exist "!HISTORY_BIT!" exit /b 0

for %%d in ("!HISTORY_BIT!") do (
  if "%%~nxd" == "History" set historyApp=ChromeHistoryView
  if "%%~nxd" == "Archived History" set historyApp=ChromeHistoryView
  if "%%~nxd" == "history.dat" set historyApp=MozillaHistoryView
  if "%%~nxd" == "places.sqlite" set historyApp=BrowsingHistoryView
  if "!historyApp!" == "" set historyApp=BrowsingHistoryView

  :: Copying history to avoid modifying it permanently
  if exist "!HISTORY_BIT!\" (
    set usingOrig=1
    set newFileName="!HISTORY_BIT!"
  ) else (
    set usingOrig=0
    echo !HISTORY_BIT!> "!VAR_PATH!sizecheck.var"
    pushd ".."
    call "check_size.bat"
    popd

    :retryThaCopy
    copy "!HISTORY_BIT!" ".\" >nul 2>nul
    set newFileName="%%~nxd"

    if not exist "!newFileName!" (
      set success=0
      echo !HISTORY_BIT!> "..\variables\brokendir.var"

      pushd ".."
      for /f %%x in ('call perm_error.bat %1 %2') do set success=1
      popd

      if "!success!" == "1" (
        goto retryThaCopy
      ) else (
        exit /b 0
      )
    )
  )
)

:: Fix UTF-8 encoding by typing to new file
start /wait "" "!historyApp!.exe" /HistorySource 6 /CustomFiles.IEFolders !newFileName! /CustomFiles.FirefoxFiles !newFileName! /stext sploder_null.txt -folder !newFileName! -file !newFileName! /UseHistoryFile 1 /HistoryFile !newFileName!

:: If it's missing, that likely means MozillaHistoryView crashed
if not exist sploder_null.txt exit /b 0
type sploder_null.txt > !CACHE_LIST!
del sploder_null.txt

if "!usingOrig!" == "0" del !newFileName!

for /f "tokens=* delims=" %%l in ('findstr /i /l /g:"..\data\history_data.txt" !CACHE_LIST!') do (
  set "entry=%%l"
  set name=!entry:~0,19!
  set value=!entry:~20!

  if "!name!" == "URL               :" (
    for /f %%z in ('cscript /nologo "..\vbs\regex.vbs" "\?v=(.{11})" "!value!" 0') do (
      set "videoId=%%z"
    )
  ) else (
    if "!videoId!" neq "" if "!value!" neq "" if "!value!" neq "N / A" (
      echo !value! >> "temp\!videoId!"
    )

    if "!name!" neq "First Visit Date  :" (
      set videoId=
    )
  )
)

del !CACHE_LIST!