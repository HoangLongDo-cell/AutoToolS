// === interceptor.js ===
// Chạy trong MAIN world. "Giăng lưới" chặn MỌI cách Facebook có thể phát ghi âm.

(function() {
  let isListening = false;
  let alreadySent = false; // Tránh gửi trùng

  // Lắng nghe lệnh bật/tắt từ content.js
  window.addEventListener('message', function(event) {
    if (event.source !== window) return;
    if (event.data && event.data.type === 'EXT_S_LISTEN_ON') {
      isListening = true;
      alreadySent = false;
      console.log('[Ext S] ✅ Đã BẬT chế độ rình rập. Giăng lưới...');
    }
    if (event.data && event.data.type === 'EXT_S_LISTEN_OFF') {
      isListening = false;
      console.log('[Ext S] ❌ Đã TẮT chế độ rình rập.');
    }
  });

  function sendCapture(data, mimeType, source) {
    if (!isListening || alreadySent) return;
    alreadySent = true;
    isListening = false;
    console.log('[Ext S] 🎉 BẮT ĐƯỢC GHI ÂM! Nguồn:', source, 'Type:', mimeType);
    window.postMessage({
      type: 'EXT_S_BLOB_CAPTURED',
      mimeType: mimeType || 'audio/mp4',
      data: data ? Array.from(new Uint8Array(data)) : null,
      source: source
    }, '*');
  }

  function sendCaptureUrl(url, source) {
    if (!isListening || alreadySent) return;
    alreadySent = true;
    isListening = false;
    console.log('[Ext S] 🎉 BẮT ĐƯỢC URL GHI ÂM! Nguồn:', source, 'URL:', url);
    window.postMessage({
      type: 'EXT_S_URL_CAPTURED',
      url: url,
      source: source
    }, '*');
  }

  // ===== LƯỚI 1: Chặn URL.createObjectURL =====
  const _origCreateObjectURL = URL.createObjectURL;
  URL.createObjectURL = function(obj) {
    const url = _origCreateObjectURL.call(this, obj);
    if (isListening && obj instanceof Blob && obj.type && 
        (obj.type.startsWith('audio/') || obj.type.startsWith('video/'))) {
      console.log('[Ext S] Lưới 1 - createObjectURL:', url, 'Type:', obj.type);
      let reader = new FileReader();
      reader.onload = function() {
        sendCapture(reader.result, obj.type, 'createObjectURL');
      };
      reader.readAsArrayBuffer(obj);
    }
    return url;
  };

  // ===== LƯỚI 2: Chặn HTMLMediaElement.play() =====
  const _origPlay = HTMLMediaElement.prototype.play;
  HTMLMediaElement.prototype.play = function() {
    if (isListening) {
      let url = this.src || this.currentSrc;
      console.log('[Ext S] Lưới 2 - Media.play():', url, 'Tag:', this.tagName);
      if (url) {
        sendCaptureUrl(url, 'media.play');
      }
    }
    return _origPlay.apply(this, arguments);
  };

  // ===== LƯỚI 3: Chặn fetch() =====
  const _origFetch = window.fetch;
  window.fetch = function() {
    let url = arguments[0];
    if (typeof url === 'object' && url.url) url = url.url; // Request object
    
    let result = _origFetch.apply(this, arguments);
    
    if (isListening) {
      result.then(response => {
        let contentType = response.headers.get('content-type') || '';
        let urlStr = (typeof url === 'string') ? url : '';
        
        let isAudio = contentType.startsWith('audio/') || 
                      contentType.startsWith('video/') ||
                      contentType.includes('octet-stream') ||
                      urlStr.includes('audioclip') ||
                      urlStr.includes('voice') ||
                      urlStr.includes('.mp4') ||
                      urlStr.includes('.mp3');
        
        if (isAudio) {
          console.log('[Ext S] Lưới 3 - fetch audio:', urlStr, 'Type:', contentType);
          let cloned = response.clone();
          cloned.arrayBuffer().then(buffer => {
            sendCapture(buffer, contentType || 'audio/mp4', 'fetch');
          });
        }
      }).catch(() => {});
    }
    
    return result;
  };

  // ===== LƯỚI 4: Chặn XMLHttpRequest =====
  const _origXHROpen = XMLHttpRequest.prototype.open;
  const _origXHRSend = XMLHttpRequest.prototype.send;
  
  XMLHttpRequest.prototype.open = function(method, url) {
    this._extS_url = url;
    return _origXHROpen.apply(this, arguments);
  };
  
  XMLHttpRequest.prototype.send = function() {
    if (isListening) {
      this.addEventListener('load', function() {
        let contentType = this.getResponseHeader('content-type') || '';
        let urlStr = this._extS_url || '';
        
        let isAudio = contentType.startsWith('audio/') ||
                      contentType.startsWith('video/') ||
                      urlStr.includes('audioclip') ||
                      urlStr.includes('voice');
        
        if (isAudio && this.response) {
          console.log('[Ext S] Lưới 4 - XHR audio:', urlStr, 'Type:', contentType);
          if (this.response instanceof ArrayBuffer) {
            sendCapture(this.response, contentType || 'audio/mp4', 'xhr');
          } else if (this.response instanceof Blob) {
            let reader = new FileReader();
            reader.onload = function() {
              sendCapture(reader.result, contentType || 'audio/mp4', 'xhr-blob');
            };
            reader.readAsArrayBuffer(this.response);
          }
        }
      });
    }
    return _origXHRSend.apply(this, arguments);
  };

  // ===== LƯỚI 5: Chặn AudioContext.decodeAudioData (Web Audio API) =====
  if (window.AudioContext || window.webkitAudioContext) {
    let AudioCtx = window.AudioContext || window.webkitAudioContext;
    const _origDecode = AudioCtx.prototype.decodeAudioData;
    
    AudioCtx.prototype.decodeAudioData = function(audioData) {
      if (isListening && audioData instanceof ArrayBuffer && audioData.byteLength > 1000) {
        console.log('[Ext S] Lưới 5 - decodeAudioData, size:', audioData.byteLength);
        sendCapture(audioData.slice(0), 'audio/mp4', 'decodeAudioData');
      }
      return _origDecode.apply(this, arguments);
    };
  }

  console.log('[Ext S] 🛡️ Đã cài đặt 5 lưới bắt ghi âm. Sẵn sàng!');
})();
