:: sindexmon spent 3000 hours in visual studio 4 this
:: UPDATE 2025/06/20 - "*.flv" added to incorporate videos from Google Video
:: UPDATE 2025/06/26 - Videos are now copied into a folder to avoid clogging (shoutout CanucksFan2006 for the suggestion)
:: UPDATE 2025/09/07 - The file has been completely revamped. Now, instead of searching your whole operating system, it only searches specific directories. Hooray for maintaining drive integrity!
:: UPDATE 2025/09/12 - Integrated rough FLV header detection, along with Firefox and Opera support
:: UPDATE 2025/09/20 - Added MP4 and WebM support; THANK YOU CANUCKSFAN2006 FOR THE HELP!!!!
:: UPDATE 2025/09/24 - Added permission checks; thank you D2 for the test cases!!
:: UPDATE 2025/10/22 - Fully integrated frame-by-frame comparisons via FFmpeg and perceptual hashing
:: UPDATE 2026/04/14 - Added direct cache index reading (paired with the existing failsafes), along with history comparisons for unindexed videos

@echo off
setlocal enabledelayedexpansion

:: If running the script as admin, this corrects the directory
cd /d "%~dp0"

title Decache

if not exist "bin" (
  echo Be sure to fully extract the ZIP file before running^^!^^!^^!
  pause
  exit /b 0
)

set isAdmin=0
net session >nul 2>nul
if %errorlevel% == 0 (
  set isAdmin=1
)

set VIDEO_DATA_FILE="%~dp0\bin\video_data.txt"
set "ASSETS_PATH=%~dp0\Verified"
set "VIDEOS_PATH=%~dp0\Unverified"
set FILE_CHECKS=
set VIDEO_IDS=

set LOCAL_HIST="%~dp0\bin\history\current_indexes.txt"
set GLOBAL_HIST="%~dp0\bin\history\indexes.txt"

:: Grab the individual video IDs for direct RegEx(ish) searching in cache index/history
for /f %%a in ('type %VIDEO_DATA_FILE%') do for /f "tokens=2 delims=|" %%b in ("%%~a") do (
  set "fitRegex=%%b"
  set "fitRegex=!fitRegex:,= !"
  set "VIDEO_IDS=!VIDEO_IDS!!fitRegex! "
)

:: Fill the Internet Explorer file checks with unique names that have not been found in any other asset
for /f "tokens=* delims=" %%a in ('type "%~dp0\bin\unique_names.txt"') do (
  set FILE_CHECKS="get_video+,videoplayback+,+.flv,+.on2,+.webm,+.mp4%%a"
)

set VIDEO_IDS=%VIDEO_IDS:~0,-1%

set /a files=0
set confirmedVideos=
set likelyVideos=

set matchedHex=
set matchedReg=

set lastSaved=
set lastWebm=
set lastMp4=

set workingHash=
set fixedName=

goto main

:getFreeName
  for %%f in (%1) do (
    set "name=%%~nf"
    set "extension=%%~xf"
  )

  set /a dupeCount=0
  set "fixedName=!name!!extension!"

  :checkDupe
  if exist "%~2\!fixedName!" (
    set /a dupeCount+=1
    set "fixedName=!name! (!dupeCount!)!extension!"
    goto checkDupe
  )

  exit /b 0

:: Copies the file from the original drive to the new "videos" folder
:saveFile
  set /a files+=1
  echo If you remove this the program explodes >nul
  <nul set /p=Found file "%~n1%~x1" ... 
  
  pushd "%~dp0\bin"
  call "check_size.bat" %1
  popd

  set "ext=%~2"
  if "!ext!" == "" (
    set "ext=%~x1"
  )

  call :getFreeName "%~n1!ext!" "%VIDEOS_PATH%\"
  echo F|xcopy %1 "%VIDEOS_PATH%\!fixedName!" > nul

  <nul set /p=copied ... 
  set "lastSaved=%VIDEOS_PATH%\!fixedName!"
  echo Batch refuses to detect a label if I don't add this >nul
  exit /b 0

:grabFileHex
  for /f %%z in ('cscript /nologo "%~dp0\bin\vbs\hex.vbs" %1 %~2') do set matchedHex=%%z
  exit /b 0

:grabRegexMatch
  set matchedReg=
  for /f %%z in ('cscript /nologo "%~dp0\bin\vbs\regex.vbs" %1 %2 0') do (
    set matchedReg=%%z
    goto keepMatch
  )

  :keepMatch
  exit /b 0

:: Add videos to the end results with a level of confirmation
:printFinding
  for %%f in ("!lastSaved!") do set "fileName=%%~nxf"
  
  set "realName=%~1"
  set "realName=!realName:PLUSER=+!"
  set "realName=!realName:+= !"
  set "realName=!realName:{=(!"
  set "realName=!realName:}=)!"
  set "realName=!realName::=-!"

  if %2 == 1 (
    call :getFreeName "!realName! @ !fileName!" "%ASSETS_PATH%\"
    move "!lastSaved!" "%ASSETS_PATH%\!fixedName!" >nul
    set "lastSaved=%ASSETS_PATH%\!fixedName!"
  ) else (
    if %2 == 2 (
      call :getFreeName "!realName! @1@ !fileName!" "%VIDEOS_PATH%\"
    ) else (
      call :getFreeName "!realName! @ !fileName!" "%VIDEOS_PATH%\"
    )

    ren "!lastSaved!" "!fixedName!"
    set "lastSaved=%VIDEOS_PATH%\!fixedName!"
  )

  set "fileName=!fileName:(={!"
  set "fileName=!fileName:)=}!"

  exit /b 0

:: Heavy function to compare known frames of a video
:compareFrames
  <nul set /p=comparing frames ... 

  if exist "%~dp0\bin\frames.raw" (
    del "%~dp0\bin\frames.raw"
  )

  set "fixMultiHash=%~1"
  set "fixMultiHash=!fixMultiHash:,= !"

  "%~dp0\bin\ffmpeg.exe" -i "!lastSaved!" -vf "scale=32:32" -pix_fmt gray -f rawvideo "%~dp0\bin\frames.raw" >nul 2>nul
  for /f "tokens=1,2" %%a in ('call "%~dp0\bin\phash.exe" "%~dp0\bin\frames.raw" !fixMultiHash!') do (
    set workingHash=%%a
    exit /b 0
  )

  exit /b 0

:: Checks if a file is a valid video file, then compares it against lost video data
:checkFile
  if not exist %1 (
    exit /b 0
  )
  
  set videoFormat=
  set neededBytes=

  set hashes=
  set vidData=

  call :grabFileHex %1 17 0

  :: WebM video header
  if "!matchedHex:~0,8!" == "1A45DFA3" (
    call :saveFile %1 ".webm"
    set videoFormat=WEBM
    set neededBytes=4489..................
    set "lastWebm=!lastSaved!"
    goto endLoop
  )

  :: FLV header
  if "!matchedHex:~0,6!" == "464C56" (
    call :saveFile %1 ".flv"
    set videoFormat=FLV
    set neededBytes=6475726174696F6E..................
    goto endLoop
  )

  :: MP4 header
  if "!matchedHex:~0,6!" == "000000" (
    if "!matchedHex:~8,8!" == "66747970" (
      if "!matchedHex:~16,8!" neq "61766966" (
        call :saveFile %1 ".mp4"
        set videoFormat=MP4
        set neededBytes=6D766864........................................
        set "lastMp4=!lastSaved!"
        goto endLoop
      )
    )
  )

  :: WebM video frag header
  if "!matchedHex:~0,8!" == "1F43B675" (
    if exist "!lastWebm!" (
      copy /b "!lastWebm!" + %1 temp.bin >nul 2>nul
      move /Y temp.bin "!lastWebm!" >nul 2>nul
      cscript /nologo "%~dp0\bin\vbs\unmodify_date.vbs" "!lastWebm!" %1
    )
    set "lastSaved=!lastWebm!"
    exit /b 0
  )

  :: MP4 frag header
  if "!matchedHex:~0,8!" == "blahblahfucktemp" (
    if exist "!lastMp4!" (
      copy /b "!lastMp4!" + %1 temp.bin >nul 2>nul
      move /Y temp.bin "!lastMp4!" >nul 2>nul
      cscript /nologo "%~dp0\bin\vbs\unmodify_date.vbs" "!lastMp4!" %1
    )
    set "lastSaved=!lastMp4!"
    exit /b 0
  )

  set lastSaved=
  exit /b 0
  
  :endLoop
  set byte_set=128,256,512,1024
  if "!videoFormat!" == "WEBM" (
    :: This deep in the file is ridiculously slow to read... sorry abt that
    set byte_set=700,1024
  )

  if !hasUnknown! == 0 (
    set hasUnknown=1
    call :readHistory
  )
  
  :: Gradually increases the number of bytes to read from the file, looking for durations
  for %%i in (!byte_set!) do (
    call :grabFileHex "!lastSaved!" %%i 0
    call :grabRegexMatch "!neededBytes!" "!matchedHex!"

    if "!matchedReg!" neq "" (
      if "!videoFormat!" == "FLV" (
        set lengthData="!matchedReg:~18,16!"

        for /f %%a in ('type %VIDEO_DATA_FILE%') do for /f "tokens=1-5,8-9 delims=|" %%b in ("%%~a") do (
          if "%%e" neq "x" if !lengthData! geq "%%e" (
            if !lengthData! leq "%%f" (
              set vidData=!vidData!,"%%b|%%c|%%d|%%g|%%h"
              if "%%d" neq "0000000000000000" (
                set "hashes=!hashes! %%d"
              )
            )
          )
        )
      ) else (
        if "!videoFormat!" == "MP4" (
          set /a "timescale=0x!matchedReg:~32,8!"
          set /a "duration=0x!matchedReg:~40,8! * 10"

          set /a lengthData=!duration!/!timescale!

          for /f %%a in ('type %VIDEO_DATA_FILE%') do for /f "tokens=1-3,8-9 delims=|" %%b in ("%%~a") do (
            if "%%e" neq "x" if !lengthData! geq %%e (
              if !lengthData! leq %%f (
                set vidData=!vidData!,"%%b|%%c|%%d|%%e|%%f"
                if "%%d" neq "0000000000000000" (
                  set "hashes=!hashes! %%d"
                )
              )
            )
          )
        ) else (
          set lengthData="!matchedReg:~6,16!"

          for /f %%a in ('type %VIDEO_DATA_FILE%') do for /f "tokens=1-3,6-9 delims=|" %%b in ("%%~a") do (
            if "%%e" neq "x" if !lengthData! geq "%%e" (
              if !lengthData! leq "%%f" (
                set vidData=!vidData!,"%%b|%%c|%%d|%%g|%%h"
                if "%%d" neq "0000000000000000" (
                  set "hashes=!hashes! %%d"
                )
              )
            )
          )
        )
      )
      
      goto endComp
    )
  )

  :endComp
  if "!vidData!" neq "" (
    set workingHash=
    set vidData=!vidData:~1!
    set titles=
    set rarity=3

    if "!hashes!" neq "" (
      set "hashes=!hashes:~1!"
      call :compareFrames "!hashes!"
    )

    for %%a in (!vidData!) do for /f "tokens=1-5 delims=|" %%b in ("%%~a") do (
      if "!workingHash!" neq "" (
        echo "%%d" | findstr "!workingHash!" >nul
        if !errorlevel! == 0 (
          call :printFinding %%b 1
          goto endHashComp
        )
      ) else (
        for %%p in (%%c) do (
          set bestRating=3

          if exist "%~dp0\bin\history\temp\%%p" (
            for /f "tokens=* delims=" %%y in ('type "%~dp0\bin\history\temp\%%p"') do (
              for /f %%z in ('cscript /nologo "%~dp0\bin\vbs\date_to_unix.vbs" "%%y" "!lastSaved!"') do (
                if "%%z" lss "!bestRating!" set "bestRating=%%z"
              )
            )
          )

          if !bestRating! lss 3 (
            if "!titles!" == "" (
              set "titles=%%b"
              if !bestRating! == 1 set rarity=2
            ) else (
              set "titles=!titles!+OR+%%b"
              set rarity=3
            )
          )
        )
      )
    )

    if "!titles!" neq "" (
      call :printFinding "!titles!" !rarity!
    )
  )

  :endHashComp
  echo compared^^!
  exit /b 0

:: Takes note of history indexes
:registerHistory
  if exist %1 (
    if %2 == init (echo %1 > !LOCAL_HIST!)
    if %2 == local (echo %1 >> !LOCAL_HIST!)
    if %2 == global (echo %1 >> !GLOBAL_HIST!)
  ) else (
    if %2 == init (del !LOCAL_HIST! 2>nul)
  )

  exit /b 0

:: Reads browser history for lost video IDs
:readHistory
  <nul set /p=scanning history ... 
  pushd "%~dp0\bin\history"

  if !lastCacheScanner! == "MZCacheView" (
    for /f "tokens=* delims=" %%h in ('findstr /i /l /c:"places.sqlite" /c:"history.dat" !GLOBAL_HIST!') do (
      call scan_history.bat %%h
    )
  ) else (
    if !lastCacheScanner! == "" (
      for /f "tokens=* delims=" %%h in ('type !GLOBAL_HIST! 2^>nul') do (
        call scan_history.bat %%h
      )
    ) else (
      for /f "tokens=* delims=" %%h in ('type !LOCAL_HIST! 2^>nul') do (
        call scan_history.bat %%h
      )
    )
  )

  popd
  exit /b 0

:scanDir
  echo Scanning folder "%~dp1"
  set lastCacheScanner=%3
  set hasUnknown=0
  set currentFile=
  set /a filesChecked=0
  
  if exist %1 (
    :: TODO - check for mimetypes; make sure the merged file is UNKNOWN! will be finnicky regardless though...
    pushd "%cd%\bin\nirsoft

    for /f "tokens=* delims=" %%f in ('call read_cache.bat %1 %2 %3') do (
      set /a filesChecked+=1
      title !filesChecked! scanned

      call :checkFile %%f %2

      if "!lastSaved!" == "" (
        if "!currentFile!" neq "" (
          copy /b "!currentFile!" + %%f temp.bin >nul 2>nul
          move /Y temp.bin "!currentFile!" >nul 2>nul
          cscript /nologo "%~dp0\bin\vbs\unmodify_date.vbs" "!currentFile!" %%f
        )
      ) else (
        set "currentFile=!lastSaved!"
      )

      if %%~zf neq 1048576 (
        set currentFile=
      )
    )

    set lastSaved=
    set lastWebm=
    set lastMp4=
    popd
  )

  :: This is here because the ID files will be created once the history is scanned, and it does not have to be scanned again for FLAs
  if !hasUnknown! == 0 (
    type !LOCAL_HIST! >> !GLOBAL_HIST! 2>nul
  )

  title Decache
  cls
  exit /b 0

:scanChromium
  for /d %%c in ("%~1\Cache*") do (
    :: There are rumors of cache clones... also Opera is built off Chromium so that's why that's there
    if exist "%%c\Cache_Data" (
      call :scanDir "%%c\Cache_Data\" "opr+ f_+" "ChromeCacheView"
    ) else if "%%~nc" neq "Cache_Data" (
      call :scanDir "%%c\" "opr+ f_+" "ChromeCacheView"
    )
  )

  for /d %%c in ("%~1\Media Cache*") do (
    call :scanDir "%%c\" "opr+ f_+" "ChromeCacheView"
  )

  exit /b 0

:: Collects Chrome and Firefox, along with browsers built off them (e.g. Microsoft Edge; Waterfox).
:scanForks
  :: Chromium
  call :scanChromium %1
  for /d %%p in ("%~1\User Data\*") do (
    call :registerHistory "%%p\History" init
    call :registerHistory "%%p\Archived History" local
    call :scanChromium "%%p"
  )

  :: Firefox
  for /d %%p in ("%~1\Profiles\*") do (
    call :registerHistory "%%p\places.sqlite" global
    call :registerHistory "%%p\history.dat" global
    call :scanDir "%%p\Cache\" "+" "MZCacheView"
    call :scanDir "%%p\Cache2\" "+" "MZCacheView"
  )

  exit /b 0

:: Finds and scans browser directories
:scanBrowsers
  :: Miscellaneous
  for /d %%c in ("%~1*") do (
    call :scanForks "%%c"

    for /d %%b in ("%%c\*") do (
      call :scanForks "%%b"
    )
  )

  :: Opera TODO: WHAT DIRECTORY DOES THIS USE EXACTLY?
  :: TEST THIS WITH YOUR VM ONCE COMPLETE AND ALSO ADD HISTORY
  call :scanDir "%~1Opera\Opera\profile\" "opr+ f_+" "OperaCacheView"
  call :scanDir "%~1Opera\Opera\cache\" "opr+ f_+" "OperaCacheView"

  exit /b 0

:scanXP
  if exist "%~1\Local Settings\" (
    call :checkPermissions "%~1" "Local Settings"
    call :scanBrowsers "%~1\Local Settings\Application Data\"
    call :registerHistory "%~1\Local Settings\History\" init
    call :scanDir "%~1\Local Settings\Temporary Internet Files\" %FILE_CHECKS% "IECacheView"
    call :registerHistory "%~1\Local Settings\Temp\History\" init
    call :scanDir "%~1\Local Settings\Temp\Temporary Internet Files\" %FILE_CHECKS% "IECacheView"
    call :scanDir "%~1\Local Settings\Temp\" "fla+.tmp" ""
  )

  del !LOCAL_HIST! 2>nul
  del !GLOBAL_HIST! 2>nul
  echo Y|del "%~dp0\bin\history\temp\*" > nul

  exit /b 0

:scanVista
  if exist "%~1\AppData\" (
    call :checkPermissions "%~1" "AppData"
    call :scanBrowsers "%~1\AppData\Local\"
    call :scanBrowsers "%~1\AppData\Roaming\"
    call :scanDir "%~1\AppData\Local\Temp\" "fla+.tmp" ""
    call :scanDir "%~1\AppData\Local\Microsoft\Windows\Temporary Internet Files\" %FILE_CHECKS% "IECacheView"
  )
  
  del !LOCAL_HIST! 2>nul
  del !GLOBAL_HIST! 2>nul
  echo Y|del "%~dp0\bin\history\temp\*" > nul

  exit /b 0

:: Mainly for password-protected user folders.
:checkPermissions
  dir "%~1\%~2\" 1>nul 2>nul
  if !errorlevel! == 1 (
    if %isAdmin% == 0 (
      echo ^^!^^! You need administrative permissions to access "%~1"
      pause >nul | set /p =Please relaunch as administrator to read this directory. Otherwise, press any key to continue . . .
    ) else (
      echo ^^!^^! Unable to access directory "%~1"
      echo This can be solved by running this script from the user in question ^(not on a backup^), or manually changing the permissions of the folder to allow access.
      pause
    )
  )

  exit /b 0

:cleanseTitle
  set "title=%~1"
  set "title=!title:+= !"
  set "title=!title:PLUSER=+!"
  set "title=!title:{=(!"
  set "title=!title:}=)!"
  echo !title!

  exit /b 0

:printTitles
  if %1 == "" (
    exit /b 0
  )

  set "fixedTitles=%~1"
  set "fixedTitles=!fixedTitles: =+!"

  for %%v in (!fixedTitles!) do (
    call :cleanseTitle "%%v"
  )

  exit /b 0

:checkLikelyVideo
  if "!goodVideo!" neq "" (
    call :getFreeName "!goodVideo:@1@=@!" "%ASSETS_PATH%"
    move "%VIDEOS_PATH%\!goodVideo!" "%ASSETS_PATH%\!fixedName!"
    set goodVideo=
  )

  exit /b 0

:driveError
  cls
  echo %~1
  pause >nul | set /p =Press any key to quit . . .
  exit /b 0

:scanDrive
  set "tempDrive=%~1"
  del !LOCAL_HIST! 2>nul
  del !GLOBAL_HIST! 2>nul

  :: Selecting hard drives leaves a stray backslash; that would mess stuff up
  if "!tempDrive:~-1,1!" == "\" (
    set "tempDrive=!tempDrive:~0,-1!"
  )

  cls

  :: For pre-2000 machines
  call :scanDir "!tempDrive!\WINDOWS\Temporary Internet Files\" %FILE_CHECKS% "IECacheView"
  call :scanDir "!tempDrive!\WINDOWS\Temp\" "fla*.tmp" ""

  :: In case the backup is of one user
  call :scanVista "!tempDrive!"
  call :scanXP "!tempDrive!"

  :: In case the backup is of the users folder
  for /f "tokens=* delims=" %%d in ('dir /a:d /b "!tempDrive!"') do (
    call :scanVista "!tempDrive!\%%d"
    call :scanXP "!tempDrive!\%%d"
  )

  for /d %%x in ("!tempDrive!","!tempDrive!\Windows.old*") do (
    :: For post-XP machines
    for /f "tokens=* delims=" %%d in ('dir /a:d /b "%%~x\Users"') do (
      call :scanVista "%%~x\Users\%%d"
    )
    
    :: For pre-Vista machines
    for /f "tokens=* delims=" %%d in ('dir /a:d /b "%%~x\Documents and Settings"') do (
      call :scanXP "%%~x\Documents and Settings\%%d"
    )
  )

  exit /b 0

:main
  if not exist "%VIDEOS_PATH%\" (
    mkdir Videos
  )

  cls

  if "%~1" == "" (
    echo:
    echo   Decache
    echo   Easy cache extractor
    echo:
    echo   Support @ sindexmon.github.io/decache/
    echo:
    echo Some points to get you started:
    echo - Videos will copy into a "Videos" folder.
    echo - Verified assets will be copied into "Assets.zip".
    echo - Both of these will be automatically created in the folder you extracted Decache to.
    echo:
    pause >nul | set /p =Press any key to select a computer . . .
    echo:

    for /f "delims=" %%f in ('cscript /nologo "bin\vbs\pickfolder.vbs" "Select a computer. The computer you're currently running is almost always found as (C:), though the location of a backup varies. See the website for more information."') do set "drive=%%f"

    if "!drive!" == "" (
      call :driveError "No folder selected."
      exit /b 0
    )

    if "!drive:~0,1!" == ":" (
      echo Invalid drive selected; re-routing to "C:"...
      set "drive=C:"
    )

    call :scanDrive "!drive!"
  ) else (
    if not exist "%~1" (
      call :driveError "File or directory does not exist: %1"
      exit /b 0
    ) else (
      :: Check for if we should read from a file
      if exist "%~1\" (
        call :scanDrive "%~1"
      ) else (
        for /f "tokens=* delims=" %%a in ('type "%~1"') do (
          if "%%~a" neq "" call :scanDrive "%%~a"
        )
      )
    )
  )

  if exist "bin\frames.raw" (
    del "bin\frames.raw"
  )
  
  set lastTitle=
  set goodVideo=

  for /f "tokens=* delims=" %%f in ('dir /a:-d /b "%VIDEOS_PATH%\*"') do (
    set "videoName=%%f"
    
    for /f "tokens=1-2 delims=@" %%a in ("%%f") do (
      if "!lastTitle!" neq "%%a" (
        call :checkLikelyVideo
        if "%%b" == "1" set "goodVideo=%%f"
      ) else (
        set goodVideo=
      )

      set "lastTitle=%%a"
    )
  )

  call :checkLikelyVideo

  cls

  title Decache

  cls

  :: Exclamation cleansing handled in VBS file
  set username=
  set server=
  set sendVideos=
  for /f "tokens=* delims=" %%z in ('cscript /nologo "%~dp0\bin\vbs\askserver.vbs" "3" "%files%"') do (
    if "!username!" == "" (
      set "username=%%z"
    ) else (
      if "!server!" == "" (
        set "server=%%z"
      ) else (
        set "sendVideos=%%z"
      )
    )
  )
  
  echo "!username!" > "%ASSETS_PATH%\credit.txt"

  :: User allowed sharing of encrypted IDs
  if "!sendVideos!" == "6" (
    type "%~dp0\bin\cached_ids.txt" >> "%~dp0\Verified\cached_ids.txt"
  )
  
  del "%~dp0\bin\cached_ids.txt" >nul 2>nul

  echo Compressing data...

  pushd "%~dp0\bin"
  call "check_size.bat" "%ASSETS_PATH%\"
  popd

  "%~dp0\bin\7za.exe" a "%~dp0\Assets.zip.lock" "%ASSETS_PATH%\*" >nul 2>nul

  call :getFreeName "Assets.zip" "%~dp0"
  ren "%~dp0\Assets.zip.lock" "!fixedName!"

  cls

  if "!username!" neq "" (
    :retryConnection
    ping google.com -n 1 >nul 2>nul
    if !errorlevel! == 1 (
      for /f %%z in ('cscript /nologo "%~dp0\bin\vbs\nointernet.vbs" "3"') do if "%%z" == "1" goto retryConnection
    ) else (
      :: maybe dont retry 5 times when the size is too big
      echo Uploading files ^(this may take a while^)...

      for /f "tokens=* delims=" %%s in ('call "%~dp0\bin\curl.exe" -o nul -w "%%{http_code}" -s -k --retry 5 -F "fieldname=@%~dp0!fixedName!" https://sploded.org/php/send.php') do (
        if "%%s" neq "200" (
          :: for some reason this says cscript is not a command wtf
          for /f %%z in ('cscript /nologo "%~dp0\bin\vbs\nointernet.vbs" "3"') do if "%%z" == "1" goto retryConnection
        )
      )
    )
  )

  cls

  if %files% == 0 (
    echo %files% videos found.
  ) else (
    if %files% == 1 (
      echo %files% video found^^! It can be found in the "Videos" folder.
    ) else (
      echo %files% videos found^^! They can be found in the "Videos" folder.
    )

    echo:

    if "%confirmedVideos%" neq "" (
      echo ===============================
      echo ^^!^^! YOU HAVE SOME LOST VIDEOS ^^!^^!
      echo ===============================
    ) else (
      echo =====================================
      echo ^^!^^! YOU MIGHT HAVE SOME LOST VIDEOS ^^!^^!
      echo =====================================
    )

    call :printTitles "%confirmedVideos%"
    call :printTitles "%likelyVideos%"
    
    :skipUnconfirmed
    echo:

    echo To watch these videos, you'll have to open them using VLC Media Player.
    echo For more context, see this tutorial: https://youtu.be/oVrzYFEoNB4
    echo:
    echo If you already have VLC installed, the videos will open automatically.
  )

  ::set /p watchVideo=Open tutorial in default browser? (YES\NO) 
  ::if %watchVideo:~0,1% == "y" or %watchVideo:~0,1% == "Y" (
  ::  start "" "https://youtu.be/oVrzYFEoNB4"
  ::)

  pause >nul | set /p =Press any key to continue . . .

  set vlcPath=
  if exist "C:\Program Files\VideoLAN\VLC\vlc.exe" (
    set "vlcPath=C:\Program Files\VideoLAN\VLC\vlc.exe"
  ) else (
    if exist "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe" set "vlcPath=C:\Program Files (x86)\VideoLAN\VLC\vlc.exe"
  )

  if "%vlcPath%" neq "" (
    for %%v in ("%VIDEOS_PATH%\*") do (
      start "" "%vlcPath%" "%%v" --one-instance --playlist-enqueue --no-playlist-autostart
    )
  ) else (
    explorer "%VIDEOS_PATH%\"
  )