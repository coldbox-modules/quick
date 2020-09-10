component {

    function up( schema, query ) {
        schema.create( "comments", function( table ) {
            table.increments( "id" );
            table.text( "body" );
            table.unsignedInteger( "commentable_id" );
            table.string( "commentable_type" );
            table.string( "designation" ).default( "public" );
            table.unsignedInteger( "user_id" );
            table.timestamp( "created_date" ).withCurrent();
            table.timestamp( "modified_date" ).withCurrent();
        } );
    }

    function down( schema, query ) {
        schema.drop( "comments" );
    }

}
