#Requires AutoHotkey v2.0
#SingleInstance Force

; Khai báo biến toàn cục lưu Window IDs
global id_mess := IniRead("settings.ini", "WindowIDs", "id_mess", 0)
global id_page_long := IniRead("settings.ini", "WindowIDs", "id_page_long", 0)
global id_page_duong := IniRead("settings.ini", "WindowIDs", "id_page_duong", 0)
global id_page_thao := IniRead("settings.ini", "WindowIDs", "id_page_thao", 0)
global id_gpt_long := IniRead("settings.ini", "WindowIDs", "id_gpt_long", 0)
global id_gpt_duong := IniRead("settings.ini", "WindowIDs", "id_gpt_duong", 0)
global id_gpt_thao := IniRead("settings.ini", "WindowIDs", "id_gpt_thao", 0)
global id_toola := IniRead("settings.ini", "WindowIDs", "id_toola", 0)
global worker_mode := IniRead("settings.ini", "Settings", "worker_mode", 2)
global queue_file := "queue.csv"
global discord_webhook := "https://discordapp.com/api/webhooks/1517897683107319818/4G91ozYWFht7924nWa7l-nWSTxP7N3uyWUtG1OZOxAiP1AP8_2YyY6t5GXj0q2yChfAW"

; Hàm gửi log Discord
SendDiscordLog(msg) {
    global discord_webhook
    if (discord_webhook == "")
        return
    try {
        req := ComObject("Msxml2.XMLHTTP.6.0")
        req.open("POST", discord_webhook, false)
        req.setRequestHeader("Content-Type", "application/json")
        req.setRequestHeader("User-Agent", "Mozilla/5.0")
        
        safe_msg := StrReplace(msg, "\", "\\")
        safe_msg := StrReplace(safe_msg, "`"", "\`"")
        safe_msg := StrReplace(safe_msg, "`n", "\n")
        safe_msg := StrReplace(safe_msg, "`r", "")
        
        body := '{"content": "' safe_msg '"}'
        req.send(body)
    } catch {
        ; Bỏ qua nếu lỗi mạng
    }
}

; Đã bỏ biến lưu tọa độ theo yêu cầu: luôn quét lại mỗi khi cần click ô chat.

; CHÚ Ý: Đường dẫn thư mục Downloads
global tool_a_downloads := "D:\HoangLong_Data\Download"

; --- CẤU HÌNH TỌA ĐỘ CLICK DỰ PHÒNG KHI KHÔNG TÌM THẤY ICON ---
; (Chỉ cần sửa các số dưới đây để đổi tọa độ click)
global page_chat_click_x := 955
global page_chat_click_y := 510

global mess_chat_click_x := 950
global mess_chat_click_y := 950

global gpt_chat_offset_y := 120
; ---------------------------------------------------------------

; Nếu chưa có file csv thì tạo mẫu
if !FileExist(queue_file) {
    FileAppend("STT,Link chat,Loại việc,Hệ bài chữa,Gửi giáo án,Mã giáo án,Đường dẫn bài nộp,Trạng thái,Thời gian bắt đầu,Thời gian hoàn thành,Xưng hô`n1,https://facebook.com/messages/t/1234,Chữa bài,APTIS GENERAL,Có,gen_bài 2,,Chưa làm,,,Anh - Em (Mặc định)`n", queue_file, "UTF-8")
} else {
    content := FileRead(queue_file, "UTF-8")
    lines := StrSplit(content, "`n", "`r")
    
    ; Migration 1: Loại việc
    if (lines.Length > 0 && !InStr(lines[1], "Loại việc")) {
        try {
            FileMove(queue_file, queue_file ".backup3", 1)
            FileAppend("STT,Link chat,Loại việc,Hệ bài chữa,Gửi giáo án,Mã giáo án,Đường dẫn bài nộp,Trạng thái,Thời gian bắt đầu,Thời gian hoàn thành`n", queue_file, "UTF-8")
            for i, line in lines {
                if (i == 1 || Trim(line) == "")
                    continue
                cols := ParseCSVLine(line)
                
                old_he := cols.Has(3) ? cols[3] : ""
                loai_viec := (Trim(old_he) == "") ? "Chỉ gửi giáo án" : "Chữa bài"
                
                new_cols := []
                new_cols.Push(cols.Has(1) ? cols[1] : "") ; 1
                new_cols.Push(cols.Has(2) ? cols[2] : "") ; 2
                new_cols.Push(loai_viec)                  ; 3
                new_cols.Push(old_he)                     ; 4
                new_cols.Push(cols.Has(4) ? cols[4] : "") ; 5
                new_cols.Push(cols.Has(5) ? cols[5] : "") ; 6
                new_cols.Push(cols.Has(6) ? cols[6] : "") ; 7
                new_cols.Push(cols.Has(7) ? cols[7] : "") ; 8
                new_cols.Push(cols.Has(8) ? cols[8] : "") ; 9
                new_cols.Push(cols.Has(9) ? cols[9] : "") ; 10
                
                row := ToCSVLine(new_cols)
                FileAppend(row "`n", queue_file, "UTF-8")
            }
            content := FileRead(queue_file, "UTF-8")
            lines := StrSplit(content, "`n", "`r")
        } catch as e {
            MsgBox("LỖI: Không thể cập nhật file queue.csv sang định dạng Loại việc.`n`nVui lòng TẮT FILE EXCEL (queue.csv) đi rồi bật lại Tool S nhé!")
            ExitApp()
        }
    }
    
    ; Migration 2: Xưng hô
    if (lines.Length > 0 && !InStr(lines[1], "Xưng hô")) {
        try {
            FileMove(queue_file, queue_file ".backup_xungho", 1)
            FileAppend("STT,Link chat,Loại việc,Hệ bài chữa,Gửi giáo án,Mã giáo án,Đường dẫn bài nộp,Trạng thái,Thời gian bắt đầu,Thời gian hoàn thành,Xưng hô`n", queue_file, "UTF-8")
            for i, line in lines {
                if (i == 1 || Trim(line) == "")
                    continue
                cols := ParseCSVLine(line)
                
                new_cols := []
                Loop 10 {
                    new_cols.Push(cols.Has(A_Index) ? cols[A_Index] : "")
                }
                new_cols.Push("Anh - Em (Mặc định)")
                
                row := ToCSVLine(new_cols)
                FileAppend(row "`n", queue_file, "UTF-8")
            }
        } catch as e {
            MsgBox("LỖI: Không thể cập nhật file queue.csv sang định dạng Xưng hô.`n`nVui lòng TẮT FILE EXCEL (queue.csv) đi rồi bật lại Tool S nhé!")
            ExitApp()
        }
    }
}

; Bật giao diện điều khiển ngay lập tức
global myGui := ""
MainGUI()

MainGUI() {
    global myGui
    myGui := Gui("+AlwaysOnTop +Resize +MinSize300x400", "Tool S - Bảng Điều Khiển")
    myGui.BackColor := "F2F6FA" ; Nền xanh lơ nhạt, sang trọng
    
    ; Đặt Font mặc định cho toàn bộ cửa sổ
    myGui.SetFont("s10", "Segoe UI")
    
    ; TIÊU ĐỀ CHÍNH
    myGui.SetFont("s13 Bold c003366") ; Màu Xanh Navy đậm
    myGui.Add("Text", "w300 Center", "🚀 TOOL S AUTOMATION")
    myGui.Add("Text", "w300 h2 0x10") ; Đường gạch ngang mờ phân cách
    
    ; NHÓM 1: CÀI ĐẶT
    myGui.SetFont("s9 Bold c0055A4") ; Xanh dương
    myGui.Add("Text", "w300 xm", "🛠️ THIẾT LẬP && ĐẦU VÀO")
    myGui.SetFont("s10 Norm cBlack")
    btnOpenWS := myGui.Add("Button", "w145 h35 xm", "🖥️ 1. setup_workspace")
    btnOpenWS.OnEvent("Click", (*) => SafeRunSetupWorkspace())
    
    btnSetup := myGui.Add("Button", "w145 h35 x+10", "⚙️ 2. Cài đặt cửa sổ")
    btnSetup.OnEvent("Click", (*) => GuiSetup_Action())
    
    btnAdd := myGui.Add("Button", "w145 h35 xm", "➕ 3. Thêm học viên")
    btnAdd.OnEvent("Click", (*) => AddToQueue_Form())
    
    btnShutdownWS := myGui.Add("Button", "w145 h35 x+10", "🛑 4. exit_workspace")
    btnShutdownWS.OnEvent("Click", (*) => SafeRunShutdownWorkspace())
    
    btnRestoreWin := myGui.Add("Button", "w145 h35 xm", "🔄 5. Hiện cửa sổ")
    btnRestoreWin.OnEvent("Click", (*) => RestoreWorkspaceWindows())
    
    btnMode := myGui.Add("Button", "w145 h35 x+10", "👥 6. Số người làm")
    btnMode.OnEvent("Click", (*) => ChangeWorkerMode())
    
    ; NHÓM 2: CA LÀM VIỆC
    myGui.Add("Text", "w300 h5 xm") ; Khoảng trống nhỏ
    myGui.SetFont("s9 Bold c0055A4")
    myGui.Add("Text", "w300 xm", "⏰ CA LÀM VIỆC")
    myGui.SetFont("s10 Norm cBlack")
    
    btnShift := myGui.Add("Button", "w145 h35 xm", "🟢 ĐÁNH DẤU VÀO CA")
    btnShift.OnEvent("Click", (*) => MarkShiftStart())
    
    btnEndShift := myGui.Add("Button", "w145 h35 x+10", "🔴 KẾT THÚC (Tan ca)")
    btnEndShift.OnEvent("Click", (*) => MarkShiftEnd())
    
    ; NHÓM 3: CHẠY TOOL
    myGui.Add("Text", "w300 h5 xm") ; Khoảng trống (xm để ép về sát lề trái)
    myGui.SetFont("s9 Bold c0055A4")
    myGui.Add("Text", "w300 xm", "▶️ ĐIỀU KHIỂN CHẠY")
    myGui.SetFont("s10 Norm cBlack")
    
    btnRunManual := myGui.Add("Button", "w145 h35 xm", "👁️ 3a. Quan sát")
    btnRunManual.OnEvent("Click", (*) => ProcessQueue("manual"))
    
    btnRunAuto := myGui.Add("Button", "w145 h35 x+10", "🚀 3b. Auto")
    btnRunAuto.OnEvent("Click", (*) => ProcessQueue("auto"))
    
    ; NHÓM 4: LỊCH SỬ & DỮ LIỆU
    myGui.Add("Text", "w300 h5 xm") ; Khoảng trống
    myGui.SetFont("s9 Bold c0055A4")
    myGui.Add("Text", "w300 xm", "📊 DỮ LIỆU && LỊCH SỬ")
    myGui.SetFont("s10 Norm cBlack")
    
    btnArchive := myGui.Add("Button", "w145 h35 xm", "🧹 Dọn & Lưu Lịch sử")
    btnArchive.OnEvent("Click", (*) => ArchiveHistory(true))
    
    btnRestore := myGui.Add("Button", "w145 h35 x+10", "🔄 Khôi phục Lịch sử")
    btnRestore.OnEvent("Click", (*) => RestoreHistory())
    
    btnOpen := myGui.Add("Button", "w300 h35 xm", "📂 Mở xem Danh sách Chung (queue.csv)")
    btnOpen.OnEvent("Click", (*) => OpenExcelWithFormat("queue.csv", "Chung"))
    
    btnOpenLong := myGui.Add("Button", "w95 h35 xm", "📝 Long")
    btnOpenLong.OnEvent("Click", (*) => OpenExcelWithFormat("queue_long.csv", "Long"))
    
    btnOpenDuong := myGui.Add("Button", "w95 h35 x+5", "📝 Dương")
    btnOpenDuong.OnEvent("Click", (*) => OpenExcelWithFormat("queue_duong.csv", "Dương"))
    
    btnOpenThao := myGui.Add("Button", "w95 h35 x+5", "📝 Thảo")
    btnOpenThao.OnEvent("Click", (*) => OpenExcelWithFormat("queue_thao.csv", "Thảo"))
    
    myGui.Show("AutoSize Center")
}

ChangeWorkerMode() {
    global worker_mode
    current_str := (worker_mode == 3) ? "3 người (Long - Dương - Thảo)" : "2 người (Long - Dương)"
    res := MsgBox("Chế độ hiện tại: " current_str "`n`nBạn có muốn đổi sang chế độ " ((worker_mode == 3) ? "2 người" : "3 người") " không?", "Chọn số người làm", "YesNo")
    if (res == "Yes") {
        worker_mode := (worker_mode == 3) ? 2 : 3
        IniWrite(worker_mode, "settings.ini", "Settings", "worker_mode")
        MsgBox("Đã chuyển sang chế độ " worker_mode " người làm!", "Thành công")
    }
}

GetWorkerBySTT(stt, mode) {
    if (mode == 3) {
        rem := Mod(stt, 3)
        if (rem == 1)
            return "duong"
        else if (rem == 2)
            return "long"
        else
            return "thao"
    } else {
        rem := Mod(stt, 2)
        if (rem == 0)
            return "long"
        else
            return "duong"
    }
}

SafeRunSetupWorkspace() {
    flag_file := A_ScriptDir "\workspace_active.txt"
    if FileExist(flag_file) {
        MsgBox("Workspace đã được setup rồi!`n`nNếu muốn setup lại, hãy bấm 'exit_workspace' trước nhé.", "Thông báo", "48")
        return
    }
    ; Tạo file flag đánh dấu workspace đang active
    try FileAppend("1", flag_file, "UTF-8")
    Run(A_ScriptDir "\setup_workspace.ahk")
}

SafeRunShutdownWorkspace() {
    flag_file := A_ScriptDir "\workspace_active.txt"
    Run(A_ScriptDir "\shutdown_workspace.ahk")
    ; Xóa file flag để cho phép setup lại
    Sleep(500)
    if FileExist(flag_file)
        try FileDelete(flag_file)
}

GuiSetup_Action() {
    global worker_mode
    if (worker_mode == 3) {
        MsgBox("Tool S Automation (Chế độ 3 người)`n`nCần chọn 8 cửa sổ độc lập theo thứ tự:`n1. Chat MESSENGER`n2. Chat PAGE LONG`n3. Chat PAGE DƯƠNG`n4. Chat PAGE THẢO`n5. GPTs LONG`n6. GPTs DƯƠNG`n7. GPTs THẢO`n8. Tool A`n`nBấm OK để bắt đầu lưu Window ID.")
    } else {
        MsgBox("Tool S Automation (Chế độ 2 người)`n`nCần chọn 6 cửa sổ độc lập theo thứ tự:`n1. Chat MESSENGER`n2. Chat PAGE LONG`n3. Chat PAGE DƯƠNG`n4. GPTs LONG`n5. GPTs DƯƠNG`n6. Tool A`n`nBấm OK để bắt đầu lưu Window ID.")
    }
    
    ToolTip("BƯỚC 1: Click chuột vào cửa sổ CHAT MESSENGER, sau đó bấm phím F9")
    KeyWait("F9", "D")
    global id_mess := WinGetID("A")
    KeyWait("F9")
    
    ToolTip("BƯỚC 2: Click chuột vào cửa sổ CHAT PAGE LONG, sau đó bấm phím F9")
    KeyWait("F9", "D")
    global id_page_long := WinGetID("A")
    KeyWait("F9")

    ToolTip("BƯỚC 3: Click chuột vào cửa sổ CHAT PAGE DƯƠNG, sau đó bấm phím F9")
    KeyWait("F9", "D")
    global id_page_duong := WinGetID("A")
    KeyWait("F9")
    
    if (worker_mode == 3) {
        ToolTip("BƯỚC 4: Click chuột vào cửa sổ CHAT PAGE THẢO, sau đó bấm phím F9")
        KeyWait("F9", "D")
        global id_page_thao := WinGetID("A")
        KeyWait("F9")
    }
    
    ToolTip("BƯỚC " ((worker_mode == 3) ? "5" : "4") ": Click chuột vào cửa sổ GPTs LONG, sau đó bấm phím F9")
    KeyWait("F9", "D")
    global id_gpt_long := WinGetID("A")
    KeyWait("F9")

    ToolTip("BƯỚC " ((worker_mode == 3) ? "6" : "5") ": Click chuột vào cửa sổ GPTs DƯƠNG, sau đó bấm phím F9")
    KeyWait("F9", "D")
    global id_gpt_duong := WinGetID("A")
    KeyWait("F9")
    
    if (worker_mode == 3) {
        ToolTip("BƯỚC 7: Click chuột vào cửa sổ GPTs THẢO, sau đó bấm phím F9")
        KeyWait("F9", "D")
        global id_gpt_thao := WinGetID("A")
        KeyWait("F9")
    }
    
    ToolTip("BƯỚC " ((worker_mode == 3) ? "8" : "6") ": Click chuột vào cửa sổ TOOL A, sau đó bấm phím F9")
    KeyWait("F9", "D")
    global id_toola := WinGetID("A")
    KeyWait("F9")
    
    IniWrite(id_mess, "settings.ini", "WindowIDs", "id_mess")
    IniWrite(id_page_long, "settings.ini", "WindowIDs", "id_page_long")
    IniWrite(id_page_duong, "settings.ini", "WindowIDs", "id_page_duong")
    IniWrite(id_gpt_long, "settings.ini", "WindowIDs", "id_gpt_long")
    IniWrite(id_gpt_duong, "settings.ini", "WindowIDs", "id_gpt_duong")
    IniWrite(id_toola, "settings.ini", "WindowIDs", "id_toola")
    
    if (worker_mode == 3) {
        IniWrite(id_page_thao, "settings.ini", "WindowIDs", "id_page_thao")
        IniWrite(id_gpt_thao, "settings.ini", "WindowIDs", "id_gpt_thao")
    }

    ToolTip() ; Tắt dòng chữ đi
    
    MsgBox("Đã cài xong cửa sổ", "Thông báo")
    
    ; Tự động dán Thông tin S vào tất cả GPTs sau khi cài đặt xong
    PasteThongTinSAll()
    
    MsgBox("Đã hoàn tất setup và gửi Thông tin S!`nBây giờ bạn hãy bấm Ctrl + Y để bắt đầu chạy (AUTO) nhé.", "Hoàn tất setup")
}

RestoreWorkspaceWindows() {
    global id_mess, id_page_long, id_page_duong, id_gpt_long, id_gpt_duong, id_toola
    global id_page_thao, id_gpt_thao, worker_mode
    
    ToolTip("🔄 Đang khôi phục các cửa sổ làm việc...", 100, 100)
    
    ; Cấu hình giống setup_workspace.ahk
    GptsUrl := "https://chatgpt.com/g/g-6a596a1268cc81919a9e75265771bea9-chua-wt"
    ToolAPath := A_ScriptDir "\Tool_A\run.bat"
    
    reopened := 0
    restored := 0
    
    ; Hàm hỗ trợ nội bộ
    RestoreAndSnap(winId, pos) {
        if (winId != 0 && WinExist("ahk_id " winId)) {
            WinRestore("ahk_id " winId)
            WinActivate("ahk_id " winId)
            WinWaitActive("ahk_id " winId,, 2)
            
            ; Bắt buộc đưa về trạng thái thả nổi (floating) trước khi Snap
            ; Đề phòng Windows 11 Snap gửi sai lệnh nếu cửa sổ đã bị dính cạnh
            WinMove(100, 100, 800, 600, "ahk_id " winId)
            Sleep(300)
            
            SnapWindowV2(pos)
            return true
        }
        return false
    }
    
    ; === GÓC TRÊN BÊN TRÁI (TL): Mess, Page Long, Page Duong, Page Thao ===
    ; Xử lý từ dưới lên để thứ tự đè đúng
    
    if (worker_mode == 3) {
        if RestoreAndSnap(id_page_thao, "TL")
            restored++
    }
    
    ; Page Dương (dưới cùng TL)
    if RestoreAndSnap(id_page_duong, "TL")
        restored++
    
    ; Page Long (giữa TL)
    if RestoreAndSnap(id_page_long, "TL")
        restored++
    
    ; Mess (trên cùng TL)
    if RestoreAndSnap(id_mess, "TL")
        restored++
    
    ; === GÓC DƯỚI BÊN TRÁI (BL): Tool A ===
    if RestoreAndSnap(id_toola, "BL") {
        restored++
    } else {
        ; Tool A bị tắt => mở lại
        SplitPath(ToolAPath, , &ToolADir)
        Run(ToolAPath, ToolADir)
        if WinWait("WT Prompt Tool",, 15) {
            Sleep(1500)
            id_toola := WinGetID("WT Prompt Tool")
            IniWrite(id_toola, "settings.ini", "WindowIDs", "id_toola")
            RestoreAndSnap(id_toola, "BL")
            reopened++
        }
    }
    
    ; === GÓC TRÊN BÊN PHẢI (TR): GPTs Dương (dưới), GPTs Long (trên), GPTs Thảo ===
    if (worker_mode == 3) {
        if RestoreAndSnap(id_gpt_thao, "TR")
            restored++
    }
    
    if RestoreAndSnap(id_gpt_duong, "TR")
        restored++
    
    if RestoreAndSnap(id_gpt_long, "TR")
        restored++
    
    ToolTip()
    MsgBox("Đã khôi phục xong!`n`n✅ Hiện lại: " restored " cửa sổ`n🔄 Mở lại: " reopened " cửa sổ", "🔄 Khôi phục Workspace", "64")
}

; Hàm Snap cửa sổ dùng cho AHK v2 (tương thích với setup_workspace.ahk)
SnapWindowV2(Pos) {
    Sleep(400)
    if (Pos == "TL") {
        Send("{LWin down}{Left}{LWin up}")
        Sleep(300)
        Send("{Esc}")
        Sleep(150)
        Send("{LWin down}{Up}{LWin up}")
    } else if (Pos == "BL") {
        Send("{LWin down}{Left}{LWin up}")
        Sleep(300)
        Send("{Esc}")
        Sleep(150)
        Send("{LWin down}{Down}{LWin up}")
    } else if (Pos == "TR") {
        Send("{LWin down}{Right}{LWin up}")
        Sleep(300)
        Send("{Esc}")
        Sleep(150)
        Send("{LWin down}{Up}{LWin up}")
    } else if (Pos == "BR") {
        Send("{LWin down}{Right}{LWin up}")
        Sleep(300)
        Send("{Esc}")
        Sleep(150)
        Send("{LWin down}{Down}{LWin up}")
    }
    Sleep(300)
    Send("{Esc}")
    Sleep(200)
}

global addGui := ""
global confirmGui := ""
global editLink := ""
global ddlType := ""
global ddlHe := ""
global editGiaoAn := ""

AddToQueue_Form() {
    global addGui, editLink, ddlType, ddlHe, editGiaoAn
    if (addGui != "") {
        try addGui.Destroy()
    }
    addGui := Gui("+AlwaysOnTop", "Thêm vào Queue")
    addGui.Add("Text", "w80", "Link Chat:")
    editLink := addGui.Add("Edit", "w160 x+10")
    btnSaveTemp := addGui.Add("Button", "w50 x+5", "Lưu")
    btnSaveTemp.OnEvent("Click", (*) => SaveTempLink())
    
    btnWord := addGui.Add("Button", "w30 x+5", "W")
    btnWord.OnEvent("Click", (*) => Run("winword.exe"))
    
    addGui.Add("Text", "w80 xm", "Loại việc:")
    ddlType := addGui.Add("DropDownList", "w250 x+10 Choose1", ["Chữa bài", "Chỉ gửi giáo án"])
    ddlType.OnEvent("Change", (*) => ToggleHeThi())
    
    addGui.Add("Text", "w80 xm", "Hệ thi:")
    ddlHe := addGui.Add("DropDownList", "w250 x+10 Choose1", ["APTIS GENERAL", "VSTEP", "APTIS ADVANCED"])
    
    addGui.Add("Text", "w80 xm", "Gửi giáo án:")
    global chkGiaoAn := addGui.Add("Checkbox", "w250 x+10", "Có gửi kèm giáo án")
    
    addGui.Add("Text", "w80 xm", "Mã giáo án:")
    editGiaoAn := addGui.Add("Edit", "w250 x+10")
    
    addGui.Add("Text", "w80 xm", "Đường dẫn bài:")
    global editBaiNop := addGui.Add("Edit", "w200 x+10")
    btnPick := addGui.Add("Button", "w40 x+5", "Chọn")
    btnPick.OnEvent("Click", (*) => SelectBaiNop())
    
    addGui.Add("Text", "w80 xm", "Xưng hô:")
    global ddlXungHo := addGui.Add("DropDownList", "w250 x+10 Choose1", ["Anh - Em (Mặc định)", "Mình - Bạn", "Em - Chị", "Em - Anh"])

    btnSave := addGui.Add("Button", "w340 h40 xm", "Thêm vào Danh sách")
    btnSave.OnEvent("Click", (*) => SaveToQueue())
    
    addGui.OnEvent("Close", (*) => CloseAddGui())
    SetTimer(WatchTempPaths, 500)
    
    addGui.Show()
}

CloseAddGui() {
    SetTimer(WatchTempPaths, 0)
    if FileExist(A_ScriptDir "\watcher_active.txt")
        FileDelete(A_ScriptDir "\watcher_active.txt")
}

SaveTempLink() {
    if FileExist(A_ScriptDir "\watcher_active.txt")
        FileDelete(A_ScriptDir "\watcher_active.txt")
    FileAppend("1", A_ScriptDir "\watcher_active.txt", "UTF-8")
    MsgBox("Đã kích hoạt Mắt Thần! Mọi file tải về từ giờ sẽ được bắt tự động.", "Thông báo", "T2")
}

WatchTempPaths() {
    global editBaiNop
    temp_file := A_ScriptDir "\temp_paths.txt"
    if FileExist(temp_file) {
        try {
            new_path := FileRead(temp_file, "UTF-8")
            new_path := Trim(new_path, " `t`r`n")
            if (new_path != "") {
                current := editBaiNop.Value
                ; Chống trùng lặp
                if !InStr(current, new_path) {
                    if (current != "")
                        editBaiNop.Value := current "|" new_path
                    else
                        editBaiNop.Value := new_path
                }
            }
            FileDelete(temp_file)
        }
    }
}

SelectBaiNop() {
    global editBaiNop
    selected := FileSelect("M3", "", "Chọn bài làm của học viên", "Word (*.docx;*.doc)")
    if Type(selected) == "Array" && selected.Length > 0 {
        str := ""
        for i, path in selected {
            str .= path (i == selected.Length ? "" : "|")
        }
        editBaiNop.Value := str
    } else if (Type(selected) == "String" && selected != "") {
        editBaiNop.Value := selected
    }
}

ToggleHeThi() {
    global ddlType, ddlHe
    if (ddlType.Value == 2) {
        ddlHe.Enabled := false
    } else {
        ddlHe.Enabled := true
    }
}

SaveToQueue() {
    global queue_file, editLink, ddlType, ddlHe, editGiaoAn, addGui, ddlXungHo, editBaiNop, chkGiaoAn
    link := editLink.Value
    if (link == "") {
        MsgBox("Vui lòng điền link chat!")
        return
    }
    
    loai := ddlType.Text
    he := ddlHe.Text
    if (loai == "Chỉ gửi giáo án") {
        he := "" ; Rỗng hệ
    }
    giao_an := editGiaoAn.Value
    bai_nop := editBaiNop.Value
    co_giao_an := chkGiaoAn.Value ? "Có" : "Không"
    xung_ho := ddlXungHo.Text
    
    stt := 1
    if FileExist(queue_file) {
        content := FileRead(queue_file, "UTF-8")
        lines := StrSplit(content, "`n", "`r")
        for i, line in lines {
            if (i == 1 || Trim(line) == "")
                continue
            cols := ParseCSVLine(line)
            if (cols.Length >= 1 && InStr(cols[1], "CA LÀM VIỆC")) {
                stt := 1
            } else {
                stt++
            }
        }
    }
    
    ; Validation: bài chữa phải có đường dẫn khi loại việc là Chữa bài
    if (loai == "Chữa bài" && bai_nop == "") {
        MsgBox("Vui lòng chọn đường dẫn bài nộp của học viên!`n`n(Link chat và Path bài chữa là bắt buộc khi chữa bài)")
        return
    }
    
    ; Hiển thị dialog xác nhận thay vì lưu trực tiếp
    ShowConfirmDialog(stt, link, loai, he, giao_an, bai_nop, co_giao_an, xung_ho)
}

ShowConfirmDialog(stt, link, loai, he, giao_an, bai_nop, co_giao_an, xung_ho) {
    global confirmGui, addGui
    
    if (confirmGui != "") {
        try confirmGui.Destroy()
    }
    
    ; Ẩn form nhập để tránh chỉnh sửa khi đang xác nhận
    addGui.Hide()
    
    ; Trích xuất ID page nếu là link business.facebook.com
    display_link := link
    if InStr(link, "business.facebook.com") {
        if RegExMatch(link, "selected_item_id=([^&]+)", &match) {
            display_link := match[1]
        }
    }
    
    ; Chuyển hệ thi sang dạng viết thường
    he_display := ""
    if InStr(he, "GENERAL")
        he_display := "aptis gen"
    else if InStr(he, "VSTEP")
        he_display := "vstep"
    else if InStr(he, "ADVANCED")
        he_display := "aptis adv"
    else if (he == "")
        he_display := "(Chỉ gửi giáo án)"
    
    ; Hiển thị giáo án
    giao_an_display := (giao_an != "") ? giao_an : "(Không gửi)"
    
    confirmGui := Gui("+AlwaysOnTop", "✅ Xác nhận thông tin học viên")
    confirmGui.BackColor := "F2F6FA"
    
    confirmGui.SetFont("s13 Bold c003366", "Segoe UI")
    confirmGui.Add("Text", "w450 Center", "KIỂM TRA THÔNG TIN HỌC VIÊN")
    confirmGui.Add("Text", "w450 h2 0x10")
    
    confirmGui.SetFont("s11 Norm c333333", "Segoe UI")
    confirmGui.Add("Text", "w450 xm", "📎 Link đoạn chat: " display_link)
    confirmGui.Add("Text", "w450 xm", "📝 Loại bài: " he_display)
    
    confirmGui.Add("Text", "w450 xm", "📂 Path bài chữa:")
    bai_nop_list := StrSplit(bai_nop, "|")
    for idx, path in bai_nop_list {
        if (Trim(path) != "")
            confirmGui.Add("Text", "w430 xm", "     " idx ". " Trim(path))
    }
    
    confirmGui.Add("Text", "w450 xm", "📚 Giáo án gửi: " giao_an_display)
    
    confirmGui.Add("Text", "w450 h15 xm")
    
    confirmGui.SetFont("s10 Norm", "Segoe UI")
    btnEdit := confirmGui.Add("Button", "w200 h40 xm", "✏️ Chỉnh sửa")
    btnEdit.OnEvent("Click", (*) => OnConfirmEdit())
    
    btnOk := confirmGui.Add("Button", "w200 h40 x+30", "✅ Ok, đã kiểm tra")
    btnOk.OnEvent("Click", (*) => OnConfirmOk(stt, link, loai, he, giao_an, bai_nop, co_giao_an, xung_ho))
    
    confirmGui.OnEvent("Close", (*) => OnConfirmEdit())
    confirmGui.Show()
}

OnConfirmEdit() {
    global confirmGui, addGui
    if (confirmGui != "") {
        try confirmGui.Destroy()
        confirmGui := ""
    }
    ; Hiện lại form nhập để người dùng chỉnh sửa
    addGui.Show()
}

OnConfirmOk(stt, link, loai, he, giao_an, bai_nop, co_giao_an, xung_ho) {
    global confirmGui, addGui, queue_file
    
    if (confirmGui != "") {
        try confirmGui.Destroy()
        confirmGui := ""
    }
    
    row := ToCSVLine([stt, link, loai, he, co_giao_an, giao_an, bai_nop, "Chưa làm", "", "", xung_ho]) "`n"
    try {
        FileAppend(row, queue_file, "UTF-8")
        MsgBox("Đã thêm STT " stt " thành công!")
        SetTimer(WatchTempPaths, 0)
        if FileExist(A_ScriptDir "\watcher_active.txt")
            FileDelete(A_ScriptDir "\watcher_active.txt")
        addGui.Destroy()
    } catch as e {
        MsgBox("KHÔNG THỂ THÊM VÀO DANH SÁCH!`n`nVui lòng TẮT FILE EXCEL (queue.csv) trước khi thêm học viên, vì Excel đang khóa file này không cho phần mềm khác lưu.`n`nLỗi chi tiết: " e.Message)
    }
}

MarkShiftStart() {
    global queue_file
    default_time := FormatTime(, "HH:mm")
    ib := InputBox("Nhập thông tin ca làm việc (ví dụ: Ca tối, Ca sáng, Thời gian...):", "Đánh dấu vào ca", "w300 h130", default_time)
    if (ib.Result == "Cancel")
        return
        
    shift_info := ib.Value
    if (shift_info == "")
        shift_info := default_time
        
    try {
        row := ToCSVLine(["CA LÀM VIỆC", shift_info, "", "", "", "", "", "", "", "", ""]) "`n"
        FileAppend(row, queue_file, "UTF-8")
        
        ; Reset bộ đếm bài chữa cho ca mới
        IniWrite(0, "settings.ini", "GradedCounts", "long")
        IniWrite(0, "settings.ini", "GradedCounts", "duong")
        IniWrite(0, "settings.ini", "GradedCounts", "thao")
        
        MsgBox("Đã vào ca", "Thông báo")
    } catch as e {
        MsgBox("LỖI: Không thể ghi vào file queue.csv. Vui lòng tắt file Excel nếu đang mở.`n" e.Message)
    }
}

MarkShiftEnd() {
    global queue_file, worker_mode
    long_file := A_ScriptDir "\queue_long.csv"
    duong_file := A_ScriptDir "\queue_duong.csv"
    thao_file := A_ScriptDir "\queue_thao.csv"
    
    if !FileExist(queue_file) {
        MsgBox("Không tìm thấy file " queue_file)
        return
    }
    
    content := FileRead(queue_file, "UTF-8")
    lines := StrSplit(content, "`n", "`r")
    
    start_idx := 0
    Loop lines.Length {
        idx := lines.Length - A_Index + 1
        if InStr(lines[idx], "CA LÀM VIỆC") {
            start_idx := idx
            break
        }
    }
    
    if (start_idx == 0) {
        MsgBox("Không tìm thấy dòng Đánh dấu vào ca nào trong danh sách!")
        return
    }
    
    res := MsgBox("Cậu có chắc chắn muốn kết thúc ca làm việc gần nhất và copy sang file của các nhân sự không?", "Xác nhận kết thúc ca", "YesNo")
    if (res != "Yes")
        return
        
    long_data := ""
    duong_data := ""
    thao_data := ""
    
    header := "STT,Link chat,Loại việc,Hệ bài chữa,Gửi giáo án,Mã giáo án,Đường dẫn bài nộp,Trạng thái,Thời gian bắt đầu,Thời gian hoàn thành,Xưng hô`n"
    if !FileExist(long_file)
        FileAppend(header, long_file, "UTF-8")
    if !FileExist(duong_file)
        FileAppend(header, duong_file, "UTF-8")
    if (worker_mode == 3 && !FileExist(thao_file))
        FileAppend(header, thao_file, "UTF-8")
        
    Loop lines.Length - start_idx + 1 {
        idx := start_idx + A_Index - 1
        line := lines[idx]
        if Trim(line) == ""
            continue
            
        cols := ParseCSVLine(line)
        if (cols.Length >= 1 && InStr(cols[1], "CA LÀM VIỆC")) {
            long_data .= line "`n"
            duong_data .= line "`n"
            if (worker_mode == 3)
                thao_data .= line "`n"
            continue
        }
        
        if (cols.Length >= 1) {
            stt_val := Trim(cols[1])
            if IsInteger(stt_val) {
                worker := GetWorkerBySTT(stt_val, worker_mode)
                if (worker == "long") {
                    long_data .= line "`n"
                } else if (worker == "duong") {
                    duong_data .= line "`n"
                } else if (worker == "thao" && worker_mode == 3) {
                    thao_data .= line "`n"
                }
            }
        }
    }
    
    try {
        if (long_data != "")
            FileAppend(long_data, long_file, "UTF-8")
        if (duong_data != "")
            FileAppend(duong_data, duong_file, "UTF-8")
        if (worker_mode == 3 && thao_data != "")
            FileAppend(thao_data, thao_file, "UTF-8")
            
        MsgBox("Đã phân ca thành công!`nLong, Dương" ((worker_mode == 3) ? ", Thảo" : "") " đã nhận được file riêng.", "Thông báo")
    } catch as e {
        MsgBox("LỖI: Không thể ghi file. Vui lòng tắt Excel nếu đang mở file queue.`n" e.Message)
    }
}

F7:: {
    pause_file := A_ScriptDir "\pause_auto.txt"
    if !FileExist(pause_file) {
        try FileAppend("1", pause_file, "UTF-8")
        ToolTip("⏸️ ĐÃ GỬI LỆNH TẠM DỪNG!`nTool S sẽ dừng lại ở bước gần nhất...", 100, 100)
        SetTimer(() => ToolTip(), -3000)
    } else {
        ToolTip("Đã có lệnh tạm dừng rồi, đợi Tool S dừng lại nhé...", 100, 100)
        SetTimer(() => ToolTip(), -2000)
    }
}

F8:: {
    MsgBox("Đã dừng khẩn cấp Tool S!", "Dừng Tool")
    Reload()
}

^y:: {
    ProcessQueue("auto")
}

F10:: {
    ; Lưu clipboard cũ để khôi phục sau
    oldClipboard := ClipboardAll()
    
    ; Xóa clipboard và copy đoạn văn bản đang bôi đen
    A_Clipboard := ""
    Send("^c")
    
    ; Chờ clipboard nhận được nội dung (tối đa 3 giây)
    if !ClipWait(3) {
        MsgBox("Không copy được nội dung! Cậu hãy bôi đen bài làm của học viên trước rồi bấm F10 nhé.", "Thông báo", "48")
        A_Clipboard := oldClipboard  ; Khôi phục clipboard cũ
        return
    }
    
    text := A_Clipboard
    if (text == "") {
        MsgBox("Clipboard trống sau khi copy! Cậu hãy bôi đen bài làm trước rồi bấm F10.", "Thông báo", "48")
        A_Clipboard := oldClipboard
        return
    }
    
    timestamp := FormatTime(, "yyyyMMdd_HHmmss")
    filepath := tool_a_downloads "\BaiLamHocVien_" timestamp ".txt"
    
    try {
        ; Lưu file với UTF-8 (giữ nguyên format chữ, ký tự tiếng Việt)
        FileAppend(text, filepath, "UTF-8")
        
        ; Nếu đang bật Watcher (Mắt Thần / Thêm học viên) thì tự ghi vào temp_paths
        if FileExist(A_ScriptDir "\watcher_active.txt") {
            FileAppend(filepath, A_ScriptDir "\temp_paths.txt", "UTF-8")
            ToolTip("✅ Đã lưu bài làm và chuyển cho Mắt Thần!`n📄 " filepath, 100, 100)
            SetTimer(() => ToolTip(), -3000)
        } else {
            ; Đang chạy Manual — tự bấm F9 để chạy tiếp
            ToolTip("✅ Đã lưu bài thành file:`n📄 " filepath "`nĐang tự động bấm F9 để chạy tiếp...", 100, 100)
            SetTimer(() => ToolTip(), -3000)
            Send("{F9}")
        }
    } catch as err {
        MsgBox("Lỗi khi lưu file: " err.Message)
    }
    
    ; Khôi phục clipboard cũ (không làm mất dữ liệu cũ của user)
    A_Clipboard := oldClipboard
}

; === HÀM TẠM DỪNG: Kiểm tra và xử lý lệnh pause từ F7 ===
CheckPause() {
    pause_file := A_ScriptDir "\pause_auto.txt"
    if !FileExist(pause_file)
        return "continue"
    
    ; Ghi nhớ cửa sổ đang làm việc trước khi hiện MsgBox
    prev_win := 0
    try prev_win := WinGetID("A")
    
    ; Xóa file pause
    try FileDelete(pause_file)
    
    SendDiscordLog("⏸️ **[PAUSE] Tool S đã tạm dừng theo yêu cầu!**")
    ToolTip()
    
    Loop {
        ; 4 (YesNo) + 48 (Icon!) + 262144 (AlwaysOnTop) = 262196
        result := MsgBox("⏸️ TOOL S ĐÃ TẠM DỪNG`n`nChọn hành động:`n`n• YES = ➕ Thêm học viên`n• NO = ▶️ Tiếp tục chữa", "⏸️ Tool S - Tạm Dừng", 262196)
        
        if (result == "Yes") {
            AddToQueue_Form()
            SendDiscordLog("➕ **[PAUSE] Đã mở form thêm học viên, đang chờ...**")
            
            ; Đợi form hiện lên rồi đợi form đóng lại
            if WinWait("Thêm vào Queue",, 5) {
                WinWaitClose("Thêm vào Queue")
            }
            
            SendDiscordLog("✅ **[PAUSE] Đã đóng form thêm học viên, hỏi lại...**")
            ; Quay lại hỏi tiếp (có thể thêm nữa hoặc tiếp tục)
            continue
        } else {
            SendDiscordLog("▶️ **[RESUME] Tool S tiếp tục chạy!**")
            
            ; Phục hồi lại cửa sổ đang làm việc dở và đưa chuột vào đó cho an toàn
            if (prev_win != 0 && WinExist("ahk_id " prev_win)) {
                WinActivate("ahk_id " prev_win)
                WinWaitActive("ahk_id " prev_win,, 2)
                try {
                    WinGetPos(&X, &Y, &W, &H, "ahk_id " prev_win)
                    if (W > 0 && H > 0)
                        MouseMove(W/2, H/2, 0)
                }
            }
            
            return "continue"
        }
    }
}

ProcessQueue(mode := "manual") {
    stop_file := A_ScriptDir "\stop_auto.txt"
    
    if (mode == "auto") {
        ; Bật WakeLock chống tắt màn hình (ES_DISPLAY_REQUIRED | ES_CONTINUOUS)
        DllCall("SetThreadExecutionState", "UInt", 0x80000002)
        ; Xóa file stop cũ nếu còn sót
        if FileExist(stop_file)
            try FileDelete(stop_file)
    }
    
    Loop {
        ; === KILL SWITCH: Kiểm tra lệnh dừng từ xa ===
        if (mode == "auto" && FileExist(stop_file)) {
            try FileDelete(stop_file)
            SendDiscordLog("🛑 **[REMOTE STOP] Đã dừng Auto theo lệnh từ xa!**")
            ToolTip()
            MsgBox("Đã dừng Auto theo lệnh từ xa (stop_auto.txt)!", "Remote Stop")
            break
        }
        
        ; === PAUSE CHECK: Kiểm tra lệnh tạm dừng từ F7 ===
        CheckPause()
        
        if !FileExist(queue_file) {
            MsgBox("Không tìm thấy file " queue_file)
            break
        }
        
        content := FileRead(queue_file, "UTF-8")
        lines := StrSplit(content, "`n", "`r")
        
        if (lines.Length < 2) {
            MsgBox("File CSV trống hoặc không có dữ liệu!")
            break
        }
        
        pending_rows := []
        Loop lines.Length {
            if (A_Index == 1 || Trim(lines[A_Index]) == "")
                continue
                
            cols := ParseCSVLine(lines[A_Index])
            if (cols.Length >= 8) {
                status := Trim(cols[8], " `t`r`n`"")
                if (status == "Chưa làm") {
                    pending_rows.Push({idx: A_Index, data: cols})
                    batch_limit := (worker_mode == 3) ? 3 : 2
                    if (pending_rows.Length == batch_limit)
                        break
                }
            }
        }
        
        if (pending_rows.Length == 0) {
            if (mode == "manual") {
                MsgBox("Không còn học viên nào ở trạng thái 'Chưa làm' hoặc 'Lỗi' trong queue.")
            } else {
                ToolTip()
                MsgBox("Đã chạy xong toàn bộ danh sách Auto!")
            }
            break
        }
        
        start_time := FormatTime(, "HH:mm")
        
        for i, rowObj in pending_rows {
            stt := Trim(rowObj.data[1], " `t`r`n`"")
            if (mode == "auto") {
                ToolTip("ĐANG CHẠY CHẾ ĐỘ AUTO`nĐang xử lý STT " stt "...", 10, 10)
                SendDiscordLog("🚀 **[AUTO] Bắt đầu xử lý STT " stt "**")
            } else {
                SendDiscordLog("🚀 **[MANUAL] Bắt đầu xử lý STT " stt "**")
            }
            UpdateCSV(lines, rowObj.idx, "Đang làm", start_time)
        }
        
        ; Phase 1 for all pending rows
        results_p1 := []
        for i, rowObj in pending_rows {
            stt := Trim(rowObj.data[1], " `t`r`n`"")
            try {
                res := ProcessRow_Phase1(rowObj.data, lines, rowObj.idx, mode)
                results_p1.Push(res)
            } catch as e {
                SendDiscordLog("❌ CRASH tại STT " stt " (Phase 1): " e.Message)
                UpdateCSV(lines, rowObj.idx, "Lỗi")
                results_p1.Push("error")
                if (mode == "manual")
                    MsgBox("Lỗi xử lý Phase 1 STT " stt ": " e.Message)
            }
        }
        
        ; === KILL SWITCH giữa Phase 1 và Phase 2 ===
        if (mode == "auto" && FileExist(stop_file)) {
            try FileDelete(stop_file)
            SendDiscordLog("🛑 **[REMOTE STOP] Đã dừng Auto giữa chừng (sau Phase 1)!**")
            ToolTip()
            MsgBox("Đã dừng Auto theo lệnh từ xa!", "Remote Stop")
            break
        }
        
        ; Phase 2 for all pending rows
        for i, rowObj in pending_rows {
            if (results_p1[i] == "done" || results_p1[i] == "error")
                continue ; Already finished (Chỉ gửi giáo án) or failed
            
            stt := Trim(rowObj.data[1], " `t`r`n`"")
            try {
                res := ProcessRow_Phase2(rowObj.data, lines, rowObj.idx, mode)
                if (!res) {
                    UpdateCSV(lines, rowObj.idx, "Lỗi")
                    SendDiscordLog("❌ Không thành công ở STT " stt " (Phase 2)")
                }
            } catch as e {
                SendDiscordLog("❌ CRASH tại STT " stt " (Phase 2): " e.Message)
                UpdateCSV(lines, rowObj.idx, "Lỗi")
                if (mode == "manual")
                    MsgBox("Lỗi xử lý Phase 2 STT " stt ": " e.Message)
            }
        }
        
        if (mode == "manual") {
            break
        }
        Sleep(2000)
    }
    
    if (mode == "auto") {
        ; Tắt WakeLock
        DllCall("SetThreadExecutionState", "UInt", 0x80000000)
        ToolTip()
        res := MsgBox("Đã chạy xong Auto! Bạn có muốn dọn dẹp các dòng 'Đã làm' và 'Lỗi' vào thư mục Lịch sử luôn không?", "Dọn dẹp Queue", "YesNo")
        if (res == "Yes") {
            ArchiveHistory()
        }
    }
}

ProcessRow_Phase1(row_data, lines, target_idx, mode) {
    global worker_mode, id_page_long, id_page_duong, id_page_thao, id_mess, id_gpt_long, id_gpt_duong, id_gpt_thao, id_toola, tool_a_downloads
    stt := Trim(row_data[1], " `t`r`n`"")
    link := Trim(row_data[2], " `t`r`n`"")
    he := Trim(row_data[4], " `t`r`n`"")
    ma_giaoan := Trim(row_data[6], " `t`r`n`"")
    bai_nop := (row_data.Length >= 8) ? Trim(row_data[7], " `t`r`n`"") : ""
    xung_ho := (row_data.Length >= 11 && Trim(row_data[11], " `t`r`n`"") != "") ? Trim(row_data[11], " `t`r`n`"") : "Anh - Em (Mặc định)"
    
    worker := GetWorkerBySTT(stt, worker_mode)
    
    if InStr(link, "business.facebook.com") {
        platform := "page"
        if (worker == "long") {
            chat_win := "ahk_id " id_page_long
        } else if (worker == "duong") {
            chat_win := "ahk_id " id_page_duong
        } else {
            chat_win := "ahk_id " id_page_thao
        }
    } else {
        platform := "mess"
        chat_win := "ahk_id " id_mess
    }
    
    folder_paths := []
    if (ma_giaoan != "") {
        arr_giao_an := StrSplit(ma_giaoan, ",")
        for i, ga in arr_giao_an {
            ga := Trim(ga)
            if (ga != "") {
                sub_path := StrReplace(ga, "_", "\")
                folder_paths.Push("D:\A_Jobs_Tool\Nhận xét Mess\" . sub_path)
            }
        }
    }
    
    ToolTip("STT " stt ": Mở link chat...")
    SendDiscordLog("🔗 [Phase 1] Đang mở link chat cho STT " stt)
    
    WinActivate(chat_win)
    WinWaitActive(chat_win)
    Sleep(500)
    Send("^l")
    Sleep(200)
    A_Clipboard := link
    ClipWait(1)
    Send("^v")
    Sleep(200)
    Send("{Enter}")
    
    ; ===== CHỜ TRANG WEB TẢI (QUÉT ICON) =====
    Sleep(3000) ; Chờ 3 giây trước khi bắt đầu tìm icon
    
    icon_to_wait := (platform == "page") ? A_ScriptDir "\page_chat.png" : A_ScriptDir "\mess_chat.png"
    ToolTip("Đang đợi trang web tải (quét icon " icon_to_wait ")...", 100, 100)
    
    ; Đảm bảo cửa sổ được active để quét không bị che
    WinActivate(chat_win)
    
    CoordMode("Pixel", "Screen")
    if (platform == "mess") {
        VX := 797, VY := 442, VW := 144, VH := 67
    } else {
        VX := SysGet(76)
        VY := SysGet(77)
        VW := SysGet(78)
        VH := SysGet(79)
    }
    Loop { ; Quét liên tục KHÔNG giới hạn thời gian, đợi đến khi tìm thấy icon
        if ImageSearch(&ix, &iy, VX, VY, VX + VW, VY + VH, "*120 " icon_to_wait) {
            ToolTip("✅ Đã tìm thấy icon tại " ix ", " iy "! Chờ 2s...", 100, 100)
            break
        }
        Sleep(300)
    }
    
    Sleep(2000) ; Chờ 2 giây sau khi tìm thấy icon để trang tải hoàn toàn
    ToolTip()
    
    ; Đảm bảo focus lại đúng cửa sổ
    WinActivate(chat_win)
    WinWaitActive(chat_win)
    Sleep(500)
    
    ; ===== CLICK VÀO Ô CHAT =====
    CoordMode("Mouse", "Screen")
    if (platform == "page") {
        ClickPageChat()
    } else {
        ClickMessChat()
    }
    CoordMode("Mouse", "Client")
    Sleep(500)
    
    ; ===== GỬI LỜI CHÀO =====
    if InStr(xung_ho, "Mình - Bạn")
        A_Clipboard := "Mình chữa bài bạn nha"
    else if InStr(xung_ho, "Em - Chị")
        A_Clipboard := "Em chữa bài chị nha"
    else if InStr(xung_ho, "Em - Anh")
        A_Clipboard := "Em chữa bài anh nha"
    else
        A_Clipboard := ""
        
    if (A_Clipboard != "") {
        ClipWait(1)
        Send("^v")
        Sleep(1000)
        Send("{Enter}")
        Sleep(500)
    }
    
    if (mode == "manual") {
        ToolTip("Đã mở link chat. Bạn hãy tải file bài làm của học viên.`nSAU KHI TẢI XONG, BẤM F9 ĐỂ TOOL S CHẠY TIẾP.", 100, 100)
        KeyWait("F9", "D")
        ToolTip()
        
        ; Focus lại sau khi người dùng tải xong và bấm F9
        WinActivate(chat_win)
        WinWaitActive(chat_win)
        Sleep(500)
        
        CoordMode("Mouse", "Screen")
        if (platform == "page") {
            ClickPageChat()
        } else {
            ClickMessChat()
        }
        CoordMode("Mouse", "Client")
        Sleep(500)
    }
    
    if (he == "") {
        ; CHỈ GỬI GIÁO ÁN
        if (folder_paths.Length > 0) {
            for i, fp in folder_paths {
                CheckPause() ; Kiểm tra F7 pause
                SendGiaoAn(fp, chat_win)
                Sleep(1000)
            }
        } else {
            if (mode == "manual") {
                MsgBox("LỖI: STT " stt " được chọn là 'Chỉ gửi giáo án' nhưng lại không có mã giáo án!")
            }
            return "error"
        }
        ToolTip()
        if (mode == "manual") {
            MsgBox("Đã gửi giáo án xong cho STT " stt)
        }
        SendDiscordLog("✅ Đã hoàn thành (Chỉ gửi giáo án) cho STT " stt)
        end_time := FormatTime(, "HH:mm")
        UpdateCSV(lines, target_idx, "Đã làm", "", end_time)
        return "done"
    }
    
    A_Clipboard := "Anh chữa bài em nha ^^"
    ClipWait(1)
    Send("^v")
    Sleep(200)
    Send("{Enter}")
    Sleep(500)
    
    CheckPause() ; F7: Sau khi gửi lời chào
    
    WinActivate("ahk_id " id_toola)
    WinWaitActive("ahk_id " id_toola)
    Sleep(500)
    
    Send("^u")
    WinWaitActive("Chọn file học viên",, 5)
    if WinActive("Chọn file học viên") {
        Sleep(500)
        files_to_send := ""
        if (bai_nop != "") {
            if InStr(bai_nop, "|") {
                arr := StrSplit(bai_nop, "|")
                for i, f in arr {
                    if FileExist(f) {
                        files_to_send .= "`"" f "`" "
                    }
                }
            } else if FileExist(bai_nop) {
                files_to_send := "`"" bai_nop "`""
            }
        }
        
        if (files_to_send != "") {
            A_Clipboard := Trim(files_to_send)
            ClipWait(1)
            Send("^v")
            Sleep(500)
            Send("{Enter}")
            WinWaitClose("Chọn file học viên",, 5)
        } else {
            if (mode == "auto") {
                SendDiscordLog("❌ LỖI: Đường dẫn bài nộp không hợp lệ hoặc file bị xóa ở STT " stt)
                Send("{Esc}")
                Sleep(500)
                return "error"
            }
            
            dl_files := GetAllFiles(tool_a_downloads, "*.docx", "Bài chữa")
            dl_txt := GetAllFiles(tool_a_downloads, "*.txt", "Bài chữa")
            for i, f in dl_txt
                dl_files.Push(f)
            
            if (dl_files.Length > 0) {
                clipboard_str := ""
                for i, f in dl_files {
                    clipboard_str .= "`"" f "`" "
                }
                A_Clipboard := Trim(clipboard_str)
                ClipWait(1)
                Send("^v")
                Sleep(500)
                Send("{Enter}")
                WinWaitClose("Chọn file học viên",, 5)
            } else {
                ToolTip("Không tìm thấy file Word nào trong thư mục Downloads!", 100, 100)
                if (mode == "auto") {
                    return "error"
                }
            }
        }
        Sleep(1000)
    }
    
    CheckPause() ; F7: Sau khi nạp file xong vào Tool A
    
    WinActivate("ahk_id " id_toola)
    WinWaitActive("ahk_id " id_toola,, 5)
    Sleep(1000)
    
    he_upper := StrUpper(he)
    if InStr(he_upper, "GEN")
        Send("{F1}")
    else if InStr(he_upper, "VSTEP")
        Send("{F2}")
    else if InStr(he_upper, "ADV")
        Send("{F3}")
    else
        Send("{F1}")
        
    Sleep(3000)
    
    A_Clipboard := ""
    Send("^p")
    ClipWait(3)
    SendDiscordLog("⏳ [Phase 1] Đang dán bài và nhờ ChatGPT chữa...")
    
    if (worker == "long")
        gpt_win := id_gpt_long
    else if (worker == "duong")
        gpt_win := id_gpt_duong
    else
        gpt_win := id_gpt_thao
    
    CheckPause() ; F7: Trước khi dán prompt vào GPT
    
    WinActivate("ahk_id " gpt_win)
    WinWaitActive("ahk_id " gpt_win)
    Sleep(1000)
    
    CoordMode("Mouse", "Screen")
    ClickGptChat(gpt_win)
    CoordMode("Mouse", "Client")
    Sleep(500)
    
    clipboard_content := A_Clipboard
    if InStr(xung_ho, "Mình - Bạn")
        clipboard_content := "chỉ riêng bài này đổi thành xưng hô Mình - bạn vì học viên bằng tuổi`n`n" clipboard_content
    else if InStr(xung_ho, "Em - Chị")
        clipboard_content := "chỉ riêng bài này đổi thành xưng hô Em - chị vì học viên lớn tuổi`n`n" clipboard_content
    else if InStr(xung_ho, "Em - Anh")
        clipboard_content := "chỉ riêng bài này đổi thành xưng hô Em - anh vì học viên lớn tuổi`n`n" clipboard_content

    A_Clipboard := clipboard_content
    ClipWait(1)

    Send("^v")
    Sleep(500)
    
    ; Tối ưu: Đợi nút Send của GPT xuất hiện thay vì đợi cứng 12s
    img_path := A_ScriptDir "\gpt_send_ready.png"
    if FileExist(img_path) {
        CoordMode("Pixel", "Screen")
        waitStart := A_TickCount
        Loop {
            found := 0
            try {
                if ImageSearch(&fX, &fY, 1810, 410, 1900, 490, "*40 " img_path)
                    found := 1
            }
            if (found) {
                Sleep(200) ; Nghỉ thêm 1 chút xíu cho an toàn khi nút vừa hiện
                break
            }
            if (A_TickCount - waitStart > 30000) { ; Tối đa 30s
                SendDiscordLog("⚠️ Chờ GPT load file quá 30s, buộc gửi luôn!")
                break
            }
            Sleep(400) ; Quét lại mỗi 0.4s
        }
    } else {
        Sleep(12000) ; Fallback nếu lỡ bị xóa mất ảnh
    }

    Send("{Enter}")
    Sleep(1000)
    Send("{Enter}")
    Sleep(1000)
    
    return "continue"
}

ProcessRow_Phase2(row_data, lines, target_idx, mode) {
    global worker_mode, id_page_long, id_page_duong, id_page_thao, id_mess, id_gpt_long, id_gpt_duong, id_gpt_thao, id_toola, tool_a_downloads
    stt := Trim(row_data[1], " `t`r`n`"")
    link := Trim(row_data[2], " `t`r`n`"")
    gui_giaoan := Trim(row_data[5], " `t`r`n`"")
    ma_giaoan := Trim(row_data[6], " `t`r`n`"")
    xung_ho := (row_data.Length >= 11 && Trim(row_data[11], " `t`r`n`"") != "") ? Trim(row_data[11], " `t`r`n`"") : "Anh - Em (Mặc định)"
    
    worker := GetWorkerBySTT(stt, worker_mode)
    
    if InStr(link, "business.facebook.com") {
        platform := "page"
        if (worker == "long") {
            chat_win := "ahk_id " id_page_long
        } else if (worker == "duong") {
            chat_win := "ahk_id " id_page_duong
        } else {
            chat_win := "ahk_id " id_page_thao
        }
    } else {
        platform := "mess"
        chat_win := "ahk_id " id_mess
    }
    
    folder_paths := []
    if (ma_giaoan != "") {
        arr_giao_an := StrSplit(ma_giaoan, ",")
        for i, ga in arr_giao_an {
            ga := Trim(ga)
            if (ga != "") {
                sub_path := StrReplace(ga, "_", "\")
                folder_paths.Push("D:\A_Jobs_Tool\Nhận xét Mess\" . sub_path)
            }
        }
    }
    
    if (worker == "long")
        gpt_win := id_gpt_long
    else if (worker == "duong")
        gpt_win := id_gpt_duong
    else
        gpt_win := id_gpt_thao
    
    SendDiscordLog("⏳ [Phase 2] Đang đợi kết quả từ ChatGPT cho STT " stt "...")
    
    WinActivate("ahk_id " gpt_win)
    WinWaitActive("ahk_id " gpt_win)
    Sleep(1000)
    
    foundCopy := false
    Loop 200 {
        CheckPause() ; Kiểm tra F7 pause
        CoordMode("Pixel", "Screen")
        CoordMode("Mouse", "Screen")
        if ImageSearch(&arrX, &arrY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*80 scroll.png") {
            Click(arrX + 10, arrY + 10)
            Sleep(1000)
            break
        }
        Sleep(5000)
    }
    CoordMode("Pixel", "Screen")
    CoordMode("Mouse", "Screen")
    
    Loop 200 {
        CheckPause() ; Kiểm tra F7 pause
        if ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*80 copy.png") {
            lastX := FoundX
            lastY := FoundY
            Sleep(6000)
            A_Clipboard := ""
            if ImageSearch(&NewX, &NewY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*80 copy.png") {
                Click(NewX + 15, NewY + 15)
            } else {
                Click(lastX + 15, lastY + 15)
            }
            ClipWait(3)
            foundCopy := true
            break
        }
        Sleep(4000)
    }
    
    CoordMode("Mouse", "Client")
    
    if (!foundCopy) {
        if (mode == "manual") {
            ToolTip("Không copy được! Bạn hãy copy thủ công, Tool S sẽ tự đi tiếp.", 100, 100)
            ClipWait(300)
        } else {
            return false
        }
    }
    
    ToolTip()
    
    if (A_Clipboard == "") {
        if (mode == "manual") {
            MsgBox("Lỗi: Không lấy được nội dung từ GPTs!")
        }
        return false
    }
    
    ; --- LƯU LẠI CLIPBOARD CHỨA BÀI CHỮA TỪ GPT ---
    gpt_clipboard := ClipboardAll()
    
    CheckPause() ; F7: Sau khi copy kết quả GPT
    
    ; --- MỞ LẠI LINK VÀ CHỜ 10 GIÂY TRƯỚC ---
    WinActivate(chat_win)
    WinWaitActive(chat_win)
    Sleep(500)
    
    Send("^l")
    Sleep(200)
    A_Clipboard := link
    ClipWait(1)
    Send("^v")
    Sleep(200)
    Send("{Enter}")
    
    ; ===== CHỜ TRANG WEB TẢI LẠI (QUÉT ICON) =====
    Sleep(3000) ; Chờ 3 giây trước khi bắt đầu tìm icon
    icon_to_wait := (platform == "page") ? A_ScriptDir "\page_chat.png" : A_ScriptDir "\mess_chat.png"
    ToolTip("Đang đợi trang web tải lại (quét icon " icon_to_wait ")...", 100, 100)
    
    WinActivate(chat_win)
    CoordMode("Pixel", "Screen")
    if (platform == "mess") {
        VX := 797, VY := 442, VW := 144, VH := 67
    } else {
        VX := SysGet(76)
        VY := SysGet(77)
        VW := SysGet(78)
        VH := SysGet(79)
    }
    Loop { ; Quét liên tục KHÔNG giới hạn thời gian, đợi đến khi tìm thấy icon
        if ImageSearch(&ix, &iy, VX, VY, VX + VW, VY + VH, "*120 " icon_to_wait) {
            ToolTip("✅ Đã tìm thấy icon tại " ix ", " iy "! Chờ 2s...", 100, 100)
            break
        }
        Sleep(300)
    }
    Sleep(2000) ; Chờ 2 giây sau khi tìm thấy icon để trang tải hoàn toàn
    ToolTip()
    
    ; --- PHỤC HỒI LẠI CLIPBOARD VÀ SANG TOOL A XỬ LÝ ---
    A_Clipboard := gpt_clipboard
    ClipWait(1)
    
    WinActivate("ahk_id " id_toola)
    WinWaitActive("ahk_id " id_toola)
    Sleep(500)
    
    Send("^{Delete}")
    Sleep(200)
    Send("^d")
    Sleep(500)
    
    Send("^f")
    Sleep(2000)
    
    Send("^+c")
    Sleep(500)
    Send("^w")
    Sleep(1000)
    
    ; --- QUAY LẠI KHUNG CHAT (VỪA LOAD XONG) ĐỂ GỬI ---
    CheckPause() ; F7: Trước khi gửi bài chữa vào chat
    
    WinActivate(chat_win)
    WinWaitActive(chat_win)
    Sleep(500)
    
    CoordMode("Mouse", "Screen")
    if (platform == "page") {
        ClickPageChat()
    } else {
        ClickMessChat()
    }
    CoordMode("Mouse", "Client")
    Sleep(2000)
    
    Send("^v")
    Sleep(6000)
    Send("{Enter}")
    Sleep(1000)
    
    latest_word := GetLatestFile(tool_a_downloads, "Bài chữa*.docx")
    if (latest_word != "") {
        CheckPause() ; F7: Trước khi gửi file Word
        SetClipboardFiles([latest_word])
        Sleep(500)
        Send("^v")
        if (platform == "page") {
            WaitForIcon("icon_file.png")
            Sleep(1500)
        } else {
            Sleep(1750)
        }
        Send("{Enter}")
        Sleep(1000)
        
        if InStr(xung_ho, "Mình - Bạn")
            A_Clipboard := "Mình gửi bạn bài chữa nha"
        else if InStr(xung_ho, "Em - Chị")
            A_Clipboard := "Em gửi chị bài chữa nha"
        else if InStr(xung_ho, "Em - Anh")
            A_Clipboard := "Em gửi anh bài chữa nha"
        else
            A_Clipboard := "Anh gửi em bài chữa nha"

        ClipWait(1)
        Send("^v")
        Sleep(6000)
        Send("{Enter}")
        Sleep(1000)
        
        FileMove(latest_word, latest_word ".sent", 1)
    } else {
        if (mode == "manual") {
            MsgBox("Không tìm thấy file Bài chữa.docx để gửi!")
        }
        return false
    }
    
    char_dau := SubStr(StrUpper(gui_giaoan), 1, 1)
    if (char_dau == "C" && folder_paths.Length > 0) {
        for i, fp in folder_paths {
            CheckPause() ; Kiểm tra F7 pause
            SendGiaoAn(fp, chat_win)
            Sleep(1000)
        }
    }
    
    ToolTip()
    if (mode == "manual") {
        MsgBox("Đã hoàn thành cho STT " stt "!")
    }
    SendDiscordLog("✅ Đã hoàn thành (Chữa bài & Gửi giáo án) cho STT " stt)
    end_time := FormatTime(, "HH:mm")
    UpdateCSV(lines, target_idx, "Đã làm", "", end_time)
    
    ; Kiểm tra bộ đếm: mỗi 5 bài chữa sẽ gửi Thông tin S để GPTs relax
    CheckGradedCounter(worker)
    
    return true
}

UpdateCSV(lines, row_index, new_status, new_start_time := "", new_end_time := "") {
    cols := ParseCSVLine(lines[row_index])
    while (cols.Length < 11) {
        cols.Push("")
    }
    cols[8] := new_status
    if (new_start_time != "")
        cols[9] := new_start_time
    if (new_end_time != "")
        cols[10] := new_end_time
        
    new_row := ToCSVLine(cols)
    lines[row_index] := new_row
    
    new_content := ""
    for i, line in lines {
        if Trim(line) != ""
            new_content .= line "`n"
    }
    
    try {
        if FileExist(queue_file) {
            FileDelete(queue_file)
        }
        FileAppend(new_content, queue_file, "UTF-8")
    } catch as e {
        MsgBox("KHÔNG THỂ CẬP NHẬT FILE EXCEL!`n`nVui lòng TẮT FILE EXCEL (queue.csv) trước khi chạy Tool S, vì Excel đang khóa file này. Bạn hãy tắt Excel và tự lưu lại nhé!`n`nLỗi chi tiết: " e.Message)
    }
}

GetAllFiles(folder, pattern, exclude_string := "") {
    files := []
    Loop Files, folder "\" pattern {
        if (exclude_string != "" && InStr(A_LoopFileName, exclude_string))
            continue
        files.Push(A_LoopFileFullPath)
    }
    return files
}

ClickPageChat() {
    CoordMode("Mouse", "Screen")
    CoordMode("Pixel", "Screen")
    ToolTip("Đang quét Page Chat bằng AHK ImageSearch...", 100, 100)
    
    VX := SysGet(76)
    VY := SysGet(77)
    VW := SysGet(78)
    VH := SysGet(79)
    
    icon_path := A_ScriptDir "\page_chat.png"
    found := false
    FoundX := 0
    FoundY := 0
    
    ; Thử tìm icon page_chat với nhiều mức tolerance (từ chính xác đến dễ dãi)
    for tol in [80, 120, 150] {
        if ImageSearch(&FoundX, &FoundY, VX, VY, VX + VW, VY + VH, "*" tol " " icon_path) {
            found := true
            ToolTip("Tìm thấy page_chat tại " FoundX ", " FoundY " (tol *" tol ")", 100, 100)
            break
        }
    }
    
    if (found) {
        ; Di chuyển chuột đến vị trí icon (dịch trái 15px tránh viền), rồi dò LÊN TRÊN tìm IBeam
        startX := FoundX - 15
        startY := FoundY
        MouseMove(startX, startY)
        Sleep(300)
        
        foundIBeam := false
        Loop 60 {
            if (A_Cursor == "IBeam") {
                ; Tìm thấy IBeam! Click 2 lần chắc chắn xác nhận khung chat
                Sleep(200)
                Click(startX, startY)
                Sleep(300)
                Click(startX, startY)
                foundIBeam := true
                ToolTip("✅ Đã click xác nhận khung chat Page tại " startX ", " startY, 100, 100)
                Sleep(500)
                break
            }
            startY := startY - 5
            MouseMove(startX, startY)
            Sleep(40)
        }
        
        if (!foundIBeam) {
            ; Fallback: click ở vị trí icon dịch lên 40px
            ToolTip("Không tìm thấy IBeam! Click dự phòng...", 100, 100)
            Click(FoundX - 15, FoundY - 40)
            Sleep(300)
            Click(FoundX - 15, FoundY - 40)
            Sleep(1000)
        }
    } else {
        ; Không tìm thấy icon → Click dự phòng vào tọa độ cố định
        ToolTip("LỖI: Không tìm thấy page_chat.png! Click dự phòng vào " page_chat_click_x ", " page_chat_click_y ".", 100, 100)
        Click(page_chat_click_x, page_chat_click_y)
        Sleep(300)
        Click(page_chat_click_x, page_chat_click_y)
        Sleep(2000)
    }
    ToolTip()
    CoordMode("Mouse", "Client")
}

ClickMessChat() {
    CoordMode("Mouse", "Screen")
    CoordMode("Pixel", "Screen")
    ToolTip("Đang quét Mess Chat bằng AHK ImageSearch...", 100, 100)
    
    ; Vùng quét chính xác cho icon mess_chat (chỉ quét trong vùng này)
    VX := 797
    VY := 442
    VW := 144
    VH := 67
    
    icon_path := A_ScriptDir "\mess_chat.png"
    found := false
    FoundX := 0
    FoundY := 0
    
    ; Thử tìm icon mess_chat với nhiều mức tolerance (từ chính xác đến dễ dãi)
    for tol in [80, 120, 150] {
        if ImageSearch(&FoundX, &FoundY, VX, VY, VX + VW, VY + VH, "*" tol " " icon_path) {
            found := true
            ToolTip("Tìm thấy mess_chat tại " FoundX ", " FoundY " (tol *" tol ")", 100, 100)
            break
        }
    }
    
    if (found) {
        ; Di chuyển chuột đến vị trí icon, rồi dò SANG TRÁI tìm IBeam
        startX := FoundX
        startY := FoundY + 10
        MouseMove(startX, startY)
        Sleep(300)
        
        foundIBeam := false
        Loop 80 {
            if (A_Cursor == "IBeam") {
                ; Tìm thấy IBeam! Click 2 lần chắc chắn xác nhận khung chat
                Sleep(200)
                Click(startX, startY)
                Sleep(300)
                Click(startX, startY)
                foundIBeam := true
                ToolTip("✅ Đã click xác nhận khung chat Mess tại " startX ", " startY, 100, 100)
                Sleep(500)
                break
            }
            startX := startX - 8
            MouseMove(startX, startY)
            Sleep(40)
        }
        
        if (!foundIBeam) {
            ; Fallback: click vào vị trí cố định
            ToolTip("Không tìm thấy IBeam sau khi quét! Click dự phòng...", 100, 100)
            Click(mess_chat_click_x, mess_chat_click_y)
            Sleep(300)
            Click(mess_chat_click_x, mess_chat_click_y)
            Sleep(1000)
        }
    } else {
        ; Không tìm thấy icon → dùng Auto-Scan IBeam dự phòng từ giữa vùng
        ToolTip("Không tìm thấy mess_chat.png! Đang dùng Auto-Scan IBeam dự phòng...", 100, 100)
        startX := VX + (VW / 2)  ; Giữa vùng quét
        startY := VY + (VH / 2)
        MouseMove(startX, startY)
        Sleep(300)
        
        foundIBeam := false
        Loop 80 {
            if (A_Cursor == "IBeam") {
                Sleep(200)
                Click(startX, startY)
                Sleep(300)
                Click(startX, startY)
                foundIBeam := true
                ToolTip("✅ Đã click xác nhận khung chat Mess (dự phòng) tại " startX ", " startY, 100, 100)
                Sleep(500)
                break
            }
            startX := startX - 8
            MouseMove(startX, startY)
            Sleep(40)
        }
        
        if (!foundIBeam) {
            ToolTip("Vẫn không thấy IBeam! Click đại vào " mess_chat_click_x ", " mess_chat_click_y ".", 100, 100)
            Click(mess_chat_click_x, mess_chat_click_y)
            Sleep(300)
            Click(mess_chat_click_x, mess_chat_click_y)
            Sleep(2000)
        }
    }
    
    ToolTip()
    CoordMode("Mouse", "Client")
}

ClickGptChat(gpt_win := "") {
    CoordMode("Mouse", "Screen")
    CoordMode("Pixel", "Screen")
    ToolTip("Đang quét ô chat GPT bằng AHK ImageSearch...", 100, 100)
    
    searchX1 := 0, searchY1 := 0, searchX2 := A_ScreenWidth, searchY2 := A_ScreenHeight
    if (gpt_win != "") {
        WinGetPos(&gptX, &gptY, &gptW, &gptH, "ahk_id " gpt_win)
        searchX1 := gptX
        searchY1 := gptY
        searchX2 := gptX + gptW
        searchY2 := gptY + gptH
    }
    
    if ImageSearch(&FoundX, &FoundY, searchX1, searchY1, searchX2, searchY2, "*80 " A_ScriptDir "\gpt_chat.png") {
        ; Icon "+" nằm bên trái ô chat, dịch sang phải để vào vùng text
        startX := FoundX + 40
        startY := FoundY + 5
        MouseMove(startX, startY)
        Sleep(200)
        
        foundIBeam := false
        Loop 30 {
            if (A_Cursor == "IBeam") {
                Sleep(300)
                Click(startX, startY)
                Sleep(200)
                Click(startX, startY)
                foundIBeam := true
                break
            }
            startX := startX + 10
            MouseMove(startX, startY)
            Sleep(50)
        }
        
        if (!foundIBeam) {
            ; Fallback: click ngay bên phải icon
            Click(FoundX + 60, FoundY + 5)
            Sleep(200)
            Click(FoundX + 60, FoundY + 5)
        }
    } else {
        ; Fallback cuối: dùng cách cũ - click vào giữa dưới cửa sổ
        ToolTip("LỖI: Không tìm thấy gpt_chat.png! Thử click dự phòng...", 100, 100)
        if (gpt_win != "") {
            WinGetPos(&gptX, &gptY, &gptW, &gptH, "ahk_id " gpt_win)
            CoordMode("Mouse", "Window")
            Click(gptW / 2, gptH - gpt_chat_offset_y)
            Sleep(200)
            Click(gptW / 2, gptH - gpt_chat_offset_y)
        }
        Sleep(2000)
    }
    ToolTip()
    CoordMode("Mouse", "Client")
}

GetLatestFile(folder, pattern, exclude_string := "") {
    latestTime := 0
    latestFile := ""
    Loop Files, folder "\" pattern {
        if (exclude_string != "" && InStr(A_LoopFileName, exclude_string))
            continue
        if (A_LoopFileTimeModified > latestTime) {
            latestTime := A_LoopFileTimeModified
            latestFile := A_LoopFileFullPath
        }
    }
    return latestFile
}

SetClipboardFiles(files) {
    totalChars := 1
    for i, filePath in files {
        totalChars += StrLen(filePath) + 1
    }
    dropFilesSize := 20
    totalBytes := dropFilesSize + totalChars * 2
    hMem := DllCall("GlobalAlloc", "UInt", 0x42, "UPtr", totalBytes, "Ptr")
    pMem := DllCall("GlobalLock", "Ptr", hMem, "Ptr")
    NumPut("UInt", dropFilesSize, pMem, 0)
    NumPut("Int", 0, pMem, 4)
    NumPut("Int", 0, pMem, 8)
    NumPut("Int", 0, pMem, 12)
    NumPut("Int", 1, pMem, 16)
    offset := dropFilesSize
    for i, filePath in files {
        StrPut(filePath, pMem + offset, "UTF-16")
        offset += (StrLen(filePath) + 1) * 2
    }
    NumPut("UShort", 0, pMem, offset)
    DllCall("GlobalUnlock", "Ptr", hMem)
    if !DllCall("OpenClipboard", "Ptr", A_ScriptHwnd) {
        MsgBox("Không mở được clipboard.")
        return
    }
    DllCall("EmptyClipboard")
    DllCall("SetClipboardData", "UInt", 15, "Ptr", hMem)
    DllCall("CloseClipboard")
}

WaitForIcon(expected_icon) {
    CoordMode("Pixel", "Screen")
    CoordMode("Mouse", "Screen")
    
    icon_dir := A_ScriptDir "\"
    searchX1 := 527
    searchY1 := 257
    searchX2 := 918
    searchY2 := 488
    
    ToolTip("Đang chờ icon " expected_icon "...")
    ; Chờ tối đa 10 giây (50 * 200ms) để icon xuất hiện
    Loop 50 {
        if ImageSearch(&ix, &iy, searchX1, searchY1, searchX2, searchY2, "*60 " icon_dir expected_icon) {
            ToolTip()
            return true
        }
        Sleep(200)
    }
    ToolTip("⏳ Timeout chờ icon " expected_icon "!")
    Sleep(500)
    ToolTip()
    return false
}

WaitForAnyMediaIcon() {
    CoordMode("Pixel", "Screen")
    CoordMode("Mouse", "Screen")
    
    icon_dir := A_ScriptDir "\"
    searchX1 := 527
    searchY1 := 257
    searchX2 := 918
    searchY2 := 488
    
    ToolTip("Đang chờ icon bất kỳ...")
    ; Chờ tối đa 10 giây (50 * 200ms)
    Loop 50 {
        if ImageSearch(&ix, &iy, searchX1, searchY1, searchX2, searchY2, "*60 " icon_dir "icon_image.png") {
            ToolTip()
            return "image"
        }
        if ImageSearch(&ix, &iy, searchX1, searchY1, searchX2, searchY2, "*60 " icon_dir "icon_file.png") {
            ToolTip()
            return "file"
        }
        if ImageSearch(&ix, &iy, searchX1, searchY1, searchX2, searchY2, "*60 " icon_dir "icon_video.png") {
            ToolTip()
            return "video"
        }
        Sleep(200)
    }
    ToolTip()
    return "timeout"
}

SendGiaoAn(folder_path, chat_win) {
    orderFile := folder_path "\thu_tu_gui.txt"
    if !FileExist(orderFile) {
        SendDiscordLog("⚠️ Lỗi: Không tìm thấy thu_tu_gui.txt trong " folder_path)
        return
    }

    content := FileRead(orderFile, "UTF-8")
    items := []
    Loop Parse, content, "`n", "`r" {
        line := Trim(A_LoopField)
        if (line != "")
            items.Push(line)
    }

    if (items.Length == 0)
        return
        
    ToolTip("Đang gửi giáo án từ: " folder_path)
    
    ; Focus đúng vào ô chat trước khi gửi toàn bộ giáo án
    WinActivate(chat_win)
    WinWaitActive(chat_win)
    Sleep(500)
    
    ; Xác định platform (sửa: thêm id_page_thao)
    if InStr(chat_win, id_page_long) || InStr(chat_win, id_page_duong) || InStr(chat_win, id_page_thao) {
        platform := "page"
    } else {
        platform := "mess"
    }
    
    ; Chờ icon chat xuất hiện trước khi click (đảm bảo trang đã tải xong)
    icon_to_wait := (platform == "page") ? A_ScriptDir "\page_chat.png" : A_ScriptDir "\mess_chat.png"
    CoordMode("Pixel", "Screen")
    if (platform == "mess") {
        sVX := 797, sVY := 442, sVW := 144, sVH := 67
    } else {
        sVX := SysGet(76)
        sVY := SysGet(77)
        sVW := SysGet(78)
        sVH := SysGet(79)
    }
    ToolTip("Đang chờ icon chat xuất hiện trước khi gửi giáo án...", 100, 100)
    Loop { ; Quét liên tục KHÔNG giới hạn thời gian, đợi đến khi tìm thấy icon
        if ImageSearch(&tmpX, &tmpY, sVX, sVY, sVX + sVW, sVY + sVH, "*120 " icon_to_wait) {
            ToolTip("✅ Đã tìm thấy icon chat! Chờ 2s...", 100, 100)
            break
        }
        Sleep(300)
    }
    Sleep(2000) ; Chờ 2 giây sau khi tìm thấy icon để trang tải hoàn toàn
    ToolTip()
    
    ; Click xác nhận khung chat (tìm icon → dò IBeam → click 2 lần)
    CoordMode("Mouse", "Screen")
    if (platform == "page") {
        ClickPageChat()
    } else {
        ClickMessChat()
    }
    CoordMode("Mouse", "Client")
    Sleep(500)

    for index, itemName in items {
        CheckPause() ; Kiểm tra F7 pause
        itemPath := folder_path "\" itemName
        if !FileExist(itemPath) {
            continue ; Bỏ qua nếu file không tồn tại
        }

        WinActivate(chat_win)
        if !WinWaitActive(chat_win, , 3) {
            SendDiscordLog("⚠️ Cảnh báo: Không thể active cửa sổ chat " chat_win " khi đang gửi giáo án.")
        }
        Sleep(300)
        
        ; 1. Thư mục -> Gửi toàn bộ file bên trong
        if InStr(FileExist(itemPath), "D") {
            files := []
            Loop Files, itemPath "\*.*", "F" {
                files.Push(A_LoopFileFullPath)
            }
            if (files.Length > 0) {
                SetClipboardFiles(files)
                Sleep(500)
                Send("^v")
                if (platform == "page") {
                    WaitForAnyMediaIcon()
                    Sleep(2000) ; Thư mục -> Chờ 2.0s
                } else {
                    Sleep(3000) ; Mess -> Chờ cứng 3.0s
                }
                Send("{Enter}")
                Sleep(2000)
            }
            continue
        }

        ; 2. File
        SplitPath(itemPath, &name, &dir, &ext, &name_no_ext, &drive)
        ext := StrLower(ext)

        if (ext == "txt") {
            ; Đọc text, dán và gửi liền
            txtContent := FileRead(itemPath, "UTF-8")
            oldClipboard := A_Clipboard
            A_Clipboard := txtContent
            ClipWait(1)
            Send("^v")
            Sleep(3000) ; Text -> Chờ 3 giây
            Send("{Enter}")
            Sleep(2000)
            A_Clipboard := oldClipboard
        } else if (ext == "mp4" || ext == "mov" || ext == "avi") {
            ; Gửi video
            SetClipboardFiles([itemPath])
            Sleep(500)
            Send("^v")
            if (platform == "page") {
                WaitForIcon("icon_video.png")
                Sleep(3000) ; Video -> Chờ thêm 3 giây
            } else {
                Sleep(12000) ; Mess -> Chờ mặc định 12 giây để upload video ổn định
            }
            Send("{Enter}")
            Sleep(2000)
        } else if (ext == "jpg" || ext == "png" || ext == "jpeg" || ext == "gif") {
            ; Gửi ảnh
            SetClipboardFiles([itemPath])
            Sleep(500)
            Send("^v")
            if (platform == "page") {
                WaitForIcon("icon_image.png")
                Sleep(2000) ; Ảnh -> Chờ 2 giây
            } else {
                Sleep(3000) ; Mess -> Chờ mặc định 3 giây
            }
            Send("{Enter}")
            Sleep(2000)
        } else {
            ; Gửi file thật
            SetClipboardFiles([itemPath])
            Sleep(500)
            Send("^v")
            if (platform == "page") {
                WaitForIcon("icon_file.png")
                Sleep(2000) ; File -> Chờ 2 giây
            } else {
                Sleep(3000) ; Mess -> Chờ mặc định 3 giây
            }
            Send("{Enter}")
            Sleep(2000)
        }
    }
    ToolTip()
}

ArchiveHistory(manual := false) {
    global queue_file
    if !FileExist(queue_file)
        return
        
    history_dir := A_ScriptDir "\History"
    if !DirExist(history_dir)
        DirCreate(history_dir)
        
    date_str := FormatTime(, "dd_MM_yyyy_HH_mm_ss")
    history_file := history_dir "\history_" date_str ".csv"
    
    content := FileRead(queue_file, "UTF-8")
    lines := StrSplit(content, "`n", "`r")
    
    new_queue := ""
    history_content := ""
    
    if !FileExist(history_file) {
        history_content .= "STT,Link chat,Loại việc,Hệ bài chữa,Gửi giáo án,Mã giáo án,Đường dẫn bài nộp,Trạng thái,Thời gian bắt đầu,Thời gian hoàn thành,Xưng hô`n"
    }
    
    moved_count := 0
    
    for i, line in lines {
        if (i == 1) {
            new_queue .= line "`n"
            continue
        }
        if Trim(line) == ""
            continue
            
        cols := ParseCSVLine(line)
        if (cols.Length >= 8) {
            status := Trim(cols[8], " `t`r`n`"")
            if (status == "Đã làm" || status == "Lỗi") {
                history_content .= line "`n"
                moved_count++
            } else {
                new_queue .= line "`n"
            }
        } else {
            new_queue .= line "`n"
        }
    }
    
    if (moved_count > 0) {
        try {
            FileMove(queue_file, queue_file ".tmp", 1)
            FileAppend(history_content, history_file, "UTF-8")
            FileDelete(queue_file ".tmp")
            FileAppend(Trim(new_queue, "`n") "`n", queue_file, "UTF-8")
            if (manual)
                MsgBox("Đã dọn dẹp và lưu " moved_count " dòng vào thư mục History!")
        } catch as e {
            if FileExist(queue_file ".tmp")
                FileMove(queue_file ".tmp", queue_file, 1)
            MsgBox("Không thể dọn dẹp! Vui lòng TẮT FILE EXCEL đi trước khi dọn dẹp nhé!")
        }
    } else {
        if (manual)
            MsgBox("Không có dòng nào ở trạng thái 'Đã làm' hoặc 'Lỗi' để dọn dẹp.")
    }
}

OpenExcelWithFormat(filename := "queue.csv", sheetName := "Chung") {
    csv_path := A_ScriptDir "\" filename
    
    if !FileExist(csv_path) {
        MsgBox("Không tìm thấy file " filename)
        return
    }
    
    ; 1. Kiểm tra nếu file Excel này đã được mở sẵn cửa sổ rồi thì active nó lên, tránh mở đè tạo bản read-only
    old_match_mode := A_TitleMatchMode
    SetTitleMatchMode(2)
    if WinExist(filename) {
        WinActivate()
        SetTitleMatchMode(old_match_mode)
        return
    }
    SetTitleMatchMode(old_match_mode)
    
    ; 2. Nếu chưa mở thì mở mới
    xl := ""
    try {
        ToolTip("Đang mở Excel...", 100, 100)
        xl := ComObject("Excel.Application")
        xl.Visible := true
        wb := xl.Workbooks.Open(csv_path)
        
        FormatSheet(wb.Sheets(1), sheetName)
        
        ToolTip()
    } catch as e {
        ToolTip()
        ; Giải phóng tiến trình Excel chạy ẩn nếu bị lỗi giữa chừng để tránh kẹt lock file
        if (xl != "") {
            try xl.Quit()
        }
        MsgBox("Lỗi mở Excel COM: " e.Message "`nFile vẫn sẽ được mở bình thường.")
        Run(csv_path)
    }
}

FormatSheet(ws, sheetName) {
    rng := ws.Range("H:H")
    rng.FormatConditions.Delete()
    
    fc1 := rng.FormatConditions.Add(1, 3, "Lỗi")
    fc1.Interior.Color := 0x8A8AFF
    fc1.Font.Color := 0x00009C
    
    fc2 := rng.FormatConditions.Add(1, 3, "Đã làm")
    fc2.Interior.Color := 0xC6EFC6
    fc2.Font.Color := 0x006100
    
    rngAll := ws.Range("A:K")
    fc3 := rngAll.FormatConditions.Add(2, 1, '=$A1="CA LÀM VIỆC"')
    if (sheetName == "Long") {
        fc3.Interior.Color := 0x00A5FF
    } else if (sheetName == "Dương") {
        fc3.Interior.Color := 0xE6D8AD
    } else if (sheetName == "Thảo") {
        fc3.Interior.Color := 0xC8A2C8 ; Màu tím nhạt cho Thảo
    } else {
        fc3.Interior.Color := 0xD6A7B4
    }
    fc3.Font.Bold := true
    
    ws.Columns("A:K").AutoFit()
    
    ws.Columns("B:B").ColumnWidth := 55
    
    try {
        lastRow := ws.Cells(ws.Rows.Count, "B").End(-4162).Row
        if (lastRow >= 2) {
            rngB := ws.Range("B2:B" lastRow)
            for cell in rngB {
                val := cell.Value
                if (Type(val) == "String" && InStr(val, "business.facebook.com")) {
                    if RegExMatch(val, "selected_item_id=([^&]+)", &match) {
                        try {
                            cell.Validation.Delete()
                            cell.Validation.Add(0)
                            cell.Validation.InputTitle := "ID khác biệt:"
                            cell.Validation.InputMessage := match[1]
                        }
                    }
                }
            }
        }
    }
    
    ws.Columns("G:G").ColumnWidth := 15
}

RestoreHistory() {
    global queue_file
    history_dir := A_ScriptDir "\History"
    latest_hist := GetLatestFile(history_dir, "history_*.csv")
    
    if (latest_hist == "") {
        MsgBox("Không tìm thấy file lịch sử nào để khôi phục!")
        return
    }
    
    SplitPath(latest_hist, &name)
    res := MsgBox("Bạn có chắc muốn khôi phục lại các dòng từ lần dọn dẹp gần nhất không?`nFile: " name, "Khôi phục Queue", "YesNo")
    if (res != "Yes")
        return
        
    try {
        FileMove(queue_file, queue_file ".tmp", 1) ; check lock
        
        hist_content := FileRead(latest_hist, "UTF-8")
        lines := StrSplit(hist_content, "`n", "`r")
        
        append_data := ""
        restored_count := 0
        for i, line in lines {
            if (i == 1 || Trim(line) == "") ; Skip header and empty lines
                continue
            append_data .= "`n" line
            restored_count++
        }
        
        if (restored_count > 0) {
            FileAppend(append_data, queue_file ".tmp", "UTF-8")
            FileMove(queue_file ".tmp", queue_file, 1)
            FileDelete(latest_hist)
            MsgBox("Đã khôi phục thành công " restored_count " dòng về queue.csv!")
        } else {
            FileMove(queue_file ".tmp", queue_file, 1)
            MsgBox("File lịch sử trống, không có gì để khôi phục.")
        }
        
    } catch as e {
        if FileExist(queue_file ".tmp")
            FileMove(queue_file ".tmp", queue_file, 1)
        MsgBox("Không thể khôi phục! Vui lòng TẮT FILE EXCEL đi trước khi khôi phục nhé!")
    }
}

ParseCSVLine(line) {
    fields := []
    Loop Parse, line, "CSV" {
        fields.Push(A_LoopField)
    }
    return fields
}

ToCSVLine(fields) {
    line := ""
    for i, val in fields {
        escaped := String(val)
        if InStr(escaped, ",") || InStr(escaped, '"') || InStr(escaped, "`n") || InStr(escaped, "`r") {
            escaped := StrReplace(escaped, '"', '""')
            escaped := '"' escaped '"'
        }
        line .= escaped (i == fields.Length ? "" : ",")
    }
    return line
}

; === THÔNG TIN S: Các hàm tương tác với GPTs ===

PasteThongTinSToGpt(gpt_win) {
    thong_tin_file := A_ScriptDir "\thong_tin_s.txt"
    if !FileExist(thong_tin_file)
        return
    
    content := FileRead(thong_tin_file, "UTF-8")
    if (Trim(content) == "")
        return
    
    WinActivate("ahk_id " gpt_win)
    if !WinWaitActive("ahk_id " gpt_win,, 5)
        return
    Sleep(1000)
    
    CoordMode("Mouse", "Screen")
    ClickGptChat(gpt_win)
    CoordMode("Mouse", "Client")
    Sleep(500)
    
    A_Clipboard := content
    ClipWait(2)
    Send("^v")
    Sleep(2000)
    
    Send("{Enter}")
    Sleep(1000)
    Send("{Enter}")
    Sleep(1000)
}

ReloadAndPasteSToGpt(gpt_win) {
    if (gpt_win == 0 || !WinExist("ahk_id " gpt_win))
        return
    
    WinActivate("ahk_id " gpt_win)
    if !WinWaitActive("ahk_id " gpt_win,, 5)
        return
    Sleep(500)
    Send("{F5}")
    
    ; Đợi cửa sổ GPT load xong bằng cách tìm khung chat (tối đa 20 giây)
    WinGetPos(&gptX, &gptY, &gptW, &gptH, "ahk_id " gpt_win)
    CoordMode("Pixel", "Screen")
    loaded := false
    Loop 20 {
        Sleep(1000)
        if ImageSearch(&FoundX, &FoundY, gptX, gptY, gptX + gptW, gptY + gptH, "*80 " A_ScriptDir "\gpt_chat.png") {
            loaded := true
            Sleep(1500) ; Đợi thêm 1.5s cho trang thật sự ổn định
            break
        }
    }
    CoordMode("Pixel", "Client")
    
    PasteThongTinSToGpt(gpt_win)
}

PasteThongTinSAll() {
    global id_gpt_long, id_gpt_duong, id_gpt_thao, worker_mode
    
    SendDiscordLog("📋 Đang tiến hành làm mới và dán Thông tin S vào tất cả GPTs...")
    
    ReloadAndPasteSToGpt(id_gpt_long)
    ReloadAndPasteSToGpt(id_gpt_duong)
    if (worker_mode == 3) {
        ReloadAndPasteSToGpt(id_gpt_thao)
    }
    
    SendDiscordLog("✅ Đã dán Thông tin S xong!")
}

CheckGradedCounter(worker) {
    global id_gpt_long, id_gpt_duong, id_gpt_thao
    
    count := Integer(IniRead("settings.ini", "GradedCounts", worker, 0))
    count++
    IniWrite(count, "settings.ini", "GradedCounts", worker)
    
    if (count >= 5) {
        ; Reset bộ đếm
        IniWrite(0, "settings.ini", "GradedCounts", worker)
        
        ; Xác định cửa sổ GPTs của nhân sự này
        if (worker == "long")
            gpt_win := id_gpt_long
        else if (worker == "duong")
            gpt_win := id_gpt_duong
        else
            gpt_win := id_gpt_thao
        
        SendDiscordLog("📋 [RELAX] " worker " đã chữa 5 bài, gửi Thông tin S để GPTs relax...")
        PasteThongTinSToGpt(gpt_win)
        
        ; Đợi 10 giây sau khi gửi Thông tin S
        SendDiscordLog("⏳ Đợi 10 giây sau khi gửi Thông tin S...")
        Sleep(10000)
    }
}
