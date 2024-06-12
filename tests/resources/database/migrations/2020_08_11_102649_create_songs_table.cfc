component {

    function up( schema, qb ) {
        schema.create( "songs", function( t ) {
            t.increments( "id" );
            t.string( "title" ).nullable();
            t.string( "download_url" );

            t.raw( "`created_date` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)" );
            t.raw( "`modified_date` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)" );

            //proposed qb pull request https://github.com/coldbox-modules/qb/pull/282:
            //t.timestamp( "created_date", 6 ).withCurrent( 6 );
            //t.timestamp( "modified_date", 6 ).withCurrent( 6 );
        } );

        qb.table( "songs" ).insert( [
            {
                "id": 1,
                "title": "Ode to Joy",
                "download_url": "https://open.spotify.com/track/4Nd5HJn4EExnLmHtClk4QV",
                "created_date": "2017-07-28 02:07:00",
                "modified_date": "2017-07-28 02:07:00"
            },
            {
                "id": 2,
                "title": "Open Arms",
                "download_url": "https://open.spotify.com/track/1m2INxep6LfNa25OEg5jZl",
                "created_date": "2017-07-28 02:07:00",
                "modified_date": "2017-07-28 02:07:00"
            }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "songs" );
    }

}
