#!/bin/bash
# ionwd.sh — Ion DTN watchdog
# - Detects unresponsiveness/lock (via timeout on bpadmin)
# - Restarts Ion using killm, then ionstart
# - Logs restart events with timestamp and reason to ionwd.log

# ===== Config =====
ION_CONFIG_FILE="/home/samo/dtn/host268484800.rc"
LOG_DIR="/home/samo/dtn"                      # Base dir for ionwd.log
LOG_FILE="$LOG_DIR/ionwd.log"

START_SLEEP=5        # Seconds to wait after stop/start
WATCH_INTERVAL=15    # Seconds between checks
TIMEOUT=2            # Seconds to wait for bpadmin before declaring unresponsive

# ===== Helpers =====
ts() { date +"%Y-%m-%d %H:%M:%S"; }

log_line() {
  echo "$(ts) - $*" | tee -a "$LOG_FILE"
}

# Start/Stop
start_ion() {
  ionstart -I "$ION_CONFIG_FILE"
}

stop_ion() {
  # Hard stop everything managed by ion
  killm
}

# Log restart event with reason
log_restart() {
  local reason="$1"
  log_line "ION RESTART: $reason"
}

# Health check: returns 0 if healthy, 1 otherwise
ion_healthy() {
  # Expect bpadmin 'l' to return prompt containing 'List what?:'
  local resp
  resp="$(timeout "$TIMEOUT" bpadmin <<< "l" 2>&1 | tr -d '\r\n')"
  local code=$?
  if [ $code -eq 0 ] && [[ "$resp" == *"List what?:"* ]]; then
    # Cleanly quit interactive if it started
    echo "q" | bpadmin >/dev/null 2>&1
    return 0
  fi
  return 1
}

restart_ion() {
  local reason="$1"
  log_restart "$reason"

  stop_ion
  sleep "$START_SLEEP"

  start_ion
  sleep "$START_SLEEP"

  if ion_healthy; then
    log_line "Ion restart successful. Health check passed."
  else
    log_line "Ion restart attempted but health check FAILED."
  fi
}

# Handle signals so we log orderly shutdown of the watchdog
trap 'log_line "ionwd exiting (signal received)."; exit 0' INT TERM

# ===== Main loop =====
log_line "Ion watchdog started. Monitoring every ${WATCH_INTERVAL}s (timeout ${TIMEOUT}s)."

while true; do
  if ion_healthy; then
    # Healthy
    :
  else
    # Determine reason for failure for the log message
    # If timeout happened, timeout returns 124. Re-run quickly just to classify.
    timeout "$TIMEOUT" bpadmin <<< "l" >/dev/null 2>&1
    case $? in
      124)   restart_ion "timeout";;
      127)   log_line "bpadmin not found. Cannot health-check. Attempting restart anyway."
             restart_ion "bpadmin-missing";;
      *)     # Could be ion not running, lock, or other error
             restart_ion "unresponsive-or-not-running";;
    esac
  fi

  sleep "$WATCH_INTERVAL"
done
