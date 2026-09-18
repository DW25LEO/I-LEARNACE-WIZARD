@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"

echo =====================================================
echo          I-LEARNACE WIZARD - ONE CLICK RUNNER
echo =====================================================
echo.
echo This single script handles first-time setup and normal startup.
echo It configures MySQL, installs packages when needed, starts the
 echo backend and frontend, verifies readiness, then opens the browser.
echo.

where node >nul 2>nul || (echo ERROR: Node.js is not installed or not in PATH.& pause & exit /b 1)
where npm >nul 2>nul || (echo ERROR: npm is not available.& pause & exit /b 1)

set "MYSQL_EXE=mysql"
where mysql >nul 2>nul || (
  if exist "%ProgramFiles%\MySQL\MySQL Server 8.0\bin\mysql.exe" set "MYSQL_EXE=%ProgramFiles%\MySQL\MySQL Server 8.0\bin\mysql.exe"
  if not exist "%MYSQL_EXE%" if exist "C:\xampp\mysql\bin\mysql.exe" set "MYSQL_EXE=C:\xampp\mysql\bin\mysql.exe"
)
"%MYSQL_EXE%" --version >nul 2>nul || (echo ERROR: MySQL client was not found. Add MySQL bin to PATH or install MySQL.& pause & exit /b 1)

if not exist "backend\.env" goto :first_setup
if not exist "frontend\.env" goto :first_setup
goto :install_and_start

:first_setup
echo FIRST-TIME SETUP
set /p MYSQL_HOST=MySQL host [localhost]: 
if "%MYSQL_HOST%"=="" set "MYSQL_HOST=localhost"
set /p MYSQL_PORT=MySQL port [3306]: 
if "%MYSQL_PORT%"=="" set "MYSQL_PORT=3306"
set /p MYSQL_USER=MySQL username [root]: 
if "%MYSQL_USER%"=="" set "MYSQL_USER=root"
set "MYSQL_DATABASE=i_learnace_wizard"
set /p MYSQL_PASSWORD=Enter MySQL password: 
if "%MYSQL_PASSWORD%"=="" (echo ERROR: MySQL password cannot be empty.& pause & exit /b 1)

set "INITIAL_SUPER_ADMIN_EMAIL=i-learnace@gmail.com"
set /p INITIAL_SUPER_ADMIN_PASSWORD=Enter I-LEARNACE Wizard Super Admin password: 
if "%INITIAL_SUPER_ADMIN_PASSWORD%"=="" (echo ERROR: Super Admin password cannot be empty.& pause & exit /b 1)

set "JWT_SECRET=I_LEARNACE_WIZARD_LOCAL_%RANDOM%%RANDOM%%RANDOM%%RANDOM%"

> backend\.env echo PORT=5000
>> backend\.env echo FRONTEND_URL=http://localhost:5175,http://127.0.0.1:5175
>> backend\.env echo MYSQL_HOST=%MYSQL_HOST%
>> backend\.env echo MYSQL_PORT=%MYSQL_PORT%
>> backend\.env echo MYSQL_USER=%MYSQL_USER%
>> backend\.env echo MYSQL_PASSWORD=%MYSQL_PASSWORD%
>> backend\.env echo MYSQL_DATABASE=%MYSQL_DATABASE%
>> backend\.env echo JWT_SECRET=%JWT_SECRET%
>> backend\.env echo INITIAL_SUPER_ADMIN_EMAIL=%INITIAL_SUPER_ADMIN_EMAIL%
>> backend\.env echo INITIAL_SUPER_ADMIN_PASSWORD=%INITIAL_SUPER_ADMIN_PASSWORD%

> frontend\.env echo VITE_API_URL=http://127.0.0.1:5000/api

echo MySQL configuration saved locally. Continuing setup...

:install_and_start
if not exist "backend\node_modules" (
  echo [1/6] Installing backend packages...
  call npm --prefix backend install
  if errorlevel 1 goto :error
) else echo [1/6] Backend packages already installed.

if not exist "frontend\node_modules" (
  echo [2/6] Installing frontend packages...
  call npm --prefix frontend install
  if errorlevel 1 goto :error
) else echo [2/6] Frontend packages already installed.

echo [3/6] Checking MySQL connection and database...
for /f "usebackq tokens=1,* delims==" %%A in ("backend\.env") do (
  if /I "%%A"=="MYSQL_HOST" set "MYSQL_HOST=%%B"
  if /I "%%A"=="MYSQL_PORT" set "MYSQL_PORT=%%B"
  if /I "%%A"=="MYSQL_USER" set "MYSQL_USER=%%B"
  if /I "%%A"=="MYSQL_PASSWORD" set "MYSQL_PASSWORD=%%B"
  if /I "%%A"=="MYSQL_DATABASE" set "MYSQL_DATABASE=%%B"
)

"%MYSQL_EXE%" -h "%MYSQL_HOST%" -P %MYSQL_PORT% -u "%MYSQL_USER%" -p"%MYSQL_PASSWORD%" -e "SELECT 1;" >nul 2>nul
if errorlevel 1 (
  echo MySQL is not ready. Trying common Windows MySQL services...
  net start MySQL80 >nul 2>nul
  net start MySQL >nul 2>nul
  timeout /t 2 /nobreak >nul
  "%MYSQL_EXE%" -h "%MYSQL_HOST%" -P %MYSQL_PORT% -u "%MYSQL_USER%" -p"%MYSQL_PASSWORD%" -e "SELECT 1;" >nul 2>nul
  if errorlevel 1 goto :db_error
)

"%MYSQL_EXE%" -h "%MYSQL_HOST%" -P %MYSQL_PORT% -u "%MYSQL_USER%" -p"%MYSQL_PASSWORD%" -e "CREATE DATABASE IF NOT EXISTS %MYSQL_DATABASE%;"
if errorlevel 1 goto :db_error

echo Checking required database tables...
set "NEED_SCHEMA="
for %%T in (schools school_applications users portal_templates) do (
  "%MYSQL_EXE%" -h "%MYSQL_HOST%" -P %MYSQL_PORT% -u "%MYSQL_USER%" -p"%MYSQL_PASSWORD%" -N -s -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='%MYSQL_DATABASE%' AND table_name='%%T';" | findstr /R "^[1-9]" >nul || set "NEED_SCHEMA=YES"
)
if defined NEED_SCHEMA (
  echo [4/6] Required tables are missing. Repairing database schema...
  for %%F in (database\schema\01_*.sql database\schema\02_*.sql database\schema\03_*.sql database\schema\04_*.sql database\schema\05_*.sql database\schema\06_*.sql database\schema\07_*.sql database\schema\08_*.sql database\schema\09_*.sql database\schema\10_*.sql database\schema\11_*.sql database\schema\12_*.sql database\schema\13_*.sql database\schema\14_*.sql database\schema\15_*.sql database\schema\16_*.sql database\schema\17_*.sql database\schema\18_*.sql database\schema\19_*.sql) do (
    if exist "%%F" (
      echo Importing %%F into %MYSQL_DATABASE%
      "%MYSQL_EXE%" -h "%MYSQL_HOST%" -P %MYSQL_PORT% -u "%MYSQL_USER%" -p"%MYSQL_PASSWORD%" %MYSQL_DATABASE% < "%%F"
      if errorlevel 1 goto :db_error
    )
  )
  call npm --prefix backend run create:super-admin
  if errorlevel 1 goto :error
  > .wizard-initialized echo initialized
) else (
  echo [4/6] Required database tables found.
)

REM Always apply Phase 17+ idempotent provisioning migrations, including upgrades to an existing local database.
echo Applying all Version 20.1 idempotent schema updates...
for %%F in (database\schema\12_*.sql database\schema\13_*.sql database\schema\14_*.sql database\schema\15_*.sql database\schema\16_*.sql database\schema\17_*.sql database\schema\18_*.sql database\schema\19_*.sql) do (
  if exist "%%F" (
    echo Importing %%F
    "%MYSQL_EXE%" -h "%MYSQL_HOST%" -P %MYSQL_PORT% -u "%MYSQL_USER%" -p"%MYSQL_PASSWORD%" %MYSQL_DATABASE% < "%%F"
    if errorlevel 1 goto :db_error
  )
)

echo [5/6] Stopping old project processes and starting fresh services...
call STOP-PROJECT.bat >nul 2>nul
start "I-LEARNACE WIZARD BACKEND" /D "%CD%\backend" cmd /k npm run dev
timeout /t 2 /nobreak >nul
start "I-LEARNACE WIZARD FRONTEND" /D "%CD%\frontend" cmd /k npm run dev -- --port 5175 --host 127.0.0.1

echo [6/6] Waiting for database-backed API readiness...
set "READY="
for /L %%A in (1,1,15) do (
  powershell -NoProfile -Command "try { $r=Invoke-WebRequest -UseBasicParsing http://127.0.0.1:5000/api/system/ready -TimeoutSec 2; if($r.StatusCode -eq 200){exit 0}else{exit 1} } catch { exit 1 }"
  if not errorlevel 1 set "READY=YES"
  if defined READY goto :openbrowser
  timeout /t 1 /nobreak >nul
)

echo WARNING: Backend readiness check failed. Check the backend window for the exact error.
goto :finish

:openbrowser
start "" http://127.0.0.1:5175

:finish
echo.
echo =====================================================
echo Frontend: http://127.0.0.1:5175
echo Backend:  http://127.0.0.1:5000/api/health
echo =====================================================
echo Keep the backend and frontend windows open while using the project.
pause
exit /b 0

:db_error
echo.
echo DATABASE/SCHEMA ERROR: Setup could not complete.
echo MySQL credentials may be correct; check the error immediately above for the exact failing schema file.
pause
exit /b 1

:error
echo.
echo SETUP ERROR: Read the error above.
pause
exit /b 1
