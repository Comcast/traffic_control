package sqlParser

import (
	"strings"
)

type ForeignKey struct {
	Table     string
	Column    string
	Alias     string
	ColValues map[string]interface{}
	//ColValues map[string]int
}

func MakeForeignKey(table string, column string, alias string) ForeignKey {
	colValues := GetForeignKeyValues(table, column)
	key := ForeignKey{table, column, alias, colValues}
	return key
}

func GetForeignKeyMap() map[string]ForeignKey {
	ForeignKeyMap := make(map[string]ForeignKey)

	//cachegroup.name
	key := MakeForeignKey("cachegroup", "name", "cachegroup_name")
	ForeignKeyMap["cachegroup"] = key

	//deliveryservice.xml_id
	key = MakeForeignKey("deliveryservice", "xml_id", "deliveryservice_name")
	ForeignKeyMap["deliveryservice"] = key
	ForeignKeyMap["job_deliveryservice"] = key

	//division.name
	key = MakeForeignKey("division", "name", "division_name")
	ForeignKeyMap["division"] = key

	//parameter.name
	key = MakeForeignKey("parameter", "name", "parameter_name")
	ForeignKeyMap["parameter"] = key

	//parent.cachegroup
	key = MakeForeignKey("cachegroup", "name", "parent_cachegroup")
	ForeignKeyMap["parent_cachegroup_id"] = key
	//phys_location.name!!
	key = MakeForeignKey("phys_location", "name", "phys_location_name")
	ForeignKeyMap["phys_location"] = key

	//profile.name
	key = MakeForeignKey("profile", "name", "profile_name")
	ForeignKeyMap["profile"] = key

	//regex.pattern
	key = MakeForeignKey("regex", "pattern", "regex_pattern")
	ForeignKeyMap["regex"] = key

	//region.name
	key = MakeForeignKey("region", "name", "region_name")
	ForeignKeyMap["region"] = key

	//status.name
	key = MakeForeignKey("status", "name", "status_name")
	ForeignKeyMap["status"] = key

	//server.host_name
	key = MakeForeignKey("server", "host_name", "server_name")
	ForeignKeyMap["serverid"] = key
	ForeignKeyMap["server"] = key

	//tm_user.username
	key = MakeForeignKey("tm_user", "username", "tm_user_username")
	ForeignKeyMap["tm_user"] = key
	ForeignKeyMap["tm_user_id"] = key
	ForeignKeyMap["job_user"] = key

	//type.name
	key = MakeForeignKey("type", "name", "type_name")
	ForeignKeyMap["type"] = key
	return ForeignKeyMap
}

//returns a map of each column name in table to its appropriate GoLang tpye (name string)
func GetColTypeMap() map[string]string {
	colMap := make(map[string]string, 0)

	cols, err := globalDB.Queryx("SELECT DISTINCT COLUMN_NAME, COLUMN_TYPE FROM information_schema.columns")
	check(err)

	for cols.Next() {
		var colName string
		var colType string

		err = cols.Scan(&colName, &colType)
		//split because SQL type returns are sometimes ex. int(11)
		colMap[colName] = strings.Split(colType, "(")[0]
	}

	return colMap
}

func GetTableMap() map[string][]string {
	var tableNames []string
	var tableMap = make(map[string][]string)

	tableRawBytes := make([]byte, 1)
	tableInterface := make([]interface{}, 1)

	tableInterface[0] = &tableRawBytes

	rows, err := globalDB.Query("SELECT TABLE_NAME FROM information_schema.tables where table_type='base table' or table_type='view'")
	check(err)

	for rows.Next() {
		err := rows.Scan(tableInterface...)
		check(err)

		tableNames = append(tableNames, string(tableRawBytes))
	}

	for _, table := range tableNames {
		rows, err = globalDB.Query("SELECT column_name from information_schema.columns where table_name='" + table + "' ORDER BY column_name asc")
		check(err)

		colMap := make([]string, 0)

		for rows.Next() {
			err = rows.Scan(tableInterface...)
			check(err)

			colMap = append(colMap, string(tableRawBytes))
		}

		tableMap[table] = colMap
	}
	return tableMap
}
