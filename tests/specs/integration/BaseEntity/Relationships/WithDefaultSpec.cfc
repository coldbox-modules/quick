component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

	function run() {
		describe( "Belongs To Spec", function() {
			beforeEach( function() {
				variables.queries = [];
			} );

			it( "will throw an exception when retrieving a relation on an unloaded entity", function() {
				var post = getInstance( "Post" );

				expect( function(){
					post.getAuthor();
				} ).toThrow(message="Retrieving an unloaded entity should throw an exception");

			} );

			it( "can load a entity and return a default entity if there is no owning entity", function() {
				var post = getInstance( "Post" ).find( 7777 );
				var author = post.getAuthorWithEmptyDefault();
				expect( post.getAuthorWithEmptyDefault() ).notToBeNull();
				expect( author ).toBeInstanceOf( "User" );
				expect( author.isLoaded() ).toBeFalse( "A default model is not loaded" );
				expect( author.retrieveAttributesData() ).toBeEmpty();
			} );

			it( "can save a new entity and return a default entity if there is no owning entity", function() {
				var post = getInstance( "Post" ).create( {
					"body" : "This is a cool body post"
				}, true );

				var author = post.getAuthorWithEmptyDefault();
				expect( post.getAuthorWithEmptyDefault() ).notToBeNull();
				expect( author ).toBeInstanceOf( "User" );
				expect( author.isLoaded() ).toBeFalse( "A default model is not loaded" );
				expect( author.retrieveAttributesData() ).toBeEmpty();
			} );

		} );
	}

	function preQBExecute(
		event,
		interceptData,
		buffer,
		rc,
		prc
	) {
		arrayAppend( variables.queries, interceptData );
	}

}
