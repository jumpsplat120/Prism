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
		if tbl.intents[1] then
			local entities, traits = {}, {}
			for key, entry in pairs(tbl.entities) do entities[key:match("([^:]+):[^:]+")] = self.parseToRealDataType(entry[1].value) end
			for key, entry in pairs(tbl.traits) do traits[key:find("wit%$") and key:match("wit%$(.+)") or key] = self.parseToRealDataType(entry[1].value) end
			if self[tbl.intents[1].name] then self[tbl.intents[1].name](self, tbl.text, traits, entities) else self.tts:speak("No intent was found.", self.addToBuffer) end
		end
	end

	self.addToBuffer = function(sound_data)
		self.sound_data_buffer[#self.sound_data_buffer + 1] = sound_data
	end

	self.interactable_list = { 
	lights = function()
		return "Empty function for lights."
	end, 
	light = function()
		return "Empty function for light."
	end,
	leds = function()
		return "Empty function for L E Dees."
	end
	}

	self.sound_data_buffer = {}
	self.currently_queued  = nil
end

function Brain:load(wit, tts, speech)
	self.wit    = wit
	self.tts    = tts
	self.speech = speech
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
end

function Brain:interact(text, traits, entities)
	local func, response
	func     = self.interactable_list[entities.interactable]
	response = entities.interactable and (func and func() or "I don't know how to interact with " .. tostring(entities.interactable)) or "What was it you wanted me to do?"
	self.tts:speak(response, self.addToBuffer)
end

function Brain:question(text, traits, entities)
end

function Brain:search(text, traits, entities)
end

function Brain:unknown(text, traits, entities)
end

return Brain()