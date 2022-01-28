component {

    function up( schema, qb ) {
        schema.create( "permissions", function( t ) {
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

    function down( schema, qb ) {
        schema.drop( "permissions" );
    }

}
