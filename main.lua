local ds_engine = require("deepspeech/main")

function love.load()
	local mic_buffer, noise_gate, gate_timing

	--mic_buffer  = 160000
	noise_gate  = .05
	gate_timing = 1

	speech = ds_engine(mic_buffer, noise_gate, gate_timing)

	speech:startMic()
end

function love.update(dt)
	speech:update(dt, print)
end

function love.threaderror(thread)
	error(thread:getError())
end