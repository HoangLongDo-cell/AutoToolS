#NoEnv
SetWorkingDir %A_ScriptDir%
SendMode Input
SetTitleMatchMode, 2 ; Cho phép tìm một phần tên cửa sổ thay vì tên đầy đủ

; ====================================================================
; CẤU HÌNH TÊN PROFILE VÀ ĐƯỜNG DẪN - BẠN HÃY CHỈNH SỬA Ở ĐÂY
; ====================================================================
EdgeProfileLong    := "Default"      ; Profile Edge của Long
ChromeProfileLong  := "Default"      ; Profile Chrome của Long (để mở GPTs)
ChromeProfileDuong := "Profile 24"   ; Profile Chrome của Dương
ChromeProfileThao  := "Profile 2"    ; Profile Chrome của Thảo
ChromeProfileMess  := "Default"      ; Profile Chrome của Chữa mess
ToolAPath          := A_ScriptDir . "\Tool_A\run.bat"  ; Đường dẫn chạy Tool A
GptsUrl            := "https://chatgpt.com/g/g-6a596a1268cc81919a9e75265771bea9-chua-wt"          ; Link mở GPTs
; ====================================================================

IniRead, WorkerMode, %A_ScriptDir%\settings.ini, Settings, worker_mode, 2


; Hàm hỗ trợ Snap cửa sổ (Sử dụng phím tắt Windows 11)
SnapWindow(Pos) {
    Sleep, 400 ; Đợi cửa sổ hiển thị ổn định
    If (Pos = "TL") {
        Send, {LWin down}{Left}{LWin up}
        Sleep, 300
        Send, {Esc} ; Tắt Snap Assist nhỡ nó cướp phím
        Sleep, 150
        Send, {LWin down}{Up}{LWin up}
    } Else If (Pos = "BL") {
        Send, {LWin down}{Left}{LWin up}
        Sleep, 300
        Send, {Esc}
        Sleep, 150
        Send, {LWin down}{Down}{LWin up}
    } Else If (Pos = "TR") {
        Send, {LWin down}{Right}{LWin up}
        Sleep, 300
        Send, {Esc}
        Sleep, 150
        Send, {LWin down}{Up}{LWin up}
    } Else If (Pos = "BR") {
        Send, {LWin down}{Right}{LWin up}
        Sleep, 300
        Send, {Esc}
        Sleep, 150
        Send, {LWin down}{Down}{LWin up}
    }
    Sleep, 300
    Send, {Esc} ; Tắt Snap Assist lần cuối
    Sleep, 200
}

; 1. GÓC TRÊN BÊN TRÁI (TL): Sắp xếp theo thứ tự hiển thị
; Mở Thảo đầu tiên (nếu chế độ 3 người) để nằm dưới cùng
If (WorkerMode = 3)
{
    Run, chrome.exe --new-window --profile-directory="%ChromeProfileThao%"
    WinWaitActive, ahk_exe chrome.exe, , 7
    SnapWindow("TL")
}

; Mở Dương tiếp theo
Run, chrome.exe --new-window --profile-directory="%ChromeProfileDuong%"
WinWaitActive, ahk_exe chrome.exe, , 7
SnapWindow("TL")

; Mở Long thứ 2 (để nó nằm giữa)
Run, msedge.exe --new-window --profile-directory="%EdgeProfileLong%"
WinWaitActive, ahk_exe msedge.exe, , 7
SnapWindow("TL")

; Mở Mess cuối cùng (để nó nằm trên cùng, đè lên các cái kia)
Run, chrome.exe --new-window --profile-directory="%ChromeProfileMess%"
WinWaitActive, ahk_exe chrome.exe, , 7
SnapWindow("TL")

; 2. GÓC DƯỚI BÊN TRÁI (BL): Tool A (Gồm cả Tab CMD và GUI Tool)
SplitPath, ToolAPath, , ToolADir  
Run, "%ToolAPath%", %ToolADir%

; Chờ Tool A (WT Prompt Tool) mở lên xong xuôi để tránh bị giành focus lúc đang Snap
WinWait, WT Prompt Tool, , 15
Sleep, 1500 ; Đợi 1.5 giây cho mọi thứ ổn định

If !ErrorLevel
{
    ; 2.1 Xử lý cái bảng đen CMD trước
    IfWinExist, cmd.exe
    {
        WinActivate, cmd.exe
        WinWaitActive, cmd.exe, , 3
        SnapWindow("BL")
    }

    ; 2.2 Xong tới xử lý cái bảng WT Prompt Tool đè lên
    WinActivate, WT Prompt Tool
    WinWaitActive, WT Prompt Tool, , 3
    SnapWindow("BL")
}

; 3. GÓC TRÊN BÊN PHẢI (TR): Chrome GPTs Long, GPTs Dương, và GPTs Thảo
; Mở GPTs Thảo trước (nếu chế độ 3 người) để nằm dưới cùng
gpt_thao_id := 0
If (WorkerMode = 3)
{
    Run, chrome.exe "%GptsUrl%" --new-window --profile-directory="%ChromeProfileThao%"
    WinWaitActive, ahk_exe chrome.exe, , 7
    WinGet, gpt_thao_id, ID, A
    SnapWindow("TR")
}

; Mở GPTs Dương tiếp theo
Run, chrome.exe "%GptsUrl%" --new-window --profile-directory="%ChromeProfileDuong%"
WinWaitActive, ahk_exe chrome.exe, , 7
WinGet, gpt_duong_id, ID, A
SnapWindow("TR")

; Mở GPTs Long sau (để nằm trên cùng)
Run, chrome.exe "%GptsUrl%" --new-window --profile-directory="%ChromeProfileLong%"
WinWaitActive, ahk_exe chrome.exe, , 7
WinGet, gpt_long_id, ID, A
SnapWindow("TR")

; (Phần F5 tự động đã được chuyển sang chức năng của Tool S)

; 4. GÓC DƯỚI BÊN PHẢI (BR): Thư mục Downloads
Run, explorer.exe shell:Downloads
WinWait, Downloads ahk_class CabinetWClass, , 7
WinActivate, Downloads ahk_class CabinetWClass

; 5. CHẠY MẮT THẦN (DOWNLOAD WATCHER) NGẦM
Run, cmd.exe /c python "%A_ScriptDir%\download_watcher.py", %A_ScriptDir%, Hide

; 6. CHẠY DISCORD BOT (ĐIỀU KHIỂN TỪ XA) NGẦM
Run, cmd.exe /c python "%A_ScriptDir%\discord_bot.py", %A_ScriptDir%, Hide

WinWaitActive, Downloads ahk_class CabinetWClass, , 5
SnapWindow("BR")

MsgBox, 64, , Bat dau lam viec thoaii!
ExitApp
