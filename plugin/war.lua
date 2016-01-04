#! /usr/bin/env lua

return function (bot)
	bot:hook("muc-message", function(event)
		local str

		if event.body:gmatch("?") then
			local r = math.random(1, 3)

			if r ==  1 then
				str = "ok"
			elseif r == 2 then
				str = "d'accord"
			elseif r == 3 then
				str = "ouais"
			end
		elseif event.body:gmatch("!") then
			local r = math.random(1, 3)
			if r == 1 then
				str = "du calme"
			elseif r == 2 then
				str = "on se calme, gros"
			else
				str = "oh!"
			end
		else
			local r = math.random(1, 4)

			if r == 1 then
				str = "hein"
			elseif r == 2 then
				str = "et donc?"
			elseif r == 3 then
				str = "va te pendre?"
			else
				str = "lol, t'es con"
			end
		end

		if math.random(1,3) == 1 then
			bot:send_message(event.room_jid, "groupchat", str)
		end
	end)
end

