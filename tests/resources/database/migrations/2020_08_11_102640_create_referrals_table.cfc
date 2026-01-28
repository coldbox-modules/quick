component {

    function up( schema, qb ) {
        schema.create( "referrals", function( t ) {
            t.increments( "id" );
            t.string( "type" );
            t.timestamp( "created_date" ).withCurrent();
            t.timestamp( "modified_date" ).withCurrent();
        } );

        qb.table( "referrals" ).insert( [
            {
                "id": 1,
                "type": "external",
                "created_date": createDateTime( 2017, 07, 28, 02, 07, 00 ),
                "modified_date": createDateTime( 2017, 07, 28, 02, 07, 00 )
            }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "referrals" );
    }

}
