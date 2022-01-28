component {

    function up( schema, qb ) {
        schema.create( "roles", function( t ) {
            t.increments( "id" );
            t.string( "name" );
        } );

        qb.table( "roles" ).insert( [
            { "id": 1, "name": "ADMIN" },
            { "id": 2, "name": "MODERATOR" },
            { "id": 3, "name": "USER" }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "roles" );
    }

}
