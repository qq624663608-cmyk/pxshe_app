@echo off
:: Git on Windows 钩子:调 PowerShell 版
:: 启用:git config core.hooksPath tool
powershell -ExecutionPolicy Bypass -File "%~dp0pre-commit.ps1"
exit /b %ERRORLEVEL%
