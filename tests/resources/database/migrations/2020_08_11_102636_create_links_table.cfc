component {

    function up( schema, query ) {
        schema.create( "links", function( table ) {
            table.increments( "link_id" );
            table.string( "link_url" );
            table.timestamp( "created_date" ).withCurrent();
            table.timestamp( "modified_date" ).withCurrent();
        } );
    }

    function down( schema, query ) {
        schema.drop( "links" );
    }

}
