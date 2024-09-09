@echo off
setlocal enabledelayedexpansion

:: Получение текущей даты в формате YYYYMMDD
for /F "tokens=1-3 delims=-" %%a in ("%date%") do set "currDay=%%a-%%b-%%c"
set "scriptDir=%~dp0"
set "filename=.log"
set "logfile=%scriptDir%%currDay%%filename%"
echo Script started

:loop
    echo Pinging google.com...
    ping -n 1 google.com >nul
    set "pingResult=%errorlevel%"
    echo Ping result: %pingResult%

    if %pingResult% neq 0 (
        echo Internet connection lost, logging...

        call :GetDateTime
        set "lostDate=!currentDate!"
        set "lostTime=!currentTime!"

        set "logEntry=!lostDate! (!lostTime!) - Internet connection lost"
        echo !logEntry! >> "%logfile%"
        echo Logged internet loss time: !logEntry!
        goto wait_for_internet
    )

    timeout /nobreak /t 1 >nul 2>&1

    rem choice /c QN /n /t 1 /d N >nul
    if %errorlevel% equ 1 goto end

    goto loop

:wait_for_internet
    echo Waiting for internet connection to be restored...
    :wait_loop
        ping -n 1 google.com >nul
        set "pingResult=%errorlevel%"
        if %pingResult% neq 0 (
            echo No internet connection, continuing to wait...
            timeout /nobreak /t 1 >nul 2>&1
            goto wait_loop
        ) else (
            echo Internet connection restored, logging...
            call :GetDateTime
            call :CalculateDowntime !lostTime! !currentTime!
            set "logEntry=!currentDate! (!currentTime!) - Internet connection restored. Downtime: !downtime!"
            echo !logEntry! >> "%logfile%"
        )
    timeout /nobreak /t 1 >nul 2>&1

    if %errorlevel% equ 1 goto end
    goto loop

:end
    endlocal
    pause
    goto :eof

:GetDateTime
    for /f "tokens=1-2 delims= " %%a in ('echo %date% %time%') do (
        set "currentDate=%%a"
        set "currentTime=%%b"
    )
    set "currentTime=!currentTime:~0,8!"
    echo [DEBUG] Date: !currentDate!, Time: !currentTime!
    goto :eof

:CalculateDowntime
    echo [DEBUG] Start Time: "%~1", End Time: "%~2"

    :: Удаление кавычек и извлечение подстрок
    set "startTimeRaw=%~1"
    set "endTimeRaw=%~2"

    set "startHour=%startTimeRaw:~0,2%"
    set "startMinute=%startTimeRaw:~3,2%"
    set "startSecond=%startTimeRaw:~6,2%"

    set "endHour=%endTimeRaw:~0,2%"
    set "endMinute=%endTimeRaw:~3,2%"
    set "endSecond=%endTimeRaw:~6,2%"

    echo [DEBUG] startHour: !startHour!, startMinute: !startMinute!, startSecond: !startSecond!
    echo [DEBUG] endHour: !endHour!, endMinute: !endMinute!, endSecond: !endSecond!

    :: Преобразование в числа без ведущих нулей
    set /a startHour=10!startHour! %% 100
    set /a startMinute=10!startMinute! %% 100
    set /a startSecond=10!startSecond! %% 100

    set /a endHour=10!endHour! %% 100
    set /a endMinute=10!endMinute! %% 100
    set /a endSecond=10!endSecond! %% 100

    echo [DEBUG] startHour: !startHour!, startMinute: !startMinute!, startSecond: !startSecond!
    echo [DEBUG] endHour: !endHour!, endMinute: !endMinute!, endSecond: !endSecond!

    :: Преобразование времени в секунды
    set /a startTime=startHour*3600 + startMinute*60 + startSecond
    set /a endTime=endHour*3600 + endMinute*60 + endSecond

    echo [DEBUG] startTime: !startTime!, endTime: !endTime!

    :: Вычисление длительности
    set /a duration=endTime - startTime
    if !duration! lss 0 set /a duration+=86400

    echo [DEBUG] Duration in seconds: !duration!

    :: Преобразование длительности в часы:минуты:секунды
    set /a hours=duration / 3600
    set /a minutes=(duration %% 3600) / 60
    set /a seconds=duration %% 60

    if !hours! lss 10 set "hours=0!hours!"
    if !minutes! lss 10 set "minutes=0!minutes!"
    if !seconds! lss 10 set "seconds=0!seconds!"

    set "downtime=!hours!:!minutes!:!seconds!"

    echo [DEBUG] Calculated Downtime: !downtime!
    goto :eof
