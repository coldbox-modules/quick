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
		} );
	}

}
