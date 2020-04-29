component extends="User" table="users" accessors="true" {

    function applyGlobalScopes() {
        this.withLatestPostId();
        this.ofType( "admin" );
    }

}
