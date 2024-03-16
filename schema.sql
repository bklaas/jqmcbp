-- MySQL dump 10.13  Distrib 5.7.24, for Linux (x86_64)
--
-- Host: localhost    Database: johnnyquest
-- ------------------------------------------------------
-- Server version	5.5.5-10.3.39-MariaDB-0ubuntu0.20.04.2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `filter`
--

DROP TABLE IF EXISTS `filter`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `filter` (
  `name` varchar(20) NOT NULL DEFAULT '',
  `filter_id` smallint(6) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`filter_id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=4017 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `filter_link`
--

DROP TABLE IF EXISTS `filter_link`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `filter_link` (
  `filter_id` smallint(6) DEFAULT NULL,
  `player_id` smallint(6) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `games`
--

DROP TABLE IF EXISTS `games`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `games` (
  `game` varchar(12) NOT NULL DEFAULT '',
  `score` tinyint(4) DEFAULT NULL,
  `region` varchar(20) DEFAULT NULL,
  `round` tinyint(4) DEFAULT NULL,
  `upset` tinyint(4) DEFAULT NULL,
  `winner` varchar(25) DEFAULT NULL,
  `record_id` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`record_id`),
  KEY `game_index` (`game`)
) ENGINE=MyISAM AUTO_INCREMENT=1398 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `last_updated`
--

DROP TABLE IF EXISTS `last_updated`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `last_updated` (
  `last_updated` varchar(40) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `picks`
--

DROP TABLE IF EXISTS `picks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `picks` (
  `name` varchar(60) DEFAULT NULL,
  `game` varchar(25) DEFAULT NULL,
  `winner` varchar(25) DEFAULT NULL,
  `player_id` smallint(5) unsigned DEFAULT NULL,
  `record_id` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`record_id`),
  KEY `id_index` (`player_id`),
  KEY `name_index` (`name`),
  KEY `game_index` (`game`),
  KEY `winner_index` (`winner`)
) ENGINE=MyISAM AUTO_INCREMENT=1816323 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `player_info`
--

DROP TABLE IF EXISTS `player_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `player_info` (
  `name` varchar(60) DEFAULT NULL,
  `email` varchar(60) DEFAULT NULL,
  `candybar` varchar(60) DEFAULT NULL,
  `location` varchar(60) DEFAULT NULL,
  `gender` char(1) DEFAULT NULL,
  `date_created` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `player_id` smallint(6) NOT NULL AUTO_INCREMENT,
  `champion` varchar(60) DEFAULT NULL,
  `entry_time` int(11) DEFAULT NULL,
  `j_factor` decimal(4,2) DEFAULT NULL,
  `j2_factor` decimal(4,2) DEFAULT NULL,
  `how_found` varchar(50) DEFAULT NULL,
  `how_found_text` varchar(50) DEFAULT NULL,
  `years_played` tinyint(4) DEFAULT NULL,
  `man_or_chimp` enum('man','chimp','celebrity') DEFAULT NULL,
  `ff1` varchar(25) DEFAULT NULL,
  `ff2` varchar(25) DEFAULT NULL,
  `ff3` varchar(25) DEFAULT NULL,
  `ff4` varchar(25) DEFAULT NULL,
  `ff_man_neighbors` int(11) DEFAULT NULL,
  `ff_chimp_neighbors` int(11) DEFAULT NULL,
  `alma_mater` varchar(25) DEFAULT NULL,
  `past_champion` varchar(25) DEFAULT NULL,
  PRIMARY KEY (`player_id`)
) ENGINE=MyISAM AUTO_INCREMENT=28329 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `scores`
--

DROP TABLE IF EXISTS `scores`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scores` (
  `player_id` int(11) DEFAULT NULL,
  `step` int(11) DEFAULT NULL,
  `score` int(11) DEFAULT NULL,
  `rank` int(11) DEFAULT NULL,
  `darwin` int(11) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `rtt` int(11) DEFAULT NULL,
  `man_or_chimp` enum('man','chimp','celebrity') DEFAULT NULL,
  `rawnumber` int(11) DEFAULT NULL,
  `combined_rank` int(11) DEFAULT NULL,
  `eliminated` enum('y','n') DEFAULT 'n',
  KEY `p_id` (`player_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `similarity_index`
--

DROP TABLE IF EXISTS `similarity_index`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `similarity_index` (
  `first_player_id` int(11) NOT NULL,
  `second_player_id` int(11) NOT NULL,
  `score` int(11) NOT NULL,
  `similarity` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `teams`
--

DROP TABLE IF EXISTS `teams`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `teams` (
  `team` varchar(25) DEFAULT NULL,
  `team_id` int(11) NOT NULL DEFAULT 0,
  `spot` varchar(10) DEFAULT NULL,
  `seed` int(2) DEFAULT NULL,
  `bracket` tinyint(3) unsigned DEFAULT NULL,
  `bracket_name` varchar(10) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`team_id`),
  UNIQUE KEY `team_id` (`team_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2024-03-16 15:46:33
