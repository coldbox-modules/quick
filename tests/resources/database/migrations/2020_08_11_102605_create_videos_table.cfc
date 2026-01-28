component {

    function up( schema, qb ) {
        schema.create( "videos", function( t ) {
            t.increments( "id" );
            t.string( "url" );
            t.string( "title" );
            t.string( "description" );
            t.timestamp( "created_date" ).withCurrent();
            t.timestamp( "modified_date" ).withCurrent();
        } );

        qb.table( "videos" ).insert( [
            {
                "id": 1,
                "url": "https://www.youtube.com/watch?v=JDzIypmP0eo",
                "title": "Building KiteTail with Adam Wathan",
                "description": "Awesome live coding experience",
                "created_date": createDateTime( 2017, 06, 28, 02, 07, 36 ),
                "modified_date": createDateTime( 2017, 06, 30, 12, 17, 24 )
            },
            {
                "id": 1245,
                "url": "https://www.youtube.com/watch?v=BgAlQuqzl8o",
                "title": "Cello Wars",
                "description": "Star Wars Cello Parody",
                "created_date": createDateTime( 2017, 07, 02, 04, 14, 22 ),
                "modified_date": createDateTime( 2017, 07, 02, 04, 14, 22 )
            }
        ] );
    }

    function down( schema, query ) {
        schema.drop( "videos" );
    }

}
