component extends="quick.models.BaseEntity" {

    function scopeLatest( builder ) {
        return builder.orderBy( "created_date", "desc" );
    }

    function posts() {
        return hasMany( "Post" );
    }

    function latestPost() {
        return hasOne( "Post" ).latest();
    }

}