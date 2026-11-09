#!/usr/bin/env bash
# Smoke test: build/install the debug app in an Android device or Waydroid,
# open TETR.IO without logging in or starting a game, and verify the user script.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

ADB="${ADB:-$HOME/Android/Sdk/platform-tools/adb}"
PACKAGE="com.ley.tetrimized.turbo"
ACTIVITY="com.example.tetr_io_wrapper.MainActivity"
APK="build/app/outputs/flutter-apk/app-debug.apk"
PORT="${TEST_DEVTOOLS_PORT:-9222}"
ADBLOCK_ENABLED="${TETRIMIZED_ADBLOCK:-true}"
CLEAR_APP_DATA="${CLEAR_APP_DATA:-0}"

if [[ ! -x "$ADB" ]]; then
  ADB="$(command -v adb || true)"
fi
if [[ -z "$ADB" || ! -x "$ADB" ]]; then
  echo "ERROR: adb not found. Set ADB or install Android platform-tools." >&2
  exit 1
fi
command -v flutter >/dev/null || { echo "ERROR: flutter not found in PATH." >&2; exit 1; }
command -v node >/dev/null || { echo "ERROR: Node.js (with built-in WebSocket) is required." >&2; exit 1; }

# Flutter 3.47 needs a newer Gradle than this repository currently uses;
# Java 17 plus this flag allows the existing Gradle build to proceed.
if [[ -z "${JAVA_HOME:-}" && -d /usr/lib/jvm/java-17-openjdk ]]; then
  export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
fi
if [[ -n "${JAVA_HOME:-}" ]]; then
  export PATH="$JAVA_HOME/bin:$PATH"
fi

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  # Resolve packages only on a fresh checkout; otherwise preserve the checked-in lockfile.
  if [[ ! -f .dart_tool/package_config.json ]]; then
    flutter pub get
  fi
  flutter build apk --debug --dart-define=TETRIMIZED_ADBLOCK="$ADBLOCK_ENABLED" --android-skip-build-dependency-validation
fi
[[ -f "$APK" ]] || { echo "ERROR: APK not found: $APK" >&2; exit 1; }

DEVICE="${ANDROID_SERIAL:-}"
if [[ -z "$DEVICE" ]]; then
  mapfile -t DEVICES < <("$ADB" devices | awk 'NR > 1 && $2 == "device" {print $1}')
  if [[ ${#DEVICES[@]} -ne 1 ]]; then
    echo "ERROR: expected exactly one authorized Android device; found ${#DEVICES[@]}." >&2
    "$ADB" devices -l >&2
    echo "Set ANDROID_SERIAL to select one." >&2
    exit 1
  fi
  DEVICE="${DEVICES[0]}"
fi
ADB_DEVICE=("$ADB" -s "$DEVICE")

"${ADB_DEVICE[@]}" install -r "$APK"
if [[ "$CLEAR_APP_DATA" == "1" ]]; then
  "${ADB_DEVICE[@]}" shell pm clear "$PACKAGE"
fi
"${ADB_DEVICE[@]}" shell am force-stop "$PACKAGE"
"${ADB_DEVICE[@]}" shell am start -W -n "$PACKAGE/$ACTIVITY"

PID=""
for _ in $(seq 1 30); do
  PID=$("${ADB_DEVICE[@]}" shell pidof "$PACKAGE" 2>/dev/null | tr -d '\r' | awk '{print $1}')
  [[ -n "$PID" ]] && break
  sleep 1
done
[[ -n "$PID" ]] || { echo "ERROR: app process did not start." >&2; exit 1; }

SOCKET="localabstract:webview_devtools_remote_${PID}"
"${ADB_DEVICE[@]}" forward "tcp:${PORT}" "$SOCKET" >/dev/null
trap '"${ADB_DEVICE[@]}" forward --remove "tcp:'"$PORT"'" >/dev/null 2>&1 || true' EXIT

PORT="$PORT" EXPECTED_ADBLOCK="$ADBLOCK_ENABLED" node --input-type=module <<'NODE'
const port = process.env.PORT;
const endpoint = `http://127.0.0.1:${port}/json/list`;
const deadline = Date.now() + 90000;
let target;
while (Date.now() < deadline) {
  try {
    const response = await fetch(endpoint);
    const pages = await response.json();
    target = pages.find((page) => page.type === "page" && page.url.startsWith("https://tetr.io"));
    if (target) break;
  } catch {}
  await new Promise((resolve) => setTimeout(resolve, 1000));
}
if (!target) {
  console.error("FAIL: TETR.IO did not appear in the WebView within 90 seconds.");
  process.exit(1);
}

const ws = new WebSocket(target.webSocketDebuggerUrl);
const pageDeadline = Date.now() + 90000;
let requestId = 0;
let pollTimer;
let interactiveSince = 0;
let lastResourceCount = -1;
let stableResourcePolls = 0;
const queryState = () => ws.send(JSON.stringify({
  id: ++requestId,
  method: "Runtime.evaluate",
  params: {
    expression: "JSON.stringify({title:document.title,readyState:document.readyState,injected:typeof window.sendTetrIoKey,adBlockEnabled:window.__tetrimizedAdBlockEnabled,navigation:(()=>{const n=performance.getEntriesByType('navigation')[0];return n?{domContentLoadedMs:Math.round(n.domContentLoadedEventEnd),loadEventEndMs:Math.round(n.loadEventEnd),transferBytes:n.transferSize}:null})(),resourceCount:performance.getEntriesByType('resource').length,resourceTypes:(()=>{const types={};for(const r of performance.getEntriesByType('resource'))types[r.initiatorType]=(types[r.initiatorType]||0)+1;return types})(),jsHeapUsedBytes:performance.memory?.usedJSHeapSize??null,resourceHosts:(()=>{const hosts={};for(const r of performance.getEntriesByType('resource')){try{const u=new URL(r.name);const h=hosts[u.hostname]??={count:0,byType:{}};h.count++;h.byType[r.initiatorType]=(h.byType[r.initiatorType]||0)+1}catch{}}return Object.entries(hosts).sort((a,b)=>b[1].count-a[1].count).slice(0,30)})()})",
    returnByValue: true,
  },
}));
const timeout = setTimeout(() => {
  console.error("FAIL: TETR.IO did not finish loading within 90 seconds.");
  ws.close();
  process.exit(1);
}, 90000);
ws.onopen = queryState;
ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  if (message.id !== requestId) return;
  const value = message.result?.result?.value;
  if (!value) {
    clearTimeout(timeout);
    console.error("FAIL: could not read the page state.", JSON.stringify(message));
    ws.close();
    process.exit(1);
  }
  const state = JSON.parse(value);
  if (state.title === "TETR.IO" && state.readyState !== "loading" && state.injected === "function" && state.adBlockEnabled === (process.env.EXPECTED_ADBLOCK === "true")) {
    if (interactiveSince === 0) interactiveSince = Date.now();
    if (state.resourceCount === lastResourceCount) stableResourcePolls++;
    else stableResourcePolls = 0;
    lastResourceCount = state.resourceCount;
    const settled = Date.now() - interactiveSince >= 12000 && stableResourcePolls >= 3;
    if (settled) {
      clearTimeout(timeout);
      clearTimeout(pollTimer);
      console.log(JSON.stringify(state, null, 2));
      console.log(`PASS: TETR.IO loaded; injection and ad-block flag verified (${state.adBlockEnabled}) (no login/game input sent).`);
      ws.close();
      process.exit(0);
    }
  }
  if (Date.now() >= pageDeadline) return;
  pollTimer = setTimeout(queryState, 1000);
};
ws.onerror = () => {
  clearTimeout(timeout);
  clearTimeout(pollTimer);
  console.error("FAIL: could not connect to the WebView DevTools endpoint.");
  process.exit(1);
};
NODE

# Waydroid diagnostic only; these figures do not predict physical-device performance.
echo "Android process memory snapshot (Waydroid diagnostic):"
"${ADB_DEVICE[@]}" shell dumpsys meminfo "$PACKAGE" | grep -E 'TOTAL PSS|TOTAL RSS|Native Heap|Dalvik Heap' | head -8 || true
echo "Android UI frame summary (Waydroid; launch/menu only, not a gameplay benchmark):"
"${ADB_DEVICE[@]}" shell dumpsys gfxinfo "$PACKAGE" | grep -E 'Total frames rendered|Janky frames:|50th percentile:|90th percentile:|95th percentile:|99th percentile:' | head -6 || true
echo "Current Android process CPU snapshot (Waydroid diagnostic):"
"${ADB_DEVICE[@]}" shell dumpsys cpuinfo | grep -E "$PACKAGE|com\.google\.android\.webview:sandboxed_process" | head -5 || true
