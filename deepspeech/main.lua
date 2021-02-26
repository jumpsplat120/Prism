local path, thread, Object, Deepspeech

path   = string.match(..., ".*/") or ""
thread = love.thread.newThread(path .. "thread.lua")
Object = require(path .. "classic")

Deepspeech = Object:extend()

function Deepspeech:new(mic_buffer, noise_gate, gate_timing)
	self.thread      = {}
	self.text_buffer = {}
	self.data_buffer = {}

	self.thread.get   = love.thread.getChannel("dshandler-out")
	self.thread.give  = love.thread.getChannel("dshandler-in")

	self.sample_rate  = self.thread.get:demand()
	self.buffer_size  = mic_buffer  or self.sample_rate * 10
	self.noise_gate   = noise_gate  or .5
	self.gate_timing  = gate_timing or .75
	self.gate_is_on   = true
	self.mic_is_on    = false
	self.waiting      = false
	self.gate_timer   = 0
end

function Deepspeech:addMic(value)
	assert(value:typeOf("RecordingDevice"), "Expected RecordingDevice for addMic!")
	self.microphone = value
end

function Deepspeech:startMic()
	if not self.microphone then
		local mic = love.audio.getRecordingDevices()[1]
		print("Adding mic:", mic:getName())
		self:addMic(love.audio.getRecordingDevices()[1])
	end
	self.microphone:start(self.buffer_size, self.sample_rate)
	self.mic_is_on = true
end

function Deepspeech:stopMic()
	if not self.microphone then
		self:addMic(love.audio.getRecordingDevices()[1])
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

function Deepspeech:update(dt, callback)
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
		if callback then callback(text) else self.text_buffer[#self.text_buffer + 1] = text end
	end
end

thread:start()

return Deepspeech