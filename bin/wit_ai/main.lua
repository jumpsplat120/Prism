Object      = require("bin/shared/classic")
socket      = require("bin/luajit_request")

WitInterface = Object:extend()

function WitInterface:new()
	self.data = {}
end

function WitInterface:update(dt)

end

function WitInterface:send(message)
	local response = socket.send("https://api.wit.ai/message?v=20210227&q=hey%20is%20this%20thing%20on", { method = "GET", headers = { Authorization = "Bearer MYD4FQRSSYUB3JFS6LPESSKO4CVHZJUC" }})

	print(response.code)
	print(response.body)
	--file = io.popen([[curl -H "Authorization: Bearer MYD4FQRSSYUB3JFS6LPESSKO4CVHZJUC" "https://api.wit.ai/message?v=20210227&q=]] .. message:gsub("'", "%27"):gsub(" ", "%20") .. '"')
	--print(file:read("*a"))
end

function WitInterface:getIntent(text, callback)

end

return WitInterface()