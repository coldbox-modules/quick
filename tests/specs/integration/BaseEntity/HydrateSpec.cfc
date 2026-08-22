component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Hydrate Spec", function() {
			it( "can hydrate an entity from a struct of data", function() {
				var memento = {
					"id"        : 4,
					"username"  : "elpete2",
					"firstName" : "Another",
					"lastName"  : "Peterson"
				};
				var user = getInstance( "User" );
				expect( user.retrieveAttribute( "username" ) ).toBe( "" );
				expect( user.retrieveAttribute( "first_name" ) ).toBe( "" );
				expect( user.retrieveAttribute( "last_name" ) ).toBe( "" );
				user.hydrate( memento );
				expect( user.isLoaded() ).toBeTrue( "An entity should be loaded after calling hydrate" );
				expect( user.retrieveAttribute( "username" ) ).toBe( "elpete2" );
				expect( user.retrieveAttribute( "first_name" ) ).toBe( "Another" );
				expect( user.retrieveAttribute( "last_name" ) ).toBe( "Peterson" );
			} );

			it( "ignores non-persistent struct properties when checking hydrated entities for changes", function() {
				var memento = {
					"cacheMetadata" : {
						"source" : "cache",
						"tags"   : [ "one", "two" ]
					},
					"id"         : 4,
					"username"   : "elpete2",
					"first_name" : "Another",
					"last_name"  : "Peterson"
				};
				var user                 = getInstance( "User" ).hydrate( memento );
				var updatedCacheMetadata = {
					"source" : "refreshed-cache",
					"tags"   : [ "three" ]
				};
				user.setCacheMetadata( updatedCacheMetadata );

				expect( user.getCacheMetadata() ).toBe( updatedCacheMetadata );
				expect( user.isDirty() ).toBeFalse();
			} );

			it( "can hydrate multiple entities at once from an array of structs", function() {
				var mementos = [
					{
						"id"        : 2,
						"username"  : "johndoe",
						"firstName" : "John",
						"lastName"  : "Doe"
					},
					{
						"id"        : 4,
						"username"  : "elpete2",
						"firstName" : "Another",
						"lastName"  : "Peterson"
					}
				];

				var users = getInstance( "User" ).hydrateAll( mementos );

				var userA = users[ 1 ];
				expect( userA.isLoaded() ).toBeTrue( "An entity should be loaded after calling hydrate" );
				expect( userA.retrieveAttribute( "username" ) ).toBe( "johndoe" );
				expect( userA.retrieveAttribute( "first_name" ) ).toBe( "John" );
				expect( userA.retrieveAttribute( "last_name" ) ).toBe( "Doe" );

				var userB = users[ 2 ];
				expect( userB.isLoaded() ).toBeTrue( "An entity should be loaded after calling hydrate" );
				expect( userB.retrieveAttribute( "username" ) ).toBe( "elpete2" );
				expect( userB.retrieveAttribute( "first_name" ) ).toBe( "Another" );
				expect( userB.retrieveAttribute( "last_name" ) ).toBe( "Peterson" );
			} );
		} );
	}

}
