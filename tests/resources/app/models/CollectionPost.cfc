component table="my_posts" extends="quick.models.BaseEntity" accessors="true" {

    property name="post_pk";
    property name="userId" column="user_id";
    property name="body";
    property name="createdDate" column="created_date";
    property name="modifiedDate" column="modified_date";

    variables._key = "post_pk";

    function author() {
        return belongsTo( "User", "user_id" );
    }

    function tags() {
        return belongsToMany( "Tag", "my_posts_tags", "custom_post_pk", "tag_id" );
    }

    function comments() {
        return polymorphicHasMany( "Comment", "commentable" );
    }

    function scopeLatest( query ) {
        return query.orderBy( "created_date", "desc" );
    }

    function newCollection( array entities = [] ) {
        return variables._wirebox.getInstance(
            name = "extras.QuickCollection",
            initArguments = {
                "collection" = arguments.entities
            }
        );
    }

}
