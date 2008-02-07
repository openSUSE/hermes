DROP TABLE IF EXISTS `persons`;
CREATE TABLE `persons` (
  `id` int NOT NULL auto_increment,
  `email` VARCHAR(255),
  `name`  VARCHAR(255),

  PRIMARY KEY(`id`)
) ENGINE=MyISAM AUTO_INCREMENT=123 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `addresses`;
CREATE TABLE `addresses` (
  `id` int NOT NULL auto_increment,
  `msg_id` int NOT NULL,
  `person_id` int NOT NULL,
  `header` enum('to','cc','bcc','reply-to') NOT NULL default 'to',

  PRIMARY KEY (`id`),

  INDEX  (`msg_id`,`person_id`,`header`)
) ENGINE=MyISAM AUTO_INCREMENT=123 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `messages`;
CREATE TABLE `messages` (
  `id` int NOT NULL auto_increment,
  `msg_type_id` int NOT NULL,
  `sender` varchar(255) default NULL,
  `subject` varchar(128) default NULL,
  `body` mediumtext,
  `delay` tinyint(4) NOT NULL default '0',
  `created` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `sent` timestamp NOT NULL default '0000-00-00 00:00:00',

  constraint fk_messages_msgtype foreign key(msg_type_id) references msg_types(id),

  PRIMARY KEY  (`id`),

  INDEX( `sender`),
  INDEX( `delay`),
  INDEX( `created`, `sent`)

) ENGINE=MyISAM DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `msg_types`;
CREATE TABLE `msg_types` (
  `id` int NOT NULL auto_increment,
  `msgtype` VARCHAR(64) default NULL,
  `added`   timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
   
  PRIMARY KEY(`id`),
  INDEX(`msgtype`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

