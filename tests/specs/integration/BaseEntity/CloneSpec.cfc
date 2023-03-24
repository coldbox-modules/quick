component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

	function run() {
		describe( "Clone Spec", function() {

			it( "can clone with matching attributes", function() {
				var user = getInstance( "User" ).find( 1 );
				var clonedUser = user.clone();

				var hashA = user.computeAttributesHash( user.retrieveAttributesData() );
				var hashB = user.computeAttributesHash( clonedUser.retrieveAttributesData() );

				expect( hashA eq hashB ).toBeTrue( "The cloned entity" );
			} );

			it( "can clone an entity as not loaded", function() {
				var user = getInstance( "User" ).find( 1 );
				expect( user.isLoaded() ).toBeTrue( "The user instance should be found and loaded, but was not." );
				var clonedUser = user.clone();
				expect( clonedUser.isLoaded() ).toBeFalse( "The cloned user instance should be not be marked as loaded, but was." );
			} );

			it( "can clone an entity as loaded", function() {
				var user = getInstance( "User" ).find( 1 );
				expect( user.isLoaded() ).toBeTrue( "The user instance should be found and loaded, but was not." );
				var clonedUser = user.clone(true);
				expect( clonedUser.isLoaded() ).toBeTrue( "The cloned user instance should be marked as loaded, but was not." );
			} );

		} );
	}

}
