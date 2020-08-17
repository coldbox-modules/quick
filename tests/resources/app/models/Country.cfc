component extends="quick.models.BaseEntity" accessors="true" {

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

    function latestPost() {
        return hasOneThrough( [ "users", "posts" ] ).latest();
    }

    function tags() {
        return hasManyThrough( [ "users", "posts", "tags" ] );
    }

    function comments() {
        return hasManyThrough( [ "users", "posts", "comments" ] ).where( 'designation', 'public' );
    }

    function commentsUsingHasManyThrough() {
        return hasManyThrough( [ "posts", "comments" ] ).where( 'designation', 'public' );
    }

    function roles() {
        return hasManyThrough( [ "users", "roles" ] );
    }

    function permissions() {
        return hasManyThrough( [ "roles", "permissions" ] );
    }

    function keyType() {
        return variables._wirebox.getInstance( "UUIDKeyType@quick" );
    }

}
