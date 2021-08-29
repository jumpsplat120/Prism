local Object

Object = require("bin/shared/classic")

Brain = Object:extend()

function Brain:new()
	self.wait = function (time, callback, callback_args)
		print("Waiting " .. time .. " seconds...")
		local run_at = os.time() + time
		self.timers[#self.timers + 1] = {run_at, callback, callback_args}
	end

	self.addToBuffer = function(sound_data)
		self.sound_data_buffer[#self.sound_data_buffer + 1] = sound_data
	end

	self.abilities = {
		tell_joke = function(tbl)
			print("Running joke module...")
			self.gpt:infer('"setup - What\'s the best thing about Switzerland?\\npunchline - I don\'t know, but the flag is a big plus.\\nsetup - I invented a new word!\\npunchline - Plagiarism!\\nsetup - Did you hear about the mathematician who\'s afraid of negative numbers?\\npunchline - He\'ll stop at nothing to avoid them.\\nsetup - Why do we tell actors to \\"break a leg?\\"\\npunchline - Because every play has a cast.\\nsetup - What do you call an alligator in a vest?\\npunchline - An investigator.\\nsetup -"', 0.8, 100, 1.0, 0.0, 0.0, function(tbl)
				print(inspect(tbl))
				--setup = tbl.choices[1].text:match("^(.+) punchline - ")
				--punchline = tbl.choices[1].text:match("punchline - (.+)")
				--print(setup, punchline)
				self.tts:speak(tbl.choices[1].text:gsub("\\n", " "):gsub("punchline - ", ""))
			end, "setup -")
		end,
		check_song = true,
		open_app = true,
		check_time = true,
		check_weather = true,
		external = true,
		create_alarm = true,
		check_alarm = true,
		create_timer = true,
		check_timer = true,
		check_presence = true,
		conversation = true
	}

	self.timers            = {}
	self.sound_data_buffer = {}
	self.currently_queued  = nil
end

function Brain:load(gpt, tts, speech)
	self.gpt    = gpt
	self.tts    = tts
	self.speech = speech

	self.tts:set_voice("Heather")
	self.tts:set_sample_rate(48)
end

function Brain:update(dt)
	if #self.sound_data_buffer > 0 then
		if self.currently_queued then
			if not self.currently_queued:isPlaying() then
				self.currently_queued = table.remove(self.sound_data_buffer, 1)
				self.currently_queued:play()
			end
		else
			self.currently_queued = table.remove(self.sound_data_buffer, 1)
			self.currently_queued:play()
		end
	end

	local new_timers = {}

	for _, obj in ipairs(self.timers) do
		if os.time() >= obj[1] then obj[2](obj[3]) else new_timers[#new_timers + 1] = obj end
	end

	self.timers = new_timers
end

function Brain:think(text)
	print("I heard: " .. text)
	if text:len() <= 280 then
		if text:find("[^%w]*priss[^%w]*") or text:find("[^%w]*prissy[^%w]*") or text:find("[^%w]*prism[^%w]*") or text:find("[^%w]*prison[^%w]*") then
			print("That had my name! Inferring...")
			self:infer(text)
		end
	end
end

function Brain:infer(text)
	self.gpt:infer('"sI would love if you told me a joke prism\\n\'tell-joke\'\\nsay something funny priss\\n\'tell-joke\'\\nhow are you doing prism\\n\'conversation\'\\nhey prism how are you doing\\n\'conversation\'\\nhey prism can you open spotify for me\\n\'open_app\' \'spotify\'\\nwhat song is playing right now priss\\n\'check_song\'\\nhey prissy what time is it\\n\'check_time\' \'current\'\\nhey prism what\'s the date\\n\'check_date\'\\nwhat time is it going to be in an hour priss\\n\'check_time\' \'+1h\'\\nwhats the weather like prissy\\n\'check_weather\' \'local\'\\nhow does it look outside priss\\n\'check_weather\' \'local\'\\nhey prison can you turn on the lights for me\\n\'external\' \'default_lights on\'\\nhey prison can you grab my light\\n\'external\' \'default_lights toggle\'\\nhey priss tell me a joke\\n\'tell_joke\'\\ncan you set an alarm priss for 10 minutes from now\\n\'create_alarm\' \'default 10m\'\\nhey prism make an alarm called meds for 8 oclock tonight\\n\'create_alarm\' \'meds 8pm\'\\nhey prison whats that alarm at 8 tonight called\\n\'check_alarm\' \'name 8pm\'\\nstart a timer for me prison\\n\'create_timer\' \'default\'\\nhey prism how long has that timer been running for\\n\'check_timer\' \'default\'\\nhow long has gaming timer been running for priss\\n\'check_timer\' \'gaming\'\\n' .. text .. '\\n"', 0.1, 100, 1.0, 0.0, 0.0, function(tbl)
		print(inspect(tbl))
		ability = tbl.choices[1].text:match("^'([^']+)'"):gsub("%-", "_")
		args = tbl.choices[1].text:match("'[^']+' '([^']+)'$")
		self.tts:speak("The ability I found was " .. (ability or "nil") .. ", and the args I found were " .. (args or "nothing"))
		if self.abilities[ability] then
			print("Found matching ability...")
			local tbl = {}
			if args then for arg in args:match("[^ ]") do tbl[tbl + 1] = arg end end
			self.wait(1, self.abilities[ability], tbl)
		end
	end, "~", "\\n")
end

return Brain()