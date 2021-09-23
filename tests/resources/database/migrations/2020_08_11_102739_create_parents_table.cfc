component {

    function up( sb, qb ) {
        sb.create( "parents", function( t ) {
            t.increments( "ID" );
            t.string( "firstname" );
            t.string( "lastname" );
        } );

        qb.table( "parents" ).insert( [
            {
                "ID": 1,
                "firstName": "Amy",
                "lastName": "Pond"
            },
            {
                "ID": 2,
                "firstName": "Rory",
                "lastName": "Williams"
            }
        ] );
    }

    function down( sb, qb ) {
        sb.drop( "parents" );
    }

}
