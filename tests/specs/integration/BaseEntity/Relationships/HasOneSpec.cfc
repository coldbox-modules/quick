component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

	function run() {
		describe( "Has One Spec", function() {
			it( "can get the owning entity", function() {
				var user = getInstance( "User" ).find( 1 );
				var post = user.getLatestPost();
				expect( post.getPost_Pk() ).toBe( 523526 );
			} );

			it( "returns null if there is no owning entity", function() {
				var user = getInstance( "User" ).find( 2 );
				expect( user.getLatestPost() ).toBeNull();
			} );

			it( "can return an empty default entity if there is no owning entity", function() {
				var user = getInstance( "User" ).find( 2 );
				expect( user.getLatestPostWithEmptyDefault() ).notToBeNull();
				var post = user.getLatestPostWithEmptyDefault();
				expect( post ).toBeInstanceOf( "Post" );
				expect( post.isLoaded() ).toBeFalse( "A default model is not loaded" );
				expect( post.retrieveAttributesData() ).toBeEmpty();
			} );

			it( "can return a configured default entity if there is no owning entity", function() {
				var user = getInstance( "User" ).find( 2 );
				expect( user.getLatestPostWithDefaultAttributes() ).notToBeNull();
				var post = user.getLatestPostWithDefaultAttributes();
				expect( post ).toBeInstanceOf( "Post" );
				expect( post.isLoaded() ).toBeFalse( "A default model is not loaded" );
				expect( post.retrieveAttributesData( aliased = true ) ).toBe( { "body" : "Default Post" } );
			} );

			it( "can configure a default entity with a callback", function() {
				var user = getInstance( "User" ).find( 2 );
				expect( user.getLatestPostWithCallbackConfiguredDefault() ).notToBeNull();
				var post = user.getLatestPostWithCallbackConfiguredDefault();
				expect( post ).toBeInstanceOf( "Post" );
				expect( post.isLoaded() ).toBeFalse( "A default model is not loaded" );
				expect( post.getBody() ).toBe( user.getUsername() );
			} );
		} );
	}

}
