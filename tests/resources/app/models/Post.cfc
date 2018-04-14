component entityname="MyPost" table="my_posts" extends="quick.models.BaseEntity" {

    property name="post_pk";
    property name="userId" column="user_id";
    property name="body";
    property name="createdDate" column="created_date";
    property name="modifiedDate" column="modified_date";

    variables.key = "post_pk";

    function author() {
        return belongsTo( "User", "user_id" );
    }

    function tags() {
        return belongsToMany(
            relationName = "Tag",
            relatedKey = "tag_id",
            foreignKey = "post_pk"
        );
    }

    function comments() {
        return polymorphicHasMany( "Comment", "commentable" );
    }

    function scopeLatest( query ) {
        return query.orderBy( "created_date", "desc" );
    }

}
