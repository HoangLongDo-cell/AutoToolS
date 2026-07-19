#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode(2)
CoordMode("Pixel", "Screen")
CoordMode("Mouse", "Screen")

global queue_file := A_ScriptDir "\queue_fix.csv"
global ini_file := A_ScriptDir "\config.ini"

global id_chat := IniRead(ini_file, "Settings", "id_chat", "")
global id_toola := IniRead(ini_file, "Settings", "id_toola", "")
global id_gpt := IniRead(ini_file, "Settings", "id_gpt", "")
global download_dir := IniRead(ini_file, "Settings", "DownloadDir", A_MyDocuments "\..\Downloads")

global page_chat_click_x := 750
global page_chat_click_y := 830
global mess_chat_click_x := 870
global mess_chat_click_y := 470
global stop_flag := false
global is_watching := false

MainGUI() {
    global MyGui, LV
    MyGui := Gui("+Resize", "Bảng Điều Khiển - Tool S Fix (Chữa Bài)")
    MyGui.OnEvent("Close", (*) => ExitApp())

    MyGui.Add("Button", "w120 h40", "➕ Thêm học viên").OnEvent("Click", AddToQueue_Form)
    MyGui.Add("Button", "x+10 w120 h40", "⚙️ Cài đặt cửa sổ").OnEvent("Click", SetupWindows)
    MyGui.Add("Button", "x+10 w120 h40", "👁️ Chạy Auto").OnEvent("Click", RunAuto)
    MyGui.Add("Button", "x+10 w120 h40", "🛑 Dừng Auto").OnEvent("Click", StopAuto)
    
    LV := MyGui.Add("ListView", "xm w600 h300 Grid", ["STT", "Link chat", "Hệ", "Bài nộp", "Xưng hô", "Trạng thái"])
    LoadQueueToLV()
    
    MyGui.Show("w630 h370")
}

SetupWindows(*) {
    MsgBox("Hãy click vào cửa sổ CHAT (Chrome/Edge) rồi bấm F9")
    KeyWait("F9", "D")
    global id_chat := WinGetID("A")
    IniWrite(id_chat, ini_file, "Settings", "id_chat")
    ToolTip("Đã lưu CHAT ID: " id_chat)
    Sleep(1000)
    
    MsgBox("Hãy click vào cửa sổ TOOL A (Python) rồi bấm F9")
    KeyWait("F9", "D")
    global id_toola := WinGetID("A")
    IniWrite(id_toola, ini_file, "Settings", "id_toola")
    ToolTip("Đã lưu TOOL A ID: " id_toola)
    Sleep(1000)
    
    MsgBox("Hãy click vào cửa sổ GPT (Chrome/Edge) rồi bấm F9")
    KeyWait("F9", "D")
    global id_gpt := WinGetID("A")
    IniWrite(id_gpt, ini_file, "Settings", "id_gpt")
    ToolTip("Đã lưu GPT ID: " id_gpt)
    Sleep(1000)
    ToolTip()
    MsgBox("Đã khai báo xong 3 cửa sổ!")
}

LoadQueueToLV() {
    global LV
    LV.Delete()
    if !FileExist(queue_file)
        return
    content := FileRead(queue_file, "UTF-8")
    Loop Parse, content, "`n", "`r" {
        if (A_Index == 1 || Trim(A_LoopField) == "")
            continue
        cols := ParseCSVLine(A_LoopField)
        while (cols.Length < 7)
            cols.Push("")
        LV.Add("", cols[1], cols[2], cols[3], cols[4], cols[5], cols[6])
    }
}

AddToQueue_Form(*) {
    global AddGui, edit_link, cb_he, edit_bainop, cb_xungho, edit_downdir
    AddGui := Gui("+AlwaysOnTop", "Thêm vào hàng đợi (Tool S Fix)")
    
    AddGui.Add("Text", "w300", "Link Facebook/Messenger:")
    edit_link := AddGui.Add("Edit", "w300 vLinkChat")
    
    AddGui.Add("Text", "w300", "Hệ:")
    cb_he := AddGui.Add("DropDownList", "w300 Choose1", ["gen", "vstep", "adv"])
    
    AddGui.Add("Text", "w300", "Bài nộp (File đường dẫn):")
    edit_bainop := AddGui.Add("Edit", "w300 vBaiNop")
    AddGui.Add("Button", "w100 x320 yp-2 h25", "Bật Mắt Thần").OnEvent("Click", ToggleWatcher)
    
    AddGui.Add("Text", "xm w300", "Xưng hô:")
    cb_xungho := AddGui.Add("DropDownList", "w300 Choose1", ["Anh - Em", "Mình - Bạn", "Em - Chị", "Em - Anh"])
    
    AddGui.Add("Text", "xm w300", "Thư mục Downloads (Để Mắt Thần theo dõi):")
    edit_downdir := AddGui.Add("Edit", "w300", download_dir)
    
    AddGui.Add("Button", "w100 x110 mt-10", "Lưu").OnEvent("Click", SaveQueueFix)
    AddGui.OnEvent("Close", CloseAddGui)
    AddGui.Show()
}

ToggleWatcher(*) {
    global is_watching, download_dir
    download_dir := edit_downdir.Value
    IniWrite(download_dir, ini_file, "Settings", "DownloadDir")
    
    if (!is_watching) {
        is_watching := true
        SetTimer(WatchDownloads, 1000)
        MsgBox("Mắt thần đã BẬT! Cậu cứ tải file Word về, tool sẽ tự động chộp lấy đường dẫn.")
    }
}

WatchDownloads() {
    global download_dir, edit_bainop, is_watching
    static last_time := 0
    if (last_time == 0)
        last_time := A_NowUTC
        
    latest_file := ""
    latest_time := last_time
    
    Loop Files, download_dir "\*.*" {
        ext := StrLower(A_LoopFileExt)
        if (ext == "docx" || ext == "doc" || ext == "txt") {
            ; Skip temporary files
            if InStr(A_LoopFileName, "~$") || InStr(A_LoopFileName, ".crdownload") || InStr(A_LoopFileName, ".tmp")
                continue
                
            timeCreated := FileGetTime(A_LoopFileFullPath, "C")
            if (timeCreated > latest_time) {
                latest_time := timeCreated
                latest_file := A_LoopFileFullPath
            }
        }
    }
    
    if (latest_file != "") {
        last_time := latest_time
        res := MsgBox("Phát hiện file mới tải về:`n" latest_file "`n`nThêm vào Bài Nộp?", "Mắt Thần", "YesNo")
        if (res == "Yes") {
            current := edit_bainop.Value
            if (current != "" && !InStr(current, latest_file))
                edit_bainop.Value := current "|" latest_file
            else
                edit_bainop.Value := latest_file
        }
    }
}

CloseAddGui(*) {
    global is_watching
    if (is_watching) {
        SetTimer(WatchDownloads, 0)
        is_watching := false
    }
}

SaveQueueFix(*) {
    link := edit_link.Value
    he := cb_he.Text
    bainop := edit_bainop.Value
    xungho := cb_xungho.Text
    
    if (link == "") {
        MsgBox("Vui lòng nhập Link!")
        return
    }
    
    stt := 1
    if FileExist(queue_file) {
        content := FileRead(queue_file, "UTF-8")
        Loop Parse, content, "`n", "`r" {
            if (Trim(A_LoopField) != "")
                stt := A_Index
        }
    } else {
        FileAppend("STT,Link chat,Hệ,Bài nộp,Xưng hô,Trạng thái,Thời gian`n", queue_file, "UTF-8")
    }
    
    CloseAddGui()
    
    new_line := ToCSVLine([stt, link, he, bainop, xungho, "Chưa làm", ""]) "`n"
    FileAppend(new_line, queue_file, "UTF-8")
    AddGui.Destroy()
    LoadQueueToLV()
}

StopAuto(*) {
    global stop_flag
    stop_flag := true
    ToolTip()
}

RunAuto(*) {
    global stop_flag, id_chat, id_toola, id_gpt
    stop_flag := false
    
    if (id_chat == "" || id_toola == "" || id_gpt == "") {
        MsgBox("Vui lòng bấm [Cài đặt cửa sổ] trước khi chạy!")
        return
    }
    if !WinExist("ahk_id " id_chat) || !WinExist("ahk_id " id_toola) || !WinExist("ahk_id " id_gpt) {
        MsgBox("Một hoặc nhiều cửa sổ đã bị đóng. Hãy khai báo lại!")
        return
    }
    
    ProcessQueueFix()
}

ProcessQueueFix() {
    global stop_flag, id_chat, id_toola, id_gpt
    if !FileExist(queue_file)
        return
        
    Loop {
        if (stop_flag)
            break
            
        content := FileRead(queue_file, "UTF-8")
        lines := StrSplit(content, "`n", "`r")
        target_idx := -1
        
        for index, line in lines {
            if (index == 1 || Trim(line) == "")
                continue
            cols := ParseCSVLine(line)
            if (cols.Length >= 6 && Trim(cols[6]) == "Chưa làm") {
                target_idx := index
                break
            }
        }
        
        if (target_idx == -1) {
            MsgBox("Đã xử lý xong tất cả danh sách!")
            break
        }
        
        row_data := ParseCSVLine(lines[target_idx])
        stt := Trim(row_data[1])
        link := Trim(row_data[2])
        he := Trim(row_data[3])
        bainop := Trim(row_data[4])
        xungho := Trim(row_data[5])
        
        start_time := FormatTime(, "HH:mm")
        UpdateCSV(&lines, target_idx, "Đang làm", start_time)
        LoadQueueToLV()
        
        ; 1. Mở link chat
        WinActivate("ahk_id " id_chat)
        WinWaitActive("ahk_id " id_chat)
        Sleep(500)
        Send("^l")
        Sleep(200)
        A_Clipboard := link
        ClipWait(1)
        Send("^v")
        Sleep(200)
        Send("{Enter}")
        Sleep(3000)
        
        platform := InStr(link, "business.facebook.com") ? "page" : "mess"
        icon_to_wait := (platform == "page") ? A_ScriptDir "\page_chat.png" : A_ScriptDir "\mess_chat.png"
        
        Loop 30 { 
            if (stop_flag) return
            if ImageSearch(&ix, &iy, 0, 0, A_ScreenWidth, A_ScreenHeight, "*120 " icon_to_wait)
                break
            Sleep(300)
        }
        Sleep(2000)
        
        if (platform == "page")
            ClickPageChat(id_chat)
        else
            ClickMessChat(id_chat)
        Sleep(500)
        
        ; Gửi lời chào
        if InStr(xungho, "Mình - Bạn")
            A_Clipboard := "Mình chữa bài bạn nha"
        else if InStr(xungho, "Em - Chị")
            A_Clipboard := "Em chữa bài chị nha"
        else if InStr(xungho, "Em - Anh")
            A_Clipboard := "Em chữa bài anh nha"
        else
            A_Clipboard := "Anh chữa bài em nha"
            
        ClipWait(1)
        Send("^v")
        Sleep(1000)
        Send("{Enter}")
        Sleep(500)
        if (stop_flag) return
        
        ; 2. Nạp file vào Tool A
        WinActivate("ahk_id " id_toola)
        WinWaitActive("ahk_id " id_toola)
        Sleep(500)
        Send("^u")
        WinWaitActive("Chọn file học viên",, 5)
        if WinActive("Chọn file học viên") {
            Sleep(500)
            files_to_send := ""
            if InStr(bainop, "|") {
                arr := StrSplit(bainop, "|")
                for i, f in arr {
                    files_to_send .= "`"" f "`" "
                }
            } else {
                files_to_send := "`"" bainop "`""
            }
            A_Clipboard := Trim(files_to_send)
            ClipWait(1)
            Send("^v")
            Sleep(500)
            Send("{Enter}")
            WinWaitClose("Chọn file học viên",, 5)
        }
        Sleep(1000)
        if (stop_flag) return
        
        WinActivate("ahk_id " id_toola)
        WinWaitActive("ahk_id " id_toola,, 5)
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
        if (stop_flag) return
        
        ; 3. Gửi Prompt lên GPT
        WinActivate("ahk_id " id_gpt)
        WinWaitActive("ahk_id " id_gpt)
        Sleep(1000)
        ClickGptChat(id_gpt)
        Sleep(500)
        
        clipboard_content := A_Clipboard
        if InStr(xungho, "Mình - Bạn")
            clipboard_content := "chỉ riêng bài này đổi thành xưng hô Mình - bạn vì học viên bằng tuổi`n`n" clipboard_content
        else if InStr(xungho, "Em - Chị")
            clipboard_content := "chỉ riêng bài này đổi thành xưng hô Em - chị vì học viên lớn tuổi`n`n" clipboard_content
        else if InStr(xungho, "Em - Anh")
            clipboard_content := "chỉ riêng bài này đổi thành xưng hô Em - anh vì học viên lớn tuổi`n`n" clipboard_content
            
        A_Clipboard := clipboard_content
        ClipWait(1)
        Send("^v")
        Sleep(500)
        
        img_path := A_ScriptDir "\gpt_send_ready.png"
        if FileExist(img_path) {
            waitStart := A_TickCount
            Loop {
                if (stop_flag) return
                if ImageSearch(&fX, &fY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*40 " img_path) {
                    Sleep(200)
                    break
                }
                if (A_TickCount - waitStart > 30000)
                    break
                Sleep(400)
            }
        } else {
            Sleep(10000)
        }
        Send("{Enter}")
        Sleep(1000)
        Send("{Enter}")
        Sleep(1000)
        
        ; 4. Đợi GPT trả lời xong và Copy
        UpdateCSV(&lines, target_idx, "Đợi GPT")
        LoadQueueToLV()
        
        WinActivate("ahk_id " id_gpt)
        Loop {
            if (stop_flag) return
            WinActivate("ahk_id " id_gpt)
            if ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*80 " A_ScriptDir "\copy.png") {
                Sleep(3000) 
                if ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*80 " A_ScriptDir "\copy.png")
                    break
            }
            Sleep(3000)
        }
        
        ; Nhấn nút copy
        if ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*80 " A_ScriptDir "\copy.png") {
            Click(FoundX, FoundY)
            Sleep(500)
        }
        if (stop_flag) return
        
        ; 5. Dán lại vào Chat FB
        WinActivate("ahk_id " id_chat)
        WinWaitActive("ahk_id " id_chat)
        Sleep(500)
        if (platform == "page")
            ClickPageChat(id_chat)
        else
            ClickMessChat(id_chat)
        Sleep(500)
        
        Send("^v")
        Sleep(1000)
        Send("{Enter}")
        Sleep(1000)
        
        end_time := FormatTime(, "HH:mm")
        UpdateCSV(&lines, target_idx, "Đã làm", "", end_time)
        LoadQueueToLV()
        Sleep(2000)
    }
}

ClickPageChat(chat_win) {
    icon_path := A_ScriptDir "\page_chat.png"
    found := false
    FoundX := 0
    FoundY := 0
    for tol in [80, 120, 150] {
        if ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*" tol " " icon_path) {
            found := true
            break
        }
    }
    if (found) {
        startX := FoundX - 15
        startY := FoundY
        MouseMove(startX, startY)
        Sleep(300)
        foundIBeam := false
        Loop 60 {
            if (A_Cursor == "IBeam") {
                Sleep(200)
                Click(startX, startY)
                Sleep(300)
                Click(startX, startY)
                foundIBeam := true
                Sleep(500)
                break
            }
            startY := startY - 5
            MouseMove(startX, startY)
            Sleep(40)
        }
        if (!foundIBeam) {
            Click(FoundX - 15, FoundY - 40)
            Sleep(300)
            Click(FoundX - 15, FoundY - 40)
            Sleep(1000)
        }
    } else {
        Click(page_chat_click_x, page_chat_click_y)
        Sleep(300)
        Click(page_chat_click_x, page_chat_click_y)
        Sleep(2000)
    }
}

ClickMessChat(chat_win) {
    icon_path := A_ScriptDir "\mess_chat.png"
    found := false
    FoundX := 0
    FoundY := 0
    for tol in [80, 120, 150] {
        if ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*" tol " " icon_path) {
            found := true
            break
        }
    }
    if (found) {
        startX := FoundX
        startY := FoundY + 10
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
                Sleep(500)
                break
            }
            startX := startX - 8
            MouseMove(startX, startY)
            Sleep(40)
        }
        if (!foundIBeam) {
            Click(mess_chat_click_x, mess_chat_click_y)
            Sleep(300)
            Click(mess_chat_click_x, mess_chat_click_y)
            Sleep(1000)
        }
    } else {
        Click(mess_chat_click_x, mess_chat_click_y)
        Sleep(300)
        Click(mess_chat_click_x, mess_chat_click_y)
        Sleep(2000)
    }
}

ClickGptChat(gpt_win) {
    if ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*80 " A_ScriptDir "\gpt_chat.png") {
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
            Click(FoundX + 60, FoundY + 5)
            Sleep(200)
            Click(FoundX + 60, FoundY + 5)
        }
    }
}

UpdateCSV(&lines, row_index, new_status, new_start_time := "", new_end_time := "") {
    cols := ParseCSVLine(lines[row_index])
    while (cols.Length < 7)
        cols.Push("")
    cols[6] := new_status
    if (new_start_time != "")
        cols[7] := new_start_time
        
    new_row := ToCSVLine(cols)
    lines[row_index] := new_row
    
    new_content := ""
    for i, line in lines {
        if Trim(line) != ""
            new_content .= line "`n"
    }
    
    try {
        if FileExist(queue_file)
            FileDelete(queue_file)
        FileAppend(new_content, queue_file, "UTF-8")
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

MainGUI()
