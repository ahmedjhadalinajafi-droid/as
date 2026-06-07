#!/usr/bin/env bash
# =============================================================================
#  build_deploy.sh — runs on the LOCAL server (Mac mini / home server)
#
#  What it does every time it runs (called by cron every minute):
#   1. Asks Hostinger whether a build has been requested from the admin panel.
#   2. If yes: pulls the latest code, builds the APK, uploads it to Hostinger,
#      and the website then notifies all app users automatically.
#
#  SETUP (one time, on the local server):
#   1. Edit the CONFIG block below.
#   2. chmod +x build_deploy.sh
#   3. Add to cron:  crontab -e
#      * * * * * /full/path/to/build_deploy.sh >> /full/path/to/build.log 2>&1
# =============================================================================

# ── CONFIG — edit these ───────────────────────────────────────────────────────
SERVER_URL="https://ahlulbaytmosque.site/app/server"
API_SECRET="ahlulbayt-masjid-2026-Kx9mPq7Lz3Wn8Rv"

# Where the masjid_app Flutter project is cloned on this machine.
REPO_DIR="$HOME/masjid_app"

# Which branch to build from.
GIT_BRANCH="claude/masjid-app-setup-MHlkW"

# Path to the flutter binary (run `which flutter` to find it).
# Common locations:
#   macOS:  $HOME/flutter/bin/flutter  or  /usr/local/bin/flutter
#   Linux:  $HOME/flutter/bin/flutter  or  /opt/flutter/bin/flutter
FLUTTER_BIN="$HOME/flutter/bin/flutter"

# Which APK to upload — arm64-v8a is ~20 MB and works on all modern phones.
# Use "app-release.apk" for the universal 60 MB build instead.
APK_FILE="app-arm64-v8a-release.apk"
# ─────────────────────────────────────────────────────────────────────────────

LOCK_FILE="/tmp/masjid_build.lock"
LOG_PREFIX="[$(date '+%Y-%m-%d %H:%M:%S')]"

log() { echo "$LOG_PREFIX $*"; }

# ── Guard: don't run if a build is already in progress ───────────────────────
if [ -f "$LOCK_FILE" ]; then
    # Stale lock? (older than 45 minutes → previous run probably crashed)
    lock_age=$(( $(date +%s) - $(date -r "$LOCK_FILE" +%s 2>/dev/null || echo 0) ))
    if [ "$lock_age" -lt 2700 ]; then
        exit 0
    fi
    log "WARNING: removing stale lock (age ${lock_age}s)"
    rm -f "$LOCK_FILE"
fi

# ── Poll Hostinger for a pending build request ────────────────────────────────
RESPONSE=$(curl -sf --max-time 15 \
    -H "X-Api-Secret: $API_SECRET" \
    "$SERVER_URL/build_status.php" 2>/dev/null) || {
    log "ERROR: could not reach $SERVER_URL/build_status.php"
    exit 0
}

# Parse the 'pending' field — if null/absent, nothing to do.
PENDING=$(echo "$RESPONSE" | python3 -c \
    "import sys,json; d=json.load(sys.stdin); print('yes' if d.get('pending') else '')" \
    2>/dev/null)
if [ -z "$PENDING" ]; then
    exit 0
fi

# Extract build parameters
get_field() {
    echo "$RESPONSE" | python3 -c \
        "import sys,json; d=json.load(sys.stdin); p=d.get('pending',{}); print(p.get('$1','$2'))" \
        2>/dev/null || echo "$2"
}
VERSION=$(get_field version "1.0.0")
BUILD=$(get_field build "1")
NOTES=$(get_field notes "أحدث إصدار من تطبيق مسجد وحسينية أهل البيت")
MANDATORY=$(get_field mandatory "false")
NOTIFY=$(get_field notify "true")

log "Build requested: v$VERSION (build $BUILD)"

# ── Lock ──────────────────────────────────────────────────────────────────────
touch "$LOCK_FILE"

report_status() {
    curl -sf --max-time 10 -X POST \
        -H "X-Api-Secret: $API_SECRET" \
        --data-urlencode "set_status=$1" \
        --data-urlencode "message=$2" \
        "$SERVER_URL/build_status.php" > /dev/null 2>&1 || true
}

cleanup() {
    rm -f "$LOCK_FILE"
}
trap cleanup EXIT

report_status "building" "🔨 جارٍ سحب الكود من GitHub..."
log "Pulling latest code from $GIT_BRANCH..."

# ── Pull latest code ──────────────────────────────────────────────────────────
cd "$REPO_DIR" || {
    log "ERROR: REPO_DIR not found: $REPO_DIR"
    report_status "failed" "❌ مجلد المشروع غير موجود: $REPO_DIR"
    exit 1
}

git fetch origin "$GIT_BRANCH" 2>&1 | tail -3
git reset --hard "origin/$GIT_BRANCH"

# ── Build ──────────────────────────────────────────────────────────────────────
report_status "building" "🔨 جارٍ البناء (flutter build apk)... قد يستغرق 2-5 دقائق"
log "Running flutter pub get..."
"$FLUTTER_BIN" pub get --no-color 2>&1 | tail -5

log "Building APK ($APK_FILE)..."
"$FLUTTER_BIN" build apk --split-per-abi --release --no-color 2>&1 | tail -10

APK_PATH="$REPO_DIR/build/app/outputs/flutter-apk/$APK_FILE"
if [ ! -f "$APK_PATH" ]; then
    log "ERROR: APK not found at $APK_PATH"
    report_status "failed" "❌ فشل البناء — لم يُعثر على $APK_FILE"
    exit 1
fi

APK_SIZE_MB=$(du -sh "$APK_PATH" | cut -f1)
log "APK built: $APK_PATH ($APK_SIZE_MB)"

# ── Upload APK to Hostinger ────────────────────────────────────────────────────
report_status "building" "📤 جارٍ رفع الـ APK إلى الخادم..."
log "Uploading APK to $SERVER_URL/receive_build.php ..."

UPLOAD_RESP=$(curl -sf --max-time 300 -X POST \
    -H "X-Api-Secret: $API_SECRET" \
    -F "apk=@$APK_PATH" \
    -F "version=$VERSION" \
    -F "build=$BUILD" \
    -F "notes=$NOTES" \
    -F "mandatory=$MANDATORY" \
    -F "notify=$NOTIFY" \
    "$SERVER_URL/receive_build.php" 2>/dev/null)

UPLOAD_OK=$(echo "$UPLOAD_RESP" | python3 -c \
    "import sys,json; d=json.load(sys.stdin); print('yes' if d.get('ok') else '')" \
    2>/dev/null)

if [ -z "$UPLOAD_OK" ]; then
    log "ERROR: upload failed. Response: $UPLOAD_RESP"
    report_status "failed" "❌ فشل رفع الـ APK: $UPLOAD_RESP"
    exit 1
fi

PUSH_RESULT=$(echo "$UPLOAD_RESP" | python3 -c \
    "import sys,json; d=json.load(sys.stdin); print(d.get('push','?'))" 2>/dev/null)
log "SUCCESS: v$VERSION published. Push notification: $PUSH_RESULT"
