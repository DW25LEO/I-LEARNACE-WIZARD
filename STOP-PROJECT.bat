@echo off
setlocal EnableExtensions
for %%P in (5000 5175) do (
  for /f "tokens=5" %%A in ('netstat -ano ^| findstr /R /C:":%%P .*LISTENING"') do taskkill /PID %%A /F >nul 2>nul
)
endlocal
exit /b 0
