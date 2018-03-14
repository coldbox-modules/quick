component entityname="MyPost" table="my_posts" extends="quick.models.BaseEntity" {

    variables.key = "post_pk";

    function author() {
        return belongsTo( "User" );
    }

    function tags() {
        return belongsToMany(
            relationName = "Tag",
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
