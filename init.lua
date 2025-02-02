local ie = minetest.request_insecure_environment()
ie.package.cpath = ie.package.cpath..";/home/user/.luarocks/lib/lua/5.1/lua-utf8.so"
local utf8 = ie.require "lua-utf8"

local blacklist = {}
local storage = minetest.get_mod_storage()

if storage:get("blacklist") then
	blacklist = minetest.deserialize(storage:get("blacklist"))
end

local function save()
	storage:set_string("blacklist",minetest.serialize(blacklist))
end

table.insert(minetest.registered_on_chat_messages, 1, function(name, message)
	if message:sub(1,1) == "/" then
		return
	end
	local privs = minetest.get_player_privs(name)
	if privs["kick"] or not privs["shout"] then
		return
	end
	minetest.log("action","CHAT: "..minetest.format_chat_message(name,minetest.strip_colors(message)))

	local cases = 0
	for _,word in ipairs(blacklist) do
		local trickyword = ""
		utf8.gsub(word, ".",function(c)
			trickyword = trickyword..c.."%W?"
		end)
		trickyword = utf8.gsub(trickyword, "%%W%?$","")
		repeat
			local p1,p2 = utf8.find(utf8.lower(message),trickyword)
			if (p1 and p2) then
				local count
				local case = utf8.sub(message, p1,p2)
				message, count = utf8.gsub(message, case,("*"):rep(utf8.len(word)))
				if type(count) == "number" then
					cases = cases + count
				end
			end
		until not (p1 and p2)
	end

	if cases <= 0 then
		return
	end

	if minetest.get_modpath("nick_prefix") then
		local data = nick_prefix.get(name)
		local prefix = ""
		if data.pronouns then
			prefix = prefix .. "["..data.pronouns.."] "
		end
		if data.prefix and data.color then
			prefix = prefix .. core.colorize(data.color, "["..data.prefix.."] ")
		end
		core.chat_send_all(core.format_chat_message(prefix..name,message))
	else
		minetest.chat_send_all(minetest.format_chat_message(name,message))
	end
	if minetest.get_modpath("irc") then
		irc.say("<"..name.."> "..minetest.strip_colors(message))
	end
	return true
end)

minetest.register_chatcommand("blist",{
  description = "Manage chat blacklist",
  params = "(<add>|<rm> <word>) | <ls>",
  privs = {server=true},
  func = function(name, param)
	local mode, word = param:match("^(%S+) (.+)$")
	if mode == "add" and word then
		for _,wrd in ipairs(blacklist) do
			if wrd == word then
				return false, word.." already in blacklist"
			end
		end
		table.insert(blacklist, word)
		save()
		return true, word.." added to blacklist"
	end
	if mode == "rm" and word then
		for num,wrd in ipairs(blacklist) do
			if wrd == word then
				table.remove(blacklist,num)
				save()
				return true, word.." removed from blacklist"
			end
		end
		return false, word.." not in blacklist"
	end
	if param == "ls" then
		return true, "Blacklisted words: "..table.concat(blacklist, ", ")
	end
	if param == "purge" then
		blacklist = {}
		save()
		return true, "Blacklist purged"
	end
	return false, "Invalid params"
end})
