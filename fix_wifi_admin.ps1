# Fix WiFi - Script chay voi quyen Admin
# Fix 1: NlaSvc (Network Location Awareness) - Thu pham chinh gay mat icon WiFi
Write-Host "[1/4] Chuyen NlaSvc sang Automatic..." -ForegroundColor Cyan
sc.exe config NlaSvc start= auto
Start-Service NlaSvc -ErrorAction SilentlyContinue
Write-Host "      OK!" -ForegroundColor Green

# Fix 2: Dam bao cac service mang khac
Write-Host "[2/4] Dam bao cac service mang khoi dong Automatic..." -ForegroundColor Cyan
sc.exe config Dhcp start= auto
sc.exe config Dnscache start= auto  
sc.exe config WlanSvc start= auto
sc.exe config nsi start= auto
Write-Host "      OK!" -ForegroundColor Green

# Fix 3: Tat Power Management cho WiFi adapter (khong cho Windows tat WiFi de tiet kiem pin)
Write-Host "[3/4] Tat Power Management cho WiFi adapter..." -ForegroundColor Cyan
$regBase = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
Get-ChildItem $regBase -ErrorAction SilentlyContinue | ForEach-Object {
    $desc = (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DriverDesc
    if ($desc -match "Realtek 8821CE") {
        # PnPCapabilities = 24 means: disable "Allow the computer to turn off this device to save power"
        Set-ItemProperty $_.PSPath -Name "PnPCapabilities" -Value 24 -Type DWord -ErrorAction SilentlyContinue
        Write-Host "      Da tat 'Allow computer to turn off this device' cho $desc" -ForegroundColor Green
    }
}

# Fix 4: Reset Winsock
Write-Host "[4/4] Reset Winsock..." -ForegroundColor Cyan
netsh winsock reset 2>$null | Out-Null
Write-Host "      OK!" -ForegroundColor Green

# Kiem tra ket qua
Write-Host ""
Write-Host "=== KET QUA ===" -ForegroundColor Yellow
$nlaSvc = Get-Service NlaSvc
Write-Host "NlaSvc Status: $($nlaSvc.Status), StartType: $($nlaSvc.StartType)" -ForegroundColor White

# Ghi ket qua ra file de kiem tra
$result = "NlaSvc StartType: $($nlaSvc.StartType), Status: $($nlaSvc.Status)"
$result | Out-File "D:\A_Tool_S_Automation\wifi_fix_result.txt" -Encoding UTF8

Write-Host ""
Write-Host "HOAN TAT! Hay KHOI DONG LAI MAY de ap dung day du." -ForegroundColor Green
Write-Host "Bam phim bat ky de dong..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
