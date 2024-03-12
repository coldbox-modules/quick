component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="name";

    function posts() {
        return belongsToMany( "Post", "my_posts_tags", "tag_id", "custom_post_pk" );
    }

    function users() {
        return hasManyDeep(
            relationName = "User AS u",
            through = [ "my_posts_tags", "Post" ],
            foreignKeys = [ "tag_id", "post_pk", "id" ],
            localKeys = [ "id", "custom_post_pk", "user_id" ]
        ).distinct().orderBy( "u.id" );
    }

    function usersBuilder() {
        return newHasManyDeepBuilder()
            .throughPivotTable( "my_posts_tags", "tag_id", "id" )
            .throughEntity( "Post", "post_pk", "custom_post_pk" )
            .toRelated( "User as u", "id", "user_id" )
            .distinct().orderBy( "u.id" );
    }

}
