component {

    function up( schema, query ) {
        schema.create( "roles", function( table ) {
            table.increments( "id" );
            table.string( "name" );
        } );
    }

    function down( schema, query ) {
        schema.drop( "roles" );
    }

}
