@echo off
mode con: cols=38 lines=12
SETLOCAL enabledelayedexpansion
chcp 65001 >nul
color 02
set "inet=2"
set "server=google.com"
set "subfolder=logs"
set min_ping=
set max_ping=
call :GetDateTime
set "startedTime=!currentTime!"
call :LogToFile "--------------------------------------"
call :LogToFile "-----===  Started monitoring  ===-----"
call :LogToFile "-----=== !currentDate!  !currentTime! ===-----"

:main
    call :CheckConnection
    if %pingResult% neq 1 (
        color 02
        set "status= ✓  Connected"
        call :Pinging
        if %inet% equ 0 (
            set "inet=1"
            call :GetDateTime
            set "startedTime=!currentTime!"
            call :LogToFile "!currentDate! (!currentTime!) - Connection restored. Downtime: !downtime!"
        )
    )
    if %pingResult% neq 0 (
        color 04
        set "status= ✗  Disconnected"

        set "avg_ping=off"
        if %inet% neq 0 (
            set "inet=0"
            call :GetDateTime
            set "startedTime=!currentTime!"
            call :LogToFile "!currentDate! (!currentTime!) - Connection lost"
        )
    )
    call :GetDateTime
    call :CalculateDowntime !startedTime! !currentTime!
    call :DisplayInfo
    timeout /nobreak /t 1 >nul 2>&1
goto main

ENDLOCAL
goto :eof


rem ----- FUNCTIONS -----

:CheckConnection
    ping -n 1 %server% >nul
    set "pingResult=%errorlevel%"
    goto :eof

:LogToFile
    SETLOCAL enabledelayedexpansion
    for /F "tokens=1-3 delims=-" %%a in ("%date%") do set "currDay=%%a-%%b-%%c"
    set "scriptDir=%~dp0..\"
    set "filename=.log"
    set "logfile=%scriptDir%%subfolder%\%currDay%%filename%"

    echo %~1 >> "%logfile%"
    ENDLOCAL
    goto :eof

:GetDateTime
    for /f "tokens=1-2 delims= " %%a in ('echo %date% %time%') do (
        set "currentDate=%%a"
        set "currentTime=%%b"
    )
    set "currentTime=!currentTime:~0,8!"
    goto :eof

:CalculateDowntime

    set "startTimeRaw=%~1"
    set "endTimeRaw=%~2"

    set "startHour=%startTimeRaw:~0,2%"
    set "startMinute=%startTimeRaw:~3,2%"
    set "startSecond=%startTimeRaw:~6,2%"

    set "endHour=%endTimeRaw:~0,2%"
    set "endMinute=%endTimeRaw:~3,2%"
    set "endSecond=%endTimeRaw:~6,2%"

    set /a startHour=10!startHour! %% 100
    set /a startMinute=10!startMinute! %% 100
    set /a startSecond=10!startSecond! %% 100

    set /a endHour=10!endHour! %% 100
    set /a endMinute=10!endMinute! %% 100
    set /a endSecond=10!endSecond! %% 100

    set /a startTime=startHour*3600 + startMinute*60 + startSecond
    set /a endTime=endHour*3600 + endMinute*60 + endSecond

    set /a duration=endTime - startTime
    if !duration! lss 0 set /a duration+=86400

    set /a hours=duration / 3600
    set /a minutes=(duration %% 3600) / 60
    set /a seconds=duration %% 60

    if !hours! lss 10 set "hours=0!hours!"
    if !minutes! lss 10 set "minutes=0!minutes!"
    if !seconds! lss 10 set "seconds=0!seconds!"

    set "downtime=!hours!:!minutes!:!seconds!"
    goto :eof

:Pinging
    for /f "tokens=6 delims== " %%a in ('ping -n 1 %server% ^| find "Average"') do set avg_ping=%%a
    set "ping_time=!avg_ping:ms=!"
    if not defined min_ping (set min_ping=!ping_time!)
    if not defined max_ping (set max_ping=!ping_time!)
    if !ping_time! gtr !max_ping! set max_ping=!ping_time!
    if !ping_time! lss !min_ping! set min_ping=!ping_time!
    goto :eof

:DisplayInfo
    cls
    echo  ____________________________________
    echo ^|                                    ^|
    echo ^|        N E T   M O N I T O R       ^|
    echo ^|            by Pozytron             ^|
    echo ^|____________________________________^|
    echo.
    echo   [ STATUS ] : !status!
    echo   [ UPTIME ] :  !downtime!
    echo   [ SERVER ] :  !server!
    echo   [ PING   ] :  !avg_ping!
    echo   [ MIN/MAX] :  !min_ping!ms / !max_ping!ms
    rem echo [Current Uptime] : !downtime!
    rem echo [Prev. Downtime] : !downtime!
    goto :eof