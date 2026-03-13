DROP TABLE IF EXISTS `similarity_index`;
CREATE TABLE `similarity_index` (
  `first_player_id` int(11) NOT NULL,
  `second_player_id` int(11) NOT NULL,
  `score` int(11) NOT NULL,
  `similarity` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

