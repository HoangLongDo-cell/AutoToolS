#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode(2)

global queue_file := A_ScriptDir "\queue_ga.csv"
global page_chat_click_x := 750
global page_chat_click_y := 830
global mess_chat_click_x := 870
global mess_chat_click_y := 470
global stop_flag := false

MainGUI() {
    global MyGui, LV
    MyGui := Gui("+Resize", "Bảng Điều Khiển - Tool S GA")
    MyGui.OnEvent("Close", (*) => ExitApp())

    MyGui.Add("Button", "w120 h40", "➕ Thêm học viên").OnEvent("Click", AddToQueue_Form)
    MyGui.Add("Button", "x+10 w120 h40", "👁️ Chạy Auto").OnEvent("Click", RunAuto)
    MyGui.Add("Button", "x+10 w120 h40", "🛑 Dừng Auto").OnEvent("Click", StopAuto)
    
    LV := MyGui.Add("ListView", "xm w600 h300 Grid", ["STT", "Link chat", "Mã giáo án", "Trạng thái", "Bắt đầu", "Hoàn thành"])
    LoadQueueToLV()
    
    MyGui.Show("w630 h370")
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
        while (cols.Length < 6)
            cols.Push("")
        LV.Add("", cols[1], cols[2], cols[3], cols[4], cols[5], cols[6])
    }
}

AddToQueue_Form(*) {
    global AddGui, edit_link, edit_maga
    AddGui := Gui("+AlwaysOnTop", "Thêm vào hàng đợi (Tool S GA)")
    AddGui.Add("Text", "w300", "Link Facebook/Messenger:")
    edit_link := AddGui.Add("Edit", "w300 vLinkChat")
    AddGui.Add("Text", "w300", "Mã giáo án (VD: gen_bai 1):")
    edit_maga := AddGui.Add("Edit", "w300 vMaGiaoAn")
    AddGui.Add("Button", "w100 x110", "Lưu").OnEvent("Click", SaveQueueGA)
    AddGui.Show()
}

SaveQueueGA(*) {
    link := edit_link.Value
    ma_ga := edit_maga.Value
    if (link == "" || ma_ga == "") {
        MsgBox("Vui lòng nhập đủ Link và Mã giáo án!")
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
        FileAppend("STT,Link chat,Mã giáo án,Trạng thái,Thời gian bắt đầu,Thời gian hoàn thành`n", queue_file, "UTF-8")
    }
    
    new_line := stt "," link "," ma_ga ",Chưa làm,,`n"
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
    global stop_flag
    stop_flag := false
    
    chat_win := ""
    if WinExist("ahk_exe chrome.exe")
        chat_win := "ahk_exe chrome.exe"
    else if WinExist("ahk_exe msedge.exe")
        chat_win := "ahk_exe msedge.exe"
    else {
        MsgBox("Không tìm thấy Chrome hoặc Edge đang mở!")
        return
    }
    
    ProcessQueueGA(chat_win)
}

ProcessQueueGA(chat_win) {
    global stop_flag
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
            if (cols.Length >= 4 && Trim(cols[4]) == "Chưa làm") {
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
        ma_giaoan := Trim(row_data[3])
        
        start_time := FormatTime(, "HH:mm")
        UpdateCSV(&lines, target_idx, "Đang làm", start_time)
        LoadQueueToLV()
        
        ; Mở link
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
        
        Sleep(3000)
        
        ; Xác định platform
        platform := InStr(link, "business.facebook.com") ? "page" : "mess"
        icon_to_wait := (platform == "page") ? A_ScriptDir "\page_chat.png" : A_ScriptDir "\mess_chat.png"
        
        ToolTip("Đang đợi trang web tải (quét icon)...", 100, 100)
        WinActivate(chat_win)
        CoordMode("Pixel", "Screen")
        
        Loop 30 { ; Timeout 9s
            if (stop_flag)
                return
            if ImageSearch(&ix, &iy, 0, 0, A_ScreenWidth, A_ScreenHeight, "*120 " icon_to_wait) {
                ToolTip("✅ Đã tìm thấy icon! Chờ 2s...", 100, 100)
                break
            }
            Sleep(300)
        }
        Sleep(2000)
        ToolTip()
        
        CoordMode("Mouse", "Screen")
        if (platform == "page")
            ClickPageChat(chat_win)
        else
            ClickMessChat(chat_win)
        CoordMode("Mouse", "Client")
        Sleep(500)
        
        ; Gửi giáo án
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
        
        if (folder_paths.Length > 0) {
            for i, fp in folder_paths {
                if (stop_flag)
                    return
                SendGiaoAn(fp, chat_win)
                Sleep(1000)
            }
        }
        
        end_time := FormatTime(, "HH:mm")
        UpdateCSV(&lines, target_idx, "Đã làm", "", end_time)
        LoadQueueToLV()
        Sleep(2000)
    }
}

ClickPageChat(chat_win) {
    CoordMode("Mouse", "Screen")
    CoordMode("Pixel", "Screen")
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
    CoordMode("Mouse", "Screen")
    CoordMode("Pixel", "Screen")
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

SendGiaoAn(folder_path, chat_win) {
    orderFile := folder_path "\thu_tu_gui.txt"
    if !FileExist(orderFile)
        return

    content := FileRead(orderFile, "UTF-8")
    items := []
    Loop Parse, content, "`n", "`r" {
        line := Trim(A_LoopField)
        if (line != "")
            items.Push(line)
    }

    if (items.Length == 0)
        return
        
    WinActivate(chat_win)
    WinWaitActive(chat_win)
    Sleep(500)

    for index, itemName in items {
        if (stop_flag)
            return
            
        itemPath := folder_path "\" itemName
        if !FileExist(itemPath)
            continue

        WinActivate(chat_win)
        Sleep(300)
        
        if InStr(FileExist(itemPath), "D") {
            files := []
            Loop Files, itemPath "\*.*", "F" {
                files.Push(A_LoopFileFullPath)
            }
            if (files.Length > 0) {
                SetClipboardFiles(files)
                Sleep(500)
                Send("^v")
                WaitForAnyMediaIcon()
                Sleep(2000)
                Send("{Enter}")
                Sleep(2000)
            }
        } else {
            SetClipboardFiles([itemPath])
            Sleep(500)
            Send("^v")
            ext := StrLower(SubStr(itemName, -3))
            if (ext == "mp4" || ext == "mov") {
                WaitForIcon("icon_video.png")
                Sleep(2000)
            } else if (ext == "png" || ext == "jpg") {
                WaitForIcon("icon_image.png")
                Sleep(1000)
            } else {
                WaitForIcon("icon_file.png")
                Sleep(1000)
            }
            Send("{Enter}")
            Sleep(1000)
        }
    }
}

WaitForAnyMediaIcon() {
    CoordMode("Pixel", "Screen")
    icon_dir := A_ScriptDir "\"
    Loop 30 {
        if ImageSearch(&ix, &iy, 0, 0, A_ScreenWidth, A_ScreenHeight, "*60 " icon_dir "icon_image.png")
            return "image"
        if ImageSearch(&ix, &iy, 0, 0, A_ScreenWidth, A_ScreenHeight, "*60 " icon_dir "icon_file.png")
            return "file"
        if ImageSearch(&ix, &iy, 0, 0, A_ScreenWidth, A_ScreenHeight, "*60 " icon_dir "icon_video.png")
            return "video"
        Sleep(200)
    }
    return "timeout"
}

WaitForIcon(expected_icon) {
    CoordMode("Pixel", "Screen")
    icon_dir := A_ScriptDir "\"
    Loop 30 {
        if ImageSearch(&ix, &iy, 0, 0, A_ScreenWidth, A_ScreenHeight, "*60 " icon_dir expected_icon)
            return true
        Sleep(200)
    }
    return false
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
    if !DllCall("OpenClipboard", "Ptr", A_ScriptHwnd)
        return
    DllCall("EmptyClipboard")
    DllCall("SetClipboardData", "UInt", 15, "Ptr", hMem)
    DllCall("CloseClipboard")
}

UpdateCSV(&lines, row_index, new_status, new_start_time := "", new_end_time := "") {
    cols := ParseCSVLine(lines[row_index])
    while (cols.Length < 6)
        cols.Push("")
    cols[4] := new_status
    if (new_start_time != "")
        cols[5] := new_start_time
    if (new_end_time != "")
        cols[6] := new_end_time
        
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
