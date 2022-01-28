component {

    function up( schema, qb ) {
        schema.create( "offices", function( t ) {
            t.increments( "id" );
            t.string( "name" );
        } );

        qb.table( "offices" ).insert( [
            {
                "id": 1,
                "name": "Acme"
            },
            {
                "id": 2,
                "name": "Scranton"
            }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "offices" );
    }

}
