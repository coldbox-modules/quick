component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

	function run() {
		describe( "Attribute Hash Spec", function() {

			it( "can compute attributes hash", function() {
				var user = getInstance( "User" ).find( 1 );
				var hash = user.computeAttributesHash( user.retrieveAttributesData() );
				expect( hash ).toBeTypeOf( "string" );
			} );

			it( "can compute attributes hash correctly", function() {
				var user = getInstance( "User" ).populate({
					"username"              : "JaneDoe",
					"first_name"            : "Jane",
					"last_name"             : "Doe",
					"password"              : hash( "password" ),
					"non-existant-property" : "any-value"
				}, true);

				var expectHash = hash('first_name=Jane&last_name=Doe&password=5F4DCC3B5AA765D61D8327DEB882CF99&username=JaneDoe')
				var hash = user.computeAttributesHash( user.retrieveAttributesData() );
				expect( expectHash eq hash ).toBeTrue( "The computeAttributesHash method does not return the correct hash" );
			} );

		} );
	}

}
