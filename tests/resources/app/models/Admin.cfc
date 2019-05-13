component extends="User" table="users" {

    function applyGlobalScopes() {
        this.withLatestPostId();
        this.ofType( "admin" );
    }

}
