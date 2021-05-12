local speech, tts, wit, brain

love.window.close()

inspect = require("bin/shared/inspect")
speech  = require("bin/deepspeech/main")
tts     = require("bin/tts/main")
wit     = require("bin/wit_ai/main")
brain   = require("bin/brain/main")

function love.load()
	speech:load()
	tts:load()
	brain:load(wit, tts, speech)
end

function love.update(dt)
	speech:update(dt, brain.think, brain)
	wit:update(dt)
	brain:update(dt)
end

function love.threaderror(thread)
	error(thread:getError())
end

function love.quit()
	tts:quit()
end