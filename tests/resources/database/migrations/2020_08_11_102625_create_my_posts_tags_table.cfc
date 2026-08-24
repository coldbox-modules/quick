component {

	function up( schema, qb ) {
		schema.create( "my_posts_tags", function( t ) {
			t.unsignedInteger( "custom_post_pk" );
			t.unsignedInteger( "tag_id" );
			t.string( "context" ).nullable();
			t.boolean( "active" ).default( false );
			t.timestamp( "created_date" ).nullable();
			t.timestamp( "modified_date" ).nullable();
			t.primaryKey( [ "custom_post_pk", "tag_id" ] );
		} );

		qb.table( "my_posts_tags" )
			.insert( [
				{
					"custom_post_pk" : 1245,
					"tag_id"         : 1,
					"context"        : "primary",
					"active"         : true
				},
				{
					"custom_post_pk" : 1245,
					"tag_id"         : 2,
					"context"        : "secondary",
					"active"         : false
				},
				{
					"custom_post_pk" : 523526,
					"tag_id"         : 1,
					"context"        : "archived",
					"active"         : false
				},
				{
					"custom_post_pk" : 523526,
					"tag_id"         : 2,
					"context"        : "review",
					"active"         : true
				},
				{
					"custom_post_pk" : 523526,
					"tag_id"         : 3,
					"context"        : "published",
					"active"         : true
				},
				{
					"custom_post_pk" : 321,
					"tag_id"         : 2,
					"context"        : "legacy",
					"active"         : false
				}
			] );
	}

	function down( schema, qb ) {
		schema.drop( "my_posts_tags" );
	}

}
