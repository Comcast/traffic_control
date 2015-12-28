PostgreSQL support for Traffic Ops.

Note: this is still very new - for now, MySQL is the safer choice!

##### To convert your database from MySQL

##### Migrating with goose

##### Running the tests and setting up you dev environment

##### TODO

1. create a pg version of dbadmin.pl
2. review database schema, and what can be made better (using migrations post MySQL conversion?)
2.1 review varchar usage
2.2 review smallint / integer usage (some are bools)
2.3 use triggers for last_updated in stead of serials
2.4 optimize indexes 
3. make it easier to switch environments ($ENV{} something?)
4. installer changes / seeds
5. ? 
