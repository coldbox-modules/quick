component entityname="MyPost" table="my_posts" extends="quick.models.BaseEntity" {
    
    variables.key = "post_pk";

    function author() {
        return belongsTo( "User" );
    }

    function scopeLatest( builder ) {
        return builder.orderBy( "created_date", "desc" );
    }

}