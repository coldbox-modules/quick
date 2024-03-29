component {

    function up( schema, qb ) {
        schema.create( "playing_fields", function( t ) {
            t.unsignedInteger( name = "fieldID", autoIncrement = true );
            t.unsignedInteger( "clientID" ).nullable();
            t.string( "fieldName" );
            t.primaryKey( [ "fieldID", "clientID" ] );
        } );

        qb.table( "playing_fields" ).insert( [
                {
                    "fieldID": 1,
                    "clientID": 1,
                    "fieldName": "First Field"
                },
                {
                    "fieldID": 1,
                    "clientID": 2,
                    "fieldName": "Second Field"
                }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "playing_fields" );
    }

}
