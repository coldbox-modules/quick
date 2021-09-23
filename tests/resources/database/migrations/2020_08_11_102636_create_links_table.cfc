component {

    function up( sb, qb ) {
        sb.create( "links", function( t ) {
            t.increments( "link_id" );
            t.string( "link_url" );
            t.timestamp( "created_date" ).withCurrent();
            t.timestamp( "modified_date" ).withCurrent();
        } );

        qb.table( "links" ).insert( [
            {
                "link_id": 1,
                "link_url": "http://example.com/some-link",
                "created_date": "2017-07-28 02:07:00"
            }
        ] );
    }

    function down( sb, qb ) {
        sb.drop( "links" );
    }

}
