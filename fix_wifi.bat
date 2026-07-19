@echo off
title == FIX WIFI - Chay voi quyen Admin ==
color 0B

:: Kiem tra quyen Admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Can quyen Administrator. Dang tu nang cap...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ============================================================
echo    FIX WIFI - Sua loi mat icon WiFi va ket noi cham
echo    Laptop: Realtek 8821CE Wireless LAN 802.11ac
echo ============================================================
echo.

:: ==========================================
:: FIX 1: Service NlaSvc (Network Location Awareness) dang de Manual
:: Day la nguyen nhan CHINH khien icon WiFi mat/cham xuat hien
:: NlaSvc chiu trach nhiem hien thi icon mang tren taskbar
:: ==========================================
echo [1/6] Chuyen NlaSvc (Network Location Awareness) sang Automatic...
sc config NlaSvc start= auto
net start NlaSvc 2>nul
echo      OK!
echo.

:: ==========================================
:: FIX 2: Dam bao cac service mang khac khoi dong dung
:: ==========================================
echo [2/6] Dam bao cac service mang core khoi dong Automatic...
sc config Dhcp start= auto
sc config Dnscache start= auto
sc config WlanSvc start= auto
sc config nsi start= auto
sc config EventSystem start= auto
echo      OK!
echo.

:: ==========================================
:: FIX 3: Tat Power Management cua WiFi adapter
:: Windows co the tat WiFi de tiet kiem pin, gay cham ket noi khi mo may
:: ==========================================
echo [3/6] Tat Power Management cho WiFi adapter...
powershell -Command "Get-PnpDevice | Where-Object { $_.FriendlyName -match 'Realtek 8821CE' } | ForEach-Object { $instanceId = $_.InstanceId; $path = 'HKLM:\SYSTEM\CurrentControlSet\Enum\' + $instanceId + '\Device Parameters\Power'; if (Test-Path $path) { Set-ItemProperty -Path $path -Name 'DefaultPowerSchemeIndex' -Value 0 -ErrorAction SilentlyContinue }; $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $key -ErrorAction SilentlyContinue | ForEach-Object { $desc = (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DriverDesc; if ($desc -match 'Realtek 8821CE') { Set-ItemProperty $_.PSPath -Name 'PnPCapabilities' -Value 24 -Type DWord -ErrorAction SilentlyContinue; Write-Host '      Da tat Allow computer to turn off this device' } } }"
echo      OK!
echo.

:: ==========================================
:: FIX 4: Reset Winsock va TCP/IP stack
:: Sua loi corruption trong network stack
:: ==========================================
echo [4/6] Reset Winsock va TCP/IP stack...
netsh winsock reset >nul 2>&1
netsh int ip reset >nul 2>&1
echo      OK!
echo.

:: ==========================================
:: FIX 5: Xoa DNS cache va gia han DHCP
:: ==========================================
echo [5/6] Xoa DNS cache va gia han DHCP...
ipconfig /flushdns >nul 2>&1
ipconfig /release >nul 2>&1
ipconfig /renew >nul 2>&1
echo      OK!
echo.

:: ==========================================
:: FIX 6: Restart WiFi adapter de ap dung thay doi
:: ==========================================
echo [6/6] Restart WiFi adapter...
netsh interface set interface "Wi-Fi 2" disable
timeout /t 3 /nobreak >nul
netsh interface set interface "Wi-Fi 2" enable
timeout /t 5 /nobreak >nul
echo      OK!
echo.

echo ============================================================
echo    HOAN TAT! Tat ca cac fix da duoc ap dung.
echo.
echo    Nhung gi da sua:
echo    [v] NlaSvc chuyen tu Manual sang Automatic (fix icon WiFi)
echo    [v] Dam bao cac service mang khoi dong tu dong
echo    [v] Tat Power Management cho WiFi adapter
echo    [v] Reset Winsock va TCP/IP stack
echo    [v] Lam moi DNS va DHCP
echo    [v] Restart WiFi adapter
echo.
echo    >> HAY KHOI DONG LAI MAY DE AP DUNG DAY DU! <<
echo ============================================================
echo.
pause
