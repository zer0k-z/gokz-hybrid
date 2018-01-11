/*	
	SQL
	
	SQL query templates.
*/



// =========================  MAPS  ========================= //

char sqlite_maps_alter1[] = 
"ALTER TABLE Maps "
..."ADD InRankedPool INTEGER NOT NULL DEFAULT '0'";

char mysql_maps_alter1[] = 
"ALTER TABLE Maps "
..."ADD InRankedPool TINYINT NOT NULL DEFAULT '0'";

char sqlite_maps_insertranked[] = 
"INSERT OR IGNORE INTO Maps "
..."(InRankedPool, Name) "
..."VALUES %s";

char sqlite_maps_updateranked[] = 
"UPDATE OR IGNORE Maps "
..."SET InRankedPool=%d "
..."WHERE Name IN (%s)";

char mysql_maps_upsertranked[] = 
"INSERT INTO Maps (InRankedPool, Name) "
..."VALUES %s "
..."ON DUPLICATE KEY UPDATE "
..."InRankedPool=VALUES(InRankedPool)";

char sql_maps_reset_mappool[] = 
"UPDATE Maps "
..."SET InRankedPool=0";

char sql_maps_getname[] = 
"SELECT Name "
..."FROM Maps "
..."WHERE MapID=%d";

char sql_maps_searchbyname[] = 
"SELECT MapID, Name "
..."FROM Maps "
..."WHERE Name LIKE '%%%s%%' "
..."ORDER BY (Name='%s') DESC, LENGTH(Name) "
..."LIMIT 1";



// =========================  PLAYERS  ========================= //

char sql_players_getalias[] = 
"SELECT Alias "
..."FROM Players "
..."WHERE SteamID32=%d";

char sql_players_searchbyalias[] = 
"SELECT SteamID32, Alias "
..."FROM Players "
..."WHERE Players.Cheater=0 AND LOWER(Alias) LIKE '%%%s%%' "
..."ORDER BY (LOWER(Alias)='%s') DESC, LastPlayed DESC "
..."LIMIT 1";



// =========================  MAPCOURSES  ========================= //

char sql_mapcourses_findid[] = 
"SELECT MapCourseID "
..."FROM MapCourses "
..."WHERE MapID=%d AND Course=%d";



// =========================  GENERAL  ========================= //

char sql_getpb[] = 
"SELECT Times.RunTime, Times.Teleports "
..."FROM Times "
..."INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID "
..."WHERE Times.SteamID32=%d AND MapCourses.MapID=%d AND MapCourses.Course=%d AND Times.Mode=%d "
..."ORDER BY Times.RunTime "
..."LIMIT %d";

char sql_getpbpro[] = 
"SELECT Times.RunTime "
..."FROM Times "
..."INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID "
..."WHERE Times.SteamID32=%d AND MapCourses.MapID=%d AND MapCourses.Course=%d AND Times.Mode=%d AND Times.Teleports=0 "
..."ORDER BY Times.RunTime "
..."LIMIT %d";

char sql_getmaptop[] = 
"SELECT Times.SteamID32, Players.Alias, MIN(Times.RunTime) AS PBTime, Times.Teleports "
..."FROM Times "
..."INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID "
..."INNER JOIN Players ON Players.SteamID32=Times.SteamID32 "
..."WHERE Players.Cheater=0 AND MapCourses.MapID=%d AND MapCourses.Course=%d AND Times.Mode=%d "
..."GROUP BY Times.SteamID32, Players.Alias, Times.Teleports "
..."ORDER BY PBTime "
..."LIMIT %d";

char sql_getmaptoppro[] = 
"SELECT Times.SteamID32, Players.Alias, MIN(Times.RunTime) AS PBTime "
..."FROM Times "
..."INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID "
..."INNER JOIN Players ON Players.SteamID32=Times.SteamID32 "
..."WHERE Players.Cheater=0 AND MapCourses.MapID=%d AND MapCourses.Course=%d AND Times.Mode=%d AND Times.Teleports=0 "
..."GROUP BY Times.SteamID32, Players.Alias "
..."ORDER BY PBTime "
..."LIMIT %d";

char sql_getwrs[] = 
"SELECT MIN(Times.RunTime), MapCourses.Course, Times.Mode "
..."FROM Times "
..."INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID "
..."INNER JOIN Players ON Players.SteamID32=Times.SteamID32 "
..."WHERE Players.Cheater=0 AND MapCourses.MapID=%d "
..."GROUP BY MapCourses.Course, Times.Mode";

char sql_getwrspro[] = 
"SELECT MIN(Times.RunTime), MapCourses.Course, Times.Mode "
..."FROM Times "
..."INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID "
..."INNER JOIN Players ON Players.SteamID32=Times.SteamID32 "
..."WHERE Players.Cheater=0 AND MapCourses.MapID=%d AND Times.Teleports=0 "
..."GROUP BY MapCourses.Course, Times.Mode";

char sql_getpbs[] = 
"SELECT MIN(Times.RunTime), MapCourses.Course, Times.Mode "
..."FROM Times "
..."INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID "
..."WHERE Times.SteamID32=%d AND MapCourses.MapID=%d "
..."GROUP BY MapCourses.Course, Times.Mode";

char sql_getpbspro[] = 
"SELECT MIN(Times.RunTime), MapCourses.Course, Times.Mode "
..."FROM Times "
..."INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID "
..."WHERE Times.SteamID32=%d AND MapCourses.MapID=%d AND Times.Teleports=0 "
..."GROUP BY MapCourses.Course, Times.Mode";

char sql_getmaprank[] = 
"SELECT COUNT(DISTINCT Times.SteamID32) "
..."FROM Times "
..."INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID "
..."INNER JOIN Players ON Players.SteamID32=Times.SteamID32 "
..."WHERE Players.Cheater=0 AND MapCourses.MapID=%d AND MapCourses.Course=%d AND Times.Mode=%d "
..."AND Times.RunTime < "
..."(SELECT MIN(Times.RunTime) "
..."FROM Times "
..."INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID "
..."INNER JOIN Players ON Players.SteamID32=Times.SteamID32 "
..."WHERE Players.Cheater=0 AND Times.SteamID32=%d AND MapCourses.MapID=%d AND MapCourses.Course=%d AND Times.Mode=%d) "
..."+ 1";

char sql_getmaprankpro[] = 
"SELECT COUNT(DISTINCT Times.SteamID32) "
..."FROM Times "
..."INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID "
..."INNER JOIN Players ON Players.SteamID32=Times.SteamID32 "
..."WHERE Players.Cheater=0 AND MapCourses.MapID=%d AND MapCourses.Course=%d AND Times.Mode=%d AND Times.Teleports=0 "
..."AND Times.RunTime < "
..."(SELECT MIN(Times.RunTime) "
..."FROM Times "
..."INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID "
..."INNER JOIN Players ON Players.SteamID32=Times.SteamID32 "
..."WHERE Players.Cheater=0 AND Times.SteamID32=%d AND MapCourses.MapID=%d AND MapCourses.Course=%d AND Times.Mode=%d AND Times.Teleports=0) "
..."+ 1";

char sql_getlowestmaprank[] = 
"SELECT COUNT(DISTINCT Times.SteamID32) "
..."FROM Times "
..."INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID "
..."INNER JOIN Players ON Players.SteamID32=Times.SteamID32 "
..."WHERE Players.Cheater=0 AND MapCourses.MapID=%d AND MapCourses.Course=%d AND Times.Mode=%d";

char sql_getlowestmaprankpro[] = 
"SELECT COUNT(DISTINCT Times.SteamID32) "
..."FROM Times "
..."INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID "
..."INNER JOIN Players ON Players.SteamID32=Times.SteamID32 "
..."WHERE Players.Cheater=0 AND MapCourses.MapID=%d AND MapCourses.Course=%d AND Times.Mode=%d AND Times.Teleports=0";

char sql_getcount_maincourses[] = 
"SELECT COUNT(*) "
..."FROM MapCourses "
..."INNER JOIN Maps ON Maps.MapID=MapCourses.MapID "
..."WHERE Maps.InRankedPool=1 AND MapCourses.Course=0";

char sql_getcount_maincoursescompleted[] = 
"SELECT COUNT(DISTINCT Times.MapCourseID) "
..."FROM Times "
..."INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID "
..."INNER JOIN Maps ON Maps.MapID=MapCourses.MapID "
..."WHERE Maps.InRankedPool=1 AND MapCourses.Course=0 AND Times.SteamID32=%d AND Times.Mode=%d";

char sql_getcount_maincoursescompletedpro[] = 
"SELECT COUNT(DISTINCT Times.MapCourseID) "
..."FROM Times "
..."INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID "
..."INNER JOIN Maps ON Maps.MapID=MapCourses.MapID "
..."WHERE Maps.InRankedPool=1 AND MapCourses.Course=0 AND Times.SteamID32=%d AND Times.Mode=%d AND Times.Teleports=0";

char sql_getcount_bonuses[] = 
"SELECT COUNT(*) "
..."FROM MapCourses "
..."INNER JOIN Maps ON Maps.MapID=MapCourses.MapID "
..."WHERE Maps.InRankedPool=1 AND MapCourses.Course>0";

char sql_getcount_bonusescompleted[] = 
"SELECT COUNT(DISTINCT Times.MapCourseID) "
..."FROM Times "
..."INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID "
..."INNER JOIN Maps ON Maps.MapID=MapCourses.MapID "
..."WHERE Maps.InRankedPool=1 AND MapCourses.Course>0 AND Times.SteamID32=%d AND Times.Mode=%d";

char sql_getcount_bonusescompletedpro[] = 
"SELECT COUNT(DISTINCT Times.MapCourseID) "
..."FROM Times "
..."INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID "
..."INNER JOIN Maps ON Maps.MapID=MapCourses.MapID "
..."WHERE Maps.InRankedPool=1 AND MapCourses.Course>0 AND Times.SteamID32=%d AND Times.Mode=%d AND Times.Teleports=0";

char sql_gettopplayers[] = 
"SELECT Players.SteamID32, Players.Alias, COUNT(*) AS RecordCount "
..."FROM Times "
..."INNER JOIN "
..."(SELECT Times.MapCourseID, MIN(Times.RunTime) AS RecordTime "
..."FROM Times "
..."INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID "
..."INNER JOIN Maps ON Maps.MapID=MapCourses.MapID "
..."INNER JOIN Players ON Players.SteamID32=Times.SteamID32 "
..."WHERE Players.Cheater=0 AND Maps.InRankedPool=1 AND MapCourses.Course=0 AND Times.Mode=%d " // Doesn't include bonuses
..."GROUP BY Times.MapCourseID) Records "
..."ON Times.MapCourseID=Records.MapCourseID AND Times.RunTime=Records.RecordTime "
..."INNER JOIN Players ON Players.SteamID32=Times.SteamID32 "
..."GROUP BY Players.SteamID32, Players.Alias "
..."ORDER BY RecordCount DESC "
..."LIMIT %d";

char sql_gettopplayerspro[] = 
"SELECT Players.SteamID32, Players.Alias, COUNT(*) AS RecordCount "
..."FROM Times "
..."INNER JOIN "
..."(SELECT Times.MapCourseID, MIN(Times.RunTime) AS RecordTime "
..."FROM Times "
..."INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID "
..."INNER JOIN Maps ON Maps.MapID=MapCourses.MapID "
..."INNER JOIN Players ON Players.SteamID32=Times.SteamID32 "
..."WHERE Players.Cheater=0 AND Maps.InRankedPool=1 AND MapCourses.Course=0 AND Times.Mode=%d AND Times.Teleports=0 " // Doesn't include bonuses
..."GROUP BY Times.MapCourseID) Records "
..."ON Times.MapCourseID=Records.MapCourseID AND Times.RunTime=Records.RecordTime "
..."INNER JOIN Players ON Players.SteamID32=Times.SteamID32 "
..."GROUP BY Players.SteamID32, Players.Alias "
..."ORDER BY RecordCount DESC "
..."LIMIT %d";

char sql_getaverage[] = 
"SELECT AVG(PBTime), COUNT(*) "
..."FROM "
..."(SELECT MIN(Times.RunTime) AS PBTime "
..."FROM Times "
..."INNER JOIN MapCourses ON Times.MapCourseID=MapCourses.MapCourseID "
..."INNER JOIN Players ON Times.SteamID32=Players.SteamID32 "
..."WHERE Players.Cheater=0 AND MapCourses.MapID=%d AND MapCourses.Course=%d AND Times.Mode=%d "
..."GROUP BY Times.SteamID32) AS PBTimes";

char sql_getaverage_pro[] = 
"SELECT AVG(PBTime), COUNT(*) "
..."FROM "
..."(SELECT MIN(Times.RunTime) AS PBTime "
..."FROM Times "
..."INNER JOIN MapCourses ON Times.MapCourseID=MapCourses.MapCourseID "
..."INNER JOIN Players ON Times.SteamID32=Players.SteamID32 "
..."WHERE Players.Cheater=0 AND MapCourses.MapID=%d AND MapCourses.Course=%d AND Times.Mode=%d AND Times.Teleports=0 "
..."GROUP BY Times.SteamID32) AS PBTimes";

char sql_getrecentrecords[] = 
"SELECT Maps.Name, MapCourses.Course, MapCourses.MapCourseID, Players.Alias, a.RunTime "
..."FROM Times AS a "
..."INNER JOIN MapCourses ON a.MapCourseID=MapCourses.MapCourseID "
..."INNER JOIN Maps ON MapCourses.MapID=Maps.MapID "
..."INNER JOIN Players ON a.SteamID32=Players.SteamID32 "
..."WHERE Players.Cheater=0 AND a.Mode=%d "
..."AND NOT EXISTS "
..."(SELECT * "
..."FROM Times AS b "
..."WHERE a.MapCourseID=b.MapCourseID AND a.Mode=b.Mode AND a.Created>b.Created AND a.RunTime>b.RunTime) "
..."ORDER BY a.Created DESC "
..."LIMIT %d";

char sql_getrecentrecords_pro[] = 
"SELECT Maps.Name, MapCourses.Course, MapCourses.MapCourseID, Players.Alias, a.RunTime "
..."FROM Times AS a "
..."INNER JOIN MapCourses ON a.MapCourseID=MapCourses.MapCourseID "
..."INNER JOIN Maps ON MapCourses.MapID=Maps.MapID "
..."INNER JOIN Players ON a.SteamID32=Players.SteamID32 "
..."WHERE Players.Cheater=0 AND a.Mode=%d AND a.Teleports=0 "
..."AND NOT EXISTS "
..."(SELECT * "
..."FROM Times AS b "
..."WHERE b.Teleports=0 AND a.MapCourseID=b.MapCourseID AND a.Mode=b.Mode AND a.Created>b.Created AND a.RunTime>b.RunTime) "
..."ORDER BY a.Created DESC "
..."LIMIT %d"; 