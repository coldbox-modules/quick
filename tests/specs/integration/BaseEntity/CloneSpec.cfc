component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Clone Spec", function() {
			it( "can clone with matching attributes", function() {
				var user       = getInstance( "User" ).find( 1 );
				var clonedUser = user.clone();

				var hashA = user.computeAttributesHash( user.retrieveAttributesData() );
				var hashB = user.computeAttributesHash( clonedUser.retrieveAttributesData() );

				expect( hashA ).toBe( hashB, "The cloned entity should have an identical hash" );
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
				var clonedUser = user.clone( markLoaded = true );
				expect( clonedUser.isLoaded() ).toBeTrue( "The cloned user instance should be marked as loaded, but was not." );
			} );

			it( "can replicate a loaded entity as a new entity without its key", function() {
				var user    = getInstance( "User" ).findOrFail( 1 );
				var replica = user.replicate();

				expect( replica.isLoaded() ).toBeFalse();
				expect( replica.retrieveAttributesData() ).notToHaveKey( "id" );
				expect( replica.getUsername() ).toBe( user.getUsername() );

				replica
					.setUsername( "replicated-user" )
					.setEmail( "replicated@example.com" )
					.save();
				expect( replica.isLoaded() ).toBeTrue();
				expect( replica.getId() ).notToBe( user.getId() );
			} );

			it( "can exclude additional attributes when replicating", function() {
				var replica = getInstance( "User" ).findOrFail( 1 ).replicate( [ "email" ] );

				expect( replica.retrieveAttributesData() ).notToHaveKey( "id" );
				expect( replica.retrieveAttributesData() ).notToHaveKey( "email" );
			} );

			it( "can clone a QuickBuilder instance", function() {
				var userBuilder  = getInstance( "User" ).orderBy( "id" );
				var userBuilder2 = userBuilder.clone();
				userBuilder2.clearOrders();
				expect( userBuilder.getOrders() ).toBe( [
					{
						"column" : {
							"type"  : "simple",
							"value" : "users.id"
						},
						"direction" : "asc"
					}
				] );
				expect( userBuilder2.getOrders() ).toBe( [] );
			} );
		} );
	}

}
