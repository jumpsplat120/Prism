local Object

Object = require("bin/shared/classic")

Brain = Object:extend()

function Brain:new()
	self.internal_chain = function(tbl)
		print(inspect(tbl))
		if tbl.intents[1] then
			local entities, traits = {}, {}
			for key, entry in pairs(tbl.entities) do
				print(key, key:match("([^:]+):[^:]+"))
				local val = entry[1].value

				if val == "true" then
					val = true
				elseif val == "false" then
					val = false
				elseif tonumber(val) ~= nil then
					val = tonumber(val)
				end

				entities[key:match("([^:]+):[^:]+")] = entry[1].value
			end
			for key, entry in pairs(tbl.traits) do
				print(key, key:find("wit%$"), key:match("wit%$(.+)"))
				local val = entry[1].value
				
				if val == "true" then
					val = true
				elseif val == "false" then
					val = false
				elseif tonumber(val) ~= nil then
					val = tonumber(val)
				end

				traits[key:find("wit%$") and key:match("wit%$(.+)") or key] = val
			end
			print(inspect(entities), inspect(traits))
			local response = self[tbl.intents[1].name](self, tbl.text, traits, entities) or "No response has been programmed."
			self.tts:speak(response, love.audio.play)
		end
	end
end

function Brain:load(wit, tts, speech)
	self.wit    = wit
	self.tts    = tts
	self.speech = speech
end

function Brain:think(text)
	if text:find("[^%w]*priss[^%w]*") or text:find("[^%w]*prissy[^%w]*") or text:find("[^%w]*prism[^%w]*") then
		self.wit:infer(text, self.internal_chain)
	end
end

function Brain:conversation(text, traits, entities)
end

function Brain:interact(text, traits, entities)
end

function Brain:question(text, traits, entities)
end

function Brain:search(text, traits, entities)

end

function Brain:unknown(text, traits, entities)
end

return Brain()