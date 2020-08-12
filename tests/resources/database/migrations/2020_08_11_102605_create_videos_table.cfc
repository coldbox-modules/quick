component {

    function up( schema, query ) {
        schema.create( "videos", function( table ) {
            table.increments( "id" );
            table.string( "url" );
            table.string( "title" );
            table.string( "description" );
            table.timestamp( "created_date" ).withCurrent();
            table.timestamp( "modified_date" ).withCurrent();
        } );
    }

    function down( schema, query ) {
        schema.drop( "videos" );
    }

}
