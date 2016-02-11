-- MySQL dump 10.13  Distrib 5.5.40, for debian-linux-gnu (x86_64)
--
-- Host: currentdb    Database: kids_toys_development
-- ------------------------------------------------------
-- Server version	5.5.40-0ubuntu0.14.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `categories`
--

DROP TABLE IF EXISTS `categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `level` int(11) DEFAULT '1',
  `level_order` int(11) DEFAULT '0',
  `parent_category_id` int(11) DEFAULT NULL,
  `full_path_ids` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `male_index` int(11) DEFAULT '1234567',
  `female_index` int(11) DEFAULT '1234567',
  PRIMARY KEY (`id`),
  KEY `index_categories_on_parent_category_id` (`parent_category_id`),
  KEY `index_categories_on_level` (`level`),
  KEY `index_categories_on_male_index` (`male_index`),
  KEY `index_categories_on_female_index` (`female_index`)
) ENGINE=InnoDB AUTO_INCREMENT=200001 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `categories`
--

LOCK TABLES `categories` WRITE;
/*!40000 ALTER TABLE `categories` DISABLE KEYS */;
INSERT INTO `categories` VALUES (10000,'Action Toys',1,0,NULL,NULL,'2014-03-27 20:45:12','2014-07-25 14:38:30',100,1234567),(11000,'Star Wars',0,0,NULL,'11000','0000-00-00 00:00:00','0000-00-00 00:00:00',200,1234567),(20000,'Dolls',1,0,NULL,NULL,'2014-03-27 20:45:13','2014-05-28 03:32:14',1234567,100),(21000,'Animals',0,0,NULL,NULL,'0000-00-00 00:00:00','0000-00-00 00:00:00',850,700),(22000,'Barbie',0,0,NULL,NULL,'0000-00-00 00:00:00','0000-00-00 00:00:00',1234567,90),(23000,'Disney',0,0,NULL,NULL,'0000-00-00 00:00:00','0000-00-00 00:00:00',1234567,110),(30000,'Video Games',1,0,NULL,NULL,'2014-03-27 20:45:13','2014-03-27 20:45:13',501,1234567),(40000,'Cars/Trucks',1,0,NULL,NULL,'2014-03-27 20:45:14','2014-05-28 03:33:28',600,1234567),(41000,'Collectibles',0,0,NULL,NULL,'0000-00-00 00:00:00','0000-00-00 00:00:00',1234567,610),(50000,'Books',1,0,NULL,NULL,'2014-03-27 20:45:14','2014-05-28 03:34:10',901,400),(60000,'Clothes',1,0,NULL,NULL,'2014-03-27 20:45:14','2014-05-28 03:21:29',1234567,1000),(70000,'Games/Puzzles',1,0,NULL,NULL,'2014-03-27 20:45:14','2014-05-28 03:34:57',701,900),(80000,'Sports',1,0,NULL,NULL,'2014-03-27 20:45:14','2014-05-28 03:35:30',500,1100),(90000,'LEGOs',1,0,NULL,NULL,'2014-03-27 20:45:15','2014-05-28 03:36:07',90,800),(100000,'Trading Cards',1,0,NULL,NULL,'2014-07-25 14:37:55','2014-07-25 14:37:55',801,1234567),(110000,'Arts & Crafts',1,0,NULL,NULL,'2014-07-25 14:40:14','2014-07-25 14:40:14',1100,500),(200000,'Other',1,0,NULL,NULL,'2014-07-25 14:42:08','2014-07-25 14:42:08',900,1500);
/*!40000 ALTER TABLE `categories` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-12-29 21:37:04
