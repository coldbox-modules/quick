component {

    function up( schema, query ) {
        schema.create( "parents", function( table ) {
            table.increments( "ID" );
            table.string( "firstname" );
            table.string( "lastname" );
        } );
    }

    function down( schema, query ) {
        schema.drop( "parents" );
    }

}
