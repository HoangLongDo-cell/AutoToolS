"""
Discord Bot điều khiển Tool S từ xa.
Lệnh hỗ trợ:
  !stop   - Dừng Auto ngay lập tức
  !status - Xem trạng thái Auto đang chạy hay không
  !help   - Xem danh sách lệnh

Bot tạo file stop_auto.txt để Tool S AHK phát hiện và dừng.
"""

import os
import sys
import time
import datetime

# Đường dẫn thư mục Tool S
TOOL_DIR = os.path.dirname(os.path.abspath(__file__))
STOP_FILE = os.path.join(TOOL_DIR, "stop_auto.txt")
WORKSPACE_FILE = os.path.join(TOOL_DIR, "workspace_active.txt")

# ====== DISCORD BOT TOKEN ======
# Cách lấy token:
# 1. Vào https://discord.com/developers/applications
# 2. Tạo Application mới (ví dụ "Tool S Bot")
# 3. Vào mục "Bot" → click "Reset Token" → copy token
# 4. Bật "MESSAGE CONTENT INTENT" trong phần Privileged Gateway Intents
# 5. Vào mục "OAuth2" → URL Generator → chọn "bot" scope + "Send Messages" & "Read Message History" permissions
# 6. Copy link invite → mở link đó → thêm bot vào server Discord của bạn
# 7. Dán token vào biến dưới đây hoặc file discord_bot_token.txt

TOKEN_FILE = os.path.join(TOOL_DIR, "discord_bot_token.txt")

def get_token():
    """Đọc token từ file hoặc biến môi trường."""
    # Ưu tiên file
    if os.path.exists(TOKEN_FILE):
        with open(TOKEN_FILE, "r", encoding="utf-8") as f:
            token = f.read().strip()
            if token:
                return token
    # Thử biến môi trường
    token = os.environ.get("DISCORD_BOT_TOKEN", "")
    if token:
        return token
    return None


def main():
    token = get_token()
    if not token:
        print("=" * 50)
        print("LỖI: Chưa có Discord Bot Token!")
        print()
        print("Cách setup:")
        print("1. Vào https://discord.com/developers/applications")
        print("2. Tạo Application → vào Bot → lấy Token")
        print("3. BẬT 'MESSAGE CONTENT INTENT'")
        print("4. Lưu token vào file: discord_bot_token.txt")
        print("   (cùng thư mục với file này)")
        print("=" * 50)
        input("Nhấn Enter để thoát...")
        sys.exit(1)

    try:
        import discord
    except ImportError:
        print("Đang cài đặt thư viện discord.py...")
        os.system(f'"{sys.executable}" -m pip install discord.py')
        import discord

    from discord.ext import tasks
    import asyncio

    intents = discord.Intents.default()
    intents.message_content = True
    client = discord.Client(intents=intents)

    CHANNEL_FILE = os.path.join(TOOL_DIR, "notify_channel.txt")
    
    class BotState:
        last_state = os.path.exists(WORKSPACE_FILE)

    @tasks.loop(seconds=3)
    async def check_status():
        current_state = os.path.exists(WORKSPACE_FILE)
        if current_state != BotState.last_state:
            BotState.last_state = current_state
            
            if os.path.exists(CHANNEL_FILE):
                with open(CHANNEL_FILE, "r") as f:
                    try:
                        cid = int(f.read().strip())
                    except ValueError:
                        cid = None
                        
                if cid:
                    channel = client.get_channel(cid)
                    if not channel:
                        try:
                            channel = await client.fetch_channel(cid)
                        except:
                            pass
                            
                    if channel:
                        time_str = datetime.datetime.now().strftime("%H:%M:%S %d/%m/%Y")
                        if current_state:
                            await channel.send(f"🟢 **Tự động báo:** Tool S đã **BẮT ĐẦU** chạy lúc {time_str}")
                        else:
                            await channel.send(f"🔴 **Tự động báo:** Tool S đã **DỪNG** lại lúc {time_str}")

    @client.event
    async def on_ready():
        print(f"✅ Bot đã online: {client.user}")
        print(f"📂 Thư mục Tool S: {TOOL_DIR}")
        print(f"🔑 Lệnh hỗ trợ: !stop, !status, !help")
        print("-" * 40)
        if not check_status.is_running():
            check_status.start()

    @client.event
    async def on_message(message):
        # Bỏ qua tin nhắn của chính bot
        if message.author == client.user:
            return

        # Lưu lại ID kênh để gửi thông báo tự động (nơi người dùng chat cuối cùng)
        try:
            with open(CHANNEL_FILE, "w") as f:
                f.write(str(message.channel.id))
        except:
            pass

        content = message.content.strip().lower()

        if content == "!stop":
            try:
                with open(STOP_FILE, "w", encoding="utf-8") as f:
                    f.write(f"stop requested at {datetime.datetime.now()}")
                await message.channel.send("🛑 **Đã gửi lệnh DỪNG!**\nTool S sẽ dừng Auto ở bước tiếp theo.")
                print(f"[{datetime.datetime.now():%H:%M:%S}] 🛑 Lệnh !stop từ {message.author}")
            except Exception as e:
                await message.channel.send(f"❌ Lỗi tạo file stop: {e}")

        elif content == "!status":
            auto_running = os.path.exists(WORKSPACE_FILE)
            stop_pending = os.path.exists(STOP_FILE)
            
            status_msg = "📊 **Trạng thái Tool S:**\n"
            status_msg += f"• Workspace: {'🟢 Đang hoạt động' if auto_running else '🔴 Chưa setup'}\n"
            status_msg += f"• Lệnh dừng: {'⏳ Đang chờ dừng...' if stop_pending else '✅ Không có'}\n"
            status_msg += f"• Thời gian: {datetime.datetime.now():%H:%M:%S %d/%m/%Y}"
            
            await message.channel.send(status_msg)

        elif content == "!help":
            help_msg = "🤖 **Tool S Bot - Lệnh hỗ trợ:**\n"
            help_msg += "• `!stop` - Dừng Auto ngay lập tức\n"
            help_msg += "• `!status` - Xem trạng thái Tool S\n"
            help_msg += "• `!help` - Xem danh sách lệnh"
            await message.channel.send(help_msg)

    print("🚀 Đang khởi động Discord Bot...")
    print(f"📂 Stop file: {STOP_FILE}")
    client.run(token)


if __name__ == "__main__":
    main()
