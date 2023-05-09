component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Belongs To Many Spec", function() {
			beforeEach( function() {
				variables.queries = [];
			} );

			it( "can get the related entities", function() {
				var post = getInstance( "Post" ).find( 1245 );
				var tags = post.getTags();
				expect( tags ).toBeArray();
				expect( tags ).toHaveLength( 2 );
			} );

			it( "can get the related entities from the inverse relationship", function() {
				var tag   = getInstance( "Tag" ).find( 1 );
				var posts = tag.getPosts();
				expect( posts ).toBeArray();
				expect( posts ).toHaveLength( 2 );
			} );
		} );
	}

}
