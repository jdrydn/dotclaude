#!/usr/bin/env bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
SESSION_ID=$(echo "$input" | jq -r '.session_id')
SESSION_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' | cut -d. -f1)
SESSION_RESETS_AT=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'

# Pick bar color based on context usage
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

FILLED=$((PCT / 10)); EMPTY=$((10 - FILLED))
printf -v FILL "%${FILLED}s"; printf -v PAD "%${EMPTY}s"
BAR="${FILL// /█}${PAD// /░}"

DURATION_DAYS=$((DURATION_MS / 86400000))
if [ "$DURATION_DAYS" -lt 4 ]; then AGE_EMOJI="🟢"
elif [ "$DURATION_DAYS" -lt 8 ]; then AGE_EMOJI="🟡"
elif [ "$DURATION_DAYS" -lt 12 ]; then AGE_EMOJI="🔴"
else AGE_EMOJI="❌"; fi

CACHE_FILE="/tmp/statusline-git-cache-$SESSION_ID"
CACHE_MAX_AGE=5  # seconds

cache_is_stale() {
    [ ! -f "$CACHE_FILE" ] || \
    # stat -f %m is macOS, stat -c %Y is Linux
    [ $(($(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0))) -gt $CACHE_MAX_AGE ]
}

if cache_is_stale; then
    if git rev-parse --git-dir > /dev/null 2>&1; then
        BRANCH=$(git branch --show-current 2>/dev/null)
        STAGED=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
        MODIFIED=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
        echo "$BRANCH|$STAGED|$MODIFIED" > "$CACHE_FILE"
    else
        echo "||" > "$CACHE_FILE"
    fi
fi

IFS='|' read -r BRANCH STAGED MODIFIED < "$CACHE_FILE"

echo -e "${CYAN}$MODEL${RESET} | ${DIR##*/} | $BRANCH +$STAGED ~$MODIFIED"
COST_FMT=$(printf '$%.2f' "$COST")
SESSION_SEG=""
if [ -n "$SESSION_PCT" ]; then
    if [ "$SESSION_PCT" -ge 90 ]; then SESSION_COLOR="$RED"
    elif [ "$SESSION_PCT" -ge 70 ]; then SESSION_COLOR="$YELLOW"
    else SESSION_COLOR="$GREEN"; fi
    SESSION_TIME=""
    if [ -n "$SESSION_RESETS_AT" ]; then
        REMAINING=$((SESSION_RESETS_AT - $(date +%s)))
        if [ "$REMAINING" -gt 0 ]; then
            R_HOURS=$((REMAINING / 3600))
            R_MINS=$(((REMAINING % 3600) / 60))
            SESSION_TIME=" (${R_HOURS}h ${R_MINS}m)"
        fi
    fi
    SESSION_SEG=" | 🔋 ${SESSION_COLOR}${SESSION_PCT}%${RESET}${SESSION_TIME}"
fi
echo -e "${BAR_COLOR}${BAR}${RESET} ${PCT}% | ${YELLOW}${COST_FMT}${RESET} | ${AGE_EMOJI}${SESSION_SEG}"
