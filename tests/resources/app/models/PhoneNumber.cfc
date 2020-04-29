component extends="quick.models.BaseEntity" accessors="true" {

    property name="number" sqltype="cf_sql_varchar" convertToNull="false";
    property name="active" casts="BooleanCast@quick";

}
