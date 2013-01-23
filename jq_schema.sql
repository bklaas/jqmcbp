
DROP TABLE IF EXISTS `player_info`;
CREATE TABLE `player_info` (
  `name` varchar(60) default NULL,
  `email` varchar(60) default NULL,
  `candybar` varchar(60) default NULL,
  `location` varchar(60) default NULL,
  `gender` char(1) default NULL,
  `date_created` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `player_id` smallint(6) NOT NULL auto_increment,
  `champion` varchar(60) default NULL,
  `entry_time` int(11) default NULL,
  `j_factor` decimal(3,2) default NULL,
  `j2_factor` decimal(3,2) default NULL,
  `how_found` varchar(50) default NULL,
  `how_found_text` varchar(50) default NULL,
  `years_played` tinyint(4) default NULL,
  `man_or_chimp` enum('man','chimp') default 'man',
  PRIMARY KEY  (`player_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
