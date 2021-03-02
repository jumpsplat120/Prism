local path, shared_path, thread, Object, Deepspeech

path        = string.match(..., ".*/") or ""
shared_path = path:gsub("deepspeech/", "") .. "shared/"
thread      = love.thread.newThread(path .. "thread.lua")
Object      = require(shared_path .. "classic")

Deepspeech = Object:extend()

function Deepspeech:new()
	self.thread      = {}
	self.text_buffer = {}
	self.data_buffer = {}

	self.thread.get  = love.thread.getChannel("dshandler-out")
	self.thread.give = love.thread.getChannel("dshandler-in")

	self.sample_rate = self.thread.get:demand()
	self.buffer_size = self.sample_rate * 10
	self.noise_gate  = .5
	self.gate_timing = .75
	self.gate_is_on  = true
	self.mic_is_on   = false
	self.waiting     = false
	self.gate_timer  = 0
end

function Deepspeech:load(mic_buffer, noise_gate, gate_timing)
	self.buffer_size = self.buffer_size and self.sample_rate * 10
	self.noise_gate  = self.noise_gate  and .05
	self.gate_timing = self.gate_timing and 1.5

	--Boost curses because I've got a dirty mouth :L
	self:boost("priss",   10)
	self:boost("press",  -10)
	self:boost("prissy",  10)
	self:boost("percy",  -10)
	self:boost("prism",   10)
	self:boost("prison", -20)
	self:boost("fuck",    10)
	self:boost("fucking", 10)
	self:boost("fucker",  10)
	self:boost("bitch",   10)
	self:boost("bitchy",  10)
	self:boost("ass",      5)

	self:startMic()
end

function Deepspeech:addMic(value)
	assert(value:typeOf("RecordingDevice"), "Expected RecordingDevice for addMic!")
	self.microphone = value
end

function Deepspeech:startMic()
	if not self.microphone then
		local mic = love.audio.getRecordingDevices()[1]
		print("Loading mic " .. mic:getName() .. "...")
		self:addMic(mic)
	end
	self.microphone:start(self.buffer_size, self.sample_rate)
	self.mic_is_on = true
end

function Deepspeech:stopMic()
	if not self.microphone then
		local mic = love.audio.getRecordingDevices()[1]
		print("Loading mic " .. mic:getName() .. "...")
		self:addMic(mic)
	end

	if self.mic_is_on then
		local data = self.microphone:stop()
		if data then self.thread.give:push(data) end
		self.mic_is_on = false
	end
end

function Deepspeech:getText()
	local text = false
	if #self.text_buffer > 0 then
		text = self.text_buffer[1]
		table.remove(self.text_buffer, 1)
	end
	return text
end

function Deepspeech:boost(word, amount)
	self.thread.give:push("boost")
	self.thread.give:push(word)
	self.thread.give:push(amount)
end

function Deepspeech:unboost(word)
	self.thread.give:push("unboost")
	self.thread.give:push(word)
end

function Deepspeech:update(dt, callback, cb_self)
	if self.mic_is_on then
		local data, avg = self.microphone:getData(), 0
		if data then
			for i = 0, data:getSampleCount() - 1, 1 do
				local sample = data:getSample(i)
				avg = avg + (sample < 0 and sample * -1 or sample)
			end

			if self.noise_gate < avg / data:getSampleCount() then

				self.gate_is_on = false
				self.gate_timer = 0
				for i, data in ipairs(self.data_buffer) do
					--don't push last one cause we'll push it down below
					if i ~= #self.data_buffer then self.thread.give:push(data) end
				end
				self.data_buffer = {}
			end
			
			if self.gate_is_on then
				--Hopefully sending the previous 10 data buffers will help with catching the first word.
				self.data_buffer[#self.data_buffer + 1] = data
				if #self.data_buffer > 10 then table.remove(self.data_buffer, 1) end
			else
				self.thread.give:push(data)
				if self.gate_timer < self.gate_timing then
					self.gate_timer = self.gate_timer + dt
				else
					self.thread.give:push("get_text")
					self.gate_timer = 0
					self.gate_is_on = true
				end
			end
		end
	end
	
	local text = self.thread.get:pop()
	
	if text then
		if callback then
			if cb_self then callback(cb_self, text) else callback(text) end
		else
			self.text_buffer[#self.text_buffer + 1] = text
		end
	end
end

thread:start()

return Deepspeech()