component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "WithDefault Spec", function() {
			it( "returns a configured default for a relation on an unloaded entity", function() {
				var post   = getInstance( "Post" );
				var author = post.getAuthorWithEmptyDefault();

				expect( author ).toBeInstanceOf( "User" );
				expect( author.isLoaded() ).toBeFalse( "A default model is not loaded" );
				expect( author.retrieveAttributesData() ).toBeEmpty();
			} );

			it( "can load a entity and return a default entity if there is no owning entity", function() {
				var post   = getInstance( "Post" ).find( 7777 );
				var author = post.getAuthorWithEmptyDefault();
				expect( post.getAuthorWithEmptyDefault() ).notToBeNull();
				expect( author ).toBeInstanceOf( "User" );
				expect( author.isLoaded() ).toBeFalse( "A default model is not loaded" );
				expect( author.retrieveAttributesData() ).toBeEmpty();
			} );

			it( "can save a new entity and return a default entity if there is no owning entity", function() {
				var post = getInstance( "Post" ).create( { "body" : "This is a cool body post" }, true );

				var author = post.getAuthorWithEmptyDefault();
				expect( post.getAuthorWithEmptyDefault() ).notToBeNull();
				expect( author ).toBeInstanceOf( "User" );
				expect( author.isLoaded() ).toBeFalse( "A default model is not loaded" );
				expect( author.retrieveAttributesData() ).toBeEmpty();
			} );

			it( "returns the default entity as a memento when requested from the relationship", function() {
				var user            = getInstance( "User" ).findOrFail( 2 );
				var expectedMemento = user
					.latestPostWithEmptyDefault()
					.get()
					.getMemento();
				var postMemento = user
					.latestPostWithEmptyDefault()
					.asMemento()
					.get();

				expect( postMemento ).toBeStruct();
				expect( postMemento ).notToBeComponent();
				expect( postMemento ).toBe( expectedMemento );
			} );
		} );
	}

}
