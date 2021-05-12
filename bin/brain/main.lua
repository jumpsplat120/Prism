local Object

Object = require("bin/shared/classic")

Brain = Object:extend()

function Brain:new()
	self.parseToRealDataType = function(val)
		local num = tonumber(val)

		return val == "true"  and true  or
			   val == "false" and false or
			   num and num or val
	end

	self.internalChain = function(tbl)
		print(inspect(tbl))
		if tbl.intents[1] then
			local entities, traits = {}, {}
			for key, entry in pairs(tbl.entities) do entities[key:match("([^:]+):[^:]+")] = self.parseToRealDataType(entry[1].value) end
			for key, entry in pairs(tbl.traits) do traits[key:find("wit%$") and key:match("wit%$(.+)") or key] = self.parseToRealDataType(entry[1].value) end
			if self[tbl.intents[1].name] then self[tbl.intents[1].name](self, tbl.text, traits, entities) else self.tts:speak("No intent was found.", self.addToBuffer) end
		else
			self.tts:speak("No intent was found.", self.addToBuffer)
		end
	end

	self.addToBuffer = function(sound_data)
		self.sound_data_buffer[#self.sound_data_buffer + 1] = sound_data
	end

	self.interactable_list = { 
	lights = function(traits, entities)
		local text
		if entities.on_off_toggle == true then
			--handle patterns
			text = "Absolutely! Turning on a random pattern."
		elseif entities.on_off_toggle == false then
			text = "Turning your lights off!"
		else
			--need to keep track of light state internally
			text = "No worries, I'll grab those lights for you."
		end
		return self.tts:variant(math.random() * 10, text)
	end, 
	light = function(traits, entities)
		--When I have any other lights, I may want to handle this differently
		return self.interactable_list.lights(traits, entities)
	end,
	leds = function(traits, entities)
		--When I have any other lights, I might want to handle this differently
		return self.interactable_list.lights(traits, entities)
	end
	}

	self.sound_data_buffer = {}
	self.currently_queued  = nil
end

function Brain:load(wit, tts, speech)
	self.wit    = wit
	self.tts    = tts
	self.speech = speech

	self.tts:set_voice("Heather")
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
end

function Brain:think(text)
	print("I heard: " .. text)
	if text:len() <= 280 then
		if text:find("[^%w]*priss[^%w]*") or text:find("[^%w]*prissy[^%w]*") or text:find("[^%w]*prism[^%w]*") then
			print("That had my name! Inferring...")
			self.wit:infer(text, self.internalChain)
		end
	end
end

function Brain:conversation(text, traits, entities)
	self.tts:speak("I heard a conversation.", self.addToBuffer)
end

function Brain:interact(text, traits, entities)
	local func, response
	func     = self.interactable_list[entities.interactable]
	response = entities.interactable and (func and func(traits, entities) or "I don't know how to interact with " .. tostring(entities.interactable)) or "What was it you wanted me to do?"
	self.tts:speak(response, self.addToBuffer)
end

function Brain:question(text, traits, entities)
	self.tts:speak("I heard a question.", self.addToBuffer)
end

function Brain:search(text, traits, entities)
	self.tts:speak("I heard a search.", self.addToBuffer)
end

function Brain:unknown(text, traits, entities)
	self.tts:speak("I did not know what that was.", self.addToBuffer)
end

return Brain()