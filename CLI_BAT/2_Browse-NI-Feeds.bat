@echo off
REM Browse and List Available NI Feeds
REM This script helps you discover available feeds on the network

echo ======================================================================
echo NI Package Feed Browser
echo ======================================================================
echo.

SET StartDir=\\argo\ni\nipkg
REM Loop until we know StartDir exists and net use does not return an error 
:loop 

net use x: /delete /yes
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

echo Connected to X: drive
echo.

goto Menu

REM Ask what to browse

:ListAll
echo.
echo ======================================================================
echo Scanning for all available feeds...
echo ======================================================================
echo.
for /D %%C in (X:\feeds\*) do (
    for /D %%P in (%%C\*) do (
        for /D %%V in (%%P\*) do (
            for /D %%B in (%%V\*) do (
                if exist "%%B\Packages.txt" (
                    echo Found: %%B
                )
            )
        )
    )
)
echo.
echo Scan complete!
echo.
echo Press any key to return to menu...
pause >nul
goto Menu

:BrowseCategory
echo.
echo Available product categories:
echo.
dir X:\feeds /B /A:D
echo.
SET /P CATEGORY="Enter category folder name (e.g., ni-b, ni-s, ni-5): "
if not exist "X:\feeds\%CATEGORY%" (
    echo Category not found!
    goto Menu
)
echo.
echo Products in %CATEGORY%:
echo.
for /D %%P in (X:\feeds\%CATEGORY%\*) do (
    echo   %%~nxP
    for /D %%V in (%%P\*) do (
        for /D %%B in (%%V\*) do (
            if exist "%%B\Packages.txt" (
                echo     - %%B
            )
        )
    )
)
echo.
echo Press any key to return to menu...
pause >nul
goto Menu

:SearchProduct
echo.
SET /P SEARCH="Enter product name to search for: "
echo.
echo Searching for products containing '%SEARCH%'...
echo.
for /D %%C in (X:\feeds\*) do (
    for /D %%P in (%%C\*%SEARCH%*) do (
        echo Found in %%C:
        echo   %%~nxP
        for /D %%V in (%%P\*) do (
            for /D %%B in (%%V\*) do (
                if exist "%%B\Packages.txt" (
                    echo     Version: %%B
                )
            )
        )
        echo.
    )
)
echo.
echo Press any key to return to menu...
pause >nul
goto Menu

:GenerateFile
echo.
echo Generating feeds.txt file with all discovered feeds...
echo.
SET "OUTPUT_FILE=%~dp0feeds_discovered.txt"
echo # Auto-generated feed list > "%OUTPUT_FILE%"
echo # Generated on %DATE% at %TIME% >> "%OUTPUT_FILE%"
echo # >> "%OUTPUT_FILE%"

SET COUNT=0
for /D %%C in (X:\feeds\*) do (
    for /D %%P in (%%C\*) do (
        for /D %%V in (%%P\*) do (
            for /D %%B in (%%V\*) do (
                if exist "%%B\Packages.txt" (
                    echo %%B>> "%OUTPUT_FILE%"
                    SET /A COUNT+=1
                )
            )
        )
    )
)

echo.
echo Generated feeds_discovered.txt with %COUNT% feeds!
echo File location: %OUTPUT_FILE%
echo.
echo You can review and copy entries to feeds.txt
echo.
echo Press any key to open file and return to menu...
pause >nul
start notepad "%OUTPUT_FILE%"
goto Menu

:Menu
echo.
echo What would you like to do?
echo   1. List all available feeds (auto-discover)
echo   2. Browse by product category
echo   3. Search for a specific product
echo   4. Generate feeds.txt file with all feeds
echo   5. Exit
echo.
SET /P CHOICE="Enter your choice (1-5): "

if "%CHOICE%"=="1" goto ListAll
if "%CHOICE%"=="2" goto BrowseCategory
if "%CHOICE%"=="3" goto SearchProduct
if "%CHOICE%"=="4" goto GenerateFile
if "%CHOICE%"=="5" goto End
goto Menu

:End
net use x: /delete /yes >nul 2>&1
echo Goodbye!
exit /b 0
