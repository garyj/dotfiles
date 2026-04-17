#!/bin/bash
# ────────────────────────────────────────────────────────────────────────────
# Claude Code statusline
# ────────────────────────────────────────────────────────────────────────────
#
# Claude Code invokes this script on every statusline refresh, piping session
# context as JSON to stdin. The script prints a single line to stdout.
#
# ANATOMY OF THE FINAL OUTPUT
#
#   ┌── from `wt list statusline --format=claude-code` ───────────┐ ┌─ this script ─┐
#   ~/d/p/pdj master ?^ ● | Opus 4.7 (1M context) ○ 4% │ ⏱ 12m $0.42 ($2.02/hr) +85 -12 │ 5h 73% (Sat) 7d 17% (Fri)
#                                                     │                                │
#                                                 wt base                       session telemetry          rate limits
#
# WORKTRUNK BASE (what comes before the first "│")
#   ~/d/p/pdj          Tilde-compressed worktree path
#   master             Current branch
#   ?                  Untracked files present
#   ^ / ↑              Ahead of default branch (commits not on main)
#   ! / ⇡              Modified tracked files / ahead of remote (unpushed)
#   ●                  CI status (green = pass, red = fail, neutral = unknown)
#   Opus 4.7 (1M ...)  Model label
#   ○                  Moon-phase context gauge (🌑 fresh → 🌕 full)
#   4%                 Percent of the model's context window used
#
# SESSION TELEMETRY (first "│…│" block)
#   ⏱ 12m              Session duration — how long this Claude session has run
#   $0.42              Session cost in USD (see plan context below)
#   ($2.02/hr)         Burn rate projection — only rendered after 1 min
#   +85 -12            Cumulative lines added / removed this session (all files)
#
#   COST FIELD, BY PLAN:
#     Max plan (you)   Equivalent API value consumed. NOT money charged.
#                      Max is flat-fee; this is useful as a relative "how much
#                      of the plan's budget am I burning through" signal.
#     Pro plan         Same as Max — equivalent API value, not dollars charged.
#     API-key billing  Actual dollars spent against your API balance.
#
# RATE LIMITS (second "│…│" block — Pro/Max plans only)
#   5h 73% (Sat)       5-hour rolling bucket: 73% used, resets Saturday
#   7d 17% (Fri)       7-day  rolling bucket: 17% used, resets Friday
#                      Reset format:  HH:MM if resetting today, else day name.
#   Colors:            green  < 75% used  — plenty of headroom
#                      yellow < 90% used  — start wrapping up
#                      red   >= 90% used  — you're about to hit the cap
#
#   On API-key billing (no subscription), rate_limits fields are absent in the
#   stdin JSON and this whole block is omitted.
#
# STDIN SCHEMA REFERENCE
#   https://code.claude.com/docs/en/statusline
#
# ────────────────────────────────────────────────────────────────────────────

# Buffer stdin once — we both forward it to `wt` and extract fields from it.
input=$(cat)

# ─── BASE: worktrunk's worktree-aware output ────────────────────────────────
# Handles everything before the first "│" separator. If wt fails or isn't on
# PATH, $base is empty — the widget sections still render below.
base=$(printf '%s' "$input" | wt list statusline --format=claude-code 2>/dev/null)

# ─── Extract all augmented fields in one jq call ────────────────────────────
# Tab-separated output is consumed by a single `read`. Numeric fields default
# to 0; rate-limit fields use `// empty` so they're empty strings when absent
# (API-key billing), which lets the rate widget self-suppress cleanly.
IFS=$'\t' read -r duration_ms cost lines_added lines_removed \
    five_pct five_resets seven_pct seven_resets < <(
    printf '%s' "$input" | jq -r '[
        (.cost.total_duration_ms // 0),
        (.cost.total_cost_usd // 0),
        (.cost.total_lines_added // 0),
        (.cost.total_lines_removed // 0),
        (.rate_limits.five_hour.used_percentage // empty),
        (.rate_limits.five_hour.resets_at // empty),
        (.rate_limits.seven_day.used_percentage // empty),
        (.rate_limits.seven_day.resets_at // empty)
    ] | @tsv' 2>/dev/null
)

# ─── ANSI colors ────────────────────────────────────────────────────────────
DIM=$'\033[2m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[01;33m'
RED=$'\033[01;31m'
RESET=$'\033[0m'
SEP=" ${DIM}│${RESET} "    # Section separator between base, telemetry, rate limits

# ─── Helpers ────────────────────────────────────────────────────────────────

# ms → concise duration: "2h 15m" / "12m" / "45s". Empty string when 0.
format_duration() {
    local ms=${1:-0}
    [ "$ms" -le 0 ] 2>/dev/null && return
    local total=$((ms / 1000))
    local h=$((total / 3600)) m=$(((total % 3600) / 60)) s=$((total % 60))
    if   [ "$h" -gt 0 ]; then printf '%dh %dm' "$h" "$m"
    elif [ "$m" -gt 0 ]; then printf '%dm' "$m"
    else                      printf '%ds' "$s"
    fi
}

# Unix ts → "HH:MM" if reset is today, else abbreviated day name ("Mon").
# Works on both GNU (`date -d`) and BSD (`date -r`) date.
format_reset() {
    local ts=$1
    [ -z "$ts" ] && return
    local today day
    today=$(date +%Y-%m-%d)
    day=$(date -d "@$ts" +%Y-%m-%d 2>/dev/null || date -r "$ts" +%Y-%m-%d 2>/dev/null)
    if [ "$day" = "$today" ]; then
        date -d "@$ts" +%H:%M 2>/dev/null || date -r "$ts" +%H:%M 2>/dev/null
    else
        date -d "@$ts" +%a    2>/dev/null || date -r "$ts" +%a    2>/dev/null
    fi
}

# Rate-limit traffic light by used percent (see color key in header comment).
rate_color() {
    awk -v p="$1" 'BEGIN { exit !(p < 75) }' && { printf '%s' "$GREEN"; return; }
    awk -v p="$1" 'BEGIN { exit !(p < 90) }' && { printf '%s' "$YELLOW"; return; }
    printf '%s' "$RED"
}

# ─── WIDGET: Session telemetry (duration + cost + burn + lines shipped) ─────
# Each sub-widget self-skips when its data is zero/missing, so fresh sessions
# show nothing here and the block fills in as the session progresses.
widgets=""

# Duration — .cost.total_duration_ms
# Appears on every session; never suppressed after the first few seconds.
dur=$(format_duration "${duration_ms:-0}")
[ -n "$dur" ] && widgets+=" ⏱ $dur"

# Cost + burn rate — .cost.total_cost_usd
# See header comment for what $ means by plan type (Max / Pro / API).
# Burn rate is held back for the first 60s to avoid nonsense projections
# like "$0.05 over 2 seconds = $90/hr".
if awk -v c="${cost:-0}" 'BEGIN { exit !(c > 0) }'; then
    widgets+=$(printf ' $%.2f' "$cost")
    if [ "${duration_ms:-0}" -gt 60000 ] 2>/dev/null; then
        per_hr=$(awk -v c="$cost" -v ms="$duration_ms" \
            'BEGIN { printf "%.2f", c / (ms / 3600000) }')
        widgets+=" (\$${per_hr}/hr)"
    fi
fi

# Lines shipped — .cost.total_lines_added / .cost.total_lines_removed
# Cumulative across every file Claude has edited this session. Appears after
# the first edit; stays until the session ends.
if [ "${lines_added:-0}" -gt 0 ] 2>/dev/null || [ "${lines_removed:-0}" -gt 0 ] 2>/dev/null; then
    widgets+=" ${GREEN}+${lines_added}${RESET} ${RED}-${lines_removed}${RESET}"
fi

# ─── WIDGET: Claude subscription rate limits (Pro/Max only) ─────────────────
# Two buckets exposed by Claude Code in stdin JSON:
#   .rate_limits.five_hour   rolling 5-hour window
#   .rate_limits.seven_day   rolling 7-day  window
#
# When the user is on API-key billing these fields are absent and the block
# is suppressed entirely (no empty parens, no leading separator).
rate=""

if [ -n "$five_pct" ]; then
    color=$(rate_color "$five_pct")
    r=$(format_reset "$five_resets")
    rate+=" ${color}5h $(printf '%.0f' "$five_pct")%${RESET}"
    [ -n "$r" ] && rate+=" ${DIM}(${r})${RESET}"
fi

if [ -n "$seven_pct" ]; then
    color=$(rate_color "$seven_pct")
    r=$(format_reset "$seven_resets")
    rate+=" ${color}7d $(printf '%.0f' "$seven_pct")%${RESET}"
    [ -n "$r" ] && rate+=" ${DIM}(${r})${RESET}"
fi

# ─── Compose final output ───────────────────────────────────────────────────
# Layout:  <wt base> │ <session telemetry> │ <rate limits>
# Each "│" section prepends itself only if it has content, so the line is
# exactly as wide as it needs to be.
output="$base"
[ -n "$widgets" ] && output+="${SEP}${widgets# }"
[ -n "$rate" ]    && output+="${SEP}${rate# }"

printf '%s\n' "$output"
