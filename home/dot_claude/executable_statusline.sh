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
#   ┌── from `wt list statusline --format=claude-code` (+ our tweaks) ┐ ┌─ this script ─┐
#   ~/d/p/pdj master ?^ ● | Opus 4.7 ○ 4% 130k │ ⏱ 12m $0.42 ($2.02/hr) +85 -12 │ 5h 73% (Sat) 7d 17% (Fri)
#                                                 │                                │
#                                             wt base                      session telemetry           rate limits
#
# WORKTRUNK BASE (what comes before the first "│")
#   ~/d/p/pdj          Tilde-compressed worktree path
#   master             Current branch
#   ?                  Untracked files present
#   ^ / ↑              Ahead of default branch (commits not on main)
#   ! / ⇡              Modified tracked files / ahead of remote (unpushed)
#   ●                  CI status (green = pass, red = fail, neutral = unknown)
#   Opus 4.7           Model label (we strip wt's trailing "(1M context)" suffix)
#   ○                  Moon-phase context gauge (🌑 fresh → 🌕 full)
#   4%                 Percent of the model's context window used
#   130k               Input tokens in current context (input + cache_read +
#                      cache_creation from the last API call — same formula
#                      wt's 4% uses). Appended by this script.
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
#
# We strip wt's trailing " (1M context)" / " (200K context)" suffix from the
# model label: it's static info (the model's max window), and we'd rather use
# that horizontal space for the live token count appended below. The regex
# tolerates ANSI color codes around the parenthesised group.
base=$(printf '%s' "$input" \
    | wt list statusline --format=claude-code 2>/dev/null \
    | sed -E 's/ \([^)]*context\)//')

# ─── Extract all augmented fields in one jq call ────────────────────────────
# One value per line, consumed by `readarray` so empty elements are preserved
# by position. IFS-based `read` won't work here: tab is IFS whitespace, and
# bash collapses consecutive whitespace separators — so `\t\t\t` between three
# empty fields would be treated as ONE separator, sliding every later field up
# and (e.g.) landing a 65995-token count where seven-day % belongs. All fields
# use a fallback (numbers → 0, optional fields → "") to guarantee a stable
# 11-line output regardless of which stdin keys are absent.
readarray -t fields < <(
    printf '%s' "$input" | jq -r '[
        (.cost.total_duration_ms // 0),
        (.cost.total_cost_usd // 0),
        (.cost.total_lines_added // 0),
        (.cost.total_lines_removed // 0),
        (.rate_limits.five_hour.used_percentage // ""),
        (.rate_limits.five_hour.resets_at // ""),
        (.rate_limits.seven_day.used_percentage // ""),
        (.rate_limits.seven_day.resets_at // ""),
        (.context_window.current_usage.input_tokens // 0),
        (.context_window.current_usage.cache_creation_input_tokens // 0),
        (.context_window.current_usage.cache_read_input_tokens // 0)
    ] | .[]' 2>/dev/null
)
duration_ms=${fields[0]:-0}
cost=${fields[1]:-0}
lines_added=${fields[2]:-0}
lines_removed=${fields[3]:-0}
five_pct=${fields[4]-}
five_resets=${fields[5]-}
seven_pct=${fields[6]-}
seven_resets=${fields[7]-}
ctx_input=${fields[8]:-0}
ctx_cache_create=${fields[9]:-0}
ctx_cache_read=${fields[10]:-0}

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

# Token count → compact string: "1.2M" / "130k" / "8.5k" / "842". Empty when 0.
# Uses "k" for thousands and "M" for millions to match common Claude Code
# conventions. Under 10k we show one decimal (8.5k) so small changes register;
# at 10k+ we drop it since the precision is noise on a status line.
format_tokens() {
    local n=${1:-0}
    [ "$n" -le 0 ] 2>/dev/null && return
    if   [ "$n" -ge 1000000 ]; then awk -v n="$n" 'BEGIN { printf "%.1fM", n/1000000 }'
    elif [ "$n" -ge 10000 ];   then awk -v n="$n" 'BEGIN { printf "%.0fk", n/1000 }'
    elif [ "$n" -ge 1000 ];    then awk -v n="$n" 'BEGIN { printf "%.1fk", n/1000 }'
    else                            printf '%d' "$n"
    fi
}

# Rate-limit traffic light by used percent (see color key in header comment).
rate_color() {
    awk -v p="$1" 'BEGIN { exit !(p < 75) }' && { printf '%s' "$GREEN"; return; }
    awk -v p="$1" 'BEGIN { exit !(p < 90) }' && { printf '%s' "$YELLOW"; return; }
    printf '%s' "$RED"
}

# ─── Token count (appended to base, next to wt's ○ X% context gauge) ────────
# Formula matches wt's percentage: input + cache_read + cache_creation from
# the last API call. Before the first API call these are all 0 → we skip.
# Suppressed entirely when base is empty (wt absent), since a bare " 130k"
# at the start of the line would be meaningless.
ctx_total=$(( ${ctx_input:-0} + ${ctx_cache_create:-0} + ${ctx_cache_read:-0} ))
tok_str=$(format_tokens "$ctx_total")
[ -n "$base" ] && [ -n "$tok_str" ] && base+=" ${DIM}${tok_str}${RESET}"

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
