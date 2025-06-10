component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Create Spec", function() {
			it( "can create and return a model that is already saved in the database", function() {
				var user = getInstance( "User" ).create( {
					"username"   : "JaneDoe",
					"first_name" : "Jane",
					"last_name"  : "Doe",
					"password"   : hash( "password" )
				} );
				expect( user.isLoaded() ).toBeTrue();
				expect(
					user.newEntity()
						.where( "username", "JaneDoe" )
						.first()
				).notToBeNull();
			} );

			it( "can ignore non-existant properties", function() {
				var user = getInstance( "User" ).create(
					{
						"username"              : "JaneDoe",
						"first_name"            : "Jane",
						"last_name"             : "Doe",
						"password"              : hash( "password" ),
						"non-existant-property" : "any-value"
					},
					true
				);
				expect( user.isLoaded() ).toBeTrue();
				expect(
					user.newEntity()
						.where( "username", "JaneDoe" )
						.first()
				).notToBeNull();
			} );

			it( "can create a new entity with a json cast", () => {
				var newTheme = getInstance( "Theme" ).create( {
					slug    : "theme-new",
					version : "0.0.1",
					config  : { "message" : "I should be cast to JSON" }
				} );

				expect( newTheme.getSlug() ).toBe( "theme-new" );
				expect( newTheme.getVersion() ).toBe( "0.0.1" );
				expect( newTheme.isNullAttribute( "config" ) ).toBeFalse();
				expect( newTheme.getConfig() ).toBe( { "message" : "I should be cast to JSON" } );
			} );
		} );
	}

}
