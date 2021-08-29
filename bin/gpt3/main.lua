Object  = require("bin/shared/classic")
request = require("bin/luajit_request")
json    = require("bin/GPT3/json")

GPT3 = Object:extend()

function GPT3:new()
	self.data = {}
	self.data.response   = {}
	self.data.auth_token = love.filesystem.read("bin/GPT3/AUTH_TOKEN")
	self.data.callback   = function() end
end

function GPT3:update(dt)
	if self.data.response.body then
		print("Recieved gpt response!")
		self.data.callback(json.decode(self.data.response.body))
		self.data.response = {}
		self.data.callback = function() end
	end
end

function GPT3:infer(message, temp, tokens, tp, fp, pp, callback, ...)
	print("inferring", message)
	local args, stop_str = {...}, "["
	for i, arg in ipairs(args) do stop_str = stop_str .. '"' .. arg .. '"' .. (i == #args and "" or ",") end
	stop_str = stop_str .. "]"
	self.data.callback = callback
	self.data.response = request.send("https://api.openai.com/v1/engines/davinci/completions", 
	{ method = "POST", headers = { ["Content-Type"] = "application/json", Authorization = "Bearer " .. self.data.auth_token },
	  data = '{ "prompt": '.. message .. '\n,"temperature": ' .. temp .. ',"max_tokens": ' .. tokens .. ',"top_p": ' .. tp .. ',"frequency_penalty": ' .. fp .. ',"presence_penalty": ' .. pp .. ',"stop": ' .. stop_str .. '}'})
end

return GPT3()