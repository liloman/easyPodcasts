-- Create the class
local Db={}

function Db:new()
    local obj={}
    local path
    setmetatable(obj,self)
    self.__index=self
    local luasql=require "luasql.sqlite3"
    -- create environment object
    env = assert (luasql.sqlite3())
    -- connect to data source
    con = assert(env:connect(abDir.."db/easyPodcasts.sqlite"))
    return obj
end



function Db:sql(str)
    local cur = assert(con:execute(str))
end 

function Db:escape(str)
    return con:escape(str)
end

function Db:select(str)
    print("Select ".. str)
    local cur = assert(con:execute(str))
    return function() return cur:fetch() end
end

function Db:close()
    -- if cur then cur:close() end
    con:close()
    env:close()
end

return Db:new()
