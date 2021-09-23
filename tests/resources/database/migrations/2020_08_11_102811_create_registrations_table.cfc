component {

    function up( sb, qb ) {
        sb.create( "registrations", function( t ) {
            t.increments( "registrationID" );
            t.unsignedInteger( "childID" );
        } );

        qb.table( "registrations" ).insert( [
            {
                "registrationID": 1,
                "childID": 1
            }
        ] );
    }

    function down( sb, qb ) {
        sb.drop( "registrations" );
    }

}
