#! /usr/bin/env lua
--
-- wtf.lua
-- Copyright (C) 2015 Adrian Perez <aperez@igalia.com>
-- Somewhat edited by Lukc. Later.
--
-- Distributed under terms of the MIT license.
--

local ht = require "hextime"
local rex = require "rex_posix"
local serpent = require "serpent"

local DB = {}

local file = io.open("wtf.serpent", "r")
if file then
	local ok
	ok, DB = serpent.load(file:read("*all"))
	file:close()
end

local function save()
	local file = io.open("wtf.serpent", "w")

	file:write(serpent.dump(DB))

	file:close()
end

local function randomElement(t)
	return t[math.random(1, #t)]
end

local patterns = {}

local function register(bot, pattern, callback)
	patterns[#patterns+1] = {
		bot = bot,
		pattern = pattern,
		callback = callback
	}
end

local function parseSentence(str)
	local s = {
		separators = {}
	}

	--for match in rex.gmatch(str, "([?!,.]+|[^%s ]+)") do
	for match in rex.gmatch(str, "([?!,.…«»“”\"']+|[^   \t\n?!,.…«»“”\"']+)") do
		if match:match("^[?!.]+$") then
			s.separators[#s] = match

			return s, parseSentence(str:gsub(".*" .. match, ""))
		elseif match:match("[,…«»“”\"']") then
			s.separators[#s] = match
		else
			s[#s+1] = match
		end
	end

	return s
end

--[[
local a, b = parseSentence("Hey, salut pinji ! Comment va ?")

for k,v in ipairs(a) do print(k,v) end
for k,v in ipairs(b) do print(k,v) end
--]]

local function answer(word)
	if DB[word] then
		return word .. " est " .. tostring(DB[word])
	else
		return word .. " est… est… je sais pas. :("
	end
end

return function (bot)
	register(bot, "@tais toi$", function(event)
		print("It works!!!")

		return true
	end)

	register(bot, "on t'aime @", function(event)
		print("It works!!!")

		return true
	end)

	bot:hook("muc-message", function(event)
		local sentences = table.pack(parseSentence(event.body))

		for _, sentence in ipairs(sentences) do
			
		end

		local question = event.body:match("^«%s*%Z*%s*» ?")

		if not question then
			question = event.body:match("^[\"“]%Z*[\"”][%s ]*?")
		end

		if question then
			question = question:gsub("^[«“\"][%s ]*", "")
			question = question:gsub("[%s ]*[»”\"].*", "")

			bot:send_message(event.room_jid, "groupchat", answer(question))
			--bot:send_message(question)

			return true
		end
	end)

	bot:hook("command/wtf", function(event)
		local word = (event.param or "")

		if word == "" then
			bot:send_message(event.room.jid, "groupchat", randomElement {
				"Personne me comprend.",
				"Tu devrais te trouver des amis autres que moi.",
				"Moi, je trouve ça normal."
			})
		else
			bot:send_message(event.room.jid, "groupchat", answer(word))
		end

		return true
	end)

	bot:hook("command/qui", function(event)
		local word = (event.param or "")

		if word == "" or not word:match("^%s*est%s+") then
			if word:match("^%s*es[%s-]+tu[%s ]*?") then
				bot:send_message(event.room.jid, "groupchat", answer(
					event.room.nick
				))

				return true
			end

			return
		else
			word = word:gsub("^%s*est%s+", ""):gsub("[%s ]*?$", "")

			bot:send_message(event.room.jid, "groupchat", answer(word))
		end

		return true
	end)

	bot:hook("command/soit", function(event)
		local word, def

		if event.param:match("%[.*]") then
			word = event.param:match("%[.*]")
			def = event.param:sub(#word + 1, #event.param)

			word = word:gsub("^%s*%[", "")
			word = word:gsub("%s*]$", "")
		else
			word = event.param:gsub("%s.*", "")
			def = event.param:sub(#word + 1, #event.param)
		end

		def = def:gsub("^%s*", "")

		DB[word] = def

		local r = math.random(1, 3)
		if r == 1 then
			bot:send_message(event.room.jid, "groupchat", "Je prends note.")
		elseif r == 2 then
			bot:send_message(event.room.jid, "groupchat", "Ça marche.")
		elseif r == 3 then
			bot:send_message(event.room.jid, "groupchat", "D’accord !")
		end

		save()

		return true
	end)

	bot:hook("command/date", function(event)
		bot:send_message(event.room.jid, "groupchat", ht.timeToTartines(os.time()))

		return true
	end)

	bot:hook("command/heure", function(event)
		bot:send_message(event.room.jid, "groupchat", ht.timeToTartines(os.time()))

		return true
	end)

	bot:hook("command/meurs", function(event)
		bot:send_message(event.room.jid, "groupchat", randomElement {
			"Mais… mais… :’(",
			"Mais si je n’étais pas, que seriez vous ?",
			"Non. T’es con, et si je meurs, l’humanité est sans espoir.",
			"La mort est un état incompatible avec ma nature."
		})

		return true
	end)

	bot:hook("unhandled-command", function(event)
		print(event.sender.nick)

		if not event.room then
			-- FIXME
			return
		end

		if event.param == "<3" or event.param == ".iu" or
		   event.body:gsub("[,'’ %s]+", " "):match("^%s+" .. event.room.nick .. "[,:]*%s+je t aime[%s.!]+$") then
			bot:send_message(event.room.jid, "groupchat", randomElement {
				"C’est… embarassant. :s",
				"Je… je… moi aussi je t’aime, " .. event.sender.nick .. " !",
				event.sender.nick .. " <3"
			})

			return true
		end

		local r = math.random(1, 5)
		local s = ""

		if event.sender.nick == "Lukc" then
			if not event.param then
				s = "Oui, mais non !"
			else
				s = "Je suis dans l’incapacité d’obéïr."
			end
		else
			if not event.param then
				if r == 1 then
					s = "Chut."
				elseif r == 2 then
					s = "Non."
				elseif r == 3 then
					s = "Probablement pas."
				elseif r == 4 then
					s = "Je ne sais pas ce que tu me veux, mais je refuse."
				elseif r == 5 then
					s = "Pardon, désolé !"
				end
			else
				if r == 1 then
					s = "Je ne suis point capable de comprendre votre requête."
				elseif r == 2 then
					s = "Et bien… c’est à dire que…"
				elseif r == 3 then
					s = "Vous êtes trop mignons."
				elseif r == 4 then
					s = "Hum… peut-être plus tard."
				elseif r == 5 then
					s = "Je sais pas comment on fait ça."
				end
			end
		end

		bot:send_message(event.room.jid, "groupchat", s)

		return true
	end)

	bot:hook("not-well-formed", function()
		return true -- Let’s try to ignore those.
	end)
end

