component {

    function up( schema, query ) {
        schema.create( "products", function( table ) {
            table.increments( "ID" );
            table.string( "name" ).nullable();
            table.string( "type" ).nullable(); // ( books|music )
            table.string( "isbn" ).nullable(); // books only
            table.string( "artist" ).nullable(); // music only
            table.unsignedInteger( "user_id" ); // relationship to user
        } );
    }

    function down( schema, query ) {
        schema.drop( "products" );
    }

}
