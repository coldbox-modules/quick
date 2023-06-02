component table="my_posts" extends="Post" accessors="true" {

    function scopeWithAuthorLastName( qb ) {
        qb.addSubselect( "authorLastName", "author.lastname" );
    }       

    function applyGlobalScopes( qb ) {
        qb.withAuthorLastName();
    }
}
