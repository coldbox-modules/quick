component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

	function run() {
		describe( "Get Spec", function() {
			it( "finds an entity by the primary key", function() {
				var user = getInstance( "User" ).find( 1 );
				expect( user.isLoaded() ).toBeTrue( "The user instance should be found and loaded, but was not." );
			} );

			it( "returns null if the record cannot be found", function() {
				expect( getInstance( "User" ).find( 999 ) ).toBeNull(
					"The user instance should be null because it could not be found, but was not."
				);
			} );

			it( "returns null if the first record cannot be found", function() {
				expect( getInstance( "Empty" ).first() ).toBeNull(
					"The instance should be null because there are none in the database."
				);
			} );

			it( "can refresh itself from the database", function() {
				var user = getInstance( "User" ).find( 1 );
				expect( user.getUsername() ).toBe( "elpete" );
				queryExecute( "UPDATE `users` SET `username` = ? WHERE `id` = ?", [ "new_username", 1 ] );
				expect( user.getUsername() ).toBe( "elpete" );
				user.refresh();
				expect( user.getUsername() ).toBe( "new_username" );
			} );

			it( "can get a fresh instance from the database", function() {
				var user = getInstance( "User" ).find( 1 );
				expect( user.getUsername() ).toBe( "elpete" );
				queryExecute( "UPDATE `users` SET `username` = ? WHERE `id` = ?", [ "new_username", 1 ] );
				expect( user.getUsername() ).toBe( "elpete" );
				var freshUser = user.fresh();
				expect( user.getUsername() ).toBe( "elpete" );
				expect( freshUser.getUsername() ).toBe( "new_username" );
			} );

			describe( "loaded", function() {
				it( "a new entity returns false when asked if it loaded", function() {
					expect( getInstance( "User" ).isLoaded() ).toBeFalse();
				} );

				it( "an entity loaded from the database returns true when asked if it loaded", function() {
					expect( getInstance( "User" ).find( 1 ).isLoaded() ).toBeTrue();
				} );
			} );

			it( "throws an exception if no entity is found using find or fail", function() {
				expect( function() {
					getInstance( "User" ).findOrFail( 1 );
				} ).notToThrow();

				expect( function() {
					getInstance( "User" ).findOrFail( 999 );
				} ).toThrow( type = "EntityNotFound" );

				expect( function() {
					getInstance( "User" ).findOrFail( 999, "Custom Message" );
				} ).toThrow( type = "EntityNotFound", regex = "Custom Message" );

				expect( function() {
					getInstance( "User" ).findOrFail( 999, function( entity, id ) {
						return "#entity.entityName()# ###id# Not Found";
					} );
				} ).toThrow( type = "EntityNotFound", regex = "User \##999 Not Found" );
			} );

			it( "throws an exception if no entity is found using first or fail", function() {
				expect( function() {
					getInstance( "User" ).whereUsername( "johndoe" ).firstOrFail();
				} ).notToThrow();

				expect( function() {
					getInstance( "User" ).whereUsername( "doesnt-exist" ).firstOrFail();
				} ).toThrow( type = "EntityNotFound" );

				expect( function() {
					getInstance( "User" ).whereUsername( "doesnt-exist" ).firstOrFail( "Custom Message" );
				} ).toThrow( type = "EntityNotFound", regex = "Custom Message" );

				expect( function() {
					getInstance( "User" )
						.whereUsername( "doesnt-exist" )
						.firstOrFail( function( entity ) {
							return "No #entity.entityName()# found with that criteria";
						} );
				} ).toThrow( type = "EntityNotFound", regex = "No User found with that criteria" );
			} );

			it( "can return if an entity exists", function() {
				expect( getInstance( "User" ).whereUsername( "johndoe" ).exists() ).toBeTrue();

				expect( getInstance( "User" ).whereUsername( "doesnt-exist" ).exists() ).toBeFalse();

				expect( getInstance( "User" ).exists( id = 1 ) ).toBeTrue();

				expect( getInstance( "User" ).exists( id = -999 ) ).toBeFalse();
			} );

			it( "throws an exception if an entity does not exist when calling existsOrFail", function() {
				expect( function() {
					getInstance( "User" ).whereUsername( "johndoe" ).existsOrFail();
				} ).notToThrow();

				expect( function() {
					getInstance( "User" ).whereUsername( "doesnt-exist" ).existsOrFail();
				} ).toThrow( type = "EntityNotFound" );

				expect( function() {
					getInstance( "User" )
						.whereUsername( "doesnt-exist" )
						.existsOrFail( errorMessage = "Custom Message" );
				} ).toThrow( type = "EntityNotFound", regex = "Custom Message" );

				expect( function() {
					getInstance( "User" ).existsOrFail( id = 1 );
				} ).notToThrow();

				expect( function() {
					getInstance( "User" ).existsOrFail( id = -999, errorMessage = "Custom Message" );
				} ).toThrow( type = "EntityNotFound", regex = "Custom Message" );

				expect( function() {
					getInstance( "User" )
						.whereUsername( "doesnt-exist" )
						.existsOrFail(
							errorMessage = function( entity ) {
								return "No #entity.entityName()# exists with that criteria";
							}
						);
				} ).toThrow( type = "EntityNotFound", regex = "No User exists with that criteria" );
			} );

			it( "can paginate a Quick query", function() {
				queryExecute( "TRUNCATE TABLE `a`" );
				for ( var i = 1; i <= 45; i++ ) {
					// create A
					var a = getInstance( "A" ).create( { "name" : "Instance #i#" } );
				}

				var p = getInstance( "A" ).orderBy( "id" ).paginate();
				expect( p.pagination.page ).toBe( 1, "Page number should be 1" );
				expect( p.results ).toHaveLength( 25 );
				expect( p.results[ 1 ].getId() ).toBe( 1, "First entity id should be 1" );
				expect( p.results[ p.results.len() ].getId() ).toBe( 25 );

				p = getInstance( "A" ).orderBy( "id" ).paginate( 2 );
				expect( p.pagination.page ).toBe( 2, "Page number should be 2" );
				expect( p.results ).toHaveLength( 20 );
				expect( p.results[ 1 ].getId() ).toBe( 26, "First entity id should be 26" );
				expect( p.results[ p.results.len() ].getId() ).toBe( 45 );
			} );

			it( "can eager load and paginate a Quick query", function() {
				queryExecute( "TRUNCATE TABLE `a`" );
				queryExecute( "TRUNCATE TABLE `b`" );

				var as = [];
				var bs = [];
				for ( var i = 1; i < 10; i++ ) {
					as.append( { "name" : "Instance #i#" } );
					for ( var j = 1; j < 5; j++ ) {
						bs.append( { "name" : "Instance #j#", "a_id" : i } );
					}
				}

				getInstance( "A" ).insert( as );
				getInstance( "B" ).insert( bs );

				var p = getInstance( "B" )
					.with( "a" )
					.orderBy( "id" )
					.paginate();
				expect( p.pagination.page ).toBe( 1, "Page number should be 1" );
				expect( p.results ).toHaveLength( 25 );
				var firstB = p.results[ 1 ];
				expect( firstB.getId() ).toBe( 1, "First entity id should be 1" );
				expect( firstB.isRelationshipLoaded( "a" ) ).toBeTrue();
			} );

			describe( "firstOrNew", function() {
				it( "can return a found entity with firstOrNew", function() {
					var existingUser = getInstance( "User" ).whereUsername( "elpete" ).firstOrNew();

					expect( existingUser.isLoaded() ).toBeTrue();
					expect( existingUser.getUsername() ).toBe( "elpete" );
				} );

				it( "can return a new unloaded entity with firstOrNew", function() {
					var newUser = getInstance( "User" ).whereUsername( "doesnotexist" ).firstOrNew();

					expect( newUser.isLoaded() ).toBeFalse();
					expect( newUser.retrieveAttributesData() ).toBe( {} );
				} );

				it( "can accept a struct of attributes to restrict the query", function() {
					var existingUser = getInstance( "User" ).firstOrNew( { "username" : "elpete" } );
					expect( existingUser.isLoaded() ).toBeTrue();
					expect( existingUser.getUsername() ).toBe( "elpete" );
				} );

				it( "the struct of attributes is returned as the new entity data", function() {
					var newUser = getInstance( "User" ).firstOrNew( { "username" : "doesntexist" } );
					expect( newUser.isLoaded() ).toBeFalse();
					expect( newUser.retrieveAttributesData( aliased = true ) ).toBe( { "username" : "doesntexist" } );
				} );

				it( "an optional second struct of attributes can be set on the new entity", function() {
					var newUser = getInstance( "User" ).firstOrNew(
						{ "username" : "doesntexist" },
						{
							"firstName" : "Doesnt",
							"lastName"  : "Exist"
						}
					);
					expect( newUser.isLoaded() ).toBeFalse();
					expect( newUser.retrieveAttributesData( aliased = true ) ).toBe( {
						"username"  : "doesntexist",
						"firstName" : "Doesnt",
						"lastName"  : "Exist"
					} );
				} );

				it( "the second struct of attributes is ignored if an entity is found", function() {
					var existingUser = getInstance( "User" ).firstOrNew(
						{ "username" : "elpete" },
						{
							"firstName" : "Doesnt",
							"lastName"  : "Exist"
						}
					);
					expect( existingUser.isLoaded() ).toBeTrue();
					expect( existingUser.getFirstName() ).notToBe( "Doesnt" );
					expect( existingUser.getLastName() ).notToBe( "Exist" );
				} );
			} );

			describe( "firstOrCreate", function() {
				it( "can return a found entity with firstOrCreate", function() {
					var existingUser = getInstance( "User" ).whereUsername( "elpete" ).firstOrCreate();

					expect( existingUser.isLoaded() ).toBeTrue();
					expect( existingUser.getUsername() ).toBe( "elpete" );
				} );

				it( "can accept a struct of attributes to restrict the query", function() {
					var existingUser = getInstance( "User" ).firstOrCreate( { "username" : "elpete" } );
					expect( existingUser.isLoaded() ).toBeTrue();
					expect( existingUser.getUsername() ).toBe( "elpete" );
				} );

				it( "the struct of attributes is returned as the new entity data", function() {
					var newUser = getInstance( "User" ).firstOrCreate( {
						"username"  : "doesntexist",
						"firstName" : "doesnt",
						"lastName"  : "exist",
						"password"  : "secret"
					} );
					expect( newUser.isLoaded() ).toBeTrue();
					var attrs = newUser.retrieveAttributesData( aliased = true );
					attrs.delete( "id" );
					expect( attrs ).toBe( {
						"username"  : "doesntexist",
						"firstName" : "doesnt",
						"lastName"  : "exist",
						"password"  : "secret"
					} );
				} );

				it( "an optional second struct of attributes can be set on the new entity", function() {
					var newUser = getInstance( "User" ).firstOrCreate(
						{ "username" : "doesntexist" },
						{
							"firstName" : "Doesnt",
							"lastName"  : "Exist",
							"password"  : "secret"
						}
					);
					expect( newUser.isLoaded() ).toBeTrue();
					var attrs = newUser.retrieveAttributesData( aliased = true );
					attrs.delete( "id" );
					expect( attrs ).toBe( {
						"username"  : "doesntexist",
						"firstName" : "doesnt",
						"lastName"  : "exist",
						"password"  : "secret"
					} );
				} );

				it( "the second struct of attributes is ignored if an entity is found", function() {
					var existingUser = getInstance( "User" ).firstOrCreate(
						{ "username" : "elpete" },
						{
							"firstName" : "Doesnt",
							"lastName"  : "Exist"
						}
					);
					expect( existingUser.isLoaded() ).toBeTrue();
					expect( existingUser.getFirstName() ).notToBe( "Doesnt" );
					expect( existingUser.getLastName() ).notToBe( "Exist" );
				} );
			} );

			describe( "findOrNew", function() {
				it( "can return a found entity with findOrNew", function() {
					var existingUser = getInstance( "User" ).findOrNew( 1 );

					expect( existingUser.isLoaded() ).toBeTrue();
					expect( existingUser.getUsername() ).toBe( "elpete" );
				} );

				it( "can return a new unloaded entity with findOrNew", function() {
					var newUser = getInstance( "User" ).findOrNew( 9999 );

					expect( newUser.isLoaded() ).toBeFalse();
					expect( newUser.retrieveAttributesData() ).toBe( {} );
				} );

				it( "an optional struct of attributes can be set on the new entity", function() {
					var newUser = getInstance( "User" ).findOrNew(
						9999,
						{
							"firstName" : "Doesnt",
							"lastName"  : "Exist"
						}
					);
					expect( newUser.isLoaded() ).toBeFalse();
					expect( newUser.retrieveAttributesData( aliased = true ) ).toBe( {
						"firstName" : "Doesnt",
						"lastName"  : "Exist"
					} );
				} );

				it( "the second struct of attributes is ignored if an entity is found", function() {
					var existingUser = getInstance( "User" ).findOrNew(
						1,
						{
							"firstName" : "Doesnt",
							"lastName"  : "Exist"
						}
					);
					expect( existingUser.isLoaded() ).toBeTrue();
					expect( existingUser.getFirstName() ).notToBe( "Doesnt" );
					expect( existingUser.getLastName() ).notToBe( "Exist" );
				} );
			} );

			describe( "findOrCreate", function() {
				it( "can return a found entity with findOrCreate", function() {
					var existingUser = getInstance( "User" ).findOrCreate( 1 );

					expect( existingUser.isLoaded() ).toBeTrue();
					expect( existingUser.getUsername() ).toBe( "elpete" );
				} );

				it( "the struct of attributes is returned as the new entity data", function() {
					var newUser = getInstance( "User" ).findOrCreate(
						9999,
						{
							"username"  : "doesntexist",
							"firstName" : "doesnt",
							"lastName"  : "exist",
							"password"  : "secret"
						}
					);
					expect( newUser.isLoaded() ).toBeTrue();
					var attrs = newUser.retrieveAttributesData( aliased = true );
					attrs.delete( "id" );
					expect( attrs ).toBe( {
						"username"  : "doesntexist",
						"firstName" : "doesnt",
						"lastName"  : "exist",
						"password"  : "secret"
					} );
				} );

				it( "the second struct of attributes is ignored if an entity is found", function() {
					var existingUser = getInstance( "User" ).findOrCreate(
						1,
						{
							"firstName" : "Doesnt",
							"lastName"  : "Exist"
						}
					);
					expect( existingUser.isLoaded() ).toBeTrue();
					expect( existingUser.getFirstName() ).notToBe( "Doesnt" );
					expect( existingUser.getLastName() ).notToBe( "Exist" );
				} );
			} );

			describe( "firstWhere", function() {
				it( "can restirct a query and get the first result", function() {
					var user = getInstance( "User" ).firstWhere( "username", "elpete" );
					expect( user.isLoaded() ).toBeTrue();
					expect( user.getUsername() ).toBe( "elpete" );
				} );
			} );
		} );
	}

}
