component {

    function up( schema, query ) {
        schema.create( "teams", function( table ) {
            table.increments( "id" );
            table.string( "name" );
            table.unsignedInteger( "officeId" );
        } );
    }

    function down( schema, query ) {
        schema.drop( "teams" );
    }

}
