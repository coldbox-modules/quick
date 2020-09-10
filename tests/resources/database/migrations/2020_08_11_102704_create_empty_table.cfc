component {

    function up( schema, query ) {
        schema.create( "empty", function( table ) {
            table.increments( "id" );
        } );
    }

    function down( schema, query ) {
        schema.drop( "empty" );
    }

}
