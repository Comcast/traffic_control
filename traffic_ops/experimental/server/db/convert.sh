#!/bin/sh

if [ ! -d "$GOPATH/src/github.com/AnatolyUSS/nmig" ]
then
	echo "Expecting to find '$GOPATH/src/github.com/AnatolyUSS/nmig'"
	exit 1	
fi

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

dropdb to_development
createdb to_development

rm -r logs_directory
node --expose-gc main.js
