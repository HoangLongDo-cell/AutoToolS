// === content.js ===
// Chạy trong isolated world. Cầu nối giữa background.js <-> interceptor.js

let listeningToast = null;
let isListening = false;

// --- Inject interceptor.js vào MAIN world ---
function injectInterceptor() {
  const script = document.createElement('script');
  script.src = chrome.runtime.getURL('interceptor.js');
  script.onload = function() { this.remove(); };
  (document.head || document.documentElement).appendChild(script);
}
injectInterceptor();

// --- Lắng nghe kết quả từ interceptor.js ---
window.addEventListener('message', function(event) {
  if (event.source !== window) return;
  
  // Nhận được dữ liệu blob thật
  if (event.data && event.data.type === 'EXT_S_BLOB_CAPTURED' && isListening) {
    console.log('[Ext S Content] Nhận blob từ interceptor! Nguồn:', event.data.source);
    isListening = false;
    stopListeningUI(true);
    window.postMessage({ type: 'EXT_S_LISTEN_OFF' }, '*');
    
    if (event.data.data) {
      let arr = new Uint8Array(event.data.data);
      let blob = new Blob([arr], { type: event.data.mimeType || 'audio/mp4' });
      let ext = guessExtension(event.data.mimeType);
      let url = URL.createObjectURL(blob);
      triggerDownload(url, ext);
    }
  }
  
  // Nhận được URL (từ media.play hook)
  if (event.data && event.data.type === 'EXT_S_URL_CAPTURED' && isListening) {
    console.log('[Ext S Content] Nhận URL từ interceptor:', event.data.url);
    isListening = false;
    stopListeningUI(true);
    window.postMessage({ type: 'EXT_S_LISTEN_OFF' }, '*');
    
    let url = event.data.url;
    if (url.startsWith('blob:') || url.startsWith('data:')) {
      // Dùng fetch để lấy dữ liệu từ blob URL rồi tải
      fetch(url).then(r => r.blob()).then(blob => {
        let ext = guessExtension(blob.type);
        let downloadUrl = URL.createObjectURL(blob);
        triggerDownload(downloadUrl, ext);
      }).catch(() => {
        // Fallback: tải trực tiếp bằng thẻ <a>
        triggerDownload(url, '.mp4');
      });
    } else {
      // Giao việc download URL thật cho background để tránh lỗi điều hướng do CORS
      triggerDownload(url, '.mp4');
    }
  }
});

// --- Lắng nghe lệnh từ background.js ---
chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
  if (request.action === "toggle_listening") {
    isListening = !isListening;
    if (isListening) {
      listeningToast = showPersistentToast("🎙️ CHẾ ĐỘ TẢI GHI ÂM ĐÃ BẬT!\nHãy bấm Play đoạn ghi âm bạn muốn tải.");
      window.postMessage({ type: 'EXT_S_LISTEN_ON' }, '*');
    } else {
      stopListeningUI(false);
      window.postMessage({ type: 'EXT_S_LISTEN_OFF' }, '*');
    }
  } else if (request.action === "show_notification") {
    showToast(request.message);
  }
});

// --- Helpers ---
function stopListeningUI(success) {
  if (listeningToast) {
    listeningToast.remove();
    listeningToast = null;
  }
  if (success) {
    showToast("✅ Đã bắt được file ghi âm, đang tải xuống...");
  } else {
    showToast("Đã TẮT chế độ tải ghi âm.");
  }
}

function guessExtension(mimeType) {
  if (!mimeType) return ".mp4";
  if (mimeType.includes("mp4")) return ".mp4";
  if (mimeType.includes("webm")) return ".webm";
  if (mimeType.includes("ogg")) return ".ogg";
  if (mimeType.includes("mpeg") || mimeType.includes("mp3")) return ".mp3";
  if (mimeType.includes("wav")) return ".wav";
  return ".mp4";
}

function triggerDownload(url, ext) {
  const filename = "VoiceMessage_" + Date.now() + ext;
  if (url.startsWith('blob:') || url.startsWith('data:')) {
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.style.display = 'none';
    document.body.appendChild(a);
    a.click();
    setTimeout(() => { if(a.parentNode) a.remove(); }, 1000);
  } else {
    // Send to background to download to bypass CORS navigation issues
    chrome.runtime.sendMessage({
      action: "download",
      url: url,
      filename: filename
    });
  }
}

// --- UI ---
function showToast(message) {
  const toast = createToastElement(message);
  document.body.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = "0";
    setTimeout(() => { if(toast.parentNode) toast.remove(); }, 500);
  }, 3500);
}

function showPersistentToast(message) {
  const toast = createToastElement(message);
  toast.style.backgroundColor = "#0055A4";
  document.body.appendChild(toast);
  return toast;
}

function createToastElement(message) {
  const toast = document.createElement("div");
  toast.innerText = message;
  Object.assign(toast.style, {
    position: "fixed",
    top: "20px",
    right: "20px",
    backgroundColor: "#34C759",
    color: "white",
    padding: "15px 25px",
    borderRadius: "8px",
    zIndex: "2147483647",
    fontFamily: "Arial, sans-serif",
    fontSize: "16px",
    fontWeight: "bold",
    boxShadow: "0 4px 6px rgba(0,0,0,0.3)",
    transition: "opacity 0.5s ease-in-out",
    pointerEvents: "none",
    whiteSpace: "pre-line"
  });
  return toast;
}
