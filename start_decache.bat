<<<<<<< HEAD:find_cached_videos.bat
:: sindexmon spent 3000 hours in visual studio 4 this
:: UPDATE 2025/06/20 - "*.flv" added to incorporate videos from Google Video
:: UPDATE 2025/06/26 - Videos are now copied into a folder to avoid clogging (shoutout CanucksFan2006 for the suggestion)
:: UPDATE 2025/09/07 - The file has been completely revamped. Now, instead of searching your whole operating system, it only searches specific directories. Hooray for maintaining drive integrity!
:: UPDATE 2025/09/12 - Integrated rough FLV header detection, along with Firefox and Opera support
:: UPDATE 2025/09/20 - Added MP4 and WebM support; THANK YOU CANUCKSFAN2006 FOR THE HELP!!!!
:: UPDATE 2025/09/24 - Added permission checks; thank you D2 for the test cases!!
:: UPDATE 2025/10/22 - Fully integrated frame-by-frame comparisons via FFmpeg and perceptual hashing

@echo off
setlocal enabledelayedexpansion

:: If running the script as admin, this corrects the directory
cd /d "%~dp0"

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

set VIDEO_DATA_FILE="bin\video_data.txt"
set "VIDEOS_PATH=Videos"
set VIDEO_IDS=

:: Grab the individual video IDs for direct RegEx(ish) searching in cache index/history
for /f %%a in ('type %VIDEO_DATA_FILE%') do for /f "tokens=2 delims=|" %%b in ("%%~a") do (
  set "fitRegex=%%b"
  set "fitRegex=!fitRegex:,= !"
  set "VIDEO_IDS=!VIDEO_IDS!!fitRegex! "
)

set VIDEO_IDS=%VIDEO_IDS:~0,-1%

set matchedIds=
set confirmedVideos=
set likelyVideos=
set foundVideos=
set /a maybeCount=0

set matchedHex=
set matchedReg=
set lastSaved=
set workingHash=

goto main

:: Copies the file from the original drive to the new "videos" folder
:saveFile
  set /a files+=1
  if !files! == 1 (title !files! video found) else (title !files! videos found)
  <nul set /p=Found video "%~n1%~x1" ... 

  :retryCopy
  for /f "tokens=3 USEBACKQ" %%s in (`dir /-c /w`) do set "size=%%s" 2>nul
  set /a "size=!size!" 2>nul
  if !errorlevel! neq 1073750992 (
    if !size! geq 0 (
      if !size! lss %~z1 (
        echo:
        echo ==============================================================
        echo ^^!^^! Unable to copy video; free up storage space to continue. ^^!^^!
        pause > NUL | set /p =Press any key to try again . . .
        echo:
        echo ==============================================================
        goto retryCopy
      )
    )
  )

  set "ext=%~2"
  if "!ext!" == "" (
    set "ext=%~x1"
  )

  set filePath="%VIDEOS_PATH%\%~n1!ext!"
  set /a dupeCount=0
  :checkDupe
  if exist !filePath! (
    set /a dupeCount+=1
    set filePath="%VIDEOS_PATH%\%~n1 (!dupeCount!)!ext!"
    goto checkDupe
  )

  echo F|xcopy %1 !filePath! > nul
  <nul set /p=copied ... 
  set lastSaved=!filePath!
  exit /b 0

:grabFileHex
  for /f %%z in ('cscript /nologo "bin\hex.vbs" %1 %~2') do set matchedHex=%%z
  exit /b 0

:grabRegexMatch
  set matchedReg=
  for /f %%z in ('cscript /nologo "bin\regex.vbs" %1 %2') do (
    set matchedReg=%%z
    goto keepMatch
  )

  :keepMatch
  exit /b 0

:: Add videos to the end results with a level of confirmation
:printFinding
  if "!likelyVideos!" neq "" set "likelyVideos=!likelyVideos!,"
  if "!confirmedVideos!" neq "" set "confirmedVideos=!confirmedVideos!,"
  if "!foundVideos!" neq "" set "foundVideos=!foundVideos!,"

  for %%f in (!lastSaved!) do set "fileName=%%~nxf"
  
  set "realName=%~1"
  set "realName=!realName:PLUSER=+!"
  set "realName=!realName:+= !"
  set "realName=!realName:{=(!"
  set "realName=!realName:}=)!"
  set "realName=!realName::=-!"

  ren !lastSaved! "%~2 '!realName!' @ !fileName!"
  set lastSaved="%VIDEOS_PATH%\%~2 '!realName!' @ !fileName!"

  set "fileName=!fileName:(={!"
  set "fileName=!fileName:)=}!"

  if %2 == "# CONFIRMED" (
    set "confirmedVideos=!confirmedVideos!File '!fileName!' is a PERFECT MATCH for '%~1'"
  ) else (
    if %2 == "# LIKELY" (
      set "likelyVideos=!likelyVideos!File '!fileName!' is a LIKELY MATCH for '%~1'"
    ) else (
      set "foundVideos=!foundVideos!File '!fileName!' is the same length as '%~1'"
      set /a maybeCount+=1
    )
  )

  exit /b 0

:: Heavy function to compare known frames of a video
:compareFrames
  <nul set /p=comparing frames ... 

  if exist "bin\frames.raw" (
    del "bin\frames.raw"
  )

  set "fixMultiHash=%1"
  set "fixMultiHash=!fixMultiHash:,= !"

  "bin\ffmpeg.exe" -i !lastSaved! -vf "scale=32:32" -pix_fmt gray -f rawvideo "bin\frames.raw" >nul 2>nul
  for /f "tokens=1,2" %%a in ('call "bin\phash.exe" "bin\frames.raw" !fixMultiHash!') do (
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

  :: WebM header
  if "!matchedHex:~0,8!" == "1A45DFA3" (
    call :saveFile %1 ".webm"
    set videoFormat=WEBM
    set neededBytes=4489..................
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
        goto endLoop
      )
    )
  )

  if %2 neq "UNKNOWN" (
    call :saveFile %1 ""
    goto endComp
  )

  exit /b 0
  
  :endLoop
  set byte_set=128,256,512,1024
  if "!videoFormat!" == "WEBM" (
    :: This deep in the file is ridiculously slow to read... sorry abt that
    set byte_set=700,1024
  )
  
  :: Gradually increases the number of bytes to read from the file, looking for durations
  for %%i in (!byte_set!) do (
    call :grabFileHex !lastSaved! %%i 0
    call :grabRegexMatch "!neededBytes!" "!matchedHex!"

    if "!matchedReg!" neq "" (
      if "!videoFormat!" == "FLV" (
        set lengthData="!matchedReg:~18,16!"

        for /f %%a in ('type %VIDEO_DATA_FILE%') do for /f "tokens=1-5,8-9 delims=|" %%b in ("%%~a") do (
          if !lengthData! geq "%%e" (
            if !lengthData! leq "%%f" (
              set vidData=!vidData!,"%%b|%%c|%%d|%%g|%%h"
              if "%%c" neq "0000000000000000" (
                set "hashes=!hashes! %%d"
              )
            )
          )
        )
      ) else (
        if "!videoFormat!" == "MP4" (
          set /a "timescale=0x!matchedReg:~32,8!"
          set /a "duration=0x!matchedReg:~40,8! * 10"

          set /a finalTime=!duration!/!timescale!

          for /f %%a in ('type %VIDEO_DATA_FILE%') do for /f "tokens=1-3,8-9 delims=|" %%b in ("%%~a") do (
            if !finalTime! geq %%e (
              if !finalTime! leq %%f (
                set vidData=!vidData!,"%%b|%%c|%%d|%%e|%%f"
                if "%%c" neq "0000000000000000" (
                  set "hashes=!hashes! %%d"
                )
              )
            )
          )
        ) else (
          set lengthData="!matchedReg:~6,16!"

          for /f %%a in ('type %VIDEO_DATA_FILE%') do for /f "tokens=1-3,6-9 delims=|" %%b in ("%%~a") do (
            if !lengthData! geq "%%e" (
              if !lengthData! leq "%%f" (
                set vidData=!vidData!,"%%b|%%c|%%d|%%g|%%h"
                if "%%c" neq "0000000000000000" (
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
    set "descriptor=# MAYBE"
    set titles=

    if "!hashes!" neq "" (
      set "hashes=!hashes:~1!"
      call :compareFrames !hashes!
    )

    for %%a in (!vidData!) do for /f "tokens=1-5 delims=|" %%b in ("%%~a") do (
      if "!workingHash!" neq "" (
        echo "%%d" | findstr "!workingHash!" >nul
        if !errorlevel! == 0 (
          call :printFinding %%b "# CONFIRMED"
          goto endHashComp
        )
      ) else (
        set "fixedId=%%c"
        set "fixedId=!fixedId:,= !"
        echo "%matchedIds%" | findstr "!fixedId!" >nul
        if !errorlevel! == 0 (
          call :printFinding %%b "# LIKELY"
          goto endHashComp
        )

        set /a diff=%%f-%%e

        if !diff! lss 5 (
          set "descriptor=# LIKELY"
        )
      
        if "!titles!" == "" (
          set "titles=%%b"
        ) else (
          set "titles=!titles!'+OR+'%%b"
        )
      )
    )

    call :printFinding !titles! "!descriptor!"
  )

  :endHashComp
  echo compared^^!
  exit /b 0

:: Scans browser history/cache indexes for lost video IDs
:scanHistory
  echo Scanning for video IDs...

  if "%~3" == "" (
    set matchedIds=
  )

  if exist %1 (
    for /f "tokens=* delims=" %%f in ('findstr /s /m "%VIDEO_IDS%" "%~1%~2"') do (
      for %%v in (%VIDEO_IDS%) do (
        findstr /c:"%%v" "%%f" >nul 2>nul
        if !errorlevel! == 0 (
          set "matchedIds=!matchedIds!%%v,"
        )
      )
    )
  )

  cls
  exit /b 0

:scanDir
  echo Scanning folder "%~dp1"
  set currentFile="0"
  
  if exist %1 (
    for %%n in (%~3) do (
      set "ext=%%n"
      set "ext=!ext:+=*!"
      for /f "tokens=* delims=" %%f in ('dir /a:-d /s /b "%~1!ext!"') do (
        if %2 == "CONCAT" (
          if !currentFile! == "0" (
            call :checkFile "%%f" %2
            set currentFile=!lastSaved!
          ) else (
            type "%%f" >> !currentFile!
          )

          if %%~zf neq 1048576 (
            set currentFile="0"
          )
        ) else (
          call :checkFile "%%f" %2
        )
      )
    )
  )

  cls
  exit /b 0

:: Collects Chrome and Firefox, along with browsers built off them (e.g. Microsoft Edge; Waterfox).
:scanForks
  :: Chromium
  for /d %%p in ("%~1\User Data\*") do (
    :: There are rumors of cache clones...
    for /d %%c in ("%%p\Cache*") do (
      call :scanHistory "%%c\" "data_*"
      call :scanDir "%%c\" "UNKNOWN" "f_+"
    )

    for /d %%c in ("%%p\Media Cache*") do (
      call :scanHistory "%%c\" "data_*"
      call :scanDir "%%c\" "CONCAT" "f_+"
    )
  )

  :: Firefox
  for /d %%p in ("%~1\Profiles\*") do (
    call :scanHistory "%%p\Cache\" "_CACHE_*"
    call :scanDir "%%p\Cache\" "UNKNOWN" "+"
    call :scanDir "%%p\Cache2\" "UNKNOWN" "+"
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

  :: Opera
  call :scanHistory "%~1Opera\Opera\profile\" "dcache4.url"
  call :scanDir "%~1Opera\Opera\profile\" "UNKNOWN" "opr+ f_+"
  call :scanHistory "%~1Opera\Opera\cache\" "dcache4.url"
  call :scanDir "%~1Opera\Opera\cache\" "UNKNOWN" "opr+ f_+"

  :: Future versions of Opera were based on Chromium
  for /d %%v in ("%~1Opera Software\*") do (
    for /d %%c in ("%%v\Cache*") do (
      call :scanHistory "%%c\" "data_*"
      call :scanDir "%%c\" "UNKNOWN" "opr+ f_+"
    )

    for /d %%c in ("%%v\Media Cache*") do (
      call :scanHistory "%%c\" "data_*"
      call :scanDir "%%c\" "CONCAT" "opr+ f_+"
    )
  )

  exit /b 0

:scanXP
  if exist "%~1\Local Settings\" (
    call :checkPermissions "%~1" "Local Settings"
    call :scanBrowsers "%~1\Local Settings\Application Data\"
    call :scanHistory "%~1\Local Settings\History\History.IE5\" "*.dat"
    call :scanHistory "%~1\Local Settings\Temporary Internet Files\" "index.dat" 1
    call :scanDir "%~1\Local Settings\Temp\" "KNOWN" "fla+.tmp"
    call :scanDir "%~1\Local Settings\Temporary Internet Files\" "KNOWN" "get_video+,videoplayback+,+.flv"
  )

  exit /b 0

:scanVista
  if exist "%~1\AppData\" (
    call :checkPermissions "%~1" "AppData"
    call :scanBrowsers "%~1\AppData\Local\"
    call :scanHistory "%~1\AppData\Local\Microsoft\Windows\WebCache\" "WebCacheV*"
    call :scanHistory "%~1\AppData\Local\Microsoft\Windows\WebCache.old\" "WebCacheV*" 1
    call :scanHistory "%~1\AppData\Local\Microsoft\Windows\Temporary Internet Files\" "index.dat" 1
    call :scanDir "%~1\AppData\Local\Temp\" "KNOWN" "fla*.tmp"
    call :scanDir "%~1\AppData\Local\Microsoft\Windows\Temporary Internet Files\" "KNOWN" "get_video+,videoplayback+,+.flv"
    call :scanDir "%~1\AppData\Local\Microsoft\Windows\INetCache\" "KNOWN" "get_video+,videoplayback+,+.flv"
    call :scanDir "%~1\AppData\Local\Packages\windows_ie_ac_001\AC\INetCache\" "KNOWN" "get_video+,videoplayback+,+.flv"
  )

  exit /b 0

:: Mainly for password-protected user folders.
:checkPermissions
  dir "%~1\%~2\" 1>nul 2>nul
  if !errorlevel! == 1 (
    if %isAdmin% == 0 (
      echo ^^!^^! You need administrative permissions to access "%~1"
      pause > NUL | set /p =Please relaunch as administrator to read this directory. Otherwise, press any key to continue . . .
    ) else (
      echo ^^!^^! Unable to access directory "%~1"
      echo This can be solved by running this script while logged into the user in question ^(not on a backup^), or manually changing the permissions of the folder to allow access.
      pause
    )
  )

  exit /b 0

:: Some minor VBScript solutions are embedded for speed.
:createHexVbs
  set vbsPath="bin\hex.vbs"
  echo With CreateObject("ADODB.Stream") > !vbsPath!
  echo   .Type = 1 >> !vbsPath!
  echo   .Open() >> !vbsPath!
  echo   .LoadFromFile(WScript.Arguments(0)) >> !vbsPath!
  echo   .Position = 0 >> !vbsPath!
  echo   theBytes = .Read(WScript.Arguments(1)) >> !vbsPath!
  echo End With >> !vbsPath!
  echo hexHeader = "" >> !vbsPath!
  echo For i = 1 To LenB(theBytes) >> !vbsPath!
  echo   hexHeader = hexHeader ^& Right("0" ^& Hex(AscB(MidB(theBytes, i, 1))), 2) >> !vbsPath!
  echo Next >> !vbsPath!
  echo WScript.Echo(hexHeader) >> !vbsPath!

  set vbsPath="bin\regex.vbs"
  echo Dim reg : Set reg = New RegExp > !vbsPath!
  echo reg.Pattern = WScript.Arguments(0) >> !vbsPath!
  echo Dim matches, match >> !vbsPath!
  echo Set matches = reg.Execute(WScript.Arguments(1)) >> !vbsPath!
  echo For Each match In matches >> !vbsPath!
  echo     WScript.Echo(match) >> !vbsPath!
  echo Next >> !vbsPath!
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

:main
  cls
  title Cached Video Finder

  echo Videos will copy into a "Videos" folder, automatically created in the folder you're running this file from.
  echo:

  echo If you're running this on the computer you intend to search, just type C:
  echo If you backed up your computer in a folder, enter the full path to that folder (example: C:\Backups\Old Laptop)
  echo:
  
  set /p drive=Enter drive to search (example: C:) 
  set "drive=%drive:/=\%"
  set drive=%drive:"=%
  if "%drive:~1,1%" neq ":" (
    set "drive=%drive:~0,1%:%drive:~1%"
  )
  if "%drive:~-1,1%" == "\" (
    set "drive=%drive:~0,-1%"
  )

  set /a files=0
  if not exist "%VIDEOS_PATH%\" (
      mkdir Videos
  )

  call :createHexVbs
  cls

  :: For pre-2000 machines
  call :scanDir "%drive%\WINDOWS\Temporary Internet Files\" "KNOWN" "get_video+,videoplayback+,+.flv"
  call :scanDir "%drive%\WINDOWS\Temp\" "KNOWN" "fla*.tmp"

  :: In case the backup is of one user
  call :scanVista "%drive%"
  call :scanXP "%drive%"

  :: In case the backup is of the users folder
  for /f "tokens=* delims=" %%d in ('dir /a:h /a:d /b "%drive%"') do (
    call :scanVista "%drive%\%%d"
    call :scanXP "%drive%\%%d"
  )

  for /d %%x in ("%drive%","%drive%\Windows.old*") do (
    :: For post-XP machines
    for /f "tokens=* delims=" %%d in ('dir /a:h /a:d /b "%%~x\Users"') do (
      call :scanVista "%%~x\Users\%%d"
    )
    
    :: For pre-Vista machines
    for /f "tokens=* delims=" %%d in ('dir /a:h /a:d /b "%%~x\Documents and Settings"') do (
      call :scanXP "%%~x\Documents and Settings\%%d"
    )
  )

  del "bin\hex.vbs"
  del "bin\regex.vbs"
  if exist "bin\frames.raw" (
    del "bin\frames.raw"
  )

  cls

  title Cached video finder

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

    if "%confirmedVideos%" == "" (
      if "%likelyVideos%" == "" (
        call :printTitles "%foundVideos%"
        goto skipUnconfirmed
      )
    )

    echo + %maybeCount% less accurate matches.
    
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

  pause > NUL | set /p =Press any key to continue . . .

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
=======
:: sindexmon spent 3000 hours in visual studio 4 this
:: UPDATE 2025/06/20 - "*.flv" added to incorporate videos from Google Video
:: UPDATE 2025/06/26 - Videos are now copied into a folder to avoid clogging (shoutout CanucksFan2006 for the suggestion)
:: UPDATE 2025/09/07 - The file has been completely revamped. Now, instead of searching your whole operating system, it only searches specific directories. Hooray for maintaining drive integrity!
:: UPDATE 2025/09/12 - Integrated rough FLV header detection, along with Firefox and Opera support
:: UPDATE 2025/09/20 - Added MP4 and WebM support; THANK YOU CANUCKSFAN2006 FOR THE HELP!!!!
:: UPDATE 2025/09/24 - Added permission checks; thank you D2 for the test cases!!
:: UPDATE 2025/10/22 - Fully integrated frame-by-frame comparisons via FFmpeg and perceptual hashing

@echo off
setlocal enabledelayedexpansion

:: If running the script as admin, this corrects the directory
cd /d "%~dp0"

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

set VIDEO_DATA_FILE="bin\video_data.txt"
set "VIDEOS_PATH=Videos"
set VIDEO_IDS=

:: Grab the individual video IDs for direct RegEx(ish) searching in cache index/history
for /f %%a in ('type %VIDEO_DATA_FILE%') do for /f "tokens=2 delims=|" %%b in ("%%~a") do (
  set "fitRegex=%%b"
  set "fitRegex=!fitRegex:,= !"
  set "VIDEO_IDS=!VIDEO_IDS!!fitRegex! "
)

set VIDEO_IDS=%VIDEO_IDS:~0,-1%

set matchedIds=
set confirmedVideos=
set likelyVideos=
set foundVideos=
set /a maybeCount=0

set matchedHex=
set matchedReg=
set lastSaved=
set workingHash=

goto main

:: Copies the file from the original drive to the new "videos" folder
:saveFile
  set /a files+=1
  if !files! == 1 (title !files! video found) else (title !files! videos found)
  <nul set /p=Found video "%~n1%~x1" ... 

  :retryCopy
  for /f "tokens=3 USEBACKQ" %%s in (`dir /-c /w`) do set "size=%%s" 2>nul
  set /a "size=!size!" 2>nul
  if !errorlevel! neq 1073750992 (
    if !size! geq 0 (
      if !size! lss %~z1 (
        echo:
        echo ==============================================================
        echo ^^!^^! Unable to copy video; free up storage space to continue. ^^!^^!
        pause > NUL | set /p =Press any key to try again . . .
        echo:
        echo ==============================================================
        goto retryCopy
      )
    )
  )

  set "ext=%~2"
  if "!ext!" == "" (
    set "ext=%~x1"
  )

  set filePath="%VIDEOS_PATH%\%~n1!ext!"
  set /a dupeCount=0
  :checkDupe
  if exist !filePath! (
    set /a dupeCount+=1
    set filePath="%VIDEOS_PATH%\%~n1 (!dupeCount!)!ext!"
    goto checkDupe
  )

  echo F|xcopy %1 !filePath! > nul
  <nul set /p=copied ... 
  set lastSaved=!filePath!
  exit /b 0

:grabFileHex
  for /f %%z in ('cscript /nologo "bin\hex.vbs" %1 %~2') do set matchedHex=%%z
  exit /b 0

:grabRegexMatch
  set matchedReg=
  for /f %%z in ('cscript /nologo "bin\regex.vbs" %1 %2') do (
    set matchedReg=%%z
    goto keepMatch
  )

  :keepMatch
  exit /b 0

:: Add videos to the end results with a level of confirmation
:printFinding
  if "!likelyVideos!" neq "" set "likelyVideos=!likelyVideos!,"
  if "!confirmedVideos!" neq "" set "confirmedVideos=!confirmedVideos!,"
  if "!foundVideos!" neq "" set "foundVideos=!foundVideos!,"

  for %%f in (!lastSaved!) do set "fileName=%%~nxf"
  
  set "realName=%~1"
  set "realName=!realName:PLUSER=+!"
  set "realName=!realName:+= !"
  set "realName=!realName:{=(!"
  set "realName=!realName:}=)!"
  set "realName=!realName::=-!"

  ren !lastSaved! "%~2 '!realName!' @ !fileName!"
  set lastSaved="%VIDEOS_PATH%\%~2 '!realName!' @ !fileName!"

  set "fileName=!fileName:(={!"
  set "fileName=!fileName:)=}!"

  if %2 == "# CONFIRMED" (
    set "confirmedVideos=!confirmedVideos!File '!fileName!' is a PERFECT MATCH for '%~1'"
  ) else (
    if %2 == "# LIKELY" (
      set "likelyVideos=!likelyVideos!File '!fileName!' is a LIKELY MATCH for '%~1'"
    ) else (
      set "foundVideos=!foundVideos!File '!fileName!' is the same length as '%~1'"
      set /a maybeCount+=1
    )
  )

  exit /b 0

:: Heavy function to compare known frames of a video
:compareFrames
  <nul set /p=comparing frames ... 

  if exist "bin\frames.raw" (
    del "bin\frames.raw"
  )

  set "fixMultiHash=%1"
  set "fixMultiHash=!fixMultiHash:,= !"

  "bin\ffmpeg.exe" -i !lastSaved! -vf "scale=32:32" -pix_fmt gray -f rawvideo "bin\frames.raw" >nul 2>nul
  for /f "tokens=1,2" %%a in ('call "bin\phash.exe" "bin\frames.raw" !fixMultiHash!') do (
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

  :: WebM header
  if "!matchedHex:~0,8!" == "1A45DFA3" (
    call :saveFile %1 ".webm"
    set videoFormat=WEBM
    set neededBytes=4489..................
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
        goto endLoop
      )
    )
  )

  if %2 neq "UNKNOWN" (
    call :saveFile %1 ""
    goto endComp
  )

  exit /b 0
  
  :endLoop
  set byte_set=128,256,512,1024
  if "!videoFormat!" == "WEBM" (
    :: This deep in the file is ridiculously slow to read... sorry abt that
    set byte_set=700,1024
  )
  
  :: Gradually increases the number of bytes to read from the file, looking for durations
  for %%i in (!byte_set!) do (
    call :grabFileHex !lastSaved! %%i 0
    call :grabRegexMatch "!neededBytes!" "!matchedHex!"

    if "!matchedReg!" neq "" (
      if "!videoFormat!" == "FLV" (
        set lengthData="!matchedReg:~18,16!"

        for /f %%a in ('type %VIDEO_DATA_FILE%') do for /f "tokens=1-5,8-9 delims=|" %%b in ("%%~a") do (
          if !lengthData! geq "%%e" (
            if !lengthData! leq "%%f" (
              set vidData=!vidData!,"%%b|%%c|%%d|%%g|%%h"
              if "%%c" neq "0000000000000000" (
                set "hashes=!hashes! %%d"
              )
            )
          )
        )
      ) else (
        if "!videoFormat!" == "MP4" (
          set /a "timescale=0x!matchedReg:~32,8!"
          set /a "duration=0x!matchedReg:~40,8! * 10"

          set /a finalTime=!duration!/!timescale!

          for /f %%a in ('type %VIDEO_DATA_FILE%') do for /f "tokens=1-3,8-9 delims=|" %%b in ("%%~a") do (
            if !finalTime! geq %%e (
              if !finalTime! leq %%f (
                set vidData=!vidData!,"%%b|%%c|%%d|%%e|%%f"
                if "%%c" neq "0000000000000000" (
                  set "hashes=!hashes! %%d"
                )
              )
            )
          )
        ) else (
          set lengthData="!matchedReg:~6,16!"

          for /f %%a in ('type %VIDEO_DATA_FILE%') do for /f "tokens=1-3,6-9 delims=|" %%b in ("%%~a") do (
            if !lengthData! geq "%%e" (
              if !lengthData! leq "%%f" (
                set vidData=!vidData!,"%%b|%%c|%%d|%%g|%%h"
                if "%%c" neq "0000000000000000" (
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
    set "descriptor=# MAYBE"
    set titles=

    if "!hashes!" neq "" (
      set "hashes=!hashes:~1!"
      call :compareFrames !hashes!
    )

    for %%a in (!vidData!) do for /f "tokens=1-5 delims=|" %%b in ("%%~a") do (
      if "!workingHash!" neq "" (
        echo "%%d" | findstr "!workingHash!" >nul
        if !errorlevel! == 0 (
          call :printFinding %%b "# CONFIRMED"
          goto endHashComp
        )
      ) else (
        set "fixedId=%%c"
        set "fixedId=!fixedId:,= !"
        echo "%matchedIds%" | findstr "!fixedId!" >nul
        if !errorlevel! == 0 (
          call :printFinding %%b "# LIKELY"
          goto endHashComp
        )

        set /a diff=%%f-%%e

        if !diff! lss 5 (
          set "descriptor=# LIKELY"
        )
      
        if "!titles!" == "" (
          set "titles=%%b"
        ) else (
          set "titles=!titles!'+OR+'%%b"
        )
      )
    )

    call :printFinding !titles! "!descriptor!"
  )

  :endHashComp
  echo compared^^!
  exit /b 0

:: Scans browser history/cache indexes for lost video IDs
:scanHistory
  echo Scanning for video IDs...

  if "%~3" == "" (
    set matchedIds=
  )

  if exist %1 (
    for /f "tokens=* delims=" %%f in ('findstr /s /m "%VIDEO_IDS%" "%~1%~2"') do (
      for %%v in (%VIDEO_IDS%) do (
        findstr /c:"%%v" "%%f" >nul 2>nul
        if !errorlevel! == 0 (
          set "matchedIds=!matchedIds!%%v,"
        )
      )
    )
  )

  cls
  exit /b 0

:scanDir
  echo Scanning folder "%~dp1"
  set currentFile="0"
  
  if exist %1 (
    for %%n in (%~3) do (
      set "ext=%%n"
      set "ext=!ext:+=*!"
      for /f "tokens=* delims=" %%f in ('dir /a:-d /s /b "%~1!ext!"') do (
        if %2 == "CONCAT" (
          if !currentFile! == "0" (
            call :checkFile "%%f" %2
            set currentFile=!lastSaved!
          ) else (
            type "%%f" >> !currentFile!
          )

          if %%~zf neq 1048576 (
            set currentFile="0"
          )
        ) else (
          call :checkFile "%%f" %2
        )
      )
    )
  )

  cls
  exit /b 0

:: Collects Chrome and Firefox, along with browsers built off them (e.g. Microsoft Edge; Waterfox).
:scanForks
  :: Chromium
  for /d %%p in ("%~1\User Data\*") do (
    :: There are rumors of cache clones...
    for /d %%c in ("%%p\Cache*") do (
      call :scanHistory "%%c\" "data_*"
      call :scanDir "%%c\" "UNKNOWN" "f_+"
    )

    for /d %%c in ("%%p\Media Cache*") do (
      call :scanHistory "%%c\" "data_*"
      call :scanDir "%%c\" "CONCAT" "f_+"
    )
  )

  :: Firefox
  for /d %%p in ("%~1\Profiles\*") do (
    call :scanHistory "%%p\Cache\" "_CACHE_*"
    call :scanDir "%%p\Cache\" "UNKNOWN" "+"
    call :scanDir "%%p\Cache2\" "UNKNOWN" "+"
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

  :: Opera
  call :scanHistory "%~1Opera\Opera\profile\" "dcache4.url"
  call :scanDir "%~1Opera\Opera\profile\" "UNKNOWN" "opr+ f_+"
  call :scanHistory "%~1Opera\Opera\cache\" "dcache4.url"
  call :scanDir "%~1Opera\Opera\cache\" "UNKNOWN" "opr+ f_+"

  :: Future versions of Opera were based on Chromium
  for /d %%v in ("%~1Opera Software\*") do (
    for /d %%c in ("%%v\Cache*") do (
      call :scanHistory "%%c\" "data_*"
      call :scanDir "%%c\" "UNKNOWN" "opr+ f_+"
    )

    for /d %%c in ("%%v\Media Cache*") do (
      call :scanHistory "%%c\" "data_*"
      call :scanDir "%%c\" "CONCAT" "opr+ f_+"
    )
  )

  exit /b 0

:scanXP
  if exist "%~1\Local Settings\" (
    call :checkPermissions "%~1" "Local Settings"
    call :scanBrowsers "%~1\Local Settings\Application Data\"
    call :scanHistory "%~1\Local Settings\History\History.IE5\" "*.dat"
    call :scanHistory "%~1\Local Settings\Temporary Internet Files\" "index.dat" 1
    call :scanDir "%~1\Local Settings\Temp\" "KNOWN" "fla+.tmp"
    call :scanDir "%~1\Local Settings\Temporary Internet Files\" "KNOWN" "get_video+,videoplayback+,+.flv"
  )

  exit /b 0

:scanVista
  if exist "%~1\AppData\" (
    call :checkPermissions "%~1" "AppData"
    call :scanBrowsers "%~1\AppData\Local\"
    call :scanHistory "%~1\AppData\Local\Microsoft\Windows\WebCache\" "WebCacheV*"
    call :scanHistory "%~1\AppData\Local\Microsoft\Windows\WebCache.old\" "WebCacheV*" 1
    call :scanHistory "%~1\AppData\Local\Microsoft\Windows\Temporary Internet Files\" "index.dat" 1
    call :scanDir "%~1\AppData\Local\Temp\" "KNOWN" "fla*.tmp"
    call :scanDir "%~1\AppData\Local\Microsoft\Windows\Temporary Internet Files\" "KNOWN" "get_video+,videoplayback+,+.flv"
    call :scanDir "%~1\AppData\Local\Microsoft\Windows\INetCache\" "KNOWN" "get_video+,videoplayback+,+.flv"
    call :scanDir "%~1\AppData\Local\Packages\windows_ie_ac_001\AC\INetCache\" "KNOWN" "get_video+,videoplayback+,+.flv"
  )

  exit /b 0

:: Mainly for password-protected user folders.
:checkPermissions
  dir "%~1\%~2\" 1>nul 2>nul
  if !errorlevel! == 1 (
    if %isAdmin% == 0 (
      echo ^^!^^! You need administrative permissions to access "%~1"
      pause > NUL | set /p =Please relaunch as administrator to read this directory. Otherwise, press any key to continue . . .
    ) else (
      echo ^^!^^! Unable to access directory "%~1"
      echo This can be solved by running this script from the user in question ^(not on a backup^), or manually changing the permissions of the folder to allow access.
      pause
    )
  )

  exit /b 0

:: Some minor VBScript solutions are embedded for speed.
:createHexVbs
  set vbsPath="bin\hex.vbs"
  echo With CreateObject("ADODB.Stream") > !vbsPath!
  echo   .Type = 1 >> !vbsPath!
  echo   .Open() >> !vbsPath!
  echo   .LoadFromFile(WScript.Arguments(0)) >> !vbsPath!
  echo   .Position = 0 >> !vbsPath!
  echo   theBytes = .Read(WScript.Arguments(1)) >> !vbsPath!
  echo End With >> !vbsPath!
  echo hexHeader = "" >> !vbsPath!
  echo For i = 1 To LenB(theBytes) >> !vbsPath!
  echo   hexHeader = hexHeader ^& Right("0" ^& Hex(AscB(MidB(theBytes, i, 1))), 2) >> !vbsPath!
  echo Next >> !vbsPath!
  echo WScript.Echo(hexHeader) >> !vbsPath!

  set vbsPath="bin\regex.vbs"
  echo Dim reg : Set reg = New RegExp > !vbsPath!
  echo reg.Pattern = WScript.Arguments(0) >> !vbsPath!
  echo Dim matches, match >> !vbsPath!
  echo Set matches = reg.Execute(WScript.Arguments(1)) >> !vbsPath!
  echo For Each match In matches >> !vbsPath!
  echo     WScript.Echo(match) >> !vbsPath!
  echo Next >> !vbsPath!
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

:main
  cls
  title Cached Video Finder

  echo Videos will copy into a "Videos" folder, automatically created in the folder you're running this file from.
  echo:

  echo If you're running this on the computer you intend to search, just type C:
  echo If you backed up your computer in a folder, enter the full path to that folder (example: C:\Backups\Old Laptop)
  echo:
  
  set /p drive=Enter drive to search (example: C:) 
  set "drive=%drive:/=\%"
  set drive=%drive:"=%
  if "%drive:~1,1%" neq ":" (
    set "drive=%drive:~0,1%:%drive:~1%"
  )
  if "%drive:~-1,1%" == "\" (
    set "drive=%drive:~0,-1%"
  )

  set /a files=0
  if not exist "%VIDEOS_PATH%\" (
      mkdir Videos
  )

  call :createHexVbs
  cls

  :: For pre-2000 machines
  call :scanDir "%drive%\WINDOWS\Temporary Internet Files\" "KNOWN" "get_video+,videoplayback+,+.flv"
  call :scanDir "%drive%\WINDOWS\Temp\" "KNOWN" "fla*.tmp"

  :: In case the backup is of one user
  call :scanVista "%drive%"
  call :scanXP "%drive%"

  :: In case the backup is of the users folder
  for /f "tokens=* delims=" %%d in ('dir /a:h /a:d /b "%drive%"') do (
    call :scanVista "%drive%\%%d"
    call :scanXP "%drive%\%%d"
  )

  for /d %%x in ("%drive%","%drive%\Windows.old*") do (
    :: For post-XP machines
    for /f "tokens=* delims=" %%d in ('dir /a:h /a:d /b "%%~x\Users"') do (
      call :scanVista "%%~x\Users\%%d"
    )
    
    :: For pre-Vista machines
    for /f "tokens=* delims=" %%d in ('dir /a:h /a:d /b "%%~x\Documents and Settings"') do (
      call :scanXP "%%~x\Documents and Settings\%%d"
    )
  )

  del "bin\hex.vbs"
  del "bin\regex.vbs"
  if exist "bin\frames.raw" (
    del "bin\frames.raw"
  )

  cls

  title Cached video finder

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

    if "%confirmedVideos%" == "" (
      if "%likelyVideos%" == "" (
        call :printTitles "%foundVideos%"
        goto skipUnconfirmed
      )
    )

    echo + %maybeCount% less accurate matches.
    
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

  pause > NUL | set /p =Press any key to continue . . .

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
>>>>>>> beta:start_decache.bat
  )