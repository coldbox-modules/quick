component extends="quick.models.BaseEntity" attributecasing="snake" {

    function scopeLatest( builder ) {
        return builder.orderBy( "created_date", "desc" );
    }

    function posts() {
        return hasMany( "Post" );
    }

    function latestPost() {
        return hasOne( "Post", "post_pk" ).latest();
    }

}