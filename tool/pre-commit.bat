@echo off
:: Git on Windows 钩子:调 PowerShell 版
:: 启用:git config core.hooksPath tool
echo [pre-commit] running tool\pre-commit.ps1 ...
powershell -ExecutionPolicy Bypass -File "%~dp0pre-commit.ps1"
set RC=%ERRORLEVEL%
echo [pre-commit] exit %RC%
exit /b %RC%
