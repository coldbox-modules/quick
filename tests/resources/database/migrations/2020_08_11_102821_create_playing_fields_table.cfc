component {

    function up( schema, query ) {
        schema.create( "playing_fields", function( table ) {
            table.unsignedInteger( name = "fieldID", autoIncrement = true );
            table.unsignedInteger( "clientID" ).nullable();
            table.string( "fieldName" );
            table.primaryKey( [ "fieldID", "clientID" ] );
        } );
    }

    function down( schema, query ) {
        schema.drop( "playing_fields" );
    }

}
