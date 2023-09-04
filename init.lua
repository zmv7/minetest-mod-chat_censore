local rus = {
	["А"]="а",
	["Б"]="б",
	["В"]="в",
	["Г"]="г",
	["Д"]="д",
	["Е"]="е",
	["Ё"]="ё",
	["Ж"]="ж",
	["З"]="з",
	["И"]="и",
	["Й"]="й",
	["К"]="к",
	["Л"]="л",
	["М"]="м",
	["Н"]="н",
	["О"]="о",
	["П"]="п",
	["Р"]="р",
	["С"]="с",
	["Т"]="т",
	["У"]="у",
	["Ф"]="ф",
	["Х"]="х",
	["Ц"]="ц",
	["Ч"]="ч",
	["Ш"]="ш",
	["Щ"]="щ",
	["Ь"]="ь",
	["Ы"]="ы",
	["Ъ"]="ъ",
	["Э"]="э",
	["Ю"]="ю",
	["Я"]="я"
}

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

	local lowmsg = message:lower()
	local toruslower = message:gsub("[%w%s]","")
		toruslower:gsub("..",function(c)
		if rus[c] then
			lowmsg = lowmsg:gsub(c,rus[c])
		end
	end)
	local cases = 0
	for _,word in ipairs(blacklist) do
		local count
		local trickyword = ""
		word:gsub(".",function(c)
			trickyword = trickyword..c.."%W?"
		end)
		trickyword = trickyword:gsub("%%W%?$","")
		lowmsg, count = lowmsg:gsub(trickyword,("*"):rep(#(word:gsub("[\128-\191]",""))))
		if type(count) == "number" then
			cases = cases + count
		end
	end
	if cases <= 0 then
		return
	end
	message = lowmsg

	if minetest.get_modpath("nick_prefix") then
		local prefix,color = nick_prefix.get(name)
		if prefix and color then
			minetest.chat_send_all(minetest.format_chat_message(minetest.colorize(color,prefix).." "..name,message))
		else
			minetest.chat_send_all(minetest.format_chat_message(name,message))
		end
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
