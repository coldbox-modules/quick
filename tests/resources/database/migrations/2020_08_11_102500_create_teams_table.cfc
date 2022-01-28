component {

    function up( schema, qb ) {
        schema.create( "teams", function( t ) {
            t.increments( "id" );
            t.string( "name" );
            t.unsignedInteger( "officeId" );
        } );

        qb.table( "teams" ).insert( [
            {
                "id": 1,
                "name": "Engineering",
                "officeId": 1
            },
            {
                "id": 2,
                "name": "Management",
                "officeId": 1
            },
            {
                "id": 3,
                "name": "Liabilities",
                "officeId": 2
            }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "teams" );
    }

}
