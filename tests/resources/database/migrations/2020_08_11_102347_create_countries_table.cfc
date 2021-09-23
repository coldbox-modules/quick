component {

    function up( sb, qb ) {
        sb.create( "countries", function( t ) {
            t.uuid( "id" ).primaryKey();
            t.string( "name" );
            t.timestamp( "created_date" ).withCurrent();
            t.timestamp( "modified_date" ).withCurrent();
        } );

        qb.table( "countries" ).insert( [
            {
                "id": "02B84D66-0AA0-F7FB-1F71AFC954843861",
                "name": "United States",
                "created_date": "2017-07-28 02:07:00",
                "modified_date": "2017-07-28 02:07:00"
            },
            {
                "id": "02BA2DB0-EB1E-3F85-5F283AB5E45608C6",
                "name": "Argentina",
                "createdDate": "2017-07-29 03:07:00",
                "modifiedDate": "2017-07-29 03:07:00"
            }
        ] );
    }

    function down( sb, qb ) {
        sb.drop( "countries" );
    }

}
