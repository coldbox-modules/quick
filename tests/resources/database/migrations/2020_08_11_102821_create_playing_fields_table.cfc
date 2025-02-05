component {

    function up( schema, qb ) {
        schema.create( "playing_fields", function( t ) {
            t.unsignedInteger( name = "fieldID", autoIncrement = true );
            t.unsignedInteger( "clientID" ).nullable();
            t.string( "fieldName" );
            t.primaryKey( [ "fieldID", "clientID" ] );
            t.uuid( "country_id" ).nullable();
        } );

        qb.table( "playing_fields" ).insert( [
                {
                    "fieldID": 1,
                    "clientID": 1,
                    "fieldName": "First Field",
                    "country_id": "02B84D66-0AA0-F7FB-1F71AFC954843861" // United States
                },
                {
                    "fieldID": 1,
                    "clientID": 2,
                    "fieldName": "Second Field",
                    "country_id": "02BA2DB0-EB1E-3F85-5F283AB5E45608C6" // Argentina
                }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "playing_fields" );
    }

}
