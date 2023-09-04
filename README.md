# minetest-mod-chat_censore
Blacklist any words in the chat, they will be replaced with '***'
#### Installation of UTF-8 version
* Install [Luarocks](https://luarocks.org) to your server
* Install `luautf8` using `luarocks`. Ensure you're choose same Lua version as Minetest uses
  * If you installed it with `--local` flag, correct the path in [Line 2](https://github.com/zmv7/minetest-mod-chat_censore/blob/utf8/init.lua#L2) to match your username and lua version.
  * If you installed it system-wide (without `--local` flag), just comment [Line 2](https://github.com/zmv7/minetest-mod-chat_censore/blob/utf8/init.lua#L2).\
* Add `chat_censore` to `secure.trusted_mods` in `minetest.conf`.
