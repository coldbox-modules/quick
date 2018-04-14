component extends="quick.models.BaseEntity" {

    property name="keyType" inject="UUID@quick" persistent="false";

    property name="id";
    property name="name";
    property name="createdDate" column="created_date";
    property name="modifiedDate" column="modified_date";

    function posts() {
        return hasManyThrough( "Post", "User" );
    }

}
