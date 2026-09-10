/// 注入到教务页面的脚本。
///
/// 所有构建都会注入：只挂载 `XMLHttpRequest` 与 `fetch` 的钩子，用于在用户
/// 自己打开的课表页面上取回课表数据。**不会**捕获表单提交——正方教务的账号
/// 密码是普通表单 POST，天然不在范围内；也只处理同源请求。
///
/// 脱敏采集上报（写入文件的那部分）由 `window.__ncpuCaptureEnabled` 控制，
/// 仅 Debug 构建由 [importCaptureEnableScript] 打开。
const String importUserScript = r'''
(function () {
  if (window.__ncpuCaptureInstalled) { return; }
  window.__ncpuCaptureInstalled = true;

  var MAX_BODY = 200000;
  var TIMETABLE_MARKER = 'xskbcx_cxXsgrkb';

  function bridge() {
    return (window.flutter_inappwebview && window.flutter_inappwebview.callHandler)
      ? window.flutter_inappwebview.callHandler
      : null;
  }

  function captureEnabled() {
    return window.__ncpuCaptureEnabled === true;
  }

  function clip(text) {
    if (typeof text !== 'string') { return null; }
    return text.length > MAX_BODY ? text.slice(0, MAX_BODY) : text;
  }

  function sameOrigin(rawUrl) {
    try {
      var resolved = new URL(rawUrl, window.location.href);
      return resolved.origin === window.location.origin;
    } catch (e) {
      return false;
    }
  }

  function reportCapture(payload) {
    if (!captureEnabled()) { return; }
    var handler = bridge();
    if (!handler) { return; }
    try {
      handler('importCapture', payload);
    } catch (e) {
      // 采集是可选能力，失败不影响页面本身。
    }
  }

  // 课表原始响应单独回传：它含有身份字段，只用于本次导入，不写入任何文件。
  function reportTimetable(url, text) {
    if (!text || url.indexOf(TIMETABLE_MARKER) === -1) { return; }
    var handler = bridge();
    if (!handler) { return; }
    try {
      handler('timetableData', text);
    } catch (e) {
      // 取不到数据时用户可重新打开一次课表查询。
    }
  }

  var originalOpen = XMLHttpRequest.prototype.open;
  var originalSend = XMLHttpRequest.prototype.send;

  XMLHttpRequest.prototype.open = function (method, url) {
    this.__ncpuCapture = { method: method, url: url };
    return originalOpen.apply(this, arguments);
  };

  XMLHttpRequest.prototype.send = function (body) {
    var xhr = this;
    var meta = xhr.__ncpuCapture || {};
    if (sameOrigin(meta.url)) {
      xhr.addEventListener('loadend', function () {
        var text = null;
        try {
          if (!xhr.responseType || xhr.responseType === 'text') {
            text = xhr.responseText;
          }
        } catch (e) {}
        reportCapture({
          method: meta.method || 'GET',
          url: meta.url,
          requestBody: typeof body === 'string' ? clip(body) : null,
          status: xhr.status,
          contentType: xhr.getResponseHeader ? xhr.getResponseHeader('Content-Type') : null,
          responseBody: clip(text)
        });
        reportTimetable(meta.url, text);
      });
    }
    return originalSend.apply(this, arguments);
  };

  if (window.fetch) {
    var originalFetch = window.fetch;
    window.fetch = function (input, init) {
      var url = (typeof input === 'string') ? input : (input && input.url);
      var method = (init && init.method) || (input && input.method) || 'GET';
      var body = (init && typeof init.body === 'string') ? init.body : null;
      var result = originalFetch.apply(this, arguments);
      if (sameOrigin(url)) {
        result.then(function (response) {
          try {
            response.clone().text().then(function (text) {
              reportCapture({
                method: method,
                url: url,
                requestBody: clip(body),
                status: response.status,
                contentType: response.headers.get('Content-Type'),
                responseBody: clip(text)
              });
              reportTimetable(url, text);
            }).catch(function () {});
          } catch (e) {}
        }).catch(function () {});
      }
      return result;
    };
  }
})();
''';

/// 仅 Debug 注入：打开脱敏采集上报。
const String importCaptureEnableScript =
    'window.__ncpuCaptureEnabled = true;';

/// 脱敏采集上报的 JS 桥接方法名，需与 Dart 侧 `addJavaScriptHandler` 一致。
const String importCaptureHandlerName = 'importCapture';

/// 课表原始响应上报的 JS 桥接方法名。
///
/// 与 [importCaptureHandlerName] 分开：课表原始数据含身份字段，
/// 只允许留在内存供本次导入使用，不进入脱敏报告。
const String importTimetableHandlerName = 'timetableData';
