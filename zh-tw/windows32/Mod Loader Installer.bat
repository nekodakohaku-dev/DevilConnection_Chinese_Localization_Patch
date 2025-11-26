@echo off
REM Change directory to the script's location
cd /d "%~dp0"

title [Devil Connection] Mod Loader Installer (HDiff Edition)
color 0F

REM ============================================================================
REM DevilConnection Mod Loader Installer
REM Created by: ShiroNeko
REM
REM This is a fan-made tool and is not affiliated with the original game developers.
REM Use this software at your own risk. The author is not responsible for any
REM damage to your game files or save data.
REM ============================================================================

REM ================= CONFIGURATION =================
set "GAME_ASAR=resources\app.asar"
set "BACKUP_ASAR=resources\app.asar.bak"
set "PATCH_FILE=patch.hdiff"
set "TOOL_EXE=hpatchz.exe"
set "LOADER_JS=Loader.js"
set "PLUGIN_DIR_TARGET=plugins"
REM =================================================

echo.
echo ==========================================================
echo       [Devil Connection] Mod Loader Installer
echo ==========================================================
echo.
echo  [1] Checking files...

REM 1. Check local files (Removed parentheses in echo to prevent syntax errors)
if exist "%TOOL_EXE%" (
    echo      [OK] Found patch tool: %TOOL_EXE%
) else (
    goto :ErrMissingTool
)

if exist "%PATCH_FILE%" (
    echo      [OK] Found patch data: %PATCH_FILE%
) else (
    goto :ErrMissingPatch
)

if exist "%LOADER_JS%" (
    echo      [OK] Found Loader.js
) else (
    goto :ErrMissingLoader
)

REM 2. Check game directory
if exist "%GAME_ASAR%" (
    echo      [OK] Game found.
) else (
    goto :ErrGameNotFound
)

REM 3. Backup Logic
echo.
echo  [2] Checking Backup...
if exist "%BACKUP_ASAR%" (
    echo      * Backup exists. Using it as source.
) else (
    echo      * Creating backup...
    copy "%GAME_ASAR%" "%BACKUP_ASAR%" > nul
    if errorlevel 1 goto :ErrBackup
)

REM 4. Apply HDiffPatch
echo.
echo  [3] Injecting Mod Loader (HDiff)...
REM Usage: hpatchz.exe -f [old] [diff] [new]
"%TOOL_EXE%" -f "%BACKUP_ASAR%" "%PATCH_FILE%" "%GAME_ASAR%"

if errorlevel 1 goto :ErrPatchFailed
echo      * Injection successful.

REM 5. Deploy Resources
echo.
echo  [4] Finalizing...
if not exist "%PLUGIN_DIR_TARGET%" (
    mkdir "%PLUGIN_DIR_TARGET%"
    echo      * Created plugins directory.
)

if exist "%LOADER_JS%" (
    copy /y "%LOADER_JS%" ".\" > nul
)

echo.
echo ==========================================================
echo  SUCCESS! Mod Loader installed.
echo ==========================================================
echo.
pause
exit /b

REM ================== ERROR HANDLERS ==================

:ErrMissingTool
echo.
echo  [ERROR] Missing %TOOL_EXE%.
pause
exit /b

:ErrMissingPatch
echo.
echo  [ERROR] Missing %PATCH_FILE%.
pause
exit /b

:ErrMissingLoader
echo.
echo  [ERROR] Missing Loader.js.
pause
exit /b

:ErrGameNotFound
echo.
echo  [ERROR] Game files not found!
echo  Please run this installer inside the game folder.
pause
exit /b

:ErrBackup
echo.
echo  [ERROR] Failed to backup files. Check permissions.
pause
exit /b

:ErrPatchFailed
echo.
echo  [ERROR] Patch failed!
echo  Possible causes:
echo  1. Game version mismatch.
echo  2. Corrupted patch file.
echo.
echo  Restoring backup...
copy /y "%BACKUP_ASAR%" "%GAME_ASAR%" > nul
pause
exit /b
