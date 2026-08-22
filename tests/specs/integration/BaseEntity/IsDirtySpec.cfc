component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "isDirty Spec", function() {
			it( "can test to see if an updated entity differs from that created", function() {
				var user = getInstance( "User" ).find( 1 );

				user.fill( { "last_name" : "Peterson" } );
				expect( user.isDirty() ).toBeFalse();

				user.fill( { "last_name" : "peterson" } );
				expect( user.isDirty() ).toBeTrue();

				user.fill( { "last_name" : "Smith" } );
				expect( user.isDirty() ).toBeTrue();

				user.fill( { "last_name" : "Peterson" } );
				expect( user.isDirty() ).toBeFalse();
			} );

			it( "can check whether a specific attribute alias or column is dirty", function() {
				var user = getInstance( "User" ).findOrFail( 1 );

				expect( user.isDirty( "username" ) ).toBeFalse();
				expect( user.isDirty( "firstName" ) ).toBeFalse();
				expect( user.isDirty( "first_name" ) ).toBeFalse();

				user.setUsername( "updated-username" );
				expect( user.isDirty( "username" ) ).toBeTrue();
				expect( user.isDirty( "firstName" ) ).toBeFalse();

				user.setFirstName( "Updated" );
				expect( user.isDirty( "firstName" ) ).toBeTrue();
				expect( user.isDirty( "first_name" ) ).toBeTrue();

				user.setUsername( "elpete" );
				expect( user.isDirty( "username" ) ).toBeFalse();
				expect( user.isDirty() ).toBeTrue();
			} );

			it( "can test whether the entity or a specific attribute is clean", function() {
				var user = getInstance( "User" ).findOrFail( 1 );

				expect( user.isClean() ).toBeTrue();
				expect( user.isClean( "username" ) ).toBeTrue();
				expect( user.isClean( "first_name" ) ).toBeTrue();

				user.setUsername( "updated-username" );
				expect( user.isClean() ).toBeFalse();
				expect( user.isClean( "username" ) ).toBeFalse();
				expect( user.isClean( "firstName" ) ).toBeTrue();
			} );
		} );
	}

}
