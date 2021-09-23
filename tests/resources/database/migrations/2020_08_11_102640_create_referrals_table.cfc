component {

    function up( sb, qb ) {
        sb.create( "referrals", function( t ) {
            t.increments( "id" );
            t.string( "type" );
            t.timestamp( "created_date" ).withCurrent();
            t.timestamp( "modified_date" ).withCurrent();
        } );

        qb.table( "referrals" ).insert( [
            {
                "id": 1,
                "type": "external",
                "created_date": "2017-07-28 02:07:00",
                "modified_date": "2017-07-28 02:07:00"
            }
        ] );
    }

    function down( sb, qb ) {
        sb.drop( "referrals" );
    }

}
