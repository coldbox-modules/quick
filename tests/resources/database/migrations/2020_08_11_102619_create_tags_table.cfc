component {

    function up( schema, query ) {
        schema.create( "tags", function( table ) {
            table.increments( "id" );
            table.string( "name" );
        } );
    }

    function down( schema, query ) {
        schema.drop( "tags" );
    }

}
