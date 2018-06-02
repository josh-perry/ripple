local ripple = {}

local Tag = {}
Tag.__index = Tag

function Tag:_addSound(sound)
	self._sounds[sound] = true
end

function Tag:_removeSound(sound)
	self._sounds[sound] = nil
end

function Tag:getVolume()
	return self._volume
end

function Tag:setVolume(volume)
	self._volume = volume
	for sound, _ in pairs(self._sounds) do
		sound:_updateVolume()
	end
end

function ripple.newTag()
	return setmetatable({
		_volume = 1,
		_sounds = {},
	}, Tag)
end

local Sound = {}
Sound.__index = Sound

function Sound:_updateVolume()
	self._finalVolume = self._volume
	for tag, _ in pairs(self._tags) do
		self._finalVolume = self._finalVolume * tag:getVolume()
	end
	for _, instance in ipairs(self._instances) do
		instance.source:setVolume(self._finalVolume * instance.volume)
	end
end

function Sound:_removeInstances()
	for i = #self._instances, 1, -1 do
		if not self._instances[i].source:isPlaying() then
			table.remove(self._instances, i)
		end
	end
end

function Sound:getVolume()
	return self._volume
end

function Sound:setVolume(volume)
	self._volume = volume
	self:_updateVolume()
end

function Sound:tag(tag)
	self._tags[tag] = true
	tag:_addSound(self)
	self:_updateVolume()
end

function Sound:untag(tag)
	self._tags[tag] = nil
	tag:_removeSound(self)
	self:_updateVolume()
end

function Sound:play(options)
	options = options or {}
	self:_removeInstances()
	local instance = {
		source = self.source:clone(),
		volume = options.volume or 1,
	}
	instance.source:setVolume(self._finalVolume * instance.volume)
	instance.source:setPitch(options.pitch or 1)
	instance.source:play()
	table.insert(self._instances, instance)
end

function ripple.newSound(options)
	local sound = setmetatable({
		source = options.source,
		_volume = options.volume or 1,
		_tags = {},
		_instances = {},
	}, Sound)
	return sound
end

return ripple