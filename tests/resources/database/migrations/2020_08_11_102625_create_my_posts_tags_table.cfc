component {

    function up( schema, query ) {
        schema.create( "my_posts_tags", function( table ) {
            table.unsignedInteger( "custom_post_pk" );
            table.unsignedInteger( "tag_id" );
            table.primaryKey( [ "custom_post_pk", "tag_id" ] );
        } );
    }

    function down( schema, query ) {
        schema.drop( "my_posts_tags" );
    }

}
