component extends="quick.models.BaseEntity" {

    property name="id";
    property name="name";
    property name="createdDate" column="created_date";
    property name="modifiedDate" column="modified_date";

    function users() {
        return hasMany( "User" );
    }

    function posts() {
        return hasManyThrough( [ "users", "posts" ] );
    }

    function tags() {
        return hasManyThrough( [ "users", "posts", "tags" ] );
    }

    function comments() {
        return hasManyThrough( [ "users", "posts", "comments" ] );
    }

    function keyType() {
        return variables._wirebox.getInstance( "UUIDKeyType@quick" );
    }

}
