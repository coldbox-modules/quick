component extends="quick.models.BaseEntity" {

    property name="number" sqltype="cf_sql_varchar" convertToNull="false";
    property name="active" casts="boolean";

}
