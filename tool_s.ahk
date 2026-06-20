#Requires AutoHotkey v2.0
#SingleInstance Force

; Khai báo biến toàn cục lưu Window IDs
global id_mess := 0
global id_page := 0
global id_gpt := 0
global id_toola := 0
global queue_file := "queue.csv"

; Biến lưu tọa độ ô chat để không phải quét lại
global cached_chatX := -1
global cached_chatY := -1

; CHÚ Ý: Đường dẫn thư mục Downloads
global tool_a_downloads := "D:\HoangLong_Data\Download"

; Nếu chưa có file csv thì tạo mẫu
if !FileExist(queue_file) {
    FileAppend("STT,Link chat,Hệ bài chữa,Gửi giáo án,Mã giáo án,Đường dẫn bài nộp,Trạng thái,Thời gian bắt đầu,Thời gian hoàn thành`n1,https://facebook.com/messages/t/1234,APTIS GENERAL,Có,gen_bài 2,,Chưa làm,,`n", queue_file, "UTF-8")
} else {
    content := FileRead(queue_file, "UTF-8")
    lines := StrSplit(content, "`n", "`r")
    if (lines.Length > 0 && !InStr(lines[1], "Thời gian bắt đầu")) {
        try {
            FileMove(queue_file, queue_file ".backup2", 1)
            FileAppend("STT,Link chat,Hệ bài chữa,Gửi giáo án,Mã giáo án,Đường dẫn bài nộp,Trạng thái,Thời gian bắt đầu,Thời gian hoàn thành`n", queue_file, "UTF-8")
            for i, line in lines {
                if (i == 1 || Trim(line) == "")
                    continue
                cols := StrSplit(line, ",")
                while (cols.Length < 9)
                    cols.Push("")
                row := ""
                for j, val in cols
                    row .= val (j == cols.Length ? "" : ",")
                FileAppend(row "`n", queue_file, "UTF-8")
            }
        } catch as e {
            MsgBox("LỖI: Không thể cập nhật file queue.csv sang định dạng mới.`n`nVui lòng TẮT FILE EXCEL (queue.csv) đi rồi bật lại Tool S nhé!")
            ExitApp()
        }
    }
}

; Bật giao diện điều khiển ngay lập tức
global myGui := ""
MainGUI()

MainGUI() {
    global myGui
    myGui := Gui("+AlwaysOnTop", "Tool S - Bảng Điều Khiển")
    myGui.Add("Text", "w300 Center", "=== CÔNG CỤ TỰ ĐỘNG HÓA TOOL S ===")
    
    btnSetup := myGui.Add("Button", "w300 h40", "1. Cài đặt Cửa sổ (F9)")
    btnSetup.OnEvent("Click", (*) => GuiSetup_Action())
    
    btnAdd := myGui.Add("Button", "w300 h40", "2. Thêm học viên vào Queue")
    btnAdd.OnEvent("Click", (*) => AddToQueue_Form())
    
    btnRunManual := myGui.Add("Button", "w300 h40", "3a. Bắt đầu chạy (Quan sát - Chờ F9)")
    btnRunManual.OnEvent("Click", (*) => ProcessQueue("manual"))
    
    btnRunAuto := myGui.Add("Button", "w300 h40", "3b. Bắt đầu chạy (AUTO 100% - Rảnh tay)")
    btnRunAuto.OnEvent("Click", (*) => ProcessQueue("auto"))
    
    btnOpen := myGui.Add("Button", "w300 h30", "Mở xem danh sách (queue.csv)")
    btnOpen.OnEvent("Click", (*) => Run(queue_file))
    
    myGui.Show("AutoSize Center")
}

GuiSetup_Action() {
    MsgBox("Tool S Automation`n`nCần chọn 4 cửa sổ độc lập theo thứ tự:`n1. Chat MESSENGER`n2. Chat PAGE`n3. ChatGPT`n4. Tool A`n`nBấm OK để bắt đầu lưu Window ID.")
    
    ToolTip("1. BƯỚC 1: Click chuột vào cửa sổ CHAT MESSENGER, sau đó bấm phím F9")
    KeyWait("F9", "D")
    global id_mess := WinGetID("A")
    KeyWait("F9")
    
    ToolTip("2. BƯỚC 2: Click chuột vào cửa sổ CHAT PAGE, sau đó bấm phím F9")
    KeyWait("F9", "D")
    global id_page := WinGetID("A")
    KeyWait("F9")
    
    ToolTip("3. BƯỚC 3: Click chuột vào cửa sổ CHATGPT, sau đó bấm phím F9")
    KeyWait("F9", "D")
    global id_gpt := WinGetID("A")
    KeyWait("F9")
    
    ToolTip("4. BƯỚC 4: Click chuột vào cửa sổ TOOL A, sau đó bấm phím F9")
    KeyWait("F9", "D")
    global id_toola := WinGetID("A")
    KeyWait("F9")
    
    ToolTip() ; Tắt dòng chữ đi
    MsgBox("Đã lưu xong 4 cửa sổ!`nBây giờ bạn hãy bấm Ctrl + Y để bắt đầu chạy nhé.", "Hoàn tất setup")
}

global addGui := ""
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
    editLink := addGui.Add("Edit", "w250 x+10")
    
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
    
    btnSave := addGui.Add("Button", "w340 h40 xm", "Thêm vào Danh sách")
    btnSave.OnEvent("Click", (*) => SaveToQueue())
    
    addGui.Show()
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
    global queue_file, editLink, ddlType, ddlHe, editGiaoAn, addGui
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
    
    stt := 1
    if FileExist(queue_file) {
        content := FileRead(queue_file, "UTF-8")
        lines := StrSplit(content, "`n", "`r")
        valid_lines := 0
        for i, line in lines {
            if Trim(line) != ""
                valid_lines++
        }
        stt := valid_lines
    }
    
    row := stt "," link "," he "," co_giao_an "," giao_an "," bai_nop ",Chưa làm,,`n"
    try {
        FileAppend(row, queue_file, "UTF-8")
        MsgBox("Đã thêm STT " stt " thành công!")
        addGui.Destroy()
    } catch as e {
        MsgBox("KHÔNG THỂ THÊM VÀO DANH SÁCH!`n`nVui lòng TẮT FILE EXCEL (queue.csv) trước khi thêm học viên, vì Excel đang khóa file này không cho phần mềm khác lưu.`n`nLỗi chi tiết: " e.Message)
    }
}

F8:: {
    MsgBox("Đã dừng khẩn cấp Tool S!", "Dừng Tool")
    Reload()
}

^y:: {
    ProcessQueue()
}

ProcessQueue(mode := "manual") {
    if (mode == "auto") {
        ; Bật WakeLock chống tắt màn hình (ES_DISPLAY_REQUIRED | ES_CONTINUOUS)
        DllCall("SetThreadExecutionState", "UInt", 0x80000002)
    }
    
    Loop {
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
        
        target_idx := 0
        row_data := []
        
        Loop lines.Length {
            if (A_Index == 1 || Trim(lines[A_Index]) == "")
                continue
                
            cols := StrSplit(lines[A_Index], ",")
            if (cols.Length >= 6) {
                status_idx := (cols.Length >= 7) ? 7 : 6
                status := Trim(cols[status_idx], " `t`r`n`"")
                if (status == "Chưa làm") {
                    target_idx := A_Index
                    row_data := cols
                    break
                }
            }
        }
        
        if (target_idx == 0) {
            if (mode == "manual") {
                MsgBox("Không còn học viên nào ở trạng thái 'Chưa làm' hoặc 'Lỗi' trong queue.")
            } else {
                ToolTip()
                MsgBox("Đã chạy xong toàn bộ danh sách Auto!")
            }
            break
        }
        
        stt := Trim(row_data[1], " `t`r`n`"")
        if (mode == "auto") {
            ToolTip("ĐANG CHẠY CHẾ ĐỘ AUTO 100% (Bấm F8 để dừng khẩn cấp)`nĐang xử lý STT " stt "...", 10, 10)
        }
        
        start_time := FormatTime(, "HH:mm:ss dd/MM/yyyy")
        UpdateCSV(lines, target_idx, "Chưa làm", start_time)
        
        try {
            success := ProcessRow(row_data, lines, target_idx, mode)
            if (!success && mode == "auto") {
                UpdateCSV(lines, target_idx, "Lỗi")
            }
        } catch as e {
            if (mode == "auto") {
                UpdateCSV(lines, target_idx, "Lỗi")
            } else {
                MsgBox("Lỗi xử lý STT " stt ": " e.Message)
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
    }
}

ProcessRow(row_data, lines, target_idx, mode) {
    stt := Trim(row_data[1], " `t`r`n`"")
    link := Trim(row_data[2], " `t`r`n`"")
    he := Trim(row_data[3], " `t`r`n`"")
    gui_giaoan := Trim(row_data[4], " `t`r`n`"")
    ma_giaoan := Trim(row_data[5], " `t`r`n`"")
    bai_nop := ""
    if (row_data.Length >= 7) {
        bai_nop := Trim(row_data[6], " `t`r`n`"")
    }
    
    if InStr(link, "business.facebook.com") {
        platform := "page"
        chat_win := "ahk_id " id_page
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
                folder_paths.Push("D:\My Jobs\Nhận xét Mess\" . sub_path)
            }
        }
    }
    
    global cached_chatX := -1
    global cached_chatY := -1
    
    ToolTip("STT " stt ": Mở link chat...")
    
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
    
    if (mode == "auto") {
        ToolTip("Đang đợi trang web tải (10 giây) trong chế độ Auto...")
        Sleep(10000)
    } else {
        ToolTip("Đang đợi trang web tải... (7 giây)")
        Sleep(7000)
        ToolTip("Đã mở link chat. Bạn hãy tải file bài làm của học viên.`nSAU KHI TẢI XONG, BẤM F9 ĐỂ TOOL S CHẠY TIẾP.", 100, 100)
        KeyWait("F9", "D")
        ToolTip()
    }
    
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
    
    if (he == "") {
        ; CHỈ GỬI GIÁO ÁN
        if (folder_paths.Length > 0) {
            for i, fp in folder_paths {
                CallToolC(fp, chat_win)
                Sleep(1000)
            }
        } else {
            if (mode == "manual") {
                MsgBox("LỖI: STT " stt " được chọn là 'Chỉ gửi giáo án' nhưng lại không có mã giáo án!")
            }
            return false
        }
        ToolTip()
        if (mode == "manual") {
            MsgBox("Đã gửi giáo án xong cho STT " stt)
        }
        end_time := FormatTime(, "HH:mm:ss dd/MM/yyyy")
        UpdateCSV(lines, target_idx, "Đã làm", "", end_time)
        return true
    }
    
    ; CHỮA BÀI
    A_Clipboard := "Anh chữa bài em nha ^^"
    ClipWait(1)
    Send("^v")
    Sleep(200)
    Send("{Enter}")
    Sleep(500)
    
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
            dl_files := GetAllFiles(tool_a_downloads, "*.docx", "Bài chữa")
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
                    return false
                }
            }
        }
        Sleep(1000)
    }
    
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
    
    WinActivate("ahk_id " id_gpt)
    WinWaitActive("ahk_id " id_gpt)
    Sleep(1000)
    
    WinGetPos(&gptX, &gptY, &gptW, &gptH, "ahk_id " id_gpt)
    CoordMode("Mouse", "Window")
    Click(gptW / 2, gptH - 120)
    CoordMode("Mouse", "Client")
    Sleep(500)
    
    Send("^v")
    Sleep(500)
    
    Sleep(12000)
    Send("{Enter}")
    Sleep(1000)
    Send("{Enter}")
    
    Sleep(5000)
    
    foundCopy := false
    Loop 200 {
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
    
    Send("^v")
    Sleep(3000)
    Send("{Enter}")
    Sleep(1000)
    
    latest_word := GetLatestFile(tool_a_downloads, "Bài chữa*.docx")
    if (latest_word != "") {
        CopyFileToClipboard(latest_word)
        Sleep(500)
        Send("^v")
        Sleep(3000)
        Send("{Enter}")
        Sleep(1000)
        
        A_Clipboard := "Anh gửi em bài chữa nha"
        ClipWait(1)
        Send("^v")
        Sleep(500)
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
            CallToolC(fp, chat_win)
            Sleep(1000)
        }
    }
    
    ToolTip()
    if (mode == "manual") {
        MsgBox("Đã hoàn thành cho STT " stt "!")
    }
    end_time := FormatTime(, "HH:mm:ss dd/MM/yyyy")
    UpdateCSV(lines, target_idx, "Đã làm", "", end_time)
    return true
}

UpdateCSV(lines, row_index, new_status, new_start_time := "", new_end_time := "") {
    cols := StrSplit(lines[row_index], ",")
    while (cols.Length < 9) {
        cols.Push("")
    }
    cols[7] := new_status
    if (new_start_time != "")
        cols[8] := new_start_time
    if (new_end_time != "")
        cols[9] := new_end_time
        
    new_row := ""
    for i, val in cols {
        new_row .= val (i == cols.Length ? "" : ",")
    }
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
    global cached_chatX, cached_chatY
    if (cached_chatX != -1) {
        ToolTip("Dùng lại tọa độ Page Chat đã lưu...", 100, 100)
        Click(cached_chatX, cached_chatY)
        Sleep(200)
        Click(cached_chatX, cached_chatY)
        return
    }

    CoordMode("Mouse", "Screen")
    CoordMode("Pixel", "Screen")
    ToolTip("Đang quét Page Chat bằng AHK ImageSearch...", 100, 100)
    
    if ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*80 page_chat.png") {
        startX := FoundX + 15
        startY := FoundY
        MouseMove(startX, startY)
        Sleep(100)
        
        foundIBeam := false
        Loop 30 {
            if (A_Cursor == "IBeam") {
                Sleep(2000)
                cached_chatX := startX
                cached_chatY := startY
                Click(cached_chatX, cached_chatY)
                Sleep(200)
                Click(cached_chatX, cached_chatY)
                foundIBeam := true
                break
            }
            startY := startY - 5
            MouseMove(startX, startY)
            Sleep(30)
        }
        
        if (!foundIBeam) {
            cached_chatX := FoundX + 15
            cached_chatY := FoundY - 40
            Click(cached_chatX, cached_chatY)
            Sleep(200)
            Click(cached_chatX, cached_chatY)
        }
    } else {
        ToolTip("LỖI: Không tìm thấy page_chat.png! Click dự phòng vào 955, 510.", 100, 100)
        cached_chatX := 955
        cached_chatY := 510
        Click(cached_chatX, cached_chatY)
        Sleep(200)
        Click(cached_chatX, cached_chatY)
        Sleep(2000)
    }
    ToolTip()
    CoordMode("Mouse", "Client")
}

ClickMessChat() {
    global cached_chatX, cached_chatY
    if (cached_chatX != -1) {
        ToolTip("Dùng lại tọa độ Mess Chat đã lưu...", 100, 100)
        Click(cached_chatX, cached_chatY)
        Sleep(200)
        Click(cached_chatX, cached_chatY)
        return
    }

    CoordMode("Mouse", "Screen")
    CoordMode("Pixel", "Screen")
    ToolTip("Đang quét Mess Chat bằng AHK ImageSearch...", 100, 100)
    
    if ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*80 mess_chat.png") {
        cached_chatX := FoundX + 50
        cached_chatY := FoundY + 10
        Click(cached_chatX, cached_chatY)
        Sleep(200)
        Click(cached_chatX, cached_chatY)
    } else {
        ToolTip("LỖI: Không tìm thấy mess_chat.png! Click dự phòng vào 950, 950.", 100, 100)
        cached_chatX := 950
        cached_chatY := 950
        Click(cached_chatX, cached_chatY)
        Sleep(200)
        Click(cached_chatX, cached_chatY)
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

CopyFileToClipboard(filePath) {
    ; Dùng PowerShell để đưa file vào clipboard (hỗ trợ dán thẳng file vào FB/Zalo)
    ps_code := "Set-Clipboard -Path '" filePath "'"
    RunWait("powershell.exe -WindowStyle Hidden -Command " ps_code,, "Hide")
}

CallToolC(folder_path, chat_win) {
    ToolTip("Đang mở giáo án bằng Tool C...`nĐường dẫn: " folder_path)
    Run("explorer.exe /select,`"" folder_path "`"")
    Sleep(2000)
    
    folder_hwnd := WinGetID("A")
    Send("^b")
    Sleep(1000)
    
    if WinWait("ahk_class #32770", "Đã chọn thư mục gửi", 3) {
        WinActivate()
        Send("{Enter}")
        Sleep(500)
        
        WinActivate(chat_win)
        WinWaitActive(chat_win)
        Sleep(500)
        
        ; Double check: focus đúng vào ô chat trước khi Tool C dán
        CoordMode("Mouse", "Screen")
        if InStr(chat_win, id_page) {
            ClickPageChat()
        } else {
            ClickMessChat()
        }
        CoordMode("Mouse", "Client")
        Sleep(500)
        
        Loop 50 {
            Send("^m")
            
            ; Tăng thời gian đợi để nội dung/file giáo án tải xong hoàn toàn
            Sleep(10000)
            
            if WinExist("ahk_class #32770", "Đã hết danh sách gửi") {
                WinActivate()
                Send("{Enter}")
                Sleep(1000)
                if WinExist("ahk_id " folder_hwnd) {
                    WinClose("ahk_id " folder_hwnd)
                }
                break
            }
            Send("{Enter}")
            Sleep(2000)
        }
    }
}
