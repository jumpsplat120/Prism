local ds_engine, tts

--ds_engine = require("bin/deepspeech/main")
tts       = require("bin/tts/main")
wit       = require("bin/wit_ai/main")

function love.load()
	local mic_buffer, noise_gate, gate_timing

	--mic_buffer  = 160000
	noise_gate  = .05
	gate_timing = 2
	--[[
	speech = ds_engine(mic_buffer, noise_gate, gate_timing)

	speech:boost("priss", 20)
	speech:boost("prissy", 20)
	speech:boost("fuck", 10)
	speech:boost("fucking", 10)
	speech:boost("fucker", 10)
	speech:boost("bitch", 10)
	speech:boost("bitchy", 10)
	speech:boost("ass", 10)
	speech:startMic()
	tts:load()
	--]]
	print(wit:send("get", "api.wit.ai", "message?v=20210227&q=hey%20is%20this%20thing%20on", { Authorization = "Bearer MYD4FQRSSYUB3JFS6LPESSKO4CVHZJUC" }))
end

function love.update(dt)
	--speech:update(dt, parrot)
end

function love.threaderror(thread)
	error(thread:getError())
end

function parrot(text)
	print(text)
	if text:find("[^%w]priss[^%w]") or text:find("[^%w]prissy[^%w]") or text:find("[^%w]prism[^%w]") then
		wit:getIntent(text)
	end
	if text:match("what") and text:match("name") then text = "My name is personally responding, intelligent search matrix, or prism for short." end
	--tts:speak(text, love.audio.play)
end

function love.quit()
	--tts:quit()
end
