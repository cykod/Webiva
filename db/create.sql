

DROP TABLE IF EXISTS clients;
CREATE TABLE clients (
   id       INT            NOT NULL auto_increment,
   name    varchar(100)   NOT NULL,
   domain_limit INT       NOT NULL DEFAULT 1,
   primary key (id)
);

DROP TABLE IF EXISTS permissions;
CREATE TABLE `permissions` (
`perm_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
`perm_source` VARCHAR( 4 ) NOT NULL ,
`perm_source_id` INT NOT NULL ,
`perm_dest` VARCHAR( 4 ) NOT NULL ,
`perm_dest_id` INT NOT NULL ,
`perm_access` VARCHAR( 6 ) NOT NULL
) TYPE = MYISAM ;



DROP TABLE IF EXISTS users;
CREATE TABLE users (
   id       INT            NOT NULL auto_increment,
   username varchar(255)   NOT NULL,
   hashed_password varchar(64)    NOT NULL,
   client_id INT           NOT NULL DEFAULT 0,
   primary key (id)
);


CREATE TABLE `roles` (
`role_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,
`role_source` VARCHAR( 4 ) NOT NULL ,
`role_source_id` INT NOT NULL ,
`role_name` VARCHAR( 16 ) NOT NULL
) TYPE = MYISAM ;


ALTER TABLE `roles` ADD INDEX ( `role_name` ( 8 ) , `role_source` ( 4 ) , `role_source_id` );
ALTER TABLE `roles` ADD INDEX ( `role_source` , `role_source_id` ) ;



DROP TABLE IF EXISTS domains;
CREATE TABLE domains (
   id       INT         NOT NULL auto_increment,
   name     varchar(255) NOT NULL,
   client_id INT        NOT NULL DEFAULT 0,
   primary key (id)
);



DROP TABLE IF EXISTS access_groups;
CREATE TABLE access_groups (
   id      INT          NOT NULL auto_increment,
   name    varchar(255) NOT NULL,
   domain_id  INT       NOT NULL DEFAULT 0,
   client_id  INT       NOT NULL DEFAULT 0,
   primary key (id)
);

DROP TABLE IF EXISTS access_groups_users;
CREATE TABLE access_groups_users (
   id    INT         NOT NULL auto_increment,
   user_id INT       NOT NULL,
   access_group_id   int NOT NULL,
   primary key (id)
);


DROP TABLE IF EXISTS site_templates;
CREATE TABLE templates (
   id          INT     NOT NULL auto_increment,
   domain_id   INT     NOT NULL,
   name        varchar(255) NOT NULL DEFAULT '',
   template_body text    NOT NULL DEFAULT '',
   template_head text    NOT NULL DEFAULT '',
   primary key (id)
);

DROP TABLE IF EXISTS zones;
CREATE TABLE zones (
   id          INT    NOT NULL auto_increment,
   site_template_id INT    NOT NULL,
   zone_idx    INT    NOT NULL,
   name        varchar(255) NOT NULL,
   primary key (id)
);


DROP TABLE IF EXISTS page_folders;
CREATE TABLE page_folders (
   id          int   NOT NULL auto_increment,
   domain_id   int   NOT NULL,
   site_template_id int    NOT NULL,
   name        varchar(255) NOT NULL,
   parent_id  int NOT NULL DEFAULT 0,
   children_count int NOT NULL DEFAULT 0,
   primary key (id)
);


DROP TABLE IF EXISTS pages;
CREATE TABLE pages (
  id        int      NOT NULL auto_increment,
  domain_id int   NOT NULL,
  page_folder_id int      NOT NULL,
  name      VARCHAR(255) NOT NULL,
  language CHAR(2) NOT NULL DEFAULT 'fr',
  primary key (id)
);



DROP TABLE IF EXISTS page_revisions;
CREATE TABLE page_revisions (
  id        int      NOT NULL auto_increment,
  page_id   int      NOT NULL,
  site_template_id int NOT NULL,
  title     VARCHAR(255) NOT NULL,
  note      VARCHAR(255) NOT NULL DEFAULT '', 
  revision decimal(4,2) NOT NULL,
  active    tinyint(1) NOT NULL DEFAULT 0,
  primary key (id)
);


DROP TABLE IF EXISTS page_paragraphs;
CREATE TABLE page_paragraphs (
   id       int      NOT NULL auto_increment,
   page_revision_id int   NOT NULL,
   zone_idx int      NOT NULL,
   position INT NOT NULL DEFAULT 0,
   display_type enum('text','html','menu') NOT NULL DEFAULT 'text',
   display_body   text NOT NULL DEFAULT '',
   primary key (id)
);
   

