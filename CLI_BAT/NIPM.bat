echo off
setlocal enableDelayedExpansion

set Major=255
set Minor=
set Update=

if not "%1" == "" (
   for /F "tokens=1,2,3 delims=. " %%a in ("%1") do (
      set Major=%%a
      set Minor=%%b
      set Update=%%c
   )
)

if "%Minor%"=="" (
   set Minor=9
)

if "%Update%"=="" (
   set Update=9
)

set StartDir=\\argo\ni\nipkg

REM Loop until we know StartDir exists and net use does not return an error 
:loop 

net use * /delete /yes
net use x: %StartDir% /user:amer\nitest nitest /persistent:no 

if not %errorlevel%==0 (
   REM Try the command without the user
   net use x: %StartDir% /persistent:no 
)

if not %errorlevel%==0 (
   REM We are still erroring, so wait 10 seconds and try the whole loop again
   ping -n 10 localhost>nul 
   GOTO loop
)

x:

cd Package Manager

for /F "tokens=1,2,3 delims=." %%a in ('DIR "*.*.*" /B /O:D /A:D') do (
   if "%Major%"=="" (
      SET VerNIPM=%%a.%%b.%%c
   ) else (
      if "%%a" LEQ "%Major%" (
         if "%%b" LEQ "%Minor%" (
            if "%%c" LEQ "%Update%" (
               SET VerNIPM=%%a.%%b.%%c
            )
         )
      )
   )
)

cd %VerNIPM%

FOR /F "delims=" %%D IN ('DIR "*.*" /B /O:D /A:D') DO SET BuildDir=%%D

if "%BuildDir%"=="meta-data" (
   echo Installing NI Package Manager %VerNIPM%
) else (
   cd %BuildDir%
   echo Installing NI Package Manager %BuildDir%
)

Install /Q
echo Done
setx PATH "%PATH%;C:\Program Files\National Instruments\NI Package Manager"

NIPackageManager --help
