component {

	function up( schema, qb ) {
		schema.create( "my_posts_tags", function( t ) {
			t.unsignedInteger( "custom_post_pk" );
			t.unsignedInteger( "tag_id" );
			t.primaryKey( [ "custom_post_pk", "tag_id" ] );
		} );

		qb.table( "my_posts_tags" )
			.insert( [
				{
					"custom_post_pk" : 1245,
					"tag_id"         : 1
				},
				{
					"custom_post_pk" : 1245,
					"tag_id"         : 2
				},
				{
					"custom_post_pk" : 523526,
					"tag_id"         : 1
				},
				{
					"custom_post_pk" : 523526,
					"tag_id"         : 2
				},
				{
					"custom_post_pk" : 523526,
					"tag_id"         : 3
				},
				{ "custom_post_pk" : 321, "tag_id" : 2 }
			] );
	}

	function down( schema, qb ) {
		schema.drop( "my_posts_tags" );
	}

}
