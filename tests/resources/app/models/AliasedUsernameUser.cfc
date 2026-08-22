component extends="quick.models.BaseEntity" accessors="true" table="users" {

	property name="id";
	property name="username" column="first_name" sqltype="cf_sql_varchar";

}
