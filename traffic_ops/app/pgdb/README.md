PostgreSQL support for Traffic Ops.

Note: this is still very new - for now, MySQL is the safer choice!

##### To convert your existing database from MySQL
1. Set up pg environment
```
blah
```
2. Run FromMySqlToPostgreSql. See https://github.com/AnatolyUss/FromMySqlToPostgreSql for prereqs. The config file that worked for me:

```
{
    "source_description" : [
        "Connection string to your MySql database",
        "Please ensure, that you have defined your connection string properly.",
        "Ensure, that details like 'charset=UTF8' are included in your connection string (if necessary)."
    ],
    "source" : "mysql:host=localhost;port=3306;charset=UTF8;dbname=to_production,root,your_mysql_passwd",
    
    "target_description" : [
        "Connection string to your PostgreSql database",
        "Please ensure, that you have defined your connection string properly.",
        "Ensure, that details like options='[double dash]client_encoding=UTF8' are included in your connection string (if necessary)."
    ],
    "target" : "pgsql:host=localhost;port=5432;dbname=to_production;options=--client_encoding=UTF8,postgres,your_postgres_passwd",
    
    "encoding_description" : [
        "PHP encoding type.",
        "If not supplied, then UTF-8 will be used as a default."
    ],
    "encoding" : "UTF-8",
    
    "schema_description" : [
        "schema - a name of the schema, that will contain all migrated tables.",
        "If not supplied, then a new schema will be created automatically."
    ],
    "schema" : "public",
    
    "data_chunk_size_description" : [
        "During migration each table's data will be split into chunks of data_chunk_size (in MB).",
        "If not supplied, then 10 MB will be used as a default."
    ],
    "data_chunk_size" : 10
}
```
3. Fix goose table
``` 
more blah
```


Note that migrating views DOES NOT work with this tool, there's a small syntax error (too many levels of ()) in the conversion.

##### Migrating to the latest version with goose
Goose needs another option to migrate 
##### Running the tests and setting up you dev environment

##### TODO

1. create a pg version of dbadmin.pl
2. review database schema, and what can be made better (using migrations post MySQL conversion?)
  1. review varchar usage
  2. review smallint / integer usage (some are bools)
  3. use triggers for last_updated in stead of serials
  4. optimize indexes 
3. make it easier to switch environments ($ENV{} something?)
4. installer changes / seeds
5. ? 
