#NoEnv
SetWorkingDir %A_ScriptDir%
SendMode Input
SetTitleMatchMode, 2

MsgBox, 36, Xac nhan, Ban co chac chan muon DONG TAT CA cac cua so lam viec (Chrome, Edge, Tool A, Downloads)?
IfMsgBox, No
    ExitApp

; Dong cac cua so trinh duyet
While WinExist("ahk_exe chrome.exe")
    WinClose, ahk_exe chrome.exe
    
While WinExist("ahk_exe msedge.exe")
    WinClose, ahk_exe msedge.exe

; Dong Tool A
WinClose, WT Prompt Tool

; Dong toan bo cua so CMD bang tieu de (Ho tro Windows Terminal)
While WinExist("cmd.exe")
    WinKill, cmd.exe

; Dong thu muc Downloads
WinClose, Downloads ahk_class CabinetWClass

; Tat Mat Than (download_watcher.py)
Run, cmd.exe /c wmic process where "commandline like '`%download_watcher.py`%'" call terminate,, Hide

; Tat Discord Bot (discord_bot.py)
Run, cmd.exe /c wmic process where "commandline like '`%discord_bot.py`%'" call terminate,, Hide

MsgBox, 64, Thanh cong, Xong viec roaii
ExitApp
