local path, Object, Handler

path    = love.filesystem.getWorkingDirectory() .. "/deepspeech/"
Object  = require(path .. "classic")
Handler = Object:extend()

require("love.sound")

function Handler:new()
	local success

	self.speech = require(path .. "lua-deepspeech")
	self.model  = {}
	self.thread = {}
	self.text   = ""
	self.data   = nil

	self.thread.get  = love.thread.getChannel("dshandler-in")
	self.thread.give = love.thread.getChannel("dshandler-out")

	success, self.model.sample_rate = self.speech.init( {model = path .. "ds-0.9.3.pbmm"} )

	--If success == false, sample_rate is an error
	if not success then error("Unable to start deepSpeech engine!", self.model.sample_rate) end

	self:startStream()

	self:send(self.model.sample_rate)
end

function Handler:startStream()
	self.stream = self.speech.newStream()
end

function Handler:feed(sound_data)
	self.stream:feed(sound_data:getPointer(), sound_data:getSampleCount())
end

function Handler:decode()
	self.stream:decode()
end

function Handler:getText()
	self.text = self.stream:finish()
end

function Handler:reset()
	self.stream:clear()
	self.text = nil
end

function Handler:update()
	self:get()
	if self.data == "get_text" then
		self:getText()
		self:send(self.text)
		self:reset()
	elseif self.data then
		self:feed(self.data)
		self:decode()
	end
end

function Handler:send(value)
	self.thread.give:push(value)
end

function Handler:get()
	local value = self.thread.get:pop()
	self.data = value and value or nil
end

handler = Handler()

while true do
	handler:update()
end