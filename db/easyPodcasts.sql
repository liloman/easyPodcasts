DROP TABLE IF EXISTS "Groups";
CREATE TABLE "Groups" ("id" INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE , "name" VARCHAR);
DROP TABLE IF EXISTS "Podcasts";
CREATE TABLE "Podcasts" ("id" INTEGER PRIMARY KEY  NOT NULL ,"ref" VARCHAR NOT NULL  DEFAULT (null) ,"idRSS" INTEGER,"title" VARCHAR,"desc" VARCHAR DEFAULT (null) ,"listened" INTEGER,"downloaded" BOOL,"url" VARCHAR,"ranking" NUMERIC,"date" DATETIME);
DROP TABLE IF EXISTS "RSS";
CREATE TABLE "RSS" ("id" INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE , "name" VARCHAR NOT NULL , "desc" VARCHAR, "img" VARCHAR, "url" VARCHAR NOT NULL , "date" DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP, "autoupdate" BOOL DEFAULT 0);
DROP TABLE IF EXISTS "RSSGroups";
CREATE TABLE "RSSGroups" ("idGroup" INTEGER NOT NULL , "idRSS" INTEGER NOT NULL , PRIMARY KEY ("idGroup", "idRSS"));
CREATE VIEW "listRSSGroups" AS     SELECT g.name groupName,r.name rss,r.img img,r.id id  from RSS as r
inner join RSSGroups as rg on rg.idRSS=r.id 
inner join Groups as g on g.id=rg.idGroup
order by groupName;
