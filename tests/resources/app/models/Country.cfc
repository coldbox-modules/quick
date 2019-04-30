component extends="quick.models.BaseEntity" {

    property name="id";
    property name="name";
    property name="createdDate" column="created_date";
    property name="modifiedDate" column="modified_date";

    function posts() {
        return hasManyThrough( "Post", "User", "country_id", "user_id" );
    }

    function keyType() {
        return variables._wirebox.getInstance( "UUIDKeyType@quick" );
    }

}
