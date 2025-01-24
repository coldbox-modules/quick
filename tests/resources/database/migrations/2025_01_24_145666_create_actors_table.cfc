component {

    function up( schema, qb ) {
        schema.create( "actors", function( t ) {
            t.guid( "id" ).primaryKey();
            t.string( "name" );
            t.timestamp( "created_date" ).withCurrent();
            t.timestamp( "modified_date" ).withCurrent();
        } );

        qb.table( "actors" ).insert( [
            {
                "id": "5B8A472F-56E8-4BD6-A03D-6157662937E3",
                "name": "Tom Anks",
                "created_date": "2017-07-28 02:07:00",
                "modified_date": "2017-07-28 02:07:00"
            }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "actors" );
    }

}
