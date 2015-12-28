PostgreSQL support for Traffic Ops.

Note: this is still very new - for now, MySQL is the safer choice!

### To convert your database from MySQL


### migrating with goose

### Running the tests and setting up you dev environment

### TODO
# create a pg version of dbadmin.pl
# review database schema, and what can be made better (using migrations post MySQL conversion?)
## review varchar usage
## review smallint / integer usage (some are bools)
## use triggers for last_updated in stead of serials
## optimize indexes 
# make it easier to switch environments ($ENV{} something?)
