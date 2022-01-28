component {

    function up( schema, qb ) {
        schema.create( "jingles", function( t ) {
            t.unsignedInteger( "FK_song" )
                .references( "id" )
                .onTable( "songs" )
                .onUpdate( "CASCADE" )
                .onDelete( "CASCADE" );
            t.integer( "catchiness" );
            t.primaryKey( "FK_song" );
        } );

        qb.newQuery().table( "songs" ).insert( [
            {
                "id": 3,
                "title": "I Wish I Was an Oscar Mayer Weiner",
                "download_url": "https://open.spotify.com/track/2wyg2ln6p4gEkdqM2mueLn?si=kWBpdUz1TLymdmTro-xjtw",
                "created_date": "2017-07-28 02:07:00",
                "modified_date": "2017-07-28 02:07:00"
            }
        ] );

        qb.newQuery().table( "jingles" ).insert( [
            {
                "FK_song": 3,
                "catchiness": 3
            }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "jingles" );
        qb.table( "songs" ).where( "id", 3 ).delete();
    }

}
