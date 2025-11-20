@echo off
setlocal EnableExtensions
cd /d "%~dp0"

:: ---------- 0) checks ----------
echo [Install]
where npx >nul 2>nul || (echo [ERR] npx not found & pause & exit /b 1)
if not exist "app.asar"   (echo [ERR] app.asar not found   & pause & exit /b 1)
if not exist "zh-tw.asar" (echo [ERR] zh-tw.asar not found & pause & exit /b 1)

:: ---------- 1) extract app.asar ----------
if not exist "_asar_app" mkdir "_asar_app"
"%ComSpec%" /d /c npx @electron/asar extract app.asar _asar_app

:: ---------- 2) extract zh-tw.asar ----------
if not exist "_asar_zh" mkdir "_asar_zh"
"%ComSpec%" /d /c npx @electron/asar extract zh-tw.asar _asar_zh

:: ---------- 3) cover ----------
attrib -R -S -H "_asar_app" /S /D >nul 2>&1
robocopy "_asar_zh" "_asar_app" /E /IS /IT /R:2 /W:1 /NFL /NDL /NJH /NJS /NP

:: ---------- 4) backup ----------
attrib -R -S -H "app.asar" >nul 2>&1
ren "app.asar" "app.asar.bak" 2>nul

:: ---------- 5) pack ----------
"%ComSpec%" /d /c npx @electron/asar pack _asar_app app.asar --unpack="*.node"

:: ---------- 6) cleanup ----------
if exist "_asar_app" (
  attrib -R -S -H "_asar_app" /S /D >nul 2>&1
  rmdir /s /q "_asar_app" >nul 2>&1
)
if exist "_asar_zh" (
  attrib -R -S -H "_asar_zh" /S /D >nul 2>&1
  rmdir /s /q "_asar_zh" >nul 2>&1
)

echo [Finish]
pause
exit /b 0
