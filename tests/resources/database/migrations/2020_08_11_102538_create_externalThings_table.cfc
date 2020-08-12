component {

    function up( schema, query ) {
        schema.create( "externalThings", function( table ) {
            table.increments( "thingId" );
            table.unsignedInteger( "userId" );
            table.string( "externalId" );
            table.string( "value" ).nullable();
        } );
    }

    function down( schema, query ) {
        schema.drop( "externalThings" );
    }

}
