component extends="quick.models.BaseEntity" {

    property name="keyType" inject="UUID@quick" persistent="false";

    property name="id";
    property name="name";
    property name="createdDate" column="created_date";
    property name="modifiedDate" column="modified_date";

    variables.relationships = {
        "posts" = function() {
            return hasManyThrough( "Post", "User", "country_id", "user_id" );
        }
    };

}
