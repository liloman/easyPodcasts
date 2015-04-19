local Class=require("classes.Class")
Podcast=Class("Podcast")

local socket=require("socket")

local Audio=require("classes.Audio")
local audio=Audio:new("mpd")

--Private variables
local tags={pubDate = true, title = true, link=true }
local title, link, url, summary , date
local imgURL, description
local bAddFirst = false
local LB=builder:get_object('listboxPodcasts')
local titleSong = builder:get_object('titleSong')
local barSong = builder:get_object('progressAdjust')
local barVolume = builder:get_object('volumeAdjust')
local boxHeader=builder:get_object('boxHeaderPodcasts')
local bufferHeader=builder:get_object('textbufferHeaderPodcasts')
local switchHeader=builder:get_object('switchUpdateRSS')
local imageHeader=builder:get_object('imageHeaderPodcasts')
local menuAddToPlaylist=builder:get_object('menuAddToPlaylist')
local selectedRssId=nil
--play contains url,title,path,idpodcast,playing
local play={}
    
callbacksChannel = {
    StartElement = function (parser, name, attr)
        callbacksChannel.CharacterData = function (parser,str)
            if name == "description"  and string.find(str,"%a") then 
                description=db:escape(str)
            end
        end
        if name == "itunes:image" then imgURL=attr.href end
        if name == "item" then 
            callbacksChannel.CharacterData = false
            callbacksChannel.StartElement = false
            Podcast:UpdateHeader()
        end
    end,
    EndElement = false,
    CharacterData = false
}

callbacksItems = {
    StartElement = function (parser, name, attr)
        if name == "enclosure" then url = attr.url end
        if tags[name] or name == "itunes:summary" then 
            callbacksItems.CharacterData = function (parser,string)
                if string=="" then return end
                if name == "title" then title=string end
                if name == "link" then link=string  end
                if name == "pubDate" then date=string  end
                if name == "itunes:summary" then summary=db:escape(string) end
            end
        end
    end,
    EndElement = function (parser, name)
        if name == "item" then 
            Podcast:InsertPodcast(date,title,link,url,summary)
        end
        callbacksItems.CharacterData = false
    end,
    CharacterData = false
}


local lxp=require("lxp")

local function scaleImage(img)
    imageHeader:clear()
    imageHeader:set_from_file(img)
    if imageHeader:get_pixbuf() then
        local scaled = imageHeader:get_pixbuf():scale_simple(150,150,1)
        imageHeader:set_from_pixbuf(scaled)
    end
end


function Podcast:initialize(name)
    self.name=name

    function LB:on_row_selected()
        if playlistActive()  then return end
        --maybe we did row:destroy() before to get here
        if not LB:get_selected_row() then return end
        local box=LB:get_selected_row():get_child()
        play.url=box:get_name()
        local elements=box:get_children()
        play.title=elements[1]:get_label()
        print("selected podcast in podcast mode"..play.title)
        play.idpodcast=elements[1]:get_name()
        play.path=audioPath..selectedRssId.."/".. play.url:match("([^/]+)$")
        if play.playing then print("playing:"..play.playing) end
    end
    -- --if started when player working
    -- if audio:Playing() then 
    --     local current=audio:CurrentSong()
    --     play.path=audioPath..current.file
    --     play.playing=play.path
    --     play.url=play.playing
    --     titleSong:set_label(current.Title)
    --     local button=builder:get_object('toolbuttonPlayPause')
    --     button:set_icon_name("media-playback-pause")
    -- end
end

function Podcast:InsertPodcast(_date,_title,_link,_url,_summary)
    local MON={Jan=1,Feb=2,Mar=3,Apr=4,May=5,Jun=6,Jul=7,Aug=8,Sep=9,Oct=10,Nov=11,Dec=12}
    local regDate= ".* (%d+) (%a+) (%d+) .*"
    local day,tmonth,year=_date:match(regDate)
    local date=year.."-"..MON[tmonth].."-"..day
    local ref = _url:match( "([^/]+)%.mp3" )
    local idrss=selectedRssId
    local res=db:select("select ref from Podcasts where ref='"..ref.."' and idRSS="..idrss)
    local title=db:escape(_title)
    if not res() then
        db:sql("insert into Podcasts(ref,idrss,title,desc,listened,downloaded,url,ranking,date) values ('"..ref.."',"..idrss..",'"..title.."','"..summary.."',0,0,'".._url.."',0,'"..date.."')")
        local res=db:select("SELECT max(id) from Podcasts")
        self:AddPodcastToLB(res(),title,_url,summary,bAddFirst)
    end

end


function Podcast:ShowSelectedRSS(idRSS)
    if not idRSS then return end
    boxHeader:set_visible(true)
    selectedRssId=idRSS
    --Reset everything
    imageHeader:clear()
    bufferHeader:set_text('',0)
    for _,child in ipairs(LB:get_children()) do child:destroy() end

    local res=db:select("SELECT desc,img,autoupdate from RSS where id="..idRSS) 
    local _desc,img,auto = res()
    if _desc then 
        bufferHeader:set_text(_desc,string.len(_desc))
        switchHeader:set_active(auto==1)
        scaleImage(img)
    end
    local sql="SELECT id,title,url,desc from Podcasts where idRSS="..idRSS.." order by date desc"
    for id,title,link,desc in db:select(sql) do
        self:AddPodcastToLB(id,title,link,desc,false)
    end
end

function Podcast:ParsePodcasts()
    if not selectedRssId then return end
    local res=db:select("select count() from Podcasts where idRSS="..selectedRssId)
    --To add first or last on LB
    bAddFirst = res() ~= 0 
    local res=db:select("select url from RSS where id="..selectedRssId)
    local url=res()
    os.execute(wget.." "..url.." -O /tmp/file.rss -o /tmp/wgetparse.log")
    self:ParsePodcast(callbacksChannel)
    self:ParsePodcast(callbacksItems)
end

function Podcast:ParsePodcast(callbacks)
    if not selectedRssId then return end
    -- local p = lxp.new(callbacks)
    local p = lxp.new(callbacks)
    local file=io.open("/tmp/file.rss","r")
    line = file:read("*l")
    while line do 
        p:parse(line)         
        p:parse("\n")     
        line = file:read("*l")
    end
    io.close()
    p:parse()               -- finishes the document
    p:close()               -- closes the parser
end


function Podcast:AddPodcastToLB(idpodcast,title,link,summary,first)
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

        for id,name in db:select("select id,name from Playlists") do
            local item=Gtk.MenuItem()
            item:set_visible(true)
            item:set_label(name)
            item:set_name("idplaylist_"..id)
            function item:on_activate() 
                local idpl=string.sub(self:get_name(),string.len("idplaylist_")+1)
                local idpd=play.idpodcast
                db:sql("insert into PodcastsPlaylists(idPodcast,idPlaylist)"..
                " values("..idpd..","..idpl..")")
            end
            menu:append(item)
        end
    end

    hbox:pack_start(ltitle, false, false, 0)
    hbox:pack_start(desc, false, false, 0)
    if first then LB:insert(hbox,0)
    else LB:insert(hbox,-1) end
    LB:show_all()

end

function Podcast:Play()
    print("play podcast")
    if not play.url then return end
    local button=builder:get_object('toolbuttonPlayPause')
    if play.playing and play.path==play.playing then 
        local relPath=play.path:match(".*/([%d]+/.*mp3)")
        --If it's not added cause downloading to slow
        if not audio:CurrentSong().Time then audio:PlayDownloading(relPath) end
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
    local res=db:select("select listened,downloaded from Podcasts where id="..play.idpodcast)
    local listened,downloaded=res()
    local listened = listened + 1
    titleSong:set_label(play.title)
    db:sql("update Podcasts set listened="..listened.." where id="..play.idpodcast)
    if downloaded==0 then download(play) end
    local relPath=play.path:match(".*/([%d]+/.*mp3)")
    play.playing=play.path
    audio:Play(relPath,0)

    button:set_icon_name("media-playback-pause")
    local status=audio:Status()
    if status.volume then
        -- local total=tonumber(status.time:match(".*:(%d+)"))
        -- barSong:set_upper(total/60)
        local volume=tonumber(status.volume)
        if volume>0 then barVolume:set_value(volume) end
    end
end

function Podcast:Next()
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
            play.path=audioPath..selectedRssId.."/".. play.url:match("([^/]+)$")
            LB:select_row(row)
            self:Play()
            break
        end
        if play.url == url then exit = 1 end
    end
end

function Podcast:Previous()
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
                play.path=audioPath..selectedRssId.."/".. play.url:match("([^/]+)$")
                LB:select_row(prow)
                self:Play()
            end
            break
        end
        pbox=box
        prow=row
    end
end

function Podcast:UpdateHeader()
    -- if not selectedRssId then return end
    local ref = iconPath..imgURL:match("([^/]+)%.jpg")..".jpg"
    os.execute(wget.." "..imgURL.." -nc -O "..ref.." -o /tmp/.wgeticon.log &")
    db:sql("update RSS set desc='"..description.."', img='"..ref.."' where id="..selectedRssId)
    bufferHeader:set_text(description,string.len(description))
    scaleImage(ref)
    imgURL=nil
    description=nil
end

function Podcast:GetSelected()
    return selectedRssId
end

function Podcast:SetSelected(idrss)
    selectedRssId=idrss
end

function Podcast:close()
    audio:close()
end



function Podcast:UpdateBar()
    if audio:Playing() then 
        local status=audio:Status()
        local current=audio:CurrentSong()
        if current.Time and play.path then 
            audio:Update(current.file)
            local relPath=play.path:match(".*/([%d]+/.*mp3)")
            local played=tonumber(status.elapsed)
            barSong:set_value(played/60)
            -- local total=tonumber(status.time:match(".*:(%d+)"))
            local total=tonumber(current.Time)
            barSong:set_upper(total/60)
        end
    end
end

function Podcast:ChangeVolume(value)
    local value=value*100
    Audio:ChangeVolume(value)
end

function Podcast:MovePlaying()
    if audio:Playing() then 
        local time=barSong:get_value()*60
        Audio:Seek(audio:Status().song,time)
    end
end

function Podcast:ResetPlay()
    for k,_ in pairs(play) do play[k]=nil end
end

return Podcast
