-- Class adaptator for the players (mpd,mocp...)
local Class=require("classes.Class")
local player={} 

local playlistrss="rss"

Audio=Class("Audio")

local function emptyPlaylist(name)
    player:playlistclear(name)
    player:load(name)
    player:clear()
end

function Audio:initialize(name)
    self.name="Audio."..name
    local audio=require("classes."..name)
    player=audio:new()
    if not player.con then print("Connection to "..name.." failed:"..player.err) end
    emptyPlaylist(playlistrss)
end

function Audio:Play(song)
    print("play:"..song)
    player:update(song)
    player:playlistadd(playlistrss,song)
    player:add(song)
    if self:Playing() then 
        player:next()
    else
        player:play(0)
    end
end

function Audio:TogglePause()
    player:toggle()
end

function Audio:Playing() 
    local status=player:status()
    return status.state=="play" 
end

function Audio:Status()
    return player:status()
end

function Audio:CurrentSong()
    return player:currentsong()
end

function Audio:PlaylistInfo()
    return player:playlistinfo()
end

function Audio:ChangeVolume(value)
    return player:set_vol(value)
end

function Audio:Seek(pos,time)
    return player:seek(pos,time)
end

return Audio
