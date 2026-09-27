#!/bin/bash
# ds_perf_all.sh <on|off> <tag> — scope=all 采样轮: 720 游戏小时窗口内每 2s 抓一次
# /profile/threads (各线程 CPU 差值). 用途: 看刀开/关时 tbb worker 的忙闲差。
WS=/d/documents/workspace
SAVE=ds_test_20260927
OUT=$WS/archive/supply_perf_20260927
API=127.0.0.1:17389
PORT=17389
HSPAN=720
state=$1; tag=$2
mkdir -p "$OUT"
lua() { curl -s --max-time 15 -X POST $API/lua -H "Content-Type: text/plain" --data-binary "$1"; }
hour() { curl -s --max-time 5 $API/health | grep -o '"game_hour":[0-9]*' | cut -d: -f2; }

echo "[$tag] kill + relaunch"
taskkill //F //IM hoi4.exe >/dev/null 2>&1
sleep 4
( cd "$WS" && ./hoi4_launcher.exe -start_save=$SAVE -http=$PORT -human_ai >/dev/null 2>&1 & )
for i in $(seq 1 60); do
  curl -s --max-time 4 $API/health 2>/dev/null | grep -q '"session_active":true' && break
  sleep 5
done
curl -s --max-time 4 $API/health | grep -q '"session_active":true' || { echo "[$tag] FATAL: no session"; exit 1; }
sleep 10
if [ "$state" = off ]; then
  lua 'hoi4.console("set_global_flag DS_TRADE_ON 0") hoi4.console("set_global_flag DS_SUPPLY_ON 0") hoi4.console("set_global_flag DS_PIN_ON 0") return "cleared"' >/dev/null
else
  lua 'return DISABLE_SUPPLY.on(true, true, true)' >/dev/null
fi
sleep 4
lua 'local s=DISABLE_SUPPLY.status() return string.format("STATE t=%s s=%s p=%s", tostring(s.state.trade),tostring(s.state.supply),tostring(s.state.pin))' > "$OUT/allstate_$tag.txt"

H0=$(hour); echo "[$tag] H0=$H0"
lua 'hoi4.game_set_speed(5) return "s5"' >/dev/null
curl -s --max-time 8 -X POST "$API/profile/start?ms=10&stacks=0&scope=all" >/dev/null
curl -s --max-time 8 -X POST $API/game/pause --data-binary '0' >/dev/null

: > "$OUT/threads_$tag.txt"
: > "$OUT/allsamples_$tag.txt"
for i in $(seq 1 400); do
  now=$(date +%s.%N)
  hh=$(hour)
  echo "$now ${hh:-0}" >> "$OUT/allsamples_$tag.txt"
  echo "### t=$now h=$hh" >> "$OUT/threads_$tag.txt"
  curl -s --max-time 5 $API/profile/threads >> "$OUT/threads_$tag.txt"
  echo >> "$OUT/threads_$tag.txt"
  [ -n "$hh" ] && [ "$hh" -ge $((H0 + HSPAN)) ] && break
  sleep 1.4
done
curl -s --max-time 8 -X POST $API/game/pause --data-binary '1' >/dev/null
curl -s --max-time 8 -X POST $API/profile/stop >/dev/null
lua 'local s=DISABLE_SUPPLY.status() return string.format("skipped=%d gated=%d passed=%d pinned=%d refilled=%d filled=%d", s.state.skipped,s.state.gated,s.state.passed,s.state.pinned,s.state.refilled,s.state.filled)' > "$OUT/allcounters_$tag.txt"
echo "[$tag] done"
