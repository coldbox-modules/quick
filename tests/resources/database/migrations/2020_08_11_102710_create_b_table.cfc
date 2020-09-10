component {

    function up( schema, query ) {
        schema.create( "b", function( table ) {
            table.increments( "id" );
            table.unsignedInteger( "a_id" ).nullable();
            table.string( "name" );
        } );
    }

    function down( schema, query ) {
        schema.drop( "b" );
    }

}
