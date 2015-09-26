#! /usr/bin/env lua
--
-- muc.lua
-- Copyright (C) 2015 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local jid = require("util.jid")
local stanza = require("util.stanza")
local xmlns_muc = "http://jabber.org/protocol/muc"

return function (bot)
	bot.stream:add_plugin("groupchat")
	bot.rooms = bot.stream.rooms

	-- Forward groupchat/* events to the bot
	local fwevents = {
		"groupchat/joining",
		"groupchat/joined",
		"groupchat/leaving",
		"groupchat/left",
	}
	for i = 1, #fwevents do
		bot.stream:hook(fwevents[i], function (room, ...)
			room.bot = bot
			bot:event(fwevents[i], room, ...)
		end)
	end

	function bot:join_room(room_jid, nick)
		local room = bot.stream:join_room(room_jid, nick)
		room.bot = bot
		room:hook("message", function (event)
			local s = event.stanza
			local replied = false
			local r = stanza.reply(s)
			if s.attr.type == "groupchat" then
				r.attr.type = s.attr.type
				r.attr.to = jid.bare(s.attr.to)
			end

			if event.nick == room.nick then
				return true
			end
			function event:reply(reply)
				if not reply then reply = "Nothing to say" end
				if replied then return false end
				replied = true
				if reply:sub(1, 4) ~= "/me " and event.sender and r.attr.type == "groupchat" then
					reply = (event.reply_to or event.sender.nick) .. ": " .. reply
				end
				room:send(r:tag("body"):text(reply))
			end
		end, 500)
		return room
	end

	bot.stream:hook("pre-groupchat/joining", function (presence)
		local muc_x = presence:get_child("x", xmlns_muc)
		if muc_x then
			muc_x:tag("history", { maxstanzas = 0 })
		end
	end)
end