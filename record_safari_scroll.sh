#!/usr/bin/env bash
set -euo pipefail

# Automated Safari website walkthrough recorder for macOS.
# The script uses Safari automation plus requestAnimationFrame scrolling.
# It records automatically with the built-in `screencapture -v` when available,
# and falls back to a guided QuickTime workflow when video capture automation is unavailable.

URL="https://csprofkgd.github.io/deep-learning-coursepage/"
INITIAL_PAUSE_SECONDS=15
SCROLL_DURATION_SECONDS=90
WINDOW_WIDTH=1600
WINDOW_HEIGHT=1000
OUTPUT_NAME="deep_learning_coursepage"

# Position the Safari window away from the menu bar while keeping browser chrome visible.
WINDOW_X=80
WINDOW_Y=60

DESKTOP_DIR="${HOME}/Desktop"
TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
OUTPUT_PATH="${DESKTOP_DIR}/${OUTPUT_NAME}_${TIMESTAMP}.mov"
CAPTURE_RECT="${WINDOW_X},${WINDOW_Y},${WINDOW_WIDTH},${WINDOW_HEIGHT}"
SCROLL_JS_FILE=""
RECORDING_PID=""

log() {
  printf "\033[1;36m==>\033[0m %s\n" "$1"
}

warn() {
  printf "\033[1;33mWarning:\033[0m %s\n" "$1" >&2
}

fail() {
  printf "\033[1;31mError:\033[0m %s\n" "$1" >&2
  exit 1
}

cleanup() {
  if [[ -n "${SCROLL_JS_FILE}" && -f "${SCROLL_JS_FILE}" ]]; then
    rm -f "${SCROLL_JS_FILE}"
  fi
}
trap cleanup EXIT

require_app() {
  local app_name="$1"
  if ! open -Ra "${app_name}" >/dev/null 2>&1; then
    fail "${app_name} is not installed or is not visible to Launch Services."
  fi
}

require_command() {
  local command_name="$1"
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    fail "Required command not found: ${command_name}"
  fi
}

print_permission_guidance() {
  cat <<'EOF'

macOS permissions that may be required:

1. Accessibility
   System Settings -> Privacy & Security -> Accessibility
   Enable Terminal, iTerm, or the shell app running this script.

2. Screen Recording
   System Settings -> Privacy & Security -> Screen Recording
   Enable Terminal and/or QuickTime Player.

3. Automation
   System Settings -> Privacy & Security -> Automation
   Allow Terminal to control Safari.
   If using QuickTime fallback, allow Terminal to control QuickTime Player.

If macOS shows a permission prompt, grant permission, then run this script again.

EOF
}

verify_requirements() {
  log "Verifying macOS tools and applications"
  require_command osascript
  require_command open
  require_command screencapture
  require_app Safari
  require_app "QuickTime Player"

  if [[ ! -d "${DESKTOP_DIR}" ]]; then
    fail "Desktop folder not found at ${DESKTOP_DIR}"
  fi
}

run_osascript() {
  /usr/bin/osascript - "$@"
}

quit_safari() {
  log "Quitting Safari if it is already running"
  run_osascript <<'APPLESCRIPT' >/dev/null
tell application "Safari"
  if it is running then
    quit
  end if
end tell
APPLESCRIPT

  local attempts=0
  while pgrep -x Safari >/dev/null 2>&1; do
    attempts=$((attempts + 1))
    if (( attempts > 30 )); then
      fail "Safari did not quit cleanly. Quit Safari manually and run again."
    fi
    sleep 0.5
  done
}

open_single_safari_window() {
  log "Opening exactly one Safari window and one Safari tab"
  run_osascript "${URL}" "${WINDOW_X}" "${WINDOW_Y}" "${WINDOW_WIDTH}" "${WINDOW_HEIGHT}" <<'APPLESCRIPT'
on run argv
  set targetUrl to item 1 of argv
  set windowX to (item 2 of argv) as integer
  set windowY to (item 3 of argv) as integer
  set windowWidth to (item 4 of argv) as integer
  set windowHeight to (item 5 of argv) as integer
  set windowRight to windowX + windowWidth
  set windowBottom to windowY + windowHeight

  tell application "Safari"
    activate
    delay 0.5
    close every window
    delay 0.5
    make new document with properties {URL:targetUrl}
    set bounds of front window to {windowX, windowY, windowRight, windowBottom}
  end tell
end run
APPLESCRIPT
}

wait_for_page_load() {
  log "Waiting for the page to finish loading"
  local attempts=0
  local state=""
  while true; do
    state="$(run_osascript <<'APPLESCRIPT' 2>/dev/null || true
tell application "Safari"
  if (count of windows) is 0 then return "missing-window"
  return do JavaScript "document.readyState" in current tab of front window
end tell
APPLESCRIPT
)"
    if [[ "${state}" == "complete" ]]; then
      break
    fi
    attempts=$((attempts + 1))
    if (( attempts > 80 )); then
      fail "Safari page did not report readyState=complete."
    fi
    sleep 0.25
  done
}

normalize_safari_state() {
  log "Verifying Safari has one window and one visible tab"
  run_osascript "${URL}" "${WINDOW_X}" "${WINDOW_Y}" "${WINDOW_WIDTH}" "${WINDOW_HEIGHT}" <<'APPLESCRIPT'
on run argv
  set targetUrl to item 1 of argv
  set windowX to (item 2 of argv) as integer
  set windowY to (item 3 of argv) as integer
  set windowWidth to (item 4 of argv) as integer
  set windowHeight to (item 5 of argv) as integer
  set windowRight to windowX + windowWidth
  set windowBottom to windowY + windowHeight

  tell application "Safari"
    activate
    if (count of windows) is 0 then
      make new document with properties {URL:targetUrl}
    end if

    repeat while (count of windows) > 1
      close window 2
    end repeat

    tell front window
      repeat while (count of tabs) > 1
        close tab 2
      end repeat
      set URL of current tab to targetUrl
      set bounds to {windowX, windowY, windowRight, windowBottom}
    end tell
  end tell
end run
APPLESCRIPT
}

scroll_to_top() {
  log "Resetting page to the top"
  run_osascript <<'APPLESCRIPT' >/dev/null
tell application "Safari"
  do JavaScript "window.scrollTo(0, 0);" in current tab of front window
end tell
APPLESCRIPT
}

prepare_scroll_script() {
  SCROLL_JS_FILE="$(mktemp "${TMPDIR:-/tmp}/safari-scroll.XXXXXX.js")"
  cat >"${SCROLL_JS_FILE}" <<EOF
(function () {
  const startY = 0;
  const maxY = Math.max(
    0,
    document.documentElement.scrollHeight - window.innerHeight
  );
  const duration = ${SCROLL_DURATION_SECONDS} * 1000;

  function easeInOutCubic(t) {
    return t < 0.5
      ? 4 * t * t * t
      : 1 - Math.pow(-2 * t + 2, 3) / 2;
  }

  window.scrollTo(0, startY);

  let startTime = null;
  function step(timestamp) {
    if (startTime === null) {
      startTime = timestamp;
    }

    const elapsed = timestamp - startTime;
    const t = Math.min(elapsed / duration, 1);
    const eased = easeInOutCubic(t);
    const y = startY + (maxY - startY) * eased;

    window.scrollTo(0, y);

    if (t < 1) {
      requestAnimationFrame(step);
    }
  }

  requestAnimationFrame(step);
})();
EOF
}

run_scroll_animation() {
  log "Starting smooth ${SCROLL_DURATION_SECONDS}s JavaScript scroll"
  run_osascript "${SCROLL_JS_FILE}" <<'APPLESCRIPT' >/dev/null
on run argv
  set jsPath to item 1 of argv
  set jsCode to read POSIX file jsPath
  tell application "Safari"
    do JavaScript jsCode in current tab of front window
  end tell
end run
APPLESCRIPT
}

countdown() {
  local seconds="$1"
  local message="$2"
  log "${message}"
  for ((remaining = seconds; remaining > 0; remaining--)); do
    printf "\rStarting in %2d seconds..." "${remaining}"
    sleep 1
  done
  printf "\r%28s\r" ""
}

move_mouse_pointer_away() {
  log "Moving mouse pointer away from the recording area if possible"
  if command -v cliclick >/dev/null 2>&1; then
    cliclick "m:${WINDOW_X},$((WINDOW_Y + WINDOW_HEIGHT + 40))" || warn "cliclick could not move the pointer."
    return
  fi

  warn "No built-in macOS command reliably moves the mouse pointer."
  warn "Optional helper 'cliclick' was not found."
  cat <<EOF

Move the mouse pointer to the bottom-right corner of the screen, outside the Safari window.
Do not touch the mouse after the countdown starts.

EOF
  countdown 8 "Waiting so you can move the pointer away"
}

supports_screencapture_video() {
  screencapture -h 2>&1 | grep -q -- "-v"
}

start_automatic_recording() {
  log "Starting automatic screen recording to ${OUTPUT_PATH}"
  screencapture -v -R"${CAPTURE_RECT}" "${OUTPUT_PATH}" >/dev/null 2>&1 &
  RECORDING_PID="$!"
  sleep 2

  if ! kill -0 "${RECORDING_PID}" >/dev/null 2>&1; then
    RECORDING_PID=""
    return 1
  fi

  return 0
}

stop_automatic_recording() {
  if [[ -z "${RECORDING_PID}" ]]; then
    return
  fi

  log "Stopping automatic recording"
  kill -INT "${RECORDING_PID}" >/dev/null 2>&1 || true
  wait "${RECORDING_PID}" >/dev/null 2>&1 || true
  RECORDING_PID=""

  if [[ -f "${OUTPUT_PATH}" ]]; then
    log "Saved recording: ${OUTPUT_PATH}"
  else
    warn "Recording process ended, but the output file was not found."
  fi
}

manual_quicktime_fallback() {
  cat <<EOF

Automatic video recording is not available or did not start.

Manual QuickTime fallback:
1. Open QuickTime Player.
2. Choose File -> New Screen Recording.
3. Select the Safari window region, keeping the toolbar and URL bar visible.
4. Make sure the mouse pointer is outside the Safari window.
5. Start recording.
6. Return to this Terminal window and press Return.

The script will then wait ${INITIAL_PAUSE_SECONDS}s at the top and perform the smooth ${SCROLL_DURATION_SECONDS}s scroll.
After the scroll finishes, stop QuickTime manually and save the movie to:

${OUTPUT_PATH}

EOF
  read -r -p "Press Return after QuickTime recording has started..."
  log "Holding at the top for ${INITIAL_PAUSE_SECONDS}s"
  sleep "${INITIAL_PAUSE_SECONDS}"
  run_scroll_animation
  sleep "$((SCROLL_DURATION_SECONDS + 3))"
  cat <<EOF

Scroll complete. Stop the QuickTime recording now and save it as:
${OUTPUT_PATH}

EOF
}

record_automatically_or_fallback() {
  if supports_screencapture_video && start_automatic_recording; then
    log "Holding at the top for ${INITIAL_PAUSE_SECONDS}s"
    sleep "${INITIAL_PAUSE_SECONDS}"
    run_scroll_animation
    sleep "$((SCROLL_DURATION_SECONDS + 3))"
    stop_automatic_recording
  else
    manual_quicktime_fallback
  fi
}

main() {
  cat <<EOF

Safari Website Recording
URL: ${URL}
Initial pause: ${INITIAL_PAUSE_SECONDS}s
Scroll duration: ${SCROLL_DURATION_SECONDS}s
Window: ${WINDOW_WIDTH}x${WINDOW_HEIGHT} at ${WINDOW_X},${WINDOW_Y}
Output: ${OUTPUT_PATH}

EOF

  verify_requirements
  print_permission_guidance
  quit_safari
  open_single_safari_window
  wait_for_page_load
  normalize_safari_state
  wait_for_page_load
  scroll_to_top
  prepare_scroll_script
  move_mouse_pointer_away
  record_automatically_or_fallback

  log "Done"
}

main "$@"
