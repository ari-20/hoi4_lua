# Third-party notices

This project vendors or submodules the following third-party components:

| component | version | location | license |
|---|---|---|---|
| Lua | 5.4.7 | `third-party/lua54/lua-5.4.7/` | MIT (© 1994-2024 Lua.org, PUC-Rio) — full text in `src/lua.h` tail and `doc/readme.html` of the vendored copy |
| cpp-httplib | 0.56.0 | `third-party/httplib/httplib.h` | MIT — full text in the header |
| Mbed TLS | 3.6.4 | `third-party/mbedtls/` (git submodule) | Apache-2.0 OR GPL-2.0-or-later (this project takes it under Apache-2.0) — `LICENSE` in the submodule |

The built `hoi4_bridge.dll` statically links all three. Distributing the
DLL requires retaining the license/notice texts of these components.
