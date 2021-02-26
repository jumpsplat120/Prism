io.stdout:setvbuf("no")

function love.conf(t)
	t.resizeable = true
	t.console = false
end