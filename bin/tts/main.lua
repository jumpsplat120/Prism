local tts, ffi, reg, socket, Object, rand, tmpname, tag, sub_path, shared_path, alpha

sub_path    = string.match(..., ".*/") or ""
shared_path = sub_path:gsub("tts/", "") .. "shared/"

socket = require("socket")
ffi    = require("ffi")
reg    = require(sub_path .. "luareg/main")

alpha  = { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" }

Object = require(shared_path .. "classic")

TTS = Object:extend()

	--===|||LOCAL HELPER FUNCTIONS|||===--

function round(val)
	return math.floor(val + .5)
end

function rand(to) 
	return math.floor(math.random() * to  + .5) + 1
end

function tmpname(length)
	local str = ""
	
	for i = 1, length or 5, 1 do str = str .. alpha[rand(#alpha - 1)] end
	
	return str
end

function run(self, eng, ...)
	local args, arg_str = {...}, ""
	local t, message, result
	for i, arg in ipairs(args) do 
		arg_str = arg_str .. tostring(arg)
		if i ~= #args then arg_str = arg_str .. "|" end
	end

	result = ffi.string(self.data.engine[eng](arg_str))
	
	t, message = result:match("(.+)=(.+)")
	
	if t == "OUT" then
		if message == "nil" then 
			return nil
		elseif tonumber(message) ~= nil then
			return tonumber(message)
		elseif message:lower() == "true" or message:lower() == "false" then
			return message:lower() == "true"
		elseif message:match("|") then
			local tbl = {}
			for val in message:gmatch("([^|]+)|") do tbl[#tbl + 1] = val end
			return tbl
		else
			return message
		end
	elseif t == "ERR" then
		error(message)
	else
		error(result)
	end
end

function tag(tag_type, value, args, closed)
	local arg_str = ""
	
	args = args or {}
	
	for k, v in pairs(args) do arg_str = arg_str .. " " .. k .. "='" .. v .. "'" end
	if closed then
		return "<" .. tag_type .. arg_str .. "/>"
	else
		return "<" .. tag_type .. arg_str .. ">" .. value .. "</" .. tag_type .. ">"
	end
end

function clamp(input, min, max)
	return input > max and input or input < min and min or input
end

function typeis(value, types, name)
	local is_type = false
	for _, val in ipairs(types) do
		is_type = type(value) == val
		if is_type == false then break end
	end
	if is_type == false then error("Invalid type; type of " .. name .. " was " .. type(value) .. ", expected " .. concat(types)) else return is_type end
end

function concat(tbl, delimiter)
	local result = ""
	delimiter = delimiter or ", "
	for i, val in ipairs(tbl) do
		result = result .. tostring(val) .. (i ~= #tbl and delimiter or "")
	end
	return result
end

function contains(tbl, value)
	local valid = false
	for _, v in ipairs(tbl) do
		if value == v then 
			valid = v
			break
		end
	end
	return valid
end

	--===|||INIT VALUES|||===--

local level_tbl = { "default", "x-low", "low", "medium", "high", "x-high" }

math.randomseed(socket.gettime())

reg:load()

	--===|||TTS CLASS|||===--
	
function TTS:new()
	self.data = {
		--https://api.cerevoice.com/v2/#vocal-gesture-list
		spurts = {
			tut                      = { 1, 2 },
			cough                    = { 3, 4, 5 },
			clear_throat             = 6,
			breathe_in               = 7,
			sharp_breath_in          = 8,
			breathe_in_through_teeth = 9,
			happy_sigh               = 10,
			sad_sigh                 = 11,
			question_hmm             = 12,
			affirmative_hmm          = 13,
			thinking_hmm             = 14,
			umm                      = { 15, 16 },
			err                      = { 17, 18 },
			giggle                   = { 19, 20 },
			laugh                    = { 21, 22, 23, 24 },
			affirmative_ah           = 25,
			negative_ah              = 26,
			question_ya              = 27,
			affirmative_ya           = 28,
			negative_ya              = 29,
			sniff                    = { 30, 21 },
			argh                     = { 32, 33 },
			ugh                      = 34,
			ocht                     = 35,
			yay                      = 36,
			affirmative_oh           = 37,
			negative_oh              = 38,
			durr                     = 39,
			yawn                     = { 40, 41 },
			snore                    = { 42, 43 },
			zzz                      = 44,
			raspberry                = { 45, 46 },
			brr                      = 47,
			snort                    = 48,
			sarcastic_laugh          = 50,
			doh                      = 51,
			gasp                     = 52
		},
		func = {},
		cereproc = {},
		rate = 48000,
		bit_depth = 16,
		channel_mode = 2
	}
		
	self.data.spurts.um  = self.data.spurts.umm
	self.data.spurts.uhm = self.data.spurts.umm
end

		--===LOVE FUNCTIONS===--
	
function TTS:load()
	local source = love.filesystem.getSource()

	self.data.fused  = love.filesystem.isFused()
	self.data.folder = self.data.fused and (love.filesystem.getSourceBaseDirectory() .. "/") or (source .. "/" .. sub_path)
	self.data.engine = ffi.load(self.data.folder .. "TTS.dll")

	ffi.cdef([[ 
		//string voice_file|string lic_file|string ssml|string out_location(|string root_file|string cert_file|string key_file)
		char * cereproc(const char* arg_string);
		//bool get_voices|int sample|int bit_depth|int channel_mode|string voice|string ssml|string output
		char * ms(const char* arg_string);
	]])
	
	--Only 64 bit voices are available. There's a registry hack to work around that but its a hack.
	self.voice = self.voices[1]

	if self.data.fused then love.filesystem.mount(love.filesystem.getSourceBaseDirectory(), "") end
end

function TTS:quit()
	for i, file in ipairs(love.filesystem.getDirectoryItems((self.data.fused and "" or sub_path) .. "audio/")) do os.remove(self.data.folder .. "audio/" .. file) end
end

		--===GETTERS===--

function TTS:get_sample_rate() return self.data.rate / 1000 end
function TTS:get_voice() return self.data.voice end
function TTS:get_bit_depth() return self.data.bit_depth end
function TTS:get_channel_mode() return self.data.channel_mode == 1 and "mono" or "stereo" end
function TTS:get_voices() return run(self, "ms", true, 0, 0, 0, "", "", "") end

		--===SETTERS===--

function TTS:set_voices(val)
	error("Unable to set voices through application; Set voices through Windows system utilities.")
end
		
function TTS:set_sample_rate(val)
	typeis(val, {"number"}, "sample rate")
	assert(contains({ 8, 11, 12, 16, 22, 24, 32, 44.1, 48 }, val), "Invalid value! '" .. tostring(val) .. "' is not a valid sample rate.")
	self.data.rate = val * 1000
end

function TTS:set_bit_depth(val)
	typeis(val, {"number"}, "bit depth")
	assert(contains({8, 16}, val), "Invalid value! '" .. tostring(val) .. "' is not a valid bit depth.")
	self.data.bit_depth = val
end

function TTS:set_channel_mode(val)
	typeis(val, {"string"}, "channel mode")
	val = val:lower()
	assert(contains({"mono", "stereo"}, val), "Invalid value! '" .. tostring(val) .. "' is not a valid channel mode.")
	self.data.channel_mode = val == "mono" and 1 or 2
end

function TTS:set_voice(val)
	typeis(val, {"string"}, "voice")
	
	print("Setting voice '" .. val .. "'...")
	local set_voice
	
	for _, voice in ipairs(self.voices) do
		if voice == val or voice:match(val) then
			set_voice = voice
			print("Matched voice to '" .. voice .. "'!")
			break
		end
	end
	
	if set_voice then 
		if set_voice:match("CereVoice") then
			local voice_name, root, path, file, data, entry_name
			
			root       = "HKLM"
			voice_name = set_voice:match("(CereVoice [%w _]+) -")
			path       = "SOFTWARE\\Microsoft\\Speech\\Voices\\Tokens"
			
			--Get all voice keys from reg
			data = reg:getSubEntries(root, path)
			
			for _, entry in ipairs(data) do
				print(entry)
				if entry:match(voice_name) then 
					entry_name = entry
					self.data.cereproc.ver = tonumber(entry:match("(%d)%.%d%.%d$"))
					break
				end
			end
			
			if entry_name then
				self.data.cereproc.folder = reg:getValue(root, path .. "\\" .. entry_name .. "\\Attributes", "VoiceFile"):match("(.+\\)[^\\]+$")
				
				file = io.popen('dir "' .. self.data.cereproc.folder .. '" /b')
			
				for item in file:lines() do
					if item:find(".lic$") then
						self.data.cereproc.lic = item
					elseif item:find(".voice$") then
						self.data.cereproc.voice = item
					elseif item:find(".pem$") then
						self.data.cereproc.root = item
					elseif item:find(".crt$") then
						self.data.cereproc.cert = item
					elseif item:find(".key$") then
						self.data.cereproc.key = item
					end
				end
				
				file:close()
			else
				error("No registry entry for 'CereVoice " .. voice_name .. " x.x.x'")
			end
			
			self.data.engine_type = "cereproc"
		else
			self.data.cereproc = {}
			self.data.engine_type = "ms"
		end
		self.data.voice = set_voice
	else
		error("Invalid value! No voice was found that matched '" .. val .. "'.")
	end
end

		--===METHODS===--
			
			--=={GENERAL TAGS}==--

--returns a break tag for a specifc length of time in ms. If no length is passed, tag will proceed without it,
--and pause for as long as the engine deems appropriate
function TTS:pause(length)
	typeis(length, {"number"}, "length")
	assert(length > 0, "Invalid length! Length must be more than 0.")
	return tag("break", "", length and { time = tostring(length) .. "ms" } or nil, true)
end

--Returns an emphasis tag for a word, with an assosciated strength. If no strength is passed, defaults to a 
--strong emphasis, which is one up from default. Valid strengths are "strong", "moderate", "none" and "reduced".
--If strength is "none", it basically tells the engine not to put any emphasis there, even if it wanted to.
function TTS:emphasis(text, strength)
	typeis(text, {"string"}, "text")
	typeis(strength, {"string"}, "strength")
	
	strength = strength:lower()
	

	assert(contains({"strong", "moderate", "reduced", "none"}, strength), "Invalid parameter 'strength'! '" .. strength .. "' is not a a valid emphasis strength.")
	
	return tag("emphasis", text, { level = strength })
end

--Returns an audio tag, which will play a .wav audio file, and contains a text fallback in case the clip is 
--unable able to be recieved. VERY finicky tag, can cause the engine to just straight up throw an exception.
--My suggestion is to use love.audio for extra audio you want playing during the clip, instead of using this
--tag. Also, this tag only seems to work with the microsoft engine, contrary to what Cereproc's docs said.
--You've been warned. EDIT: Got an email that said it only works as a closed tag. Still doesn't work lol.
function TTS:audio(file, fallback)
	print("WARNING: This tag has a tendency to fail!")
	print(file, "-", fallback)
	typeis(file, {"string"}, "file")
	if self.data.engine_type == "ms" then typeis(fallback, {"string"}, "fallback") end
	
	return tag("audio", fallback, { src = file }, self.data.engine_type == "cereproc")
end

--Allows you to use the IPA or some other phoneme set. Cereproc also has their own phoneme set, and it will
--automatically convert the unicode into the cereproc set if that's the voice you're using.
--Array? Unicode str? Using utf8?
function TTS:phoneme()
	print("Not currently implemented.")
	return ""
end

--Not entirely clear what the say-as tag does. I'll get around to it when I understand what it's saying.
function TTS:sayAs()
	print("Not currently implemented.")
end

--Helper function that forms a pitch string. Used in conjunction with the prosody tag. t is type, and expects
--a string of 'hertz', 'percent', or 'level'. Value is the value of the pitch, either a string or number for 
--level, or number if type is hertz or percentage. If using a number, value will be rounded to closest interger 
--value. If type is level, either a string representing the level ("default", "x-low", "low", "medium", "high",
--"x-high") or a number between 1 - 6 to access one of the values in the array.
function TTS:pitch(t, value)
	local is_number, str_val, valid

	typeis(t, {"string"}, "t")
	typeis(value, {"number", "string"}, "value")

	is_number = type(value) == "number"
	str_val   = tostring(value):lower()

	t = t:lower()

	assert(contains({ "hertz", "percent", "percentage", "level" }, t), "Invalid parameter 't'; " .. tostring(t) .. " is not a valid type option.")

	if t ~= "level" then
		return (value > 0 and "+" or "") .. str_val .. (t == "hertz" and "Hz" or "%")
	else
		value = is_number and round(value) or str_val
		
		for i, val in ipairs(level_tbl) do if val == value or i == value then valid = val end end

		assert(valid, "Invalid parameter 'value'; " .. str_val .. " is not a valid level option.")
		
		return valid
	end
end

--Helper function to form a contour string. Used in conjuction with the prosody tag. Takes up to 5 tables, each
--one formatted in the following; { t, pos, value }, where t is a string 'hertz' or 'percent', value is a number
--value, and pos is a number value between 0 and  100. Both the value and position will be rounded to the nearest
--whole number, and the position will be clamped between 0 and 100.
function TTS:contour(...)
	local args, tbl, result = {...}, {}, ""
	
	for i, arg in ipairs(args) do
		typeis(arg, {"table"}, "arg")
		assert(#arg == 3, "Malformed table; table argument is expected to only have 3 elements, but contains " .. #arg)
		typeis(arg[1], {"string"}, "t")
		typeis(arg[2], {"number"}, "pos")
		typeis(arg[3], {"number"}, "value")
		
		arg[1] = arg[1]:lower()
		arg[2] = arg[2] > 100 and 100 or arg[2] < 0 and 0 or arg[2]

		assert(contains({"hertz", "percent", "percentage"}, arg[1]), "Invalid table parameter 't'; " .. arg[1] .. " is not a valid option.")

		tbl[i] = "(" .. tostring(arg[2]) .. "%," .. (arg[3] > 0 and "+" or "") .. tostring(arg[3]) .. (arg[1] == "hertz" and "Hz" or "%") .. ")"
	end

	return concat(tbl, " ")
end

--Helper function that forms a pitch string. Used in conjunction with the prosody tag. t is type, and expects
--a string of 'hertz', 'percent', or 'level'. Value is the value of the pitch, either a string or number for 
--level, or number if type is hertz or percentage. If using a number, value will be rounded to closest interger 
--value. If type is level, either a string representing the level ("default", "x-low", "low", "medium", "high",
--"x-high") or a number between 1 - 6 to access one of the values in the array.
function TTS:range(t, value)
	return self:pitch(t, value)
end

--Helper function that forms a rate string. Used in conjunction with the prosody tag. Value is either a string
--containing one of the accepted string rates ("default", "x-low", "low", "medium", "high", "x-high"), or it
--can be a non negative number value, which will be a percentage, and act as a multiplier to the speed at
--which the voice is spoken. So for example, 50% is half as fast as normal, while 200% would be twice as fast
--as normal. If true is passed to the second value, the value will instead be used as a value to retrieve
--one of the above string rates from the array. ie 1 == default, 2 == x-low, and so on. The number values will
--be automatically rounded to the nearest whole number value.
function TTS:rate(value, array)
	local is_string = typeis(value, {"number", "string"}, "value") == "string"
	if array ~= nil then typeis(array, {"boolean"}, "array") end

	if is_string then
		if contains(level_tbl, value) then return value end
	elseif array then
		local str = level_tbl[value]
		assert(str, value .. " is not a valid index for the level table.")
		return str:gsub("low", "slow"):gsub("high", "fast")
	else
		value = clamp(round(value), 0, math.huge)
		return tostring(value) .. "%"
	end
end

--Pass a value, returns a duration string. Value is rounded, and must be greater than 0.
function TTS:duration(value)
	typeis(value, {"number"}, "value")
	assert(value > 0, "Unable to have a duration less than 1 ms.")
	return tostring(round(value)) .. "ms"
end

--Pass a value to get a volume string. If array is true, uses value as an index for string
--table. ie 1 == default, 2 == silent, 3 == x-soft, etc.
function TTS:volume(value, array)
	local is_string, tbl, str
	
	is_string = typeis(value, {"number", "string"}, "value") == "string"
	tbl       = {"default", "silent", "x-soft", "soft", "medium", "high", "x-high"}

	if is_string then
		str = contains(tbl, value)
		assert(str, value .. " is not a valid volume string.")
		return str
	elseif array then
		str = tbl[value]
		assert(str, value .. " is not a valid volume table index.")
		return str
	else
		str = tostring(value)
		return (value >= 0 and "+" or "") .. (value % 1 == 0 and str .. ".0" or str) .. "dB"
	end
end

--Prosody tag. Use helper functions to form the correct strings, or refer to the w3 spec.
function TTS:prosody(text, pitch, contour, range, rate, duration, volume)
	typeis(text, {"string"}, "text")
	
	if duration then typeis(duration, {"string"}, "duration") end
	if contour then typeis(contour, {"string"}, "contour") end
	if volume then typeis(volume, {"string"}, "volume") end
	if pitch then typeis(pitch, {"string"}, "pitch") end
	if range then typeis(range, {"string"}, "range") end
	if rate then typeis(rate, {"string"}, "rate") end

	local tbl, has_entries = {}, false

	if duration then 
		tbl.duration = duration
		has_entries = true
	end
	if contour then
		tbl.contour = contour
		has_entries = true
	end
	if volume then
		tbl.volume = volume
		has_entries = true
	end
	if pitch then
		tbl.pitch = pitch
		has_entries = true
	end
	if range then
		tbl.range = range
		has_entries = true
	end
	if rate then
		tbl.rate = rate
		has_entries = true
	end

	return has_entries and tag("prosody", text, tbl) or text
end

--Not really useful in a tts context, maybe more useful if we were rendering the xml. Basically says
--what's in the replace, instead of what in the tag. Doing it cause it's a valid tag, but really lazily.
function TTS:sub(value, replace)
	typeis(value, {"string"}, "value")
	typeis(replace, {"string"}, "replace")
	return tag(sub, value, {alias = replace})
end

			--=={CEREPROC TAGS}==--
			
--returns a spurt tag for a specific sound. If a spurt is an array, then it will pick one at random.
--If you pass an index, it will pick that one specifically. Will fail gracefully; ie, if the index isn't
--an option, then it returns the first valid value, and if the id isn't valid, will simply return an
--empty string. Cereproc specific tag.
function TTS:spurt(id, index)
	if self.data.engine_type == "cereproc" then
		assert(type(id) == "string", "Invalid parameter 'id'; '" .. tostring(id) .. "' is not a string.")
		if index then assert(type(index) == "index", "Invalid parameter 'index'; '" .. tostring(id) .. "' is not a number.") end
		
		local spurt
		
		id = id:lower()
		
		if self.data.spurts[id] then
			spurt = self.data.spurts[id]
			if type(spurt) == "table" then
				index = index or rand(#spurt)
				spurt = spurt[index] and spurt[index] or spurt[rand(#spurt)]
			end
			
			spurt = tostring(spurt)
		
			return tag("spurt", "*", { audio = "g0001_" .. tostring("0"):rep(3 - spurt:len()) .. spurt })
		else
			return ""
		end
	else
		return ""
	end
end

--Returns a variation of the spoken word or phrase, based off the numeric value passed. Value will be
--rounded to the nearest whole number, and clamped between 0 and math.huge.
function TTS:variant(value, text)
	if self.data.engine_type == "cereproc" then
		typeis(value, {"number"}, "value")
		typeis(text, {"string"}, "text")
		return tag("usel", text, {variant = tostring(clamp(round(value), 0, math.huge))})
	else
		return text
	end
end

--Returns an emotion tag. Note that only certain cereproc voices support the emotion tag; currently listed
--at Adam, Caitlin, Heather, Isabella, Jack, Jess, Katherine, Kirsty, Laura, Sarah, Stuart, Suzanne and 
--William. If emote passed is not a valid emote, simply returns the text.
function TTS:emotion(emote, text)
	if self.data.engine_type == "cereproc" then
		typeis(emote, {"string"}, "emote")
		typeis(text, {"string"}, "text")

		emote = emote:lower()

		assert(contains({"happy", "sad", "calm", "cross"}, emote), emote .. " is not a valid emote option.")

		return tag("voice", text, {emotion = emote})
	else
		return text
	end
end

--Main function. Automatically wraps everything in 'speak' tags cause that's the highest level required tag.
--returns a love audioSource that you can do whatever you want with. Files will be saved in a folder, and 
--will be cleaned on shutdown.
function TTS:speak(ssml, callback)
	local filename, path
	
	filename      = tmpname(6)
	relative_path = (love.filesystem.isFused() and "" or sub_path) .. "audio/" .. filename .. ".wav"
	full_path     = self.data.folder .. "audio/" .. filename .. ".wav"
	
	if (self.data.engine_type == "cereproc") then
		local folder, cere, lic, root, cert, key, voice
		
		cere   = self.data.cereproc
		folder = cere.folder
		lic    = folder .. cere.lic
		voice  = folder .. cere.voice
		
		if cere.ver < 6 then
			root = ""
			cert = ""
			key  = ""
		else
			root  = folder .. cere.root
			cert  = folder .. cere.cert
			key   = folder .. cere.key
		end
		
		--string voice_file|string lic_file|string ssml|string out_location(|string root_file|string cert_file|string key_file)
		run(self, "cereproc", voice, lic, ssml, full_path, root, cert, key)
		love.audio.newSource(relative_path, "static"):play()
	else
		--bool get_voices|int sample|int bit_depth|int channel_mode|string voice|string ssml|string output
		run(self, "ms", false, self.data.rate, self.data.bit_depth, self.data.channel_mode, self.data.voice, ssml, full_path) 
		love.audio.newSource(relative_path, "static"):play()
	end

	print(ssml)
end

return TTS()