component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Polymorphic Belongs To Spec", function() {
			it( "can get the related polymorphic entity", function() {
				var commentA = getInstance( "Comment" ).find( 1 );
				expect( commentA.getCommentable() ).toBeInstanceOf( "app.models.Post" );
				expect( commentA.getCommentable().getBody() ).toBe( "My awesome post body" );

				var commentB = getInstance( "Comment" ).find( 2 );
				expect( commentB.getCommentable() ).toBeInstanceOf( "app.models.Post" );
				expect( commentB.getCommentable().getBody() ).toBe( "My post with a different author" );

				var commentC = getInstance( "Comment" ).find( 3 );
				expect( commentC.getCommentable() ).toBeInstanceOf( "app.models.Video" );
				expect( commentC.getCommentable().getTitle() ).toBe( "Cello Wars" );
			} );

			it( "can eager load polymorphic entities with different primary key names", function() {
				var comments = getInstance( "Comment" )
					.with( "commentable" )
					.orderBy( "id" )
					.get();

				expect( comments ).toHaveLength( 5 );
				expect( comments[ 1 ].getCommentable() ).toBeInstanceOf( "app.models.Post" );
				expect( comments[ 1 ].getCommentable().getPost_Pk() ).toBe( 1245 );
				expect( comments[ 3 ].getCommentable() ).toBeInstanceOf( "app.models.Video" );
				expect( comments[ 3 ].getCommentable().getId() ).toBe( 1245 );
			} );
		} );
	}

}
