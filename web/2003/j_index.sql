select picks.player_id, sum(teams.seed) as total from teams, picks 
	where teams.team = picks.winner 
	and picks.game like "%1_%" 
	group by picks.player_id 
	order by total desc;
