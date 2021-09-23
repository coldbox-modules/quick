component {

    function up( sb, qb ) {
        sb.create( "permissions", function( t ) {
            t.increments( "id" );
            t.string( "name" );
        } );
        
        qb.table( "permissions" ).insert( [
            {
                "id": 1,
                "name": "MANAGE_USERS"
            },
            {
                "id": 2,
                "name": "APPROVE_POSTS"
            }
        ] );
    }

    function down( sb, qb ) {
        sb.drop( "permissions" );
    }

}
