@echo off
setlocal enabledelayedexpansion

set CACHE_LIST="sploder_2.txt"
set "CACHE_VIEW=%~2"
set "TEMP_FOLDER=temp\"
set FILE_DATA="..\..\Verified\contents.txt"
set /p FOLDER=<"..\variables\cachefolder.var"
set SILENCE_ERRORS=%4

if not exist "!FOLDER!" (
  exit /b 0
)

:: For flas, skip directly to printing the files
if "!CACHE_VIEW!" == "" goto unusedCheck

:: fix utf-8 encoding by typing to new file
start /wait "" "!CACHE_VIEW!.exe" -folder "!FOLDER!" /stext sploder_null.txt /sort URL
type sploder_null.txt > !CACHE_LIST!
del sploder_null.txt

:: the columns listed here are FIREFOX EXCLUSIVE!
set url=
set filename=
set fileSize=
set offset=0
set encoding=
set createDate=
set accessDate=
set /a fileCount=0

goto main

:fixCopy
  :retryCopy
  echo F|xcopy "!fixCopy1!" "!fixCopy2!" >nul 2>nul

  if not exist "!fixCopy2!" (
    for /f %%c in ('cscript /nologo "..\vbs\error32.vbs" !SILENCE_ERRORS!') do if "%%c" == "6" goto retryCopy
  )

  exit /b 0

:handleLine
  set "entry=%~1"
  set "name=!entry:~0,19!"
  set "value=!entry:~20!"
  
  if "!name!" == "URL               :" (
    set offset=0

    echo "!value!" | findstr /c:"web.archive.org" >nul 2>nul
    if "!errorlevel!" neq "0" (
      set "url=!value!"
    )
  ) else (
    if "!url!" neq "" if "!name!" neq "Subfolder Name    :" if "!name!" neq "File Size         :" if "!name!" neq "Record Created Time" if "!name!" neq "Last Accessed     :" if "!name!" neq "Last Modified     :" if "!name!" neq "Filename          :" (
      if "!name!" == "Content Encoding  :" if "!CACHE_VIEW!" neq "OperaCacheView" (
        goto skipThisLine
      )

      if "!fileSize!" neq "0" if "!fileSize!" neq "" (
        set "fixedUrl=!url!"
        for /f %%z in ('cscript /nologo "..\vbs\regex.vbs" "[\?&]ip=([0-9\.\:]+)" "!url!" 0') do (
          set "fixedUrl=!fixedUrl:%%z=REDACTED!"
        )

        for /f %%z in ('cscript /nologo "..\vbs\regex.vbs" "[\?&]id=(o-[\w-]{44})" "!url!" 0') do (
          if exist "id_pairs\%%z" (
            set /p origId=< "id_pairs\%%z"
            set "fixedUrl=!fixedUrl!&video_id=!origId!"
          )
        )

        echo "!fileCount! !fixedUrl!" >> !FILE_DATA!

        :: Internet Explorer
        if "!name!" == "Full Path         :" if "!value!" neq "" set "origPath=!value!"

        :: Chrome and Firefox
        if "!name!" == "Cache Name        :" (
          if "!value!" == "" (
            set origPath=

            start /wait "" "!CACHE_VIEW!.exe" -folder "!FOLDER!" /copycache "!url!" "" /CopyFilesFolder "dump"
            for /f "tokens=* delims=" %%f in ('dir /b "dump"') do set "origPath=dump\%%f"

            if "!origPath!" neq "" if "!createDate!" neq "" (
              echo !origPath!> "..\variables\unmodify1.var"
              cscript /nologo "..\vbs\unmodify_date.vbs" "..\variables\unmodify1.var" "!createDate!" "1"
            )
          ) else if exist "!FOLDER!entries\!value!" (
            set "origPath=!FOLDER!entries\!value!"
          ) else (
            if "!value:~-1!" == "]" (
              set "offset=!value:~9,-1!"
              set "value=!value:~0,6!"
            )

            set "origPath=!FOLDER!!value!"
          )
        )

        :: Opera. Has a strange header that I'm not dealing with, and apparently Nirsoft didn't want to deal with it either. Forgotten child
        if "!name!" == "Content Encoding  :" (
          if "!filename!" == "" (
            set origPath=

            start /wait "" "!CACHE_VIEW!.exe" -folder "!FOLDER!" /copycache "!url!" "" /CopyFilesFolder "dump"
            for /f "tokens=* delims=" %%f in ('dir /b "dump"') do (
              set "filename=%%~nxf"
              set "origPath=dump\%%f"
            )

            if "!origPath!" neq "" if "!accessDate!" neq "" (
              echo !origPath!> "..\variables\unmodify1.var"
              cscript /nologo "..\vbs\unmodify_date.vbs" "..\variables\unmodify1.var" "!accessDate!" "1"
            )
          ) else (
            set "origPath=!FOLDER!!filename!"
          )
        )

        echo "!fileCount! !origPath!" >> "..\private_locations.txt"

        if exist "!origPath!" (
          echo !origPath!> "..\variables\sizecheck.var"
          pushd ".."
          call "check_size.bat"
          popd

          for %%f in ("!origPath!") do (
            set modifyLevel=0
            set "outputFile=..\..\Verified\[!fileCount!]!filename:\=!"
            set "outputDir=..\..\Verified\"

            if %%~zf leq !fileSize! (
              set "fixCopy1=!origPath!"
              set "fixCopy2=!outputFile!"
              call :fixCopy
            ) else (
              :retryTruncate
              set blockSize=1024

              :: First bits
              set /a "first_count=(!blockSize! - (!offset! %% !blockSize!)) %% !blockSize!"
              if !first_count! gtr !fileSize! set "first_count=!fileSize!"

              :: Main bits
              set /a "bytes_after_start=!fileSize! - !first_count!"
              set /a "main_count=!bytes_after_start! / !blockSize!"
              set /a "main_skip=(!offset! + !first_count!) / !blockSize!"

              :: End bits
              set /a "end_count=!bytes_after_start! %% !blockSize!"
              set /a "end_skip=!offset! + !first_count! + (!main_count! * !blockSize!)"

              "..\dd.exe" if="!origPath!" of="!outputFile!1" bs=1 skip=!offset! count=!first_count! >nul 2>nul
              "..\dd.exe" if="!origPath!" of="!outputFile!2" bs=!blockSize! skip=!main_skip! count=!main_count! >nul 2>nul
              "..\dd.exe" if="!origPath!" of="!outputFile!3" bs=1 skip=!end_skip! count=!end_count! >nul 2>nul

              if exist "!outputFile!1" if exist "!outputFile!2" if exist "!outputFile!3" (
                copy /b "!outputFile!1" + "!outputFile!2" + "!outputFile!3" "!outputFile!" >nul 2>nul
              )

              if not exist "!outputFile!" (
                for /f %%c in ('cscript /nologo "..\vbs\error32.vbs" !SILENCE_ERRORS!') do if "%%c" == "6" goto retryTruncate
              ) else (
                set modifyLevel=1
              )

              del "!outputFile!1" >nul 2>nul
              del "!outputFile!2" >nul 2>nul
              del "!outputFile!3" >nul 2>nul
            )

            if exist "!outputFile!" (
              if "!encoding!" neq "" (
                :retryCompression
                move "!outputFile!" "!outputFile!.!encoding!" >nul 2>nul
                "..\7z\7z.exe" x "!outputFile!.!encoding!" -o"!outputDir!" >nul 2>nul

                if not exist "!outputFile!" (
                  for /f %%c in ('cscript /nologo "..\vbs\decompress_error.vbs" "!errorlevel!"') do if "%%c" == "6" goto retryCompression
                  move "!outputFile!.!encoding!" "!outputFile!" >nul 2>nul
                ) else (
                  set modifyLevel=1
                  del "!outputFile!.!encoding!" >nul 2>nul
                )
              )

              if "!offset!" == "0" (
                if "!modifyLevel!" == "1" (
                  echo !outputFile!> "..\variables\unmodify1.var"
                  echo !origPath!> "..\variables\unmodify2.var"
                  cscript /nologo "..\vbs\unmodify_date.vbs" "..\variables\unmodify1.var" "..\variables\unmodify2.var" "0"
                )
              ) else if "!createDate!" neq "" (
                echo !outputFile!> "..\variables\unmodify1.var"
                cscript /nologo "..\vbs\unmodify_date.vbs" "..\variables\unmodify1.var" "!createDate!" "1"
              )
            )
          )
        )
        
        set /a fileCount+=1
        echo Y|del "dump\*" > nul 2>nul
      )

      set url=
    )

    :skipThisLine
    echo yeah > nul
  )

  if "!value!" neq "" (
    if "!name!" == "Full Path         :" for %%f in ("!value!") do for %%j in ("%%~dpf.") do type nul > "!TEMP_FOLDER!%%~nxj%%~nxf"
    if "!name!" == "Cache Name        :" if "!value:~-1!" neq "]" type nul > "!TEMP_FOLDER!!value!"
    if "!CACHE_VIEW!" == "OperaCacheView" if "!name!" == "Filename          :" type nul > "!TEMP_FOLDER!!value:\=!"
  )

  if "!name!" == "Filename          :" set "filename=!value!"
  if "!name!" == "Content Encoding  :" set "encoding=!value!"
  if "!name!" == "Record Created Time" set "createDate=!value:~1!"
  if "!name!" == "Last Modified     :" set "createDate=!value!"
  if "!name!" == "Last Accessed     :" set "accessDate=!value!"

  if "!name!" == "File Size         :" (
    if "!value!" == "" (
      set "fileSize=0"
    ) else (
      for /f %%z in ('cscript /nologo "..\vbs\regex.vbs" "\D" "!value!" 2') do set "fileSize=%%z"
    )
  )

  exit /b 0

:main
  if exist !FILE_DATA! (
    for /f %%a in ('type !FILE_DATA!') do set /a fileCount+=1
  )
  
  for /f "tokens=* delims=" %%l in ('findstr /i /l /c:"/watch?" /c:"/videoplayback?" /c:"/get_video?" !CACHE_LIST!') do (
    for /f %%z in ('cscript /nologo "..\vbs\regex.vbs" "[\?&](?:video_id|id|v)=([\w-]{11}(?^![\w-])|[0-9a-f]{16}(?^![0-9a-f]))" "%%l" 0') do (
      for /f %%x in ('cscript /nologo "..\vbs\md5.vbs" "%%z"') do echo %%x>> "..\cached_ids.txt"
    )
  )

  start /wait "" "!CACHE_VIEW!.exe" -folder "!FOLDER!" /copycache "https://www.youtube.com/watch?" "" /CopyFilesFolder "watch_pages"
  pushd "watch_pages"
  for /f "tokens=* delims=" %%l in ('type "..\..\data\watch_page_data.txt"') do (
    for %%f in (*%%l*) do (
      for /f %%z in ('cscript /nologo "..\..\vbs\regex.vbs" "u0026id=(o-[\w-]{44})" "%%f" 1') do (
        echo %%z>> "..\..\data\asset_data.txt"
        echo %%l> "..\id_pairs\%%z"
      )
    )
  )
  
  popd
  echo Y|del "watch_pages\*" > nul
  
  findstr /i /l /g:"..\data\asset_data.txt" !CACHE_LIST! > "findstr_dump.txt"

  :: Limit dumped columns to exclusively relevant ones
  cscript /nologo "..\vbs\limit_cache_dump.vbs" "findstr_dump.txt" "fixed_history.txt"
  for /f "tokens=* delims=" %%l in ('type "fixed_history.txt"') do (
    set "temp=%%l"
    call :handleLine "%%temp%%"
  )

  :unusedCheck
  set unique_names=0

  for %%n in (%~1) do (
    if "%%n" == "mainpage_final+.swf" set unique_names=1

    set "ext=%%n"
    set "ext=!ext:+=*!"

    dir /o:d /a:-d /s /b "!FOLDER!!ext!" > "..\variables\tempdir.var" 2>nul
    for /f "tokens=* delims=" %%f in ('cscript /nologo "..\vbs\fixdir.vbs" "..\variables\tempdir.var"') do (
      set "thaName=%%~nxf"
      if "!thaName:~0,7!" neq "_CACHE_" if "!thaName!" neq "index" (
        if "!CACHE_VIEW!" == "IECacheView" (
          for %%j in ("%%~dpf.") do set "tempname=%%~nxj%%~nxf"
        ) else if "!CACHE_VIEW!" == "OperaCacheView" (
          if exist "!FOLDER!%%~nxf" (
            set "tempname=%%~nxf"
          ) else (
            for %%j in ("%%~dpf.") do set "tempname=%%~nxj%%~nxf"
          )
        ) else (
          set "tempname=%%~nxf"
        )

        if not exist "!TEMP_FOLDER!!tempname!" (
          if "!unique_names!" == "0" (
            echo %%f> "..\variables\exstorage.var"
            for /f "tokens=* delims=" %%c in ('cscript /nologo "..\vbs\cleanse_ex.vbs" "..\variables\exstorage.var" "0"') do set "fixedFile=%%c"
            echo !fixedFile!
          ) else (
            echo %%f> "..\variables\sizecheck.var"
            pushd ".."
            call "check_size.bat"
            popd

            echo "!fileCount! %%~nxf" >> !FILE_DATA!
            echo "!fileCount! %%f" >> "..\private_locations.txt"

            set "fixCopy1=%%f"
            set "fixCopy2=..\..\Verified\[!fileCount!]%%~nxf"
            call :fixCopy

            set /a fileCount+=1
          )
        )
      )
    )
  )

  echo Y|del "!TEMP_FOLDER!*" > nul