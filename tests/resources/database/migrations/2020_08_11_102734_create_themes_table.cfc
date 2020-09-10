component {

    function up( schema, query ) {
        schema.create( "themes", function( table ) {
            table.increments( "id" );
            table.string( "slug" );
            table.string( "version" );
            table.text( "config" ).nullable();
        } );
    }

    function down( schema, query ) {
        schema.drop( "themes" );
    }

}
