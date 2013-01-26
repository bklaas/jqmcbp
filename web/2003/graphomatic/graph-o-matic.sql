# ROUND SQL
select sum(games.score) as total, picks.name, player_info.player_id
 from games, picks, player_info
 where
 picks.game = games.game and
 picks.winner = games.winner and
 picks.name = player_info.name and
 (player_info.player_id = "NUMBER1" or player_info.player_id = "NUMBER2") and
 games.round = "ROUND"
 group by name;   

# REGION SQL
select sum(games.score) as total, picks.name, player_info.player_id
 from games, picks, player_info
 where
 picks.game = games.game and
 picks.winner = games.winner and
 picks.name = player_info.name and
 (player_info.player_id = "NUMBER1" or player_info.player_id = "NUMBER2") and
 games.region = "REGION"
 group by name;   
