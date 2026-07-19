@echo off
echo ==============================================
echo KHOI DONG DISCORD BOT CHO TOOL S SIMPLE
echo ==============================================
echo.
echo [INFO] Dang kiem tra va cai dat thu vien discord.py...
pip show discord.py >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Dang tien hanh cai dat...
    pip install discord.py
)

echo.
echo [INFO] Dang khoi dong Bot...
python discord_bot.py
pause
