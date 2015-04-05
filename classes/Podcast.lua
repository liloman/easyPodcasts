local Class=require("Class")
Podcast=Class("Podcast")

-- local tags={title=true, itunes:subtitle=true,link=true,itunes:summary =true}
local tags={title = true, link=true }
local title, link, url, summary 
local LB=builder:get_object('listboxPodcasts')

callbacks = {
    StartElement = function (parser, name, attr)
        if name == "enclosure" then url = attr.url end
        if tags[name] or name == "itunes:summary" then 
            callbacks.CharacterData = function (parser,string)
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
        callbacks.CharacterData = false
    end,
    CharacterData = false
}


--Private variables
local LB=builder:get_object('listboxPodcasts')
local selectedRSS=nil
local play={}
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
        local title = db:escape(pre[3])
        local date = pre[4]
        print(title,_summary,_url,date)
        db:sql("insert into Podcasts(ref,idrss,title,desc,listened,downloaded,url,ranking) values ("..ref..","..idrss..",'"..title.."','"..summary.."',0,0,'".._url.."',0)")
    end
end

function Podcast:ShowSelectedRSS(idRSS)
    selectedRSS=idRSS
    for _,child in ipairs(LB:get_children()) do child:destroy() end
    local sql="SELECT title,url,desc from Podcasts where idRSS="..idRSS
    for title,link,desc in db:select(sql) do
        self:AddPodcastToLB(title,link,desc)
    end
    if builder:get_object('switchUpdateRSS').state then self:UpdatePodcasts() end
end

function Podcast:UpdatePodcasts()
    print "UpdatePodcasts "
    local p = lxp.new(callbacks)
    local res=db:select("select url from RSS where id="..selectedRSS)
    local url=res()
    os.execute("/usr/bin/wget "..url.." -O /tmp/file.rss")
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


function Podcast:AddPodcastToLB(title,link,summary)
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
    LB:insert(hbox,-1)
    LB:show_all()

end

function Podcast:Play()
    if not play.url then return end
    local path=audioPath..selectedRSS.."/"
    local ref = play.url:match( "([^/]+)$" )
    os.execute("mkdir -p  "..path)
    os.execute("/usr/bin/wget "..play.url.." -nc -O "..path..ref.." &")
    local bar=builder:get_object('progressbarSong')
    bar:set_text(play.title)
    os.execute("/usr/bin/mplayer "..path..ref)
end
return Podcast
