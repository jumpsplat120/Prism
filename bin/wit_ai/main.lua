Object  = require("bin/shared/classic")
request = require("bin/luajit_request")
json    = require("bin/wit_ai/json")

WitInterface = Object:extend()

function WitInterface:new()
	self.data = {}
	self.data.response   = {}
	self.data.auth_token = love.filesystem.read("bin/wit_ai/AUTH_TOKEN")
	self.data.callback   = function() end
end

function WitInterface:update(dt)
	if self.data.response.body then
		self.data.callback(json.decode(self.data.response.body))
		self.data.response = {}
		self.data.callback = function() end
	end
end

function WitInterface:infer(message, callback)
	self.data.callback = callback
	self.data.response = request.send("https://api.wit.ai/message?v=20210227&q=" .. message:gsub(" ", "%%20"):gsub("'", "%%27"), { method = "GET", headers = { Authorization = "Bearer " .. self.data.auth_token }})
end

return WitInterface()