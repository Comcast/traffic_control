#!/bin/sh
#
# Copyright 2016 Comcast Cable Communications Management, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# convert.sh uses nmig to migrate a traffic_ops 1.x mysql database to the start of a 2.x
# postgres database.  It requires the nmig tool and node.js -- see
# https://github.com/AnatolyUSS/nmig for installation instructions.
#
# Once this conversion is complete, the goose migration tool will be used to move
# the database to the current migration level (see db/migrations/*).
if [ ! -d "$GOPATH/src/github.com/AnatolyUSS/nmig" ]
then
	echo "Expecting to find '$GOPATH/src/github.com/AnatolyUSS/nmig'"
	exit 1	
fi

# Modifications required on the mysql db for nmig to convert successfully: NOT NULL columns that have
# empty strings in some entries will fail,  so we change them to allow NULL and postrgres db can be
# updated later.
read -rp 'Mysql user: ' user
read -srp 'Password: ' pw
mysql -u"$user" -p"$pw" to_development || (echo "mysql update failed"; exit 1) <<MYSQL_COMMANDS
alter table parameter modify column value varchar(1024) null;
alter table parameter modify column value varchar(1024) null;
alter table phys_location
   modify column address varchar(128) null,
   modify column city varchar(128) null,
   modify column state varchar(2) null,
   modify column zip varchar(5) null;
alter table regex
   modify column pattern varchar(255) null;
alter table to_extension
   modify column version varchar(45) null,
   modify column info_url varchar(45) null,
   modify column script_file varchar(45) null;
MYSQL_COMMANDS

# TODO:  add username/passwd prompts for postgres here...
dropdb to_development
createdb to_development

cd "$GOPATH/src/github.com/AnatolyUSS/nmig"
rm -r logs_directory
node --expose-gc main.js
