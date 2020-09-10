component {

    function up( schema, query ) {
        schema.create( "my_posts", function( table ) {
            table.increments( "post_pk" );
            table.unsignedInteger( "user_id" ).nullable();
            table.text( "body" );
            table.timestamp( "created_date" ).withCurrent();
            table.timestamp( "modified_date" ).withCurrent();
            table.timestamp( "published_date" ).nullable();
        } );
    }

    function down( schema, query ) {
        schema.drop( "my_posts" );
    }

}
