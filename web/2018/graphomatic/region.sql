# REGION SQL
select picks.player_id as name, games.region, sum(games.score) as total
 from games, picks, player_info
 where
 picks.game = games.game and
 picks.winner = games.winner and
 picks.name = player_info.name and
 (player_info.player_id = 'NUMBER1' or player_info.player_id = 'NUMBER2') and
 games.region = 'REGION'
 group by name order by player_info.player_id
