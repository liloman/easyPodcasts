local Class=require("classes.Class")
Playlist=Class("Playlist")

local socket=require("socket")

local Audio=require("classes.Audio")
local audio=Audio:new("mpd")

--Private variables
local LB=builder:get_object('listboxPodcasts')
local LB2=builder:get_object('listboxRSS')
local titleSong = builder:get_object('titleSong')
local barSong = builder:get_object('progressAdjust')
local barVolume = builder:get_object('volumeAdjust')
local boxHeader=builder:get_object('boxHeaderPodcasts')
local bufferHeader=builder:get_object('textbufferHeaderPodcasts')
local switchHeader=builder:get_object('switchUpdateRSS')
local imageHeader=builder:get_object('imageHeaderPodcasts')
local selectedPlaylist=nil
    
function Playlist:initialize(name)
    self.name=name
    for name in db:select("SELECT name from Playlists") do audio:emptyPlaylist(name) end
    for name,rss,ref in db:select("select name,idRSS,ref from listPodcastsPlaylists") do
        print("name:"..name.." idrss:"..rss.." ref:"..ref)
        audio:addtoPlaylist(rss.."/"..ref..".mp3",name)
    end
end

function Playlist:getPlaylistSelected()
    return selectedPlaylist
end


function Playlist:ShowPlaylists()
    print("showplayslist")
    boxHeader:set_visible(false)
    for _,child in ipairs(LB:get_children()) do child:destroy() end
    for _,child in ipairs(LB2:get_children()) do child:destroy() end

    function LB:on_row_selected()
        if not playlistmode() then return end
        print("selected podcast in playlist mode")
        --maybe we did row:destroy() before to get here
        if not LB:get_selected_row() then return end
        local box=LB:get_selected_row():get_child()
        play.url=box:get_name()
        local elements=box:get_children()
        play.title=elements[1]:get_label()
        play.idpodcast=elements[1]:get_name()
        local res=db:select("select idRSS from Podcasts where id="..play.idpodcast)
        play.path=audioPath..res().."/".. play.url:match("([^/]+)$")
        if play.playing then print("playing:"..play.playing) end
    end

    function LB2:on_row_selected()
        if not playlistmode() then return end
        print("playlist selected")
        local row=self:get_selected_row()
        if not row then return end
        local child=row:get_child():get_name()
        local id=string.sub(child,string.len("idplaylist_")+1)
        Playlist:ShowSelectedPlaylist(id)
    end

    self:AddPlaylistToLB("current",0)
    for id,name in db:select("SELECT id,name from Playlists") do
        self:AddPlaylistToLB(name,id)
    end
end

function Playlist:AddPlaylistToLB(playlist,id)
    print("adding "..playlist)
    local hbox=Gtk.HBox()
    hbox:set_name("idplaylist_"..id)
    local label=Gtk.Label()
    label:set_label(id)
    hbox:pack_start(label, false, false, 0)
    local label=Gtk.Label()
    label:set_label(playlist)
    hbox:pack_end(label, false, false, 0)
    LB2:insert(hbox,-1)
    LB2:show_all()
end

function Playlist:ShowSelectedPlaylist(id)
    if not id then return end
    local res=db:select("select name from Playlists where id="..id) 
    selectedPlaylist=res() or "rss"
    for _,child in ipairs(LB:get_children()) do child:destroy() end

    for id,title,url,desc in db:select("select id,title,url,desc from listPodcastsPlaylists where idPlaylist="..id) do
        self:AddPodcastToLB(id,title,url,desc,false)
    end
end

function Playlist:AddPodcastToLB(idpodcast,title,link,summary,first)
    local hbox=Gtk.VBox()
    hbox:set_name(link)
    local ltitle=Gtk.Label()
    ltitle:set_label(title)
    ltitle:set_name(idpodcast)
    local buffer=Gtk.TextBuffer()
    buffer:set_text(summary,string.len(summary))
    local desc=Gtk.TextView()
    desc:set_buffer(buffer)
    desc:set_wrap_mode(1)
    hbox:pack_start(ltitle, false, false, 0)
    hbox:pack_start(desc, false, false, 0)
    if first then LB:insert(hbox,0)
    else LB:insert(hbox,-1) end
    LB:show_all()
end

return Playlist
