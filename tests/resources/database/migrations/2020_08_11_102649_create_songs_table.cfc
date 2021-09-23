component {

    function up( sb, qb ) {
        sb.create( "songs", function( t ) {
            t.increments( "id" );
            t.string( "title" ).nullable();
            t.string( "download_url" );
            t.timestamp( "created_date" ).withCurrent();
            t.timestamp( "modified_date" ).withCurrent();
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
            },
            {
                "id": 3,
                "title": "I Wish I Was an Oscar Mayer Weiner",
                "download_url": "https://open.spotify.com/track/2wyg2ln6p4gEkdqM2mueLn?si=kWBpdUz1TLymdmTro-xjtw",
                "created_date": "2017-07-28 02:07:00",
                "modified_date": "2017-07-28 02:07:00"
            }
        ] );
    }

    function down( sb, qb ) {
        sb.drop( "songs" );
    }

}
