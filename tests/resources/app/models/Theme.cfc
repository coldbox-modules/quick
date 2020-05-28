component extends="quick.models.BaseEntity" accessors="true" {

	property name="id";
    property name="slug";
    property name="version" sqltype="cf_sql_varchar";
    property name="config" casts="JsonCast@quick";

}
