@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

REM -------------------------------
REM Config
REM -------------------------------
set "CSProj=C:\Users\Chaos\RiderProjects\GhostInTheCodeLogo\GhostInTheCodeLogo.csproj"

if not exist "%CSProj%" (
    echo ERROR: Project file not found: "%CSProj%"
    exit /b 1
)

set "CONFIG=%1"
if "%CONFIG%"=="" set "CONFIG=Release"

if /I "%CONFIG%"=="Release" (
    set "OUTPUT_DIR=%~dp0GITHUB RELEASE"
) else (
    set "OUTPUT_DIR=%~dp0GITHUB PRERELEASE"
)

REM Normalize full path
for %%I in ("%OUTPUT_DIR%") do set "OUTPUT_DIR=%%~fI"

REM -------------------------------
REM Clean output root safely
REM -------------------------------
if exist "%OUTPUT_DIR%" rd /s /q "%OUTPUT_DIR%"
mkdir "%OUTPUT_DIR%"

mkdir "%OUTPUT_DIR%\NET"

set "TMP_ROOT=%OUTPUT_DIR%\_tmp"
mkdir "%TMP_ROOT%"

REM -------------------------------
REM Read TargetFrameworks
REM -------------------------------
set "TFs="
for /f "usebackq tokens=*" %%A in (`type "%CSProj%" ^| findstr "<TargetFrameworks>"`) do (
    set "line=%%A"
    set "line=!line:<TargetFrameworks>=!"
    set "line=!line:</TargetFrameworks>=!"
    set "line=!line:;= !"
    for %%B in (!line!) do set "TFs=!TFs! %%B"
)
set "TFs=!TFs:~1!"

REM -------------------------------
REM Read RuntimeIdentifiers
REM -------------------------------
set "RIDs="
for /f "usebackq tokens=*" %%A in (`type "%CSProj%" ^| findstr "<RuntimeIdentifiers>"`) do (
    set "line=%%A"
    set "line=!line:<RuntimeIdentifiers>=!"
    set "line=!line:</RuntimeIdentifiers>=!"
    set "line=!line:;= !"
    for %%B in (!line!) do set "RIDs=!RIDs! %%B"
)
set "RIDs=!RIDs:~1!"

if "!TFs!"=="" set "TFs=net6.0"
if "!RIDs!"=="" set "RIDs=win-x64"

echo TargetFrameworks: !TFs!
echo RuntimeIdentifiers: !RIDs!

REM -------------------------------
REM Build Loop
REM -------------------------------
for %%F in (!TFs!) do (
    for %%R in (!RIDs!) do (

        set "TF_NAME=%%F"
        set "RID_FLAT=%%R"
        set "OUT=!TMP_ROOT!\!TF_NAME!-!RID_FLAT!"

        if exist "!OUT!" rd /s /q "!OUT!"
        mkdir "!OUT!"

        echo Publishing NET: %%F / %%R
        dotnet publish "%CSProj%" -c "%CONFIG%" -f "%%F" -r "%%R" ^ -o "!OUT!" -p:NoWarn=CS0618 || echo Failed %%F/%%R
        copy /Y "C:\Users\Chaos\RiderProjects\GhostInTheCodeLogo\LICENSE.md" "!OUT!\LICENSE.md"
        copy /Y "C:\Users\Chaos\RiderProjects\GhostInTheCodeLogo\README.md" "!OUT!\README.md"
        set "ZIP_OUT=%OUTPUT_DIR%\NET\!TF_NAME!-!RID_FLAT!.zip"

        powershell -NoProfile -Command ^ "Compress-Archive -Path '!OUT!\*' -DestinationPath '!ZIP_OUT!' -Force"

        rd /s /q "!OUT!"
    )
)

REM Remove temp root completely
rd /s /q "%TMP_ROOT%"

echo.
echo Build completed! Artifacts in:
echo %OUTPUT_DIR%

ENDLOCAL