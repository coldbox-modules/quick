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

			it( "persists relationships filled before creating the parent", function() {
				var user = getInstance( "User" ).create( {
					"username"   : "aggregate-user",
					"first_name" : "Aggregate",
					"last_name"  : "User",
					"password"   : hash( "password" ),
					"posts"      : [
						{ "body" : "First child" },
						{ "body" : "Second child" }
					]
				} );

				expect( user.isLoaded() ).toBeTrue();
				expect( user.getPosts() ).toHaveLength( 2 );
				expect( user.getPosts()[ 1 ].isLoaded() ).toBeTrue();
				expect( user.getPosts()[ 1 ].getUser_Id() ).toBe( user.getId() );
				expect( user.getPosts()[ 2 ].isLoaded() ).toBeTrue();
				expect( user.getPosts()[ 2 ].getUser_Id() ).toBe( user.getId() );
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

			it( "can create and return multiple entities", function() {
				var users = getInstance( "User" ).createAll( [
					{
						"username"  : "first-new-user",
						"firstName" : "First",
						"lastName"  : "User"
					},
					{
						"username"  : "second-new-user",
						"firstName" : "Second",
						"lastName"  : "User"
					}
				] );

				expect( users ).toBeArray();
				expect( users ).toHaveLength( 2 );
				expect( users[ 1 ].isLoaded() ).toBeTrue();
				expect( users[ 1 ].getId() ).notToBeNull();
				expect( users[ 1 ].getFirstName() ).toBe( "First" );
				expect( users[ 2 ].isLoaded() ).toBeTrue();
				expect( users[ 2 ].getId() ).notToBeNull();
				expect( users[ 2 ].getFirstName() ).toBe( "Second" );
				expect( getInstance( "User" ).whereIn( "username", [ "first-new-user", "second-new-user" ] ).count() ).toBe(
					2
				);
			} );
		} );
	}

}
