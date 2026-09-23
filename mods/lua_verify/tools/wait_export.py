# wait_export.py - poll for export-done flag (flag-file protocol, t35)
# usage: python wait_export.py [timeout_sec]
#
# t46 加固: 热重载可能一次 touch 触发多轮导出, 删除 flag 后仍可能被上一轮
# (旧代码) 的导出写回 —— 只按“存在性”判定会拿到陈旧导出。改为要求
# flag 的 mtime 晚于本脚本启动时刻 (且 flag 内容时间戳 >= 启动时刻)。
import sys, os, time

LUA = os.environ.get('MOD_LUA_DIR',
    os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lua'))
# t90: 9-12 重写后 savefull_export.lua 只写 tmp_savefull_done.flag
# (旧 a1_export_done.flag 是 legacy matrix 出口的名字, 已无人写)
FLAG = os.path.join(LUA, 'tmp_savefull_done.flag')


def main():
    timeout = int(sys.argv[1]) if len(sys.argv) > 1 else 60
    # t90: 参考时刻可由调用方传入 (rm flag 之前取的 epoch)。
    # POST /lua 是同步执行 — curl 返回时导出 (含写 flag) 已完成, flag mtime
    # 早于本脚本启动时刻, 旧 t0=启动时刻 护栏会空转到超时 (9-12 GER 实测)。
    t0 = float(sys.argv[2]) if len(sys.argv) > 2 else time.time()
    if os.path.exists(FLAG):
        print('[wait_export] WARN: flag exists before wait (stale export?)')
        print('[wait_export] correct order: rm flag -> touch objects.lua -> run this')
    while time.time() - t0 < timeout:
        try:
            mt = os.path.getmtime(FLAG)
        except OSError:
            mt = 0
        if mt >= t0:
            # 再等一拍: 确保写入完成 (大小稳定)
            time.sleep(0.5)
            try:
                if os.path.getmtime(FLAG) == mt:
                    print('[wait_export] new export done (%.1fs)' % (time.time() - t0))
                    return 0
            except OSError:
                pass
        time.sleep(1)
    print('[wait_export] TIMEOUT %ds - check reloader log for lua errors' % timeout)
    return 2


if __name__ == '__main__':
    sys.exit(main())
