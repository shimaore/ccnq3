-- generic.sql -- SQL tables creation
-- Copyright (C) 2009  Stephane Alnet
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

--
-- Table structure versions
--
-- standard-create.sql
CREATE TABLE version (
    table_name CHAR(32) NOT NULL,
    table_version INT UNSIGNED DEFAULT 0 NOT NULL,
    CONSTRAINT t_name_idx UNIQUE (table_name)
);

-- These tables are provisioned.

--
-- Table structure for table 'avpops'
--
-- avpops-create.sql
INSERT INTO version (table_name, table_version) values ('avpops','3');
CREATE TABLE avpops (
    id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
    uuid CHAR(64) DEFAULT '' NOT NULL,
    username CHAR(128) DEFAULT 0 NOT NULL,
    domain CHAR(64) DEFAULT '' NOT NULL,
    attribute CHAR(32) DEFAULT '' NOT NULL,
    type INT(11) DEFAULT 0 NOT NULL,
    value CHAR(128) DEFAULT '' NOT NULL,
    last_modified DATETIME DEFAULT '1900-01-01 00:00:01' NOT NULL
);

CREATE INDEX ua_idx ON avpops (uuid, attribute);
CREATE INDEX uda_idx ON avpops (username, domain, attribute);
CREATE INDEX value_idx ON avpops (value);

if need_trusted
--
-- Table structure for table trusted
-- permissions-create.sql
INSERT INTO version (table_name, table_version) values ('trusted','5');
CREATE TABLE trusted (
    id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
    -- grp
    ip CHAR(50) NOT NULL,
    -- mask
    -- port
    proto CHAR(4) NOT NULL,
    pattern CHAR(64) DEFAULT NULL,
    context_info CHAR(32)
);

CREATE INDEX peer_idx ON trusted (ip);

-- USE trusted_reload (MI) TO RELOAD
end if need_trusted

if need_address
INSERT INTO version (table_name, table_version) values ('address','4');
CREATE TABLE address (
    id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
    grp SMALLINT(5) UNSIGNED DEFAULT 0 NOT NULL,
    ip CHAR(15) NOT NULL,
    mask TINYINT DEFAULT 32 NOT NULL,
    port SMALLINT(5) UNSIGNED DEFAULT 0 NOT NULL
    -- proto
    -- pattern
    -- context_info
);

-- USE address_reload (MI) TO RELOAD
end if need_address

--
-- Table structure for table 'domain' -- domains this proxy is responsible for
--
-- domain-create.sql
INSERT INTO version (table_name, table_version) values ('domain','2');
CREATE TABLE domain (
    id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
    domain CHAR(64) DEFAULT '' NOT NULL,
    last_modified DATETIME DEFAULT '1900-01-01 00:00:01' NOT NULL,
    CONSTRAINT domain_idx UNIQUE (domain)
);

-- END
