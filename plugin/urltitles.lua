#! /usr/bin/env lua
--
-- urltitles.lua
-- Copyright (C) 2015 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local html_title = require("util.html").extract_title
local urlfetch = require("util.urlfetch")


local function identity(x) return x end

local function iterate_patterns(...)
	local pattern_tables = { ... }
	return coroutine.wrap(function ()
		for _, patterns in ipairs(pattern_tables) do
			if patterns ~= nil then
				for k, v in pairs(patterns) do
					if type(k) == "number" then
						coroutine.yield(v, identity)
					else
						coroutine.yield(k, v)
					end
				end
			end
		end
	end)
end

local function match_url(url, include, exclude)
	local has_include_patterns = false
	for pattern, postprocess in include do
		has_include_patterns = true
		if url:match(pattern) then
			return true, postprocess
		end
	end

	for pattern, _ in exclude do
		if url:match(pattern) then
			return false, nil
		end
	end

	return not has_include_patterns, identity
end


local function handle_urltitles(bot, event)
	local url = event.body and event.body:match("https?://%S+")
	if url then
		local include_patterns, exclude_patterns
		local room_config = event:room_config("urltitles")

		if room_config then
			include_patterns = iterate_patterns(room_config.include,
			                                    bot.config.plugin.urltitles.include)
			exclude_patterns = iterate_patterns(room_config.exclude,
			                                    bot.config.plugin.urltitles.exclude)
		else
			include_patterns = iterate_patterns(bot.config.plugin.urltitles.include)
			exclude_patterns = iterate_patterns(bot.config.plugin.urltitles.exclude)
		end

		local should_expand, postprocess = match_url(url, include_patterns, exclude_patterns)
		if not should_expand then
			bot:debug("urltitles: URL skipped: " .. url)
			return
		end

		urlfetch(url, nil, function (data, code)
			if code ~= 200 then
				bot:warn("urltitles: HTTP code=" .. code .. " for " .. url)
				return
			end

			local title = html_title(data)
			if title then
				title = postprocess(title)
				if type(title) == "string" and #title > 0 then
					event:post(title)
				end
			end
		end)
	end
end

return function (bot)
	local function handle_message(event) handle_urltitles(bot, event) end
	bot:hook("message", handle_message)
	bot:hook("groupchat/joined", function (room)
		room:hook("message", handle_message)
	end)
end
