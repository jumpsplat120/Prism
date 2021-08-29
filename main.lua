local speech, tts, wit, brain

love.window.close()

inspect = require("bin/shared/inspect")
speech  = require("bin/deepspeech/main")
tts     = require("bin/tts/main")
gpt     = require("bin/gpt3/main")
brain   = require("bin/brain/main")

function love.load()
	speech:load(nil, .1, .75)
	tts:load()
	brain:load(gpt, tts, speech)
end

function love.update(dt)
	speech:update(dt, brain.think, brain)
	gpt:update(dt)
	brain:update(dt)
end

function love.threaderror(thread)
	error(thread:getError())
end

function love.quit()
	tts:quit()
end