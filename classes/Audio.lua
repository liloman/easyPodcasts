-- Class adaptator for the players (mpd,mocp...)
local Class=require("classes.Class")
local player={} 

local defaultPlaylist="rss"
local selected=""

Audio=Class("Audio")


function Audio:loadPlaylist(name)
    player:load(name)
end

function Audio:initialize(name)
    self.name="Audio."..name
    local audio=require("classes."..name)
    player=audio:new()
    if not player.con then print("Connection to "..name.." failed:"..player.err) end
    self:emptyPlaylist(defaultPlaylist)
end

function Audio:PlayDownloading(podcast,playlist)
    self:addtoPlaylist(podcast,playlist or defaultPlaylist)
    player:play(0)
end

function Audio:Play(podcast,pos,playlist)
    print("PLAYYY")
    local playlist= playlist or defaultPlaylist
    local pos=self:SearchPodcast(podcast) 

    -- Clear, add and play just that podcast
    if playlist == defaultPlaylist then 
        print("default playlist")
        self:emptyPlaylist(playlist)
        while not pos do
            self:addtoPlaylist(podcast,playlist)
            pos=self:SearchPodcast(podcast) 
        end
    end

    if selected ~= playlist then 
        self:loadPlaylist(playlist) 
        selected = playlist
    end
    player:play(pos)
end

function Audio:SearchPodcast(podcast)
    local pos=nil
    for _,v in ipairs(player:playlistinfo()) do
        if v.file == podcast then pos=v.Pos  end
    end
    return pos
end


function Audio:addtoPlaylist(podcast,playlist)
    print("add "..podcast.." on "..playlist)
    player:update(podcast)
    -- if it not exists not added then...
    player:playlistadd(playlist,podcast)
    player:load(playlist)
end

function Audio:emptyPlaylist(name)
    player:playlistclear(name)
    player:load(name)
    player:clear()
end

function Audio:Update(song)
    player:update(song)
end

function Audio:TogglePause()
    player:toggle()
end

function Audio:Playing() 
    local status=player:status()
    return status.state=="play" 
end

function Audio:Previous()
    return player:previous()
end

function Audio:Next()
    return player:next()
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
