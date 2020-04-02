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
        return hasManyThrough(
            "Tag",
            [ "User", "Post" ],
            {
                "User": "countryId",
                "Post": "user_id",
                "Tag": "custom_post_pk"
            },
            {
                "User": "id",
                "Post": "post_pk",
                "Country": "id"
            }
        );
    }

    function comments() {
        return hasManyThrough(
            "Comment",
            [ "User", "Post" ],
            {
                "User": "countryId",
                "Post": "user_id",
                "Comment": "commentable_id"
            },
            {
                "User": "id",
                "Post": "post_pk",
                "Comment": "id"
            }
        );
    }

    function keyType() {
        return variables._wirebox.getInstance( "UUIDKeyType@quick" );
    }

}
