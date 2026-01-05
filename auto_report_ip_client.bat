@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
title RustDesk IP Auto Report

REM ============================================
REM RustDesk IP Auto Report Tool
REM Double-click to run
REM ============================================

SET SERVER_URL=http://34.96.199.184:8888/update-ip
SET SECRET_KEY=RDhHSjQoKjc0RUc3RFNLLi91cGRhdGUtcGhvbmVzLnNoQA==
SET IP_CACHE_FILE=%USERPROFILE%\.rustdesk_last_ip
SET LOG_FILE=%USERPROFILE%\.rustdesk_ip_report.log
SET TASK_NAME=RustDesk Auto IP Report

echo.
echo ============================================
echo    RustDesk IP Auto Report
echo    Computer: %COMPUTERNAME%
echo ============================================
echo.

REM Step 1: Get public IP
echo [Step 1] Getting public IP...
echo.

REM Try multiple sources - China-friendly
SET CURRENT_IP=

REM Source 1: ipify.org (returns plain IP)
for /f %%i in ('powershell -Command "try { $ip = (Invoke-WebRequest -Uri 'https://api.ipify.org' -UseBasicParsing -TimeoutSec 5).Content.Trim(); if($ip -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') { $ip } else { '' } } catch { '' }"') do set CURRENT_IP=%%i

REM Source 2: ip.sb (returns plain IP)
if "!CURRENT_IP!"=="" (
    echo Trying backup source 1...
    for /f %%i in ('powershell -Command "try { $ip = (Invoke-WebRequest -Uri 'https://api.ip.sb/ip' -UseBasicParsing -TimeoutSec 5).Content.Trim(); if($ip -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') { $ip } else { '' } } catch { '' }"') do set CURRENT_IP=%%i
)

REM Source 3: ipinfo.io (returns plain IP)
if "!CURRENT_IP!"=="" (
    echo Trying backup source 2...
    for /f %%i in ('powershell -Command "try { $ip = (Invoke-WebRequest -Uri 'https://ipinfo.io/ip' -UseBasicParsing -TimeoutSec 5).Content.Trim(); if($ip -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') { $ip } else { '' } } catch { '' }"') do set CURRENT_IP=%%i
)

REM Source 4: myip.ipip.net (returns text with IP)
if "!CURRENT_IP!"=="" (
    echo Trying backup source 3...
    for /f %%i in ('powershell -Command "try { $content = (Invoke-WebRequest -Uri 'https://myip.ipip.net' -UseBasicParsing -TimeoutSec 5).Content; if($content -match '(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})') { $matches[1] } else { '' } } catch { '' }"') do set CURRENT_IP=%%i
)

REM Source 5: cip.cc (returns text with IP)
if "!CURRENT_IP!"=="" (
    echo Trying backup source 4...
    for /f %%i in ('powershell -Command "try { $content = (Invoke-WebRequest -Uri 'https://cip.cc' -UseBasicParsing -TimeoutSec 5).Content; if($content -match 'IP\s*:\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})') { $matches[1] } else { '' } } catch { '' }"') do set CURRENT_IP=%%i
)

if "!CURRENT_IP!"=="" (
    echo [ERROR] Cannot get public IP from any source
    echo [%date% %time%] ERROR: Cannot get IP >> "%LOG_FILE%"
    goto END
)

REM Validate IP format
echo !CURRENT_IP! | findstr /R "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Invalid IP format: !CURRENT_IP!
    echo [%date% %time%] ERROR: Invalid IP format >> "%LOG_FILE%"
    goto END
)

echo Current IP: !CURRENT_IP!
echo.

REM Step 2: Check if IP changed
echo [Step 2] Checking IP change...
echo.

set IP_CHANGED=1
if exist "%IP_CACHE_FILE%" (
    set /p LAST_IP=<"%IP_CACHE_FILE%"
    if "!CURRENT_IP!"=="!LAST_IP!" (
        echo [INFO] IP unchanged, skip report
        echo [%date% %time%] IP unchanged: !CURRENT_IP! >> "%LOG_FILE%"
        set IP_CHANGED=0
        goto CHECK_TASK
    ) else (
        echo [DETECT] IP changed: !LAST_IP! -^> !CURRENT_IP!
    )
) else (
    echo [DETECT] First run, need to report
)

echo.

REM Step 3: Report IP to server
echo [Step 3] Reporting IP to server...
echo.

powershell -Command "$body = @{ip='!CURRENT_IP!';device_id='%COMPUTERNAME%';secret='%SECRET_KEY%'} | ConvertTo-Json; try { $response = Invoke-RestMethod -Uri '%SERVER_URL%' -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 15; if ($response.status -eq 'success') { Write-Host '[SUCCESS] IP reported!' -ForegroundColor Green; exit 0 } else { Write-Host '[FAILED] Server error: ' $response.error -ForegroundColor Red; exit 1 } } catch { Write-Host '[FAILED] Cannot connect: ' $_.Exception.Message -ForegroundColor Red; exit 1 }"

if %ERRORLEVEL% EQU 0 (
    echo !CURRENT_IP!> "%IP_CACHE_FILE%"
    echo [%date% %time%] IP reported: !CURRENT_IP! >> "%LOG_FILE%"
    echo.
    echo [OK] IP added to whitelist!
) else (
    echo [%date% %time%] Report failed >> "%LOG_FILE%"
    echo.
    echo [ERROR] Report failed, please check:
    echo    1. Server running: auto_update_ip_server.sh start
    echo    2. Network connection OK
    echo    3. Firewall allows port 8888
    goto END
)

echo.

:CHECK_TASK
REM Step 4: Check scheduled task
echo [Step 4] Checking scheduled task...
echo.

schtasks /query /tn "%TASK_NAME%" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Scheduled task exists
) else (
    echo Installing scheduled task...
    
    REM Create task XML
    set TASK_XML=%TEMP%\rustdesk_task.xml
    
    echo ^<?xml version="1.0" encoding="UTF-16"?^> > "%TASK_XML%"
    echo ^<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^> >> "%TASK_XML%"
    echo   ^<RegistrationInfo^> >> "%TASK_XML%"
    echo     ^<Description^>RustDesk Auto IP Report - Check every hour^</Description^> >> "%TASK_XML%"
    echo   ^</RegistrationInfo^> >> "%TASK_XML%"
    echo   ^<Triggers^> >> "%TASK_XML%"
    echo     ^<CalendarTrigger^> >> "%TASK_XML%"
    echo       ^<Repetition^> >> "%TASK_XML%"
    echo         ^<Interval^>PT1H^</Interval^> >> "%TASK_XML%"
    echo       ^</Repetition^> >> "%TASK_XML%"
    echo       ^<StartBoundary^>2025-01-01T00:00:00^</StartBoundary^> >> "%TASK_XML%"
    echo       ^<Enabled^>true^</Enabled^> >> "%TASK_XML%"
    echo       ^<ScheduleByDay^> >> "%TASK_XML%"
    echo         ^<DaysInterval^>1^</DaysInterval^> >> "%TASK_XML%"
    echo       ^</ScheduleByDay^> >> "%TASK_XML%"
    echo     ^</CalendarTrigger^> >> "%TASK_XML%"
    echo     ^<LogonTrigger^> >> "%TASK_XML%"
    echo       ^<Enabled^>true^</Enabled^> >> "%TASK_XML%"
    echo     ^</LogonTrigger^> >> "%TASK_XML%"
    echo   ^</Triggers^> >> "%TASK_XML%"
    echo   ^<Settings^> >> "%TASK_XML%"
    echo     ^<MultipleInstancesPolicy^>IgnoreNew^</MultipleInstancesPolicy^> >> "%TASK_XML%"
    echo     ^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^> >> "%TASK_XML%"
    echo     ^<StopIfGoingOnBatteries^>false^</StopIfGoingOnBatteries^> >> "%TASK_XML%"
    echo     ^<AllowHardTerminate^>true^</AllowHardTerminate^> >> "%TASK_XML%"
    echo     ^<StartWhenAvailable^>true^</StartWhenAvailable^> >> "%TASK_XML%"
    echo     ^<RunOnlyIfNetworkAvailable^>true^</RunOnlyIfNetworkAvailable^> >> "%TASK_XML%"
    echo     ^<AllowStartOnDemand^>true^</AllowStartOnDemand^> >> "%TASK_XML%"
    echo     ^<Enabled^>true^</Enabled^> >> "%TASK_XML%"
    echo     ^<Hidden^>false^</Hidden^> >> "%TASK_XML%"
    echo     ^<RunOnlyIfIdle^>false^</RunOnlyIfIdle^> >> "%TASK_XML%"
    echo     ^<WakeToRun^>false^</WakeToRun^> >> "%TASK_XML%"
    echo     ^<ExecutionTimeLimit^>PT1M^</ExecutionTimeLimit^> >> "%TASK_XML%"
    echo     ^<Priority^>7^</Priority^> >> "%TASK_XML%"
    echo   ^</Settings^> >> "%TASK_XML%"
    echo   ^<Actions Context="Author"^> >> "%TASK_XML%"
    echo     ^<Exec^> >> "%TASK_XML%"
    echo       ^<Command^>"%~f0"^</Command^> >> "%TASK_XML%"
    echo       ^<Arguments^>/silent^</Arguments^> >> "%TASK_XML%"
    echo     ^</Exec^> >> "%TASK_XML%"
    echo   ^</Actions^> >> "%TASK_XML%"
    echo ^</Task^> >> "%TASK_XML%"
    
    schtasks /create /tn "%TASK_NAME%" /xml "%TASK_XML%" /f >nul 2>&1
    
    if %ERRORLEVEL% EQU 0 (
        echo [SUCCESS] Task installed
        echo    - Check every hour
        echo    - Run on startup
        echo    - Only report when IP changes
        echo [%date% %time%] Task installed >> "%LOG_FILE%"
        del "%TASK_XML%" >nul 2>&1
    ) else (
        echo [INFO] Need admin rights to install task
        echo        Right-click and "Run as administrator"
        del "%TASK_XML%" >nul 2>&1
    )
)

echo.
echo ============================================
echo    Done!
echo    - Current IP: !CURRENT_IP!
echo    - Task: Check every hour
echo    - Log: %LOG_FILE%
echo ============================================
echo.

:END
REM Pause if not silent mode
if not "%1"=="/silent" (
    echo Press any key to close...
    pause >nul
)
