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
--play contains url,title,path,idpodcast,playing
local play={}
    
function Playlist:initialize(name)
    self.name=name
    for name in db:select("SELECT name from Playlists") do audio:emptyPlaylist(name) end
    for name,rss,ref in db:select("select name,idRSS,ref from listPodcastsPlaylists") do
        print("name:"..name.." idrss:"..rss.." ref:"..ref)
        audio:addtoPlaylist(rss.."/"..ref..".mp3",name)
    end
end

function Playlist:Play()
    print("play playlist")
    if not play.url then return end
    local button=builder:get_object('toolbuttonPlayPause')
    if play.playing and play.path==play.playing then 
        local relPath=play.path:match(".*/([%d]+/.*mp3)")
        --If it's not added cause downloading to slow
        if not audio:CurrentSong().Time then audio:PlayDownloading(relPath,selectedPlaylist) end
        --Maybe even now not playing already so wait more 
        if not audio:CurrentSong().Time then return end
        if button:get_icon_name() == "media-playback-start" then
            button:set_icon_name("media-playback-pause") 
        else button:set_icon_name("media-playback-start") end
        --Toggle between Play and Pause
        audio:TogglePause()
        print("sale de ajuste del boton")
        return
    end 
    print("play2")
    audio:loadPlaylist(selectedPlaylist)
    local res=db:select("select listened,downloaded from Podcasts where id="..play.idpodcast)
    local listened,downloaded=res()
    local listened = listened + 1
    titleSong:set_label(play.title)
    db:sql("update Podcasts set listened="..listened.." where id="..play.idpodcast)
    if downloaded==0 then download(play) end
    local relPath=play.path:match(".*/([%d]+/.*mp3)")
    play.playing=play.path
    local pos=audio:SearchPodcast(relPath) 
    if not pos then --Not found therefore is neither downloaded nor added already
        print("dice que not found:"..downloaded.." "..relPath.." y play:"..play.path.." playlist:"..selectedPlaylist)
        --Loop until position... really bad hack
        while not pos do
            audio:addtoPlaylist(relPath,selectedPlaylist)
            pos=audio:SearchPodcast(relPath) 
        end
        db:sql("update Podcasts set downloaded=1 where id="..play.idpodcast)
    end

    audio:Play(relPath,pos,playlist) 

    button:set_icon_name("media-playback-pause")
    local status=audio:Status()
    if status.volume then
        -- local total=tonumber(status.time:match(".*:(%d+)"))
        -- barSong:set_upper(total/60)
        local volume=tonumber(status.volume)
        if volume>0 then barVolume:set_value(volume) end
    end
end

function Playlist:ShowPlaylists()
    print("showplayslist")
    boxHeader:set_visible(false)
    for _,child in ipairs(LB:get_children()) do child:destroy() end
    for _,child in ipairs(LB2:get_children()) do child:destroy() end

    function LB:on_row_selected()
        if not playlistActive() then return end
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
        if not playlistActive() then return end
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
    function desc:on_populate_popup(menu)
        --Remove all stock entries menu
        for _,child in ipairs(menu:get_children()) do child:destroy() end

        local item=Gtk.MenuItem()
        item:set_visible(true)
        item:set_label("Remove")
        function item:on_activate() 
            local row=LB2:get_selected_row()
            local child=row:get_child():get_name()
            local idpl=string.sub(child,string.len("idplaylist_")+1)
            db:sql("delete from PodcastsPlaylists where idPodcast="..play.idpodcast..
            " and idPlaylist="..idpl)
            LB:get_selected_row():destroy()
            LB:show_all()
        end
        menu:append(item)

        local item=Gtk.MenuItem()
        item:set_visible(true)
        item:set_label("Empty Playlist")
        function item:on_activate() 
            local row=LB2:get_selected_row()
            local child=row:get_child():get_name()
            local idpl=string.sub(child,string.len("idplaylist_")+1)
            db:sql("delete from PodcastsPlaylists where idPlaylist="..idpl)
            for _,child in ipairs(LB:get_children()) do child:destroy() end
            LB:show_all()
        end
        menu:append(item)
    end
    hbox:pack_start(ltitle, false, false, 0)
    hbox:pack_start(desc, false, false, 0)
    if first then LB:insert(hbox,0)
    else LB:insert(hbox,-1) end
    LB:show_all()
end

function Playlist:AddPlaylist()
    local builder = Gtk.Builder()
    assert(builder:add_from_file((abDir..'ui/dialogAddRSS.ui')))
    local window = builder.objects.windowRSS
    local buttonCancel=builder:get_object('buttonCancel')
    builder:get_object('grid1'):remove_row(1)
    builder:get_object('labelFrame'):set_label("Add New Playlist")
    window:set_title("Add New Playlist")
    function buttonCancel:on_clicked()
        window:destroy()
    end

    local buttonOk=builder:get_object('buttonOk')
    function buttonOk:on_clicked()
        local name=builder:get_object('name'):get_text()
        if name=="" then builder:get_object('name'):grab_focus() return end
        db:sql("insert into Playlists(name) values ('"..name.."')") 
        local res=db:select("select max(id) max from Playlists") 
        Playlist:AddPlaylistToLB(name,res())
    end
    window:show_all()
end

function Playlist:DelPlaylist()
    local row=LB2:get_selected_row()
    if not row then return end
    local child=row:get_child():get_name()
    local id=string.sub(child,string.len("idplaylist_")+1)
    print("Deleting playlist "..id)
    db:sql("delete from Playlists where id="..id) 
    db:sql("delete from PodcastsPlaylists where idPlaylist="..id) 
    row:destroy()
    LB2:show_all()
end

function Playlist:Next(auto)
    if not play.url then return end
    local url,box=nil,nil
    local exit = 0
    for _, row in ipairs(LB:get_children()) do
        box=row:get_child()
        url=box:get_name()
        if exit == 1 then 
            play.url=url
            local elements=box:get_children()
            play.title=elements[1]:get_label()
            play.idpodcast=elements[1]:get_name()
            local res=db:select("select idRSS,downloaded from Podcasts where id="..play.idpodcast)
            local idRSS,downloaded=res()
            play.path=audioPath..idRSS.."/".. play.url:match("([^/]+)$")
            LB:select_row(row)
            self:Play()
            break
        end
        if play.url == url then exit = 1 end
    end
end

function Playlist:Previous()
    if not play.url then return end
    local url,box,pbox,prow=nil,nil,nil,nil
    local exit = 0
    for _, row in ipairs(LB:get_children()) do
        box=row:get_child()
        url=box:get_name()
        if play.url == url then
            if pbox then
                play.url=pbox:get_name()
                local elements=pbox:get_children()
                play.title=elements[1]:get_label()
                play.idpodcast=elements[1]:get_name()
                local res=db:select("select idRSS,downloaded from Podcasts where id="..play.idpodcast)
                local idRSS,downloaded=res()
                play.path=audioPath..idRSS.."/".. play.url:match("([^/]+)$")
                LB:select_row(prow)
                self:Play()
            end
            break
        end
        pbox=box
        prow=row
    end
end

function Playlist:UpdateBar()
    if audio:Playing() then 
        local status=audio:Status()
        local current=audio:CurrentSong()
        if current.Time and play and play.path then 
            audio:Update(current.file)
            local relPath=play.path:match(".*/([%d]+/.*mp3)")
            --Changed to next song on the playlist automaticaly
            -- but not playing and changed to playlists and select one row
            -- tricky to get it right...
            -- if current.file ~= relPath and playlistmode then self:Next(true) end
            local played=tonumber(status.elapsed)
            barSong:set_value(played/60)
            -- local total=tonumber(status.time:match(".*:(%d+)"))
            local total=tonumber(current.Time)
            barSong:set_upper(total/60)
        end
    end
end

function Playlist:ResetPlay()
    for k,_ in pairs(play) do play[k]=nil end
end

return Playlist
