local Class=require("Class")
Podcast=Class("Podcast")

local tags={title = true, link=true }
local title, link, url, summary 
local imgURL, description
local LB=builder:get_object('listboxPodcasts')

callbacksChannel = {
    StartElement = function (parser, name, attr)
        callbacksChannel.CharacterData = function (parser,str)
            if name == "description"  and string.find(str,"%a") then 
                description=db:escape(str)
            end
        end
        if name == "itunes:image" then imgURL=attr.href end
    end,
    EndElement = function (parser, name)
        if name == "image" then 
            callbacksChannel.CharacterData = false
            callbacksChannel.StartElement = false
            Podcast:InsertHeader(imgURL,description)
        end
    end,
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
                if name == "itunes:summary" then summary=db:escape(string) end
            end
        end
    end,
    EndElement = function (parser, name)
        if name == "item" then 
            Podcast:InsertPodcast(title,link,url,summary)
        end
        callbacksItems.CharacterData = false
    end,
    CharacterData = false
}


--Private variables
local LB=builder:get_object('listboxPodcasts')
local selectedRSS=nil
local play={ }
local lxp=require("lxp")

function Podcast:initialize(name)
    self.name=name
    function LB:on_row_selected()
        --maybe we did row:destroy() before to get here
        if not LB:get_selected_row() then return end
        local box=LB:get_selected_row():get_child()
        play.url=box:get_name()
        local elements=box:get_children()
        play.title=elements[1]:get_label()
    end
end

function Podcast:InsertPodcast(_title,_link,_url,_summary)
    local ref = _url:match( "([^/]+)%.mp3" )
    local idrss=selectedRSS
    local res=db:select("select ref from Podcasts where ref="..ref.." and idRSS="..idrss)
    if not res() then
        local pre = (_title.."-"):gmatch("([^-]*)-") 
        local title = db:escape(pre(3))
        local date = pre(4)
        db:sql("insert into Podcasts(ref,idrss,title,desc,listened,downloaded,url,ranking) values ("..ref..","..idrss..",'"..title.."','"..summary.."',0,0,'".._url.."',0)")
        self:AddPodcastToLB(title,_url,summary,true)
    end
end

function Podcast:ShowSelectedRSS(idRSS)
    selectedRSS=idRSS
    local buffer=builder:get_object('textbufferHeaderPodcasts')
    for desc,img,auto in db:select("SELECT desc,img,autoupdate from RSS where id="..idRSS) do
        buffer:set_text(desc,string.len(desc))
        local switch=builder:get_object('switchUpdateRSS')
        switch:set_state(auto==1)
        --Aqui iría la imagen...
    end
    for _,child in ipairs(LB:get_children()) do child:destroy() end
    local sql="SELECT title,url,desc from Podcasts where idRSS="..idRSS.." order by ref desc"
    for title,link,desc in db:select(sql) do
        self:AddPodcastToLB(title,link,desc,false)
    end
    if builder:get_object('switchUpdateRSS').state then self:ParsePodcasts() end
end

function Podcast:ParsePodcasts()
    self:ParsePodcast(callbacksChannel)
    self:ParsePodcast(callbacksItems)
end

function Podcast:ParsePodcast(callbacks)
    if not selectedRSS then return end
    -- local p = lxp.new(callbacks)
    local p = lxp.new(callbacks)
    local res=db:select("select url from RSS where id="..selectedRSS)
    local url=res()
    os.execute("/usr/bin/wget "..url.." -O /tmp/file.rss -o /tmp/wgetparse.log")
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


function Podcast:AddPodcastToLB(title,link,summary,first)
    local hbox=Gtk.VBox()
    hbox:set_name(link)
    local ltitle=Gtk.Label()
    ltitle:set_label(title)
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

function Podcast:Play()
    if not play.url then return end
    if play.playing and play.url==play.playing then 
        local button=builder:get_object('toolbuttonPlayPause')
        if button:get_icon_name() == "media-playback-start" then
            button:set_icon_name("media-playback-pause")
        else
            button:set_icon_name("media-playback-start")
        end
        --Toggle between Play and Pause
        os.execute(mocp.." -G")
        return
    end
    local path=audioPath..selectedRSS.."/"
    local ref = play.url:match( "([^/]+)$" )
    os.execute("mkdir -p  "..path)
    os.execute("/usr/bin/wget "..play.url.." -nc -O "..path..ref.." -o "..os.tmpname().." &")
    local bar=builder:get_object('progressbarSong')
    bar:set_text(play.title)
    --Clear playlist, queue the song and play. And dont sync with other clients
    os.execute(mocp.." -c -p -q "..path..ref)
    play.playing=play.url
end

function Podcast:Forward()
    if not play.url then return end
    local url,box=nil,nil
    local exit = 0
    for _, row in ipairs(LB:get_children()) do
        box=row:get_child()
        url=box:get_name()
        if exit == 1 then exit = 2 end
        if play.playing == url then exit = 1 end
        if exit == 2 then
            play.url=url
            local elements=box:get_children()
            play.title=elements[1]:get_label()
            break
        end
    end
    self:Play()
end

function Podcast:Previous()
    if not play.url then return end
    local url,box,pbox=nil,nil,nil
    local exit = 0
    for _, row in ipairs(LB:get_children()) do
        box=row:get_child()
        url=box:get_name()
        if play.playing == url then
            if pbox then
                play.url=pbox:get_name()
                local elements=pbox:get_children()
                play.title=elements[1]:get_label()
                pbox:get_parent():grab_focus()
            end
            break
        end
        pbox=box
    end
    self:Play()
end

function Podcast:InsertHeader(imgURL,description)
    if not selectedRSS then return end
    local ref = iconPath..imgURL:match("([^/]+)%.jpg")..".jpg"
    local buffer=builder:get_object('textbufferHeaderPodcasts')
    os.execute("/usr/bin/wget "..imgURL.." -nc -O "..ref.." -o /tmp/.wgeticon.log &")
    db:sql("update RSS set desc='"..description.."', img='"..ref.."' where id="..selectedRSS)
    buffer:set_text(description,string.len(description))
end

function Podcast:GetSelected()
    return selectedRSS
end

return Podcast
