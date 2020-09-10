component {

    function up( schema, query ) {
        schema.create( "registrations", function( table ) {
            table.increments( "registrationID" );
            table.unsignedInteger( "childID" );
        } );
    }

    function down( schema, query ) {
        schema.drop( "registrations" );
    }

}
