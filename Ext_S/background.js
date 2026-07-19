// === background.js ===
// Lắng nghe phím tắt VÀ click icon để bật/tắt chế độ tải ghi âm

function toggleListening() {
  chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
    if (tabs[0]) {
      chrome.tabs.sendMessage(tabs[0].id, {
        action: "toggle_listening"
      }).catch(() => {
        console.log("[Ext S] Content script chưa sẵn sàng. Hãy reload trang.");
      });
    }
  });
}

// Phím tắt Alt+Y
chrome.commands.onCommand.addListener((command) => {
  if (command === "toggle-capture") {
    toggleListening();
  }
});

// Click vào icon extension
chrome.action.onClicked.addListener((tab) => {
  toggleListening();
});

// Lắng nghe yêu cầu download từ content script
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === "download") {
    chrome.downloads.download({
      url: request.url,
      filename: request.filename
    });
  }
});
