@rem This program only works on Windows XP and up
cls
@echo off
ver | "%SYSTEMROOT%\System32\find" " 4." > nul
if not errorlevel 1 (
  echo:
  echo   Decache
  echo   Easy cache extractor
  echo:
  echo   Support @ sindexmon.github.io/decache/
  echo:
  echo It appears that you're using a computer from the 90s. Decache is not compatible with your operating system.
  echo Some tips to get you started:
  echo - Try backing up the computer to a USB, or cloning the hard drive entirely.
  echo - Run this program on said backup using a computer that runs Windows XP or higher.
  echo - If this computer is still running on its original hard drive, it probably won't work for much longer.
  echo:
  pause
  exit
)

ver | "%SYSTEMROOT%\System32\find" " 5.0" > nul
if not errorlevel 1 (
  echo:
  echo   Decache
  echo   Easy cache extractor
  echo:
  echo   Support @ sindexmon.github.io/decache/
  echo:
  echo It appears that you're using Windows 2000. Decache is not compatible with your operating system.
  echo Some tips to get you started:
  echo - Try backing up the computer to a USB, or cloning the hard drive entirely.
  echo - Run this program on said backup using a computer that runs Windows XP or higher.
  echo - If this computer is still running on its original hard drive, it probably won't work for much longer.
  echo:
  pause
  exit
)

findstr >nul 2>nul
if %errorlevel% == 9009 (
  echo Decache is unable to run because your computer is missing 'findstr.exe'. This might be because you're doing some awesome work-around for your broken PC and are running it from the terminal in recovery mode. If so, hell yeah!
  echo:
  echo If you experience this error, please report it.
  echo:
  pause
  exit /b 0
)

:: sindexmon spent 3000 hours in visual studio 4 this
:: UPDATE 2025/06/20 - "*.flv" added to incorporate videos from Google Video
:: UPDATE 2025/06/26 - Videos are now copied into a folder to avoid clogging (shoutout CanucksFan2006 for the suggestion)
:: UPDATE 2025/09/07 - The file has been completely revamped. Now, instead of searching your whole operating system, it only searches specific directories. Hooray for maintaining drive integrity!
:: UPDATE 2025/09/12 - Integrated rough FLV header detection, along with Firefox and Opera support
:: UPDATE 2025/09/20 - Added MP4 and WebM support; THANK YOU CANUCKSFAN2006 FOR THE HELP!!!!
:: UPDATE 2025/09/24 - Added permission checks; thank you D2 for the test cases!!
:: UPDATE 2025/10/22 - Fully integrated frame-by-frame comparisons via FFmpeg and perceptual hashing
:: UPDATE 2026/04/14 - Added direct cache index reading (paired with the existing failsafes), along with history comparisons for unindexed videos
:: UPDATE 2026/04/28 - This code has become unintelligible due to Batch's demonic parsing system. half the variables are now being managed in the form of files, oh lord

:: If running the script as admin, this corrects the directory
cd /d "%~dp0" 2>nul

title Decache

set isAdmin=0
net session >nul 2>nul
if %errorlevel% == 0 (
  set isAdmin=1
  if not exist "%~dp0" (
    echo Decache is unable to run as administrator. This is because of issues regarding a folder preceding it.
    echo:
    echo Look for any folder with a percentage sign in the name ^(e.g. %%1, %%errorlevel%%^), or anything wrapped up in exclamation marks ^(e.g. ^^!errorlevel^^!^). Try changing these names, and try again.
    echo:
    pause
    exit /b 0
  )
)

:: Enabling here to avoid issues with current directory
setlocal enabledelayedexpansion

if not exist "bin" (
  echo Be sure to fully extract the ZIP file before running^^!^^!^^!
  pause
  exit /b 0
)

set SILENCE_ERRORS=0
set KEEP_ALL=0
set driveArg=

for %%x in (%*) do (
  set "newArg=%%x"
  if "!newArg!" == "/keepall" (
    set KEEP_ALL=1
  )

  if "!newArg:~0,8!" == "/silence" (
    if "!newArg:~9,1!" neq "" if "!newArg:~9,1!" lss "3" set SILENCE_ERRORS=!newArg:~9,1!

    if "!SILENCE_ERRORS!" == "0" if "!newArg:~9,1!" neq "0" (
      echo Invalid silence type "!newArg:~9,1!"
      pause
      exit /b 0
    )
  )
  
  if exist "%%~x" (
    set "driveArg=%%~x"
  )
)

set "BASE=."
set FILE_CHECKS=
set VIDEO_IDS=

set "LOCAL_HIST=\bin\history\current_indexes.txt"
set "GLOBAL_HIST=\bin\history\indexes.txt"

:: Grab the individual video IDs for direct RegEx(ish) searching in cache index/history
for /f %%a in ('type "!BASE!\bin\data\video_data.txt"') do for /f "tokens=2 delims=|" %%b in ("%%~a") do (
  set "fitRegex=%%b"
  set "fitRegex=!fitRegex:,= !"
  set "VIDEO_IDS=!VIDEO_IDS!!fitRegex! "
)

:: Fill the Internet Explorer file checks with unique names that have not been found in any other asset
for /f "tokens=* delims=" %%a in ('type "!BASE!\bin\data\unique_names.txt"') do (
  set FILE_CHECKS="get_video+,videoplayback+,+.flv,+.on2,+.webm,+.mp4%%a"
)

set VIDEO_IDS=%VIDEO_IDS:~0,-1%

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
  echo !getFreeName1!> "!BASE!\bin\variables\exstorage.var"
  for /f "tokens=* delims=" %%c in ('cscript /nologo "!BASE!\bin\vbs\cleanse_ex.vbs" "!BASE!\bin\variables\exstorage.var" "0"') do set "newGetFreeName1=%%c"
  for %%f in ("!newGetFreeName1!") do (
    set "name=%%~nf"
    set "extension=%%~xf"
  )

  set /a dupeCount=0
  set "fixedName=!name!!extension!"

  :checkDupe
  if exist "%~1\!fixedName!" (
    set /a dupeCount+=1
    set "fixedName=!name! (!dupeCount!)!extension!"
    goto checkDupe
  )

  exit /b 0

:: Copies the file from the original drive to the new "videos" folder
:saveFile
  echo !checkFile1!> "!BASE!\bin\variables\exstorage.var"
  for /f "tokens=* delims=" %%c in ('cscript /nologo "!BASE!\bin\vbs\cleanse_ex.vbs" "!BASE!\bin\variables\exstorage.var" "0"') do set "newCheckFile1=%%c"
  for %%f in ("!newCheckFile1!") do (
    echo !checkFile1!> "!BASE!\bin\variables\sizecheck.var"
    pushd "..\"
    call "check_size.bat"
    popd

    set "ext=%~1"
    if "!ext!" == "" (
      set "ext=%%~xf"
    )
    
    set "getFreeName1=%%~nf!ext!"
    call :getFreeName "!BASE!\Unverified\"
    echo F|xcopy "!checkFile1!" "!BASE!\Unverified\!fixedName!" > nul

    set "lastSaved=!BASE!\Unverified\!fixedName!"
    echo Batch refuses to detect a label if I don't add this >nul
  )

  exit /b 0

:grabRegexMatch
  set matchedReg=
  for /f %%z in ('cscript /nologo "!BASE!\bin\vbs\regex.vbs" %1 %2 0') do (
    set matchedReg=%%z
    goto keepMatch
  )

  :keepMatch
  exit /b 0

:: Add videos to the end results with a level of confirmation
:printFinding
  echo !lastSaved!> "!BASE!\bin\variables\exstorage.var"
  for /f "tokens=* delims=" %%c in ('cscript /nologo "!BASE!\bin\vbs\cleanse_ex.vbs" "!BASE!\bin\variables\exstorage.var" "0"') do set "newLastSaved=%%c"
  for %%f in ("!newLastSaved!") do set "fileName=%%~nxf"
  
  set "realName=%~1"
  set "realName=!realName:PLUSER=+!"
  set "realName=!realName:+= !"
  set "realName=!realName:{=(!"
  set "realName=!realName:}=)!"
  set "realName=!realName::=-!"

  if %2 == 1 (
    set "getFreeName1=!realName! @ !fileName!"
    call :getFreeName "!BASE!\Verified\"
    move "!lastSaved!" "!BASE!\Verified\!fixedName!" >nul
    set "lastSaved=!BASE!\Verified\!fixedName!"
  ) else (
    if %2 == 2 (
      set "getFreeName1=!realName! @1@ !fileName!"
      call :getFreeName "!BASE!\Unverified\"
    ) else (
      set "getFreeName1=!realName! @ !fileName!"
      call :getFreeName "!BASE!\Unverified\"
    )

    ren "!lastSaved!" "!fixedName!"
    set "lastSaved=!BASE!\Unverified\!fixedName!"
  )

  set "fileName=!fileName:(={!"
  set "fileName=!fileName:)=}!"

  echo !lastSaved!> "..\variables\unmodify1.var"
  for /f "tokens=* delims=" %%c in ('cscript /nologo "!BASE!\bin\vbs\unmodify_date.vbs" "..\variables\unmodify1.var" "" "0"') do (
    set "exteriorDateNuts=%%c"
    echo "clockman">> "!lastSaved!"

    if "!fixedName:~-1!" == "v" (
      set /a strLen=0
      for /l %%i in (0, 1, 100) do (
        if "!fixedName:~%%i!" == "" (
          goto ending
        ) else (
          set /a strLen+=1
        )
      )

      :ending
      echo !strlen!>> "!lastSaved!"
    ) else (
      echo cracks>> "!lastSaved!"
    )

    echo !lastSaved!> "..\variables\unmodify1.var"
    cscript /nologo "!BASE!\bin\vbs\unmodify_date.vbs" "..\variables\unmodify1.var" "!exteriorDateNuts!" "1"
  )

  exit /b 0

:: Heavy function to compare known frames of a video
:compareFrames
  <nul set /p=comparing frames ... 

  if exist "..\frames.raw" (
    del "..\frames.raw"
  )

  set "fixMultiHash=%~1"
  set "fixMultiHash=!fixMultiHash:,= !"

  "..\ffmpeg.exe" -i "!lastSaved!" -vf "scale=32:32" -pix_fmt gray -f rawvideo "..\frames.raw" >nul 2>nul
  for /f "tokens=1,2" %%a in ('call "..\phash.exe" "..\frames.raw" !fixMultiHash!') do (
    set workingHash=%%a
    exit /b 0
  )

  exit /b 0

:: Verify if a video is lost
:verifyVideo
  if "!lastSaved!" == "" exit /b 0
  
  set hashes=
  set vidData=

  echo !lastSaved!> "!BASE!\bin\variables\exstorage.var"
  for /f "tokens=* delims=" %%c in ('cscript /nologo "!BASE!\bin\vbs\cleanse_ex.vbs" "!BASE!\bin\variables\exstorage.var" "0"') do set "newLastSaved=%%c"
  for %%f in ("!newLastSaved!") do (
    echo If you remove this the program explodes >nul
    <nul set /p=Found file "%%~nf%%~xf" ... 
  )

  if !hasUnknown! == 0 (
    set hasUnknown=1
    call :readHistory
  )
  
  "..\ffmpeg.exe" -i "!lastSaved!" 2>&1 | findstr /c:"Duration: 0" > "!BASE!\bin\variables\ffmpeg_output.var"
  for /f "tokens=2 delims= " %%l in ('type "!BASE!\bin\variables\ffmpeg_output.var"') do (
    set "videoLength=%%l"
    set "videoLength=!videoLength:~0,-1!"

    for /f %%a in ('type "!BASE!\bin\data\video_data.txt"') do for /f "tokens=1-5 delims=|" %%b in ("%%~a") do (
      if "%%e" neq "x" if "!videoLength!" geq "%%e" if "!videoLength!" leq "%%f" (
        set vidData=!vidData!,"%%b|%%c|%%d"
        if "%%d" neq "0000000000000000" (
          set "hashes=!hashes! %%d"
        )
      )
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

    for %%a in (!vidData!) do for /f "tokens=1-3 delims=|" %%b in ("%%~a") do (
      if "!workingHash!" neq "" (
        echo "%%d" | findstr "!workingHash!" >nul
        if !errorlevel! == 0 (
          call :printFinding %%b 1
          goto endHashComp
        )
      ) else (
        for %%p in (%%c) do (
          set bestRating=3

          if exist "..\history\temp\%%p" (
            for /f "tokens=* delims=" %%y in ('type "..\history\temp\%%p"') do (
              echo !lastSaved!> "..\variables\unmodify1.var"
              for /f %%z in ('cscript /nologo "!BASE!\bin\vbs\date_to_unix.vbs" "%%y" "..\variables\unmodify1.var"') do (
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
    ) else if "!KEEP_ALL!" == "0" (
      del "!lastSaved!"
    ) else (
      set "getFreeName1=!lastSaved!"
      call :getFreeName "!BASE!\Dump"
      move "!lastSaved!" "!BASE!\Dump\!fixedName!" >nul 2>nul
    )
  ) else if "!KEEP_ALL!" == "0" (
    del "!lastSaved!"
  ) else (
    set "getFreeName1=!lastSaved!"
    call :getFreeName "!BASE!\Dump"
    move "!lastSaved!" "!BASE!\Dump\!fixedName!" >nul 2>nul
  )

  :endHashComp
  echo compared^^!
  exit /b 0

:: Checks if a file is a valid video file, then compares it against lost video data
:checkFile
  if not exist "!checkFile1!" (
    exit /b 0
  )

  set success=0
  echo !checkFile1!> "!BASE!\bin\variables\brokendir.var"

  pushd "!BASE!\bin\"
  for /f %%x in ('call perm_error.bat !isAdmin! !SILENCE_ERRORS!') do (
    set success=1
    set "matchedHex=%%x"
  )
  popd

  if "!success!" == "0" goto skipFragCheck

  :: WebM video header
  if "!matchedHex:~0,8!" == "1A45DFA3" (
    if "!lastWebm!" neq "" (
      set "lastSaved=!lastWebm!"
      call :verifyVideo
    )

    call :saveFile ".webm"
    set "lastWebm=!lastSaved!"
    exit /b 0
  )

  :: FLV header
  if "!matchedHex:~0,6!" == "464C56" (
    call :saveFile ".flv"
    exit /b 0
  )

  :: MP4 header
  if "!matchedHex:~0,6!" == "000000" (
    if "!matchedHex:~8,8!" == "66747970" (
      if "!matchedHex:~16,8!" neq "61766966" (
        if "!lastMp4!" neq "" (
          set "lastSaved=!lastMp4!"
          call :verifyVideo
        )

        call :saveFile ".mp4"
        set "lastMp4=!lastSaved!"
        exit /b 0
      )
    )
  )

  :: WebM video frag header
  if "!matchedHex:~0,8!" == "1F43B675" (
    if exist "!lastWebm!" (
      copy /b "!lastWebm!" + "!checkFile1!" temp.bin >nul 2>nul
      move /Y temp.bin "!lastWebm!" >nul 2>nul
      
      echo !lastWebm!> "..\variables\unmodify1.var"
      echo !checkFile1!> "..\variables\unmodify2.var"
      cscript /nologo "!BASE!\bin\vbs\unmodify_date.vbs" "..\variables\unmodify1.var" "..\variables\unmodify2.var" "0"
    )
    set "lastSaved=!lastWebm!"
    exit /b 0
  )

  :: MP4 frag header
  if "!matchedHex:~8,8!" == "6D6F6F66" goto mp4FragCheck
  if "!matchedHex:~8,8!" == "73747970" goto mp4FragCheck
  goto skipFragCheck

  :mp4FragCheck
  if exist "!lastMp4!" (
    copy /b "!lastMp4!" + "!checkFile1!" temp.bin >nul 2>nul
    move /Y temp.bin "!lastMp4!" >nul 2>nul

    echo !lastMp4!> "..\variables\unmodify1.var"
    echo !checkFile1!> "..\variables\unmodify2.var"
    cscript /nologo "!BASE!\bin\vbs\unmodify_date.vbs" "..\variables\unmodify1.var" "..\variables\unmodify2.var" "0"
  )
  set "lastSaved=!lastMp4!"
  exit /b 0

  :skipFragCheck
  set lastSaved=
  exit /b 0

:: Takes note of history indexes
:registerHistory
  if exist "!registerHistory1!" (
    :: Fixes exclamation marks cuz delayed expansion causes them to disappear
    echo !registerHistory1!> "!BASE!\bin\variables\exstorage.var"
    for /f "tokens=* delims=" %%c in ('cscript /nologo "!BASE!\bin\vbs\cleanse_ex.vbs" "!BASE!\bin\variables\exstorage.var" "0"') do set "newRegisterHistory1=%%c"

    if %1 == init (echo !newRegisterHistory1!> "!BASE!!LOCAL_HIST!")
    if %1 == local (echo !newRegisterHistory1!>> "!BASE!!LOCAL_HIST!")
    if %1 == global (echo !newRegisterHistory1!>> "!BASE!!GLOBAL_HIST!")
  ) else (
    if %1 == init (del "!BASE!!LOCAL_HIST!" 2>nul)
  )

  exit /b 0

:: Reads browser history for lost video IDs
:readHistory
  <nul set /p=scanning history ... 
  pushd "..\history"

  if !lastCacheScanner! == "MZCacheView" (
    for /f "tokens=* delims=" %%h in ('findstr /i /l /c:"places.sqlite" /c:"history.dat" "!BASE!!GLOBAL_HIST!"') do (
      echo %%h> "!BASE!\bin\variables\historybit.var"
      call scan_history.bat !isAdmin! !SILENCE_ERRORS!
    )
  ) else (
    if !lastCacheScanner! == "" (
      for /f "tokens=* delims=" %%h in ('type "!BASE!!GLOBAL_HIST!" 2^>nul') do (
        echo %%h> "!BASE!\bin\variables\historybit.var"
        call scan_history.bat !isAdmin! !SILENCE_ERRORS!
      )
    ) else (
      for /f "tokens=* delims=" %%h in ('type "!BASE!!LOCAL_HIST!" 2^>nul') do (
        echo %%h> "!BASE!\bin\variables\historybit.var"
        call scan_history.bat !isAdmin! !SILENCE_ERRORS!
      )
    )
  )

  popd
  exit /b 0

:scanDir
  set lastCacheScanner=%2
  set hasUnknown=0
  set currentFile=
  set /a filesChecked=0
  
  if exist "!scanDir1!" (
    cls
    echo Scanning folder "!scanDir1!"
    
    pushd "nirsoft"
    set "BASE=..\.."

    echo !scanDir1!> "!BASE!\bin\variables\cachefolder.var"
    for /f "tokens=* delims=" %%f in ('call read_cache.bat %1 %2 !isAdmin! !SILENCE_ERRORS!') do (
      set /a filesChecked+=1
      title !filesChecked! scanned

      set "checkFile1=%%f"
      call :checkFile

      if "!lastSaved!" == "" (
        if "!currentFile!" neq "" (
          copy /b "!currentFile!" + "%%f" temp.bin >nul 2>nul
          move /Y temp.bin "!currentFile!" >nul 2>nul

          echo !currentFile!> "..\variables\unmodify1.var"
          echo %%f> "..\variables\unmodify2.var"
          cscript /nologo "!BASE!\bin\vbs\unmodify_date.vbs" "..\variables\unmodify1.var" "..\variables\unmodify2.var" "0"
        )
      ) else (
        set "currentFile=!lastSaved!"
      )

      :: Avoid cleansing issues preventing Windows from printing size
      for %%g in ("%%f") do if %%~zg neq 1048576 (
        if "!currentFile!" neq "" if "!currentFile!" neq "!lastWebm!" if "!currentFile!" neq "!lastMp4!" (
          set "lastSaved=!currentFile!"
          call :verifyVideo
        )

        set currentFile=
      ) else (
        if "!currentFile!" == "!lastWebm!" set lastWebm=
        if "!currentFile!" == "!lastMp4!" set lastMp4=
      )
    )

    if "!currentFile!" neq "" (
      set "lastSaved=!currentFile!"
      call :verifyVideo
    )

    if "!lastMp4!" neq "" (
      set "lastSaved=!lastMp4!"
      call :verifyVideo
    )

    if "!lastWebm!" neq "" (
      set "lastSaved=!lastWebm!"
      call :verifyVideo
    )

    set lastSaved=
    set lastWebm=
    set lastMp4=
    popd
    set "BASE=.."
  )

  :: This is here because the ID files will be created once the history is scanned, and it does not have to be scanned again for FLAs
  if !hasUnknown! == 0 (
    type "!BASE!!LOCAL_HIST!" >> "!BASE!!GLOBAL_HIST!" 2>nul
  )

  title Decache
  exit /b 0

:massPermissionScan
  echo !massPermissionScan1!> "!BASE!\bin\variables\recursive.var"
  for /f "tokens=* delims=" %%p in ('cscript /nologo "!BASE!\bin\vbs\recursive_dir.vbs" "!BASE!\bin\variables\recursive.var" 0 ""') do (
    echo %%p> "!BASE!\bin\variables\brokendir.var"
    for /f %%x in ('call perm_error.bat !isAdmin! !SILENCE_ERRORS!') do echo ok >nul
  )

  exit /b 0

:: Finds and scans browser directories
:scanBrowsers
  if not exist "!scanBrowsers1!" exit /b 0
  
  cls & echo Searching for cache under "!scanBrowsers1!" ...
  echo !scanBrowsers1!> "!BASE!\bin\variables\recursive.var"

  :: Chromium
  for /f "tokens=* delims=" %%c in ('cscript /nologo "!BASE!\bin\vbs\recursive_dir.vbs" "!BASE!\bin\variables\recursive.var" 1 "data_1"') do (
    set "scanDir1=%%c"

    if "!scanDir1:~-11!" == "Cache_Data\" (
      set "registerHistory1=!scanDir1!..\..\History"
      call :registerHistory init

      set "registerHistory1=!scanDir1!..\..\Archived History"
      call :registerHistory local
    ) else (
      set "registerHistory1=!scanDir1!..\History"
      call :registerHistory init

      set "registerHistory1=!scanDir1!..\Archived History"
      call :registerHistory local
    )

    call :scanDir "opr+ f_+" "ChromeCacheView"
  )

  :: Firefox
  for /f "tokens=* delims=" %%c in ('cscript /nologo "!BASE!\bin\vbs\recursive_dir.vbs" "!BASE!\bin\variables\recursive.var" 0 "Profiles"') do (
    dir /a:d /b "%%cProfiles\" > "!BASE!\bin\variables\tempdir.var" 2>nul
    for /f "tokens=* delims=" %%p in ('cscript /nologo "!BASE!\bin\vbs\fixdir.vbs" "!BASE!\bin\variables\tempdir.var"') do (
      set "registerHistory1=%%cProfiles\%%p\places.sqlite"
      call :registerHistory global

      set "registerHistory1=%%cProfiles\%%p\history.dat"
      call :registerHistory global

      set "scanDir1=%%cProfiles\%%p\Cache\"
      call :scanDir "+" "MZCacheView"

      set "scanDir1=%%cProfiles\%%p\Cache2\"
      call :scanDir "+" "MZCacheView"
    )
  )

  :: Opera; Nir Sofer never made anything with support for pre-Chromium Opera history because he was bored that day. He is also the only guy in the universe who makes that software. So no Opera history checks.
  for /f "tokens=* delims=" %%c in ('cscript /nologo "!BASE!\bin\vbs\recursive_dir.vbs" "!BASE!\bin\variables\recursive.var" 1 "dcache4.url"') do (
    set "operaPath=%%c"
    set "scanDir1=!operaPath:~0,-11!"

    call :scanDir "opr+" "OperaCacheView"
  )

  cls
  exit /b 0

echo FUCK FUCK FUCKKKKKK FUCKKKKK 

:scanXP
  echo !scannedPC!\Local Settings\> "!BASE!\bin\variables\checkdir.var"
  echo !scannedPC!\> "!BASE!\bin\variables\brokendir.var"
  for /f %%e in ('call check_dir_exists.bat') do for /f %%t in ('call perm_error.bat !isAdmin! !SILENCE_ERRORS!') do (
    cls & echo Searching for cache under "!scannedPC!\Application Data\" ...

    if exist "!scannedPC!\Application Data\" (
      set "massPermissionScan1=!scannedPC!\Application Data\"
      call :massPermissionScan

      set "scanBrowsers1=!scannedPC!\Application Data\"
      call :scanBrowsers
    )

    cls & echo Searching for cache under "!scannedPC!\Local Settings\" ...

    set "massPermissionScan1=!scannedPC!\Local Settings\"
    call :massPermissionScan

    set "scanBrowsers1=!scannedPC!\Local Settings\Application Data\"
    call :scanBrowsers

    set "registerHistory1=!scannedPC!\Local Settings\History\"
    call :registerHistory init

    set "scanDir1=!scannedPC!\Local Settings\Temporary Internet Files\"
    call :scanDir %FILE_CHECKS% "IECacheView"

    set "registerHistory1=!scannedPC!\Local Settings\Temp\History\"
    call :registerHistory init

    set "scanDir1=!scannedPC!\Local Settings\Temp\Temporary Internet Files\"
    call :scanDir %FILE_CHECKS% "IECacheView"

    set "scanDir1=!scannedPC!\Local Settings\Temp\"
    call :scanDir "fla+.tmp" ""
  )

  del "!BASE!!LOCAL_HIST!" 2>nul
  del "!BASE!!GLOBAL_HIST!" 2>nul
  echo Y|del "history\temp\*" > nul

  exit /b 0

echo oops there's some parsing issue!!!

:scanVista
  echo !scannedPC!\AppData\> "!BASE!\bin\variables\checkdir.var"
  echo !scannedPC!\> "!BASE!\bin\variables\brokendir.var"
  for /f %%e in ('call check_dir_exists.bat') do for /f %%t in ('call perm_error.bat !isAdmin! !SILENCE_ERRORS!') do (
    cls & echo Searching for cache under "!scannedPC!\AppData\" ...

    :: Permission scans
    set "massPermissionScan1=!scannedPC!\AppData\"
    call :massPermissionScan
    
    :: Cache scans (Roaming first because of Firefox history)
    set "scanBrowsers1=!scannedPC!\AppData\Roaming\"
    call :scanBrowsers

    set "scanBrowsers1=!scannedPC!\AppData\LocalLow\"
    call :scanBrowsers
    
    set "scanBrowsers1=!scannedPC!\AppData\Local\"
    call :scanBrowsers

    set "registerHistory1=!scannedPC!\AppData\Local\Microsoft\Windows\History\"
    call :registerHistory init
    
    set "scanDir1=!scannedPC!\AppData\Local\Microsoft\Windows\Temporary Internet Files\"
    call :scanDir %FILE_CHECKS% "IECacheView"

    set "scanDir1=!scannedPC!\AppData\Local\Temp\"
    call :scanDir "fla+.tmp" ""
  )
  
  del "!BASE!!LOCAL_HIST!" 2>nul
  del "!BASE!!GLOBAL_HIST!" 2>nul
  echo Y|del "history\temp\*" > nul

  exit /b 0

echo oops there's some parsing issue!!

:scanRoot
  echo !scanRoot1!\> "!BASE!\bin\variables\brokendir.var"
  for /f %%t in ('call perm_error.bat !isAdmin! !SILENCE_ERRORS!') do (
    :: For post-XP machines
    echo !scanRoot1!\Users\> "!BASE!\bin\variables\brokendir.var"
    for /f %%t in ('call perm_error.bat !isAdmin! !SILENCE_ERRORS!') do (
      dir /a:d /b "!scanRoot1!\Users\" > "!BASE!\bin\variables\tempdir.var" 2>nul
      for /f "tokens=* delims=" %%d in ('cscript /nologo "!BASE!\bin\vbs\fixdir.vbs" "!BASE!\bin\variables\tempdir.var"') do (
        set "scannedPC=!scanRoot1!\Users\%%d"
        call :scanVista
      )
    )

    :: For pre-Vista machines
    echo !scanRoot1!\Documents and Settings\> "!BASE!\bin\variables\brokendir.var"
    for /f %%t in ('call perm_error.bat !isAdmin! !SILENCE_ERRORS!') do (
      dir /a:d /b "!scanRoot1!\Documents and Settings\" > "!BASE!\bin\variables\tempdir.var" 2>nul
      for /f "tokens=* delims=" %%d in ('cscript /nologo "!BASE!\bin\vbs\fixdir.vbs" "!BASE!\bin\variables\tempdir.var"') do (
        set "scannedPC=!scanRoot1!\Documents and Settings\%%d"
        call :scanXP
      )
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
    set "getFreeName1=!goodVideo:@1@=@!"
    call :getFreeName "!BASE!\Verified"
    move "!BASE!\Unverified\!goodVideo!" "!BASE!\Verified\!fixedName!" >nul 2>nul
    set goodVideo=
  )

  exit /b 0

:driveError
  cls
  echo !driveError1!
  if "%SILENCE_ERRORS%" == "0" (
    pause >nul | set /p =Press any key to quit . . .
    echo:
  )
  exit /b 0

:scanDrive
  if "!KEEP_ALL!" == "1" if not exist "!BASE!\Dump\" mkdir "!BASE!\Dump"
  if exist "bin\variables\lock.var" (
    for /f %%e in ('cscript /nologo "bin\vbs\multitask.vbs"') do (
      if "%%e" == "7" exit
    )
  ) else (
    echo locked>"bin\variables\lock.var"
  )

  del "!BASE!!LOCAL_HIST!" 2>nul
  del "!BASE!!GLOBAL_HIST!" 2>nul

  :: Selecting hard drives leaves a stray backslash; that would mess stuff up
  if "!tempDrive:~-1,1!" == "\" (
    set "tempDrive=!tempDrive:~0,-1!"
  )

  cls
  pushd "bin\"
  set "BASE=.."

  :: For pre-2000 machines
  set "scanDir1=!tempDrive!\WINDOWS\Temporary Internet Files\"
  call :scanDir %FILE_CHECKS% "IECacheView"
  set "scanDir1=!tempDrive!\WINDOWS\Temp\"
  call :scanDir "fla*.tmp" ""

  :: In case the backup is of one user
  set "scannedPC=!tempDrive!"
  call :scanVista
  call :scanXP

  :: In case the backup is of the users folder
  dir /a:d /b "!tempDrive!\" > "!BASE!\bin\variables\tempdir.var" 2>nul
  for /f "tokens=* delims=" %%d in ('cscript /nologo "!BASE!\bin\vbs\fixdir.vbs" "!BASE!\bin\variables\tempdir.var"') do (
    set "scannedPC=!tempDrive!\%%d"
    call :scanVista
    call :scanXP
  )
  
  set "scanRoot1=!tempDrive!"
  call :scanRoot

  dir /a:d /b "!tempDrive!\Windows.old*" > "!BASE!\bin\variables\tempdir.var" 2>nul
  for /f "tokens=* delims=" %%x in ('cscript /nologo "!BASE!\bin\vbs\fixdir.vbs" "!BASE!\bin\variables\tempdir.var"') do (
    set "scanRoot1=!tempDrive!\%%~x"
    call :scanRoot
  )

  popd
  set "BASE=."
  exit /b 0

:main
  if not exist "!BASE!\Verified\" mkdir "!BASE!\Verified"
  if not exist "!BASE!\Unverified\" mkdir "!BASE!\Unverified"

  cls

  if "!driveArg!" == "" (
    echo:
    echo   Decache
    echo   Easy cache extractor
    echo:
    echo   Support @ sindexmon.github.io/decache/
    echo:
    echo Some points to get you started:
    echo - Verified assets will be copied into "Assets.zip".
    echo - Unverified assets require manual verification.
    echo:
    pause >nul | set /p =Press any key to select a computer . . .
    echo:

    for /f "delims=" %%f in ('cscript /nologo "bin\vbs\pickfolder.vbs" "Select a computer. The computer you're currently running is almost always found as (C:), though the location of a backup varies. See the website for more information."') do set "drive=%%f"

    if "!drive!" == "" (
      set "driveError1=No folder selected."
      call :driveError
      exit /b 0
    )

    if "!drive:~0,1!" == ":" (
      echo Invalid drive selected; re-routing to "C:"...
      set "drive=C:"
    )

    set "tempDrive=!drive!"
    for /f %%a in ('cscript /nologo "bin\vbs\keepall.vbs"') do if "%%a" == "6" set KEEP_ALL=1
    call :scanDrive
  ) else (
    if exist "!driveArg!\" (
      set "tempDrive=!driveArg!"
      call :scanDrive
    ) else (
      for /f "tokens=* delims=" %%a in ('type "!driveArg!"') do (
        if exist "%%~a" (
          set "tempDrive=%%~a"
          call :scanDrive
        ) else (
          set "driveError1=File or directory does not exist: %%~a"
          call :driveError
        )
      )
    )
  )

  if exist "bin\frames.raw" (
    del "bin\frames.raw"
  )
  
  set lastTitle=
  set goodVideo=

  dir /a:-d /b "Unverified" > "!BASE!\bin\variables\tempdir.var" 2>nul
  for /f "tokens=* delims=" %%f in ('cscript /nologo "bin\vbs\fixdir.vbs" "!BASE!\bin\variables\tempdir.var"') do (
    set "videoName=%%f"
    
    for /f "tokens=1-2 delims=@" %%a in ("%%f") do (
      if "!lastTitle!" neq "%%a" (
        call :checkLikelyVideo
        if "%%b" == "1" set "goodVideo=%%f"
        dir "!BASE!\Verified\%%a*" >nul 2>nul && set goodVideo=
      ) else (
        set goodVideo=
      )

      set "lastTitle=%%a"
    )
  )

  call :checkLikelyVideo

  cls

  title Decache

  set /a numVideos=0
  for /f "tokens=* delims=" %%a in ('type "bin\cached_ids.txt" 2^>nul') do set /a numVideos+=1
  for /f "tokens=* delims=" %%a in ('dir /a:-d /b "Verified" 2^>nul ^| "%SYSTEMROOT%\System32\find" /c /v ""') do set totalFiles=%%a

  set /a unverifiedFiles=0
  dir /a:-d /b "Unverified" > "!BASE!\bin\variables\tempdir.var" 2>nul
  for /f "tokens=* delims=" %%x in ('cscript /nologo "bin\vbs\fixdir.vbs" "!BASE!\bin\variables\tempdir.var"') do (
    echo "%%x" | findstr /c:"@" >nul 2>nul
    if "!errorlevel!" == "0" set /a unverifiedFiles+=1
  )

  set verifiedFiles=!totalFiles!
  if exist "Verified/contents.txt" set /a verifiedFiles-=1
  if exist "Verified/credit.txt" set /a verifiedFiles-=1
  if exist "Verified/cached_ids.txt" set /a verifiedFiles-=1
  if exist "Verified/desktop.ini" set /a verifiedFiles-=1

  dir /a:-d /b "Unverified" > "!BASE!\bin\variables\tempdir.var" 2>nul
  for /f "tokens=* delims=" %%x in ('cscript /nologo "bin\vbs\fixdir.vbs" "!BASE!\bin\variables\tempdir.var"') do (
    set "getFreeName1=%%x"
    set "getFreeName1=!getFreeName1:@1@=@!"

    if "!getFreeName1!" neq "%%x" (
      call :getFreeName "Unverified"
      ren "Unverified\%%x" "!fixedName!"
    )
  )

  del "bin\variables\lock.var" >nul 2>nul
  cls

  :: Exclamation cleansing handled in VBS file
  set identifier=
  set publicCred=
  set sendVideos=
  for /f "tokens=* delims=" %%z in ('cscript /nologo "bin\vbs\askforname.vbs" "!verifiedFiles!" "!numVideos!"') do (
    if "!identifier!" == "" (
      set "identifier=%%z"
    ) else (
      if "!publicCred!" == "" (
        set "publicCred=%%z"
      ) else (
        set "sendVideos=%%z"
      )
    )
  )
  
  if "!identifier!" == "" (
    del "!BASE!\Verified\credit.txt" >nul 2>nul
  ) else (
    echo PRIVATE:!identifier!> "!BASE!\Verified\credit.txt"
    echo PUBLIC:!publicCred!>> "!BASE!\Verified\credit.txt"
    
    dir /a:-d /b "Unverified" > "!BASE!\bin\variables\tempdir.var" 2>nul
    for /f "tokens=* delims=" %%x in ('cscript /nologo "bin\vbs\fixdir.vbs" "!BASE!\bin\variables\tempdir.var"') do (
      echo Unverified\%%x> "!BASE!\bin\variables\unmodify1.var"
      for /f "tokens=* delims=" %%c in ('cscript /nologo "bin\vbs\unmodify_date.vbs" "!BASE!\bin\variables\unmodify1.var" "" "0"') do (
        echo !identifier!>> "Unverified\%%x"
        echo !publicCred!>> "Unverified\%%x"
        cscript /nologo "bin\vbs\unmodify_date.vbs" "!BASE!\bin\variables\unmodify1.var" "%%c" "1"
      )
    )
  )

  

  :: User allowed sharing of encrypted IDs
  if "!sendVideos!" == "6" (
    if not exist "Verified\cached_ids.txt" set /a totalFiles+=1
    type "bin\cached_ids.txt" >> "Verified\cached_ids.txt" 2>nul
  )
  
  del "bin\cached_ids.txt" >nul 2>nul

  if "!totalFiles!" neq "0" (
    echo !BASE!\Verified\> "!BASE!\bin\variables\sizecheck.var"
    pushd "bin"
    call "check_size.bat"
    popd
  
    :compressData
    echo Compressing data...
    "bin\7z\7z.exe" a -tzip "Assets.zip.lock" "!BASE!\Verified\*" >nul 2>nul

    if not exist "Assets.zip.lock" (
      echo Compressing failed; retrying...
      goto compressData
    )
  
    set "getFreeName1=Assets.zip"
    call :getFreeName "."
    ren "Assets.zip.lock" "!fixedName!"

    cls
  )

  del "!BASE!\bin\raw_contents.txt" >nul 2>nul
  type "!BASE!\Verified\credit.txt" >> "!BASE!\bin\raw_contents.txt" 2>nul
  echo CONTENTS>> "!BASE!\bin\raw_contents.txt" 2>nul
  type "!BASE!\Verified\contents.txt" >> "!BASE!\bin\raw_contents.txt" 2>nul
  echo FILENAMES>> "!BASE!\bin\raw_contents.txt" 2>nul
  dir /b "!BASE!\Verified" >> "!BASE!\bin\raw_contents.txt" 2>nul
  echo CACHED>> "!BASE!\bin\raw_contents.txt" 2>nul
  type "!BASE!\Verified\cached_ids.txt" >> "!BASE!\bin\raw_contents.txt" 2>nul

  if "!identifier!" neq "" (
    :retryConnection
    ping google.com -n 1 >nul 2>nul
    if !errorlevel! == 1 (
      for /f %%z in ('cscript /nologo "bin\vbs\nointernet.vbs" "!verifiedFiles!" "!fixedName!"') do if "%%z" == "1" goto retryConnection
    ) else (
      echo Uploading files ^(this may take a while^)...
      
      set urlProvided=0

      for /f "tokens=* delims=" %%s in ('call "bin\curl.exe" -X POST -s -k --retry 1 --data-binary "@!BASE!\bin\raw_contents.txt" -H "x-API-Key: upload" https://upload.decache.workers.dev/upload') do (
        if "%%s" neq "nothing 2 see here" (
          set urlProvided=1
          set "uploadURL=%%s"
          echo !uploadURL!> "!BASE!\bin\variables\url.var"
          for /f %%z in ('cscript /nologo "!BASE!\bin\vbs\regex.vbs" "[^^\w\:\-\./\?\=\&\%%\n\r]" "!BASE!\bin\variables\url.var" 1') do set "uploadURL="
          echo url = "!uploadURL!"> "!BASE!\bin\curl.cfg"
        )
      )
      
      if "!urlProvided!" == "1" (
        set statusCode=
        for /f "tokens=* delims=" %%s in ('call "bin\curl.exe" -X PUT -o nul -w "%%{http_code}" -s -k --retry 1 --data-binary "@!fixedName!" -K "!BASE!\bin\curl.cfg"') do (
          set "statusCode=%%s"
        )

        if "!statusCode!" neq "200" (
          for /f %%z in ('cscript /nologo "bin\vbs\nointernet.vbs" "!verifiedFiles!" "!fixedName!"') do if "%%z" == "1" goto retryConnection
        )
      )
    )
  )

  if "!unverifiedFiles!" neq "0" cscript /nologo "bin\vbs\likely_alert.vbs" "!unverifiedFiles!"

  cls

  echo Thank you for using Decache^^!
  echo:
  echo For further information, please see the website:
  echo sindexmon.github.io/decache/
  echo:
  
  if "!unverifiedFiles!" neq "0" (
    if "!unverifiedFiles!" == "1" (
      echo To watch your !unverifiedFiles! unverified video, you'll have to open them using VLC Media Player.
    ) else (
      echo To watch your !unverifiedFiles! unverified videos, you'll have to open them using VLC Media Player.
    )

    echo If you already have VLC installed, the videos will open automatically.
    echo:

    pause >nul | set /p =Press any key to exit . . .

    set vlcPath=
    if exist "C:\Program Files\VideoLAN\VLC\vlc.exe" (
      set "vlcPath=C:\Program Files\VideoLAN\VLC\vlc.exe"
    ) else (
      if exist "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe" set "vlcPath=C:\Program Files (x86)\VideoLAN\VLC\vlc.exe"
    )

    if "!vlcPath!" neq "" (
      for %%v in ("!BASE!\Unverified\*") do (
        start "" "!vlcPath!" "%%v" --one-instance --playlist-enqueue --no-playlist-autostart
      )
    ) else (
      explorer "!BASE!\Unverified\"
    )
  ) else (
    pause >nul | set /p =Press any key to exit . . .
  )