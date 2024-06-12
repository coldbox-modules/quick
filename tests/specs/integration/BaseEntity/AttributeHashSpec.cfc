component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Attribute Hash Spec", function() {
			it( "can compute attributes hash", function() {
				var user = getInstance( "User" ).find( 1 );
				var hash = user.computeAttributesHash( user.retrieveAttributesData() );
				expect( hash ).toBeTypeOf( "string" );
			} );

			it( "can compute attributes hash correctly", function() {
				var passwordHash = hash( "password" )
				var user         = getInstance( "User" ).populate(
					{
						"username"              : "JaneDoe",
						"first_name"            : "Jane",
						"last_name"             : "Doe",
						"password"              : passwordHash,
						"non-existant-property" : "any-value"
					},
					true
				);

				var expectedHash = hash( "first_name=Jane&last_name=Doe&password=#passwordHash#&username=JaneDoe" );
				var hash         = user.computeAttributesHash( user.retrieveAttributesData() );
				expect( expectedHash ).toBe( hash, "The computeAttributesHash method does not return the correct hash" );
			} );
		} );
	}

}
