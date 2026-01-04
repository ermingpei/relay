@echo off
chcp 65001 >nul 2>&1
title RustDesk IP自动上报工具

REM ============================================
REM RustDesk IP自动上报工具 - 全自动版
REM 双击运行即可自动上报IP到服务器
REM ============================================

SET SERVER_URL=http://34.96.199.184:8888/update-ip
SET SECRET_KEY=RDhHSjQoKjc0RUc3RFNLLi91cGRhdGUtcGhvbmVzLnNoQA==
SET IP_CACHE_FILE=%USERPROFILE%\.rustdesk_last_ip
SET LOG_FILE=%USERPROFILE%\.rustdesk_ip_report.log
SET TASK_NAME=RustDesk Auto IP Report

echo.
echo ============================================
echo    RustDesk IP自动上报工具
echo    电脑名称: %COMPUTERNAME%
echo ============================================
echo.

REM 步骤1: 立即上报IP
echo [步骤1] 正在上报IP到服务器...
echo.

REM 获取公网IP
echo 正在获取公网IP...
for /f %%i in ('powershell -Command "(Invoke-WebRequest -Uri 'https://api.ipify.org' -UseBasicParsing -TimeoutSec 10).Content"') do set CURRENT_IP=%%i

if "%CURRENT_IP%"=="" (
    echo [错误] 无法获取公网IP，请检查网络连接
    goto END
)

echo 当前公网IP: %CURRENT_IP%
echo.

REM 检查IP是否变化
if exist "%IP_CACHE_FILE%" (
    set /p LAST_IP=<"%IP_CACHE_FILE%"
    if "%CURRENT_IP%"=="!LAST_IP!" (
        echo [提示] IP未变化，跳过上报
        goto CHECK_TASK
    )
)

REM 发送IP到服务器
echo 正在发送IP到服务器...
powershell -Command "$body = @{ip='%CURRENT_IP%';device_id='%COMPUTERNAME%';secret='%SECRET_KEY%'} | ConvertTo-Json; try { $response = Invoke-RestMethod -Uri '%SERVER_URL%' -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 15; if ($response.status -eq 'success') { Write-Host '[成功] IP已上报到服务器！' -ForegroundColor Green; exit 0 } else { Write-Host '[失败] 服务器返回错误: ' $response.error -ForegroundColor Red; exit 1 } } catch { Write-Host '[失败] 无法连接服务器: ' $_.Exception.Message -ForegroundColor Red; exit 1 }"

if %ERRORLEVEL% EQU 0 (
    echo %CURRENT_IP%> "%IP_CACHE_FILE%"
    echo [%date% %time%] IP上报成功: %CURRENT_IP% >> "%LOG_FILE%"
    echo.
    echo ✅ IP已成功添加到服务器白名单！
) else (
    echo [%date% %time%] IP上报失败 >> "%LOG_FILE%"
    echo.
    echo ❌ 上报失败，请检查：
    echo    1. 服务器是否运行了 auto_update_ip_server.sh start
    echo    2. 网络连接是否正常
    echo    3. 防火墙是否允许访问端口8888
    goto END
)

echo.

:CHECK_TASK
REM 步骤2: 检查并安装定时任务
echo [步骤2] 检查定时任务...
echo.

schtasks /query /tn "%TASK_NAME%" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [已安装] 定时任务已存在，每小时自动检查IP变化
) else (
    echo 正在安装定时任务...
    
    REM 创建定时任务XML配置
    set TASK_XML=%TEMP%\rustdesk_task.xml
    
    echo ^<?xml version="1.0" encoding="UTF-16"?^> > "%TASK_XML%"
    echo ^<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^> >> "%TASK_XML%"
    echo   ^<RegistrationInfo^> >> "%TASK_XML%"
    echo     ^<Description^>RustDesk自动IP上报 - 每小时检查IP变化^</Description^> >> "%TASK_XML%"
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
        echo [成功] 定时任务已安装
        echo        - 每小时自动检查IP变化
        echo        - 开机时自动运行
        echo        - 只在IP变化时上报
        echo [%date% %time%] 定时任务已安装 >> "%LOG_FILE%"
        del "%TASK_XML%" >nul 2>&1
    ) else (
        echo [提示] 需要管理员权限才能安装定时任务
        echo        请右键此文件，选择"以管理员身份运行"
        del "%TASK_XML%" >nul 2>&1
    )
)

echo.
echo ============================================
echo    完成！
echo    - 当前IP: %CURRENT_IP%
echo    - 定时任务: 每小时自动检查
echo    - 日志文件: %LOG_FILE%
echo ============================================
echo.

:END
REM 如果不是静默模式，暂停显示结果
if not "%1"=="/silent" (
    echo 按任意键关闭窗口...
    pause >nul
)
