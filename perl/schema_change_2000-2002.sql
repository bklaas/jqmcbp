use johnnyquest;

create table picks
(
	name varchar(60),
	game varchar(25) NOT NULL,
        winner varchar(25)
);

create table player_info
(
	name varchar(60),
	email varchar(60),
	candybar varchar(60),
	location varchar(60),
	gender char(1),
	date_created timestamp(10),
	player_id smallint(6) AUTO_INCREMENT PRIMARY KEY,
        champion varchar(60)
);
        
	
