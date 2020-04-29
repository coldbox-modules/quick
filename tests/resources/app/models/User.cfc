component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="username";
    property name="firstName" column="first_name";
    property name="lastName" column="last_name";
    property name="password";
    property name="countryId" column="country_id";
    property name="teamId" column="team_id";
    property name="createdDate" column="created_date";
    property name="modifiedDate" column="modified_date";
    property name="email" column="email" update="false" insert="true";
    property name="type";
    property name="externalID";

    property name="address" casts="AddressCast" persistent="false" getter="false";
    property name="streetOne";
    property name="streetTwo";
    property name="city";
    property name="state";
    property name="zip";

    function externalThings() { return hasMany( relationName = "externalThing", foreignKey = "externalID", localKey = "externalID" ); }

    function scopeLatest( qb ) {
        return qb.orderBy( "created_date", "desc" );
    }

    function scopeOfType( qb, type = "limited" ) {
        return qb.where( "type", type );
    }

    function scopeOfTypeWithWhen( qb, type ) {
        return qb.when( ! isNull( type ) && len( type ), function( q ) {
            q.ofType( type );
        } );
    }

    function scopeResetPasswords( qb ) {
        return qb.updateAll( { "password" = "" } ).result.recordcount;
    }

    function scopeWithLatestPostId() {
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

    function scopeWithLatestPostIdRelationship() {
        addSubselect(
            "latestPostId",
            this.ignoreLoadedGuard( function() {
                return this.withoutRelationshipConstraints( function() {
                    return this.posts()
                        .addCompareConstraints()
                        .latest()
                        .select( "post_pk" );
                } );
            } )
        );
    }

    function scopeWithLatestPostIdRelationshipShortcut() {
        addSubselect(
            "latestPostId",
            "posts.post_pk"
        );
    }

    function country() {
        return belongsTo( "Country", "country_id" );
    }

    function team() {
        return belongsTo( "Team", "team_id" );
    }

    function teammates() {
        return tap( hasManyThrough( [ "team", "users" ] ), function( r ) {
            r.where( r.qualifyColumn( "id" ), "<>", this.getId() );
        } );
    }

    function officemates() {
        return tap( hasManyThrough( [ "team", "office", "teams", "users" ] ), function( r ) {
            r.where( r.qualifyColumn( "id" ), "<>", this.getId() );
        } );
    }

    function officematesAlternate() {
        return tap( hasManyThrough( [ "team", "office", "users" ] ), function( r ) {
            r.where( r.qualifyColumn( "id" ), "<>", this.getId() );
        } );
    }

    function roles() {
        return belongsToMany( "Role" );
    }

    function permissions() {
        return hasManyThrough( [ "roles", "permissions" ] );
    }

    function posts() {
        return hasMany( "Post", "user_id" ).latest();
    }

    function publishedPosts() {
        return hasMany( "Post", "user_id" ).whereNotNull( "published_date" );
    }

    function latestPost() {
        return hasOne( "Post", "user_id" ).latest();
    }

    function latestPostWithEmptyDefault() {
        return hasOne( "Post", "user_id" ).latest().withDefault();
    }

    function latestPostWithDefaultAttributes() {
        return hasOne( "Post", "user_id" ).latest().withDefault( {
            "body": "Default Post"
        } );
    }

    function latestPostWithCallbackConfiguredDefault() {
        return hasOne( "Post", "user_id" ).latest().withDefault( function( post, user ) {
            post.setBody( user.getUsername() );
        } );
    }

}
