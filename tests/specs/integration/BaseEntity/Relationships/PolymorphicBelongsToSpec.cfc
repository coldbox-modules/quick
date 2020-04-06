component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

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
		} );
	}

}
