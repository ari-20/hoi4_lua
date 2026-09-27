#!/bin/bash
# ds_perf_ab.sh <on|off> <tag> — 单轮测量: 载锚档 → 置刀态 → 跑固定 720 游戏小时
# 窗口(带主线程 5ms 栈采样) → 落 samples/folded/top/state 四件。
# 控制变量: 同一锚档、同启动参数(speed 5, -human_ai)、同窗口长度、同采样设置。
WS=/d/documents/workspace
SAVE=ds_test_20260927
OUT=$WS/archive/supply_perf_20260927
API=127.0.0.1:17389
PORT=17389
HSPAN=720
state=$1
tag=$2
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
if ! curl -s --max-time 4 $API/health 2>/dev/null | grep -q '"session_active":true'; then
  echo "[$tag] FATAL: session never came up (check -http=$PORT reached the game)"; exit 1
fi
sleep 10                                    # 让游戏内派发/读旗恢复落定

echo "[$tag] set knife state = $state"
if [ "$state" = off ]; then
  lua 'hoi4.console("set_global_flag DS_TRADE_ON 0") hoi4.console("set_global_flag DS_SUPPLY_ON 0") hoi4.console("set_global_flag DS_PIN_ON 0") return "flags cleared"' >/dev/null
else
  lua 'return DISABLE_SUPPLY.on(true, true, true)' >/dev/null
fi
sleep 4

lua 'local s=DISABLE_SUPPLY.status() return string.format("STATE trade=%s supply=%s pin=%s synced=%s | FLAG %s/%s/%s", tostring(s.state.trade),tostring(s.state.supply),tostring(s.state.pin),tostring(s.state.synced),tostring(s.flags.trade),tostring(s.flags.supply),tostring(s.flags.pin))' > "$OUT/state_$tag.txt"
lua 'local s=DISABLE_SUPPLY.status() return string.format("skipped=%d gated=%d passed=%d pinned=%d refilled=%d filled=%d move=%d", s.state.skipped,s.state.gated,s.state.passed,s.state.pinned,s.state.refilled,s.state.filled,s.state.move_hits)' > "$OUT/counters_start_$tag.txt"

H0=$(hour)
echo "[$tag] H0=$H0  profile start + unpause"
lua 'hoi4.game_set_speed(5) return "s5"' >/dev/null
curl -s --max-time 8 -X POST "$API/profile/start?ms=5&stacks=1" >/dev/null
curl -s --max-time 8 -X POST $API/game/pause --data-binary '0' >/dev/null

: > "$OUT/samples_$tag.txt"
for i in $(seq 1 400); do
  now=$(date +%s.%N)
  hh=$(hour)
  echo "$now ${hh:-0}" >> "$OUT/samples_$tag.txt"
  [ -n "$hh" ] && [ "$hh" -ge $((H0 + HSPAN)) ] && break
  sleep 0.4
done

curl -s --max-time 8 -X POST $API/game/pause --data-binary '1' >/dev/null
curl -s --max-time 8 -X POST $API/profile/stop >/dev/null
lua 'local s=DISABLE_SUPPLY.status() return string.format("skipped=%d gated=%d passed=%d pinned=%d refilled=%d filled=%d move=%d", s.state.skipped,s.state.gated,s.state.passed,s.state.pinned,s.state.refilled,s.state.filled,s.state.move_hits)' > "$OUT/counters_end_$tag.txt"
curl -s --max-time 8 -X POST "$API/profile/top?n=25" > "$OUT/top_$tag.txt"
curl -s --max-time 20 -X POST "$API/profile/folded?path=D:/documents/workspace/archive/supply_perf_20260927/folded_$tag.txt" >/dev/null
echo "[$tag] done: $(tail -1 "$OUT/samples_$tag.txt")"
