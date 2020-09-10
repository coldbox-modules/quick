component {

    function up( schema, query ) {
        schema.create( "songs", function( table ) {
            table.increments( "id" );
            table.string( "title" ).nullable();
            table.string( "download_url" );
            table.timestamp( "created_date" ).withCurrent();
            table.timestamp( "modified_date" ).withCurrent();
        } );
    }

    function down( schema, query ) {
        schema.drop( "songs" );
    }

}
