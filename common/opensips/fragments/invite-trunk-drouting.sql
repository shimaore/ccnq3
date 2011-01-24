--
-- List of gateways
-- Note: we are not using the full feature here.
--       We assume a single configuration per address.

INSERT INTO version (table_name, table_version) values ('dr_gateways','3');
CREATE TABLE dr_gateways (
    gwid INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
    type INT(11) UNSIGNED DEFAULT 0 NOT NULL,
    address CHAR(128) NOT NULL,
    strip INT(11) UNSIGNED DEFAULT 0 NOT NULL,
    pri_prefix CHAR(16) DEFAULT NULL,
    attrs CHAR(255) DEFAULT NULL,
    description CHAR(128) DEFAULT '' NOT NULL
);

--
-- Rules for drouting
-- Note: we currently do not use timerec.
--       also, needs to figure out a way to do gwlist using the GUI.

INSERT INTO version (table_name, table_version) values ('dr_rules','2');
CREATE TABLE dr_rules (
    ruleid INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
    groupid CHAR(255) NOT NULL,
    prefix CHAR(64) NOT NULL,
    timerec CHAR(255) NOT NULL,
    priority INT(11) DEFAULT 0 NOT NULL,
    routeid INT(11) UNSIGNED DEFAULT 0 NOT NULL,
    gwlist CHAR(255) NOT NULL,
    description CHAR(128) DEFAULT '' NOT NULL
);

--
-- We're not using this table.
--
INSERT INTO version (table_name, table_version) values ('dr_gw_lists','1');
CREATE TABLE dr_gw_lists (
    id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
    gwlist CHAR(255) NOT NULL,
    description CHAR(128) DEFAULT '' NOT NULL
);
