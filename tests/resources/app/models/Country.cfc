component extends="quick.models.BaseEntity" {

    property name="id";
    property name="name";
    property name="createdDate" column="created_date";
    property name="modifiedDate" column="modified_date";

    function posts() {
        return hasManyThrough(
            relationName = "Post",
            intermediates = "User",
            foreignKeys = {
                "Post": "user_id"
                // `User` is left out here to show the defaults working
            },
            localKeys = {
                "User": "id",
                "Post": "post_pk"
            }
        );
    }

    function keyType() {
        return variables._wirebox.getInstance( "UUIDKeyType@quick" );
    }

}
