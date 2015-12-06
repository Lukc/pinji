#! /usr/bin/env lua
--
-- hello.lua
-- Copyright (C) 2015 Adrian Perez <aperez@igalia.com>
-- Somewhat edited by Lukc. Later.
--
-- Distributed under terms of the MIT license.
--

---
-- TODO:
--   - Usefulness?
--   - Markov chains improvements
--     - Identify start of sentences.
--     - Assign true probabilities to things instead of duplicating them
--       indefinitely.
--   - People will ask for help. How about we help them?
--     (« <nick> sert à quoi ? », « nick, help » ?)
---
-- Food for thought:
--   - <username> est <whatever> (?)
--   - <nick>, meurs.
--   - (On |J’)aime <foo>
--   - (On |Je) suis <foo>
--   - Je suis ton père. « Et bien je vous dirai que non. »

local serpent = require "serpent"

local DB = {}

local file = io.open("DB.sav", "r")
if file then
	local ok
	ok, DB = serpent.load(file:read("*all"))
	file:close()
end

local function generateSentence(word)
	local str = word[math.random(1, #word)]
	local word = DB[str]

	if word then
		local next = generateSentence(word)

		if next then
			return str .. " " .. next
		else
			return str
		end
	elseif str ~= false then
		return str
	end
end

local function save()
	local file = io.open("DB.sav", "w")

	file:write(serpent.dump(DB))

	file:close()
end

local smileysData = {
	{
		pattern = "xxD",
		output = function()
			return "x" .. (function()
				local s = ""
				for i = 1, math.random(2, 28) do
					s = s .. "x"
				end
				return s
			end) .. "D"
		end
	},
	{
		pattern = ":))",
		output = ":))))))"
	},
	{
		pattern = ":@@@",
		output = "Graaaaawrgh!"
	}
}

local function smileys(event)
	for i = 1, #smileysData do
		local data = smileysData[i]

		if event.body:match(data.pattern) then
			local output = data.output

			if type(output) == "string" then
				bot:send_message(output)
			else
				bot:send_message(output())
			end
		end
	end
end

return function (bot)
	bot:hook("muc-message", function(event)
		-- Markov, start
		local str = {}

		for f in event.body:gmatch("[^ 	]+") do
			str[#str+1] = f

			if f == "bite" and math.random(0,3) < 3 then
				bot:send_message("Voir règle N°2.")
			end
		end

		for i = 1, #str do
			local s = str[i]
			local next = str[i+1]

			if not DB[s] then
				DB[s] = {}
				DB[#DB+1] = DB[s]
			end

			if next then
				DB[s][#DB[s] + 1] = next
			else
				DB[s][#DB[s] + 1] = false
			end
		end
		-- Markov, end

		if math.random(1,15) == 1 then
			bot:send_message(generateSentence(DB[math.random(1, #DB)]))
		end

		--bot:send_message(event.room_jid, "groupchat", s)
		save()
	end)

	bot:hook("command/parle", function(bot)
		local str = generateSentence(DB[math.random(1, #DB)]) or ""

		print("[[" .. str .. "]]")

		return str
	end)
end

