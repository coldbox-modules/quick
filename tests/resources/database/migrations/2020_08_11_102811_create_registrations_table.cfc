component {

    function up( schema, qb ) {
        schema.create( "registrations", function( t ) {
            t.increments( "registrationID" );
            t.unsignedInteger( "childID" );
        } );

        qb.table( "registrations" ).insert( [
            { "registrationID": 1, "childID": 1 }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "registrations" );
    }

}
