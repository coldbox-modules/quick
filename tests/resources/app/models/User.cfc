component quick {

    property name="id";
    property name="username";
    property name="firstName" column="first_name";
    property name="lastName" column="last_name";
    property name="password";
    property name="countryId" column="country_id";
    property name="createdDate" column="created_date";
    property name="modifiedDate" column="modified_date";
    property name="email" column="email" update="false" insert="true";
    property name="type";

    function scopeLatest( query ) {
        return query.orderBy( "created_date", "desc" );
    }

    function scopeOfType( query, type = "limited" ) {
        return query.where( "type", type );
    }

    function scopeWithLatestPostId( query ) {
        addSubselect( "latestPostId", newEntity( "Post" )
            .select( "post_pk" )
            .whereColumn( "users.id", "user_id" )
            .latest() );

        /*
        // can also use closures
        addSubselect( "latestPostId", function( q ) {
            // you don't have to use an entity.
            // it just helps with scopes, column names, tables, etc.
            // there is also a query passed to you.
            return newEntity( "Post" )
                .select( "post_pk" )
                .whereColumn( "users.id", "userId" )
                .latest();
        } );
        */
    }

    function posts() {
        return hasMany( "Post", "user_id" );
    }

    function latestPost() {
        return hasOne( "Post", "user_id" ).latest();
    }

}
