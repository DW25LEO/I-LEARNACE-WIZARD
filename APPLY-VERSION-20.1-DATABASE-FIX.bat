@echo off
setlocal
cd /d "%~dp0"

if not exist "backend\.env" (
  echo backend\.env was not found.
  echo Run SETUP-PROJECT.bat first.
  pause
  exit /b 1
)

for /f "usebackq tokens=1,* delims==" %%A in ("backend\.env") do (
  if /I "%%A"=="MYSQL_HOST" set "MYSQL_HOST=%%B"
  if /I "%%A"=="MYSQL_PORT" set "MYSQL_PORT=%%B"
  if /I "%%A"=="MYSQL_USER" set "MYSQL_USER=%%B"
  if /I "%%A"=="MYSQL_PASSWORD" set "MYSQL_PASSWORD=%%B"
  if /I "%%A"=="MYSQL_DATABASE" set "MYSQL_DATABASE=%%B"
)
if "%MYSQL_HOST%"=="" set "MYSQL_HOST=127.0.0.1"
if "%MYSQL_PORT%"=="" set "MYSQL_PORT=3306"
if "%MYSQL_DATABASE%"=="" set "MYSQL_DATABASE=i_learnace_wizard"

where mysql >nul 2>nul
if errorlevel 1 (
  echo MySQL command was not found in PATH.
  echo Use RUN-I-LEARNACE-WIZARD.bat instead; it locates MySQL automatically.
  pause
  exit /b 1
)

echo Applying Version 20.1 database migrations...
for %%F in (database\schema\16_*.sql database\schema\17_*.sql database\schema\18_*.sql database\schema\19_*.sql) do (
  if exist "%%F" (
    echo Importing %%F
    mysql -h "%MYSQL_HOST%" -P %MYSQL_PORT% -u "%MYSQL_USER%" -p"%MYSQL_PASSWORD%" %MYSQL_DATABASE% < "%%F"
    if errorlevel 1 (
      echo Migration failed on %%F
      pause
      exit /b 1
    )
  )
)
echo.
echo Version 20.1 database fix completed successfully.
echo Restart the project using RUN-I-LEARNACE-WIZARD.bat.
pause
