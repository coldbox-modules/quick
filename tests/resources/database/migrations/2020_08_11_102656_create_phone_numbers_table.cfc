component {

    function up( schema, query ) {
        schema.create( "phone_numbers", function( table ) {
            table.increments( "id" );
            table.string( "number" );
            table.boolean( "active" ).nullable();
        } );
    }

    function down( schema, query ) {
        schema.drop( "phone_numbers" );
    }

}
