DROP TABLE IF EXISTS `progress`;
CREATE TABLE `progress` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pid` int(11) NOT NULL,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fill_state` varchar(50) DEFAULT NULL,
  `phase` varchar(50) DEFAULT NULL COMMENT 'phase of construction',
  `fillby` varchar(50) DEFAULT NULL COMMENT 'filled in by who',
  `phone` varchar(50) DEFAULT NULL,
  `progress` varchar(1000) DEFAULT NULL,
  `problem` varchar(1000) DEFAULT NULL,
  `invest_mon` varchar(50) DEFAULT NULL,
  `actual_start` varchar(50) DEFAULT NULL,
  `actual_finish` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=335 DEFAULT CHARSET=utf8;
