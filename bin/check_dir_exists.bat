@echo off
setlocal enabledelayedexpansion

set /p UNKNOWN_DIR=<"variables\checkdir.var"

:: Get the error message of a nonexistent file
dir /b sindexmonfanclub\ >nul 2>"variables\errormsg.var"
set /p errorMsg=<"variables\errormsg.var"

dir /b "!UNKNOWN_DIR!\" >nul 2> "variables\unkdirlist.var"

if "!errorlevel!" == "0" (
  echo 1
) else for /f "tokens=* delims=" %%e in ('type "variables\unkdirlist.var"') do (
  if "%%e" neq "!errorMsg!" echo 2
  goto endDirCheck
)

:endDirCheck