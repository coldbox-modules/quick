component extends="User" table="users" accessors="true" {

    function applyGlobalScopes( qb ) {
        qb.withLatestPostId();
        qb.ofType( "admin" );
    }

}
