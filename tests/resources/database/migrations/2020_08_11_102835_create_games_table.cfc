component {

    function up( schema, query ) {
        schema.create( "games", function( table ) {
            table.increments( "ID" );
            table.unsignedInteger( "fieldID" ).nullable();
            table.unsignedInteger( "clientID" ).nullable();
        } );
    }

    function down( schema, query ) {
        schema.drop( "games" );
    }

}
