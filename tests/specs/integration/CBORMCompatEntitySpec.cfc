component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

	function run() {
		describe( "CBORM Compatibility Entity Spec", function() {
			beforeEach( function() {
				variables.user = getInstance( dsl = "provider:CompatUser" );
			} );

			it( "list (without arguments)", function() {
				var users = user.list();
				expect( users ).toBeQuery();
				expect( users ).toHaveLength( 5, "Five users should exist in the database and be returned." );
			} );

			it( "list (as objects)", function() {
				var users = user.list( asQuery = false );
				expect( users ).toHaveLength( 5, "Five users should exist in the database and be returned." );
				expect( users[ 1 ].getId() ).toBe( 1 );
				expect( users[ 1 ].getUsername() ).toBe( "elpete" );
				expect( users[ 2 ].getId() ).toBe( 2 );
				expect( users[ 2 ].getUsername() ).toBe( "johndoe" );
				expect( users[ 3 ].getId() ).toBe( 3 );
				expect( users[ 3 ].getUsername() ).toBe( "janedoe" );
				expect( users[ 4 ].getId() ).toBe( 4 );
				expect( users[ 4 ].getUsername() ).toBe( "elpete2" );
			} );

			it( "list (with arguments)", function() {
				var users = user.list(
					criteria  = { lastName : "Doe" },
					sortOrder = "username",
					max       = 2,
					offset    = 1,
					asQuery   = false
				);
				expect( users ).toHaveLength( 1 );
				expect( users[ 1 ].getId() ).toBe( 2 );
				expect( users[ 1 ].getUsername() ).toBe( "johndoe" );
			} );

			it( "count", function() {
				expect( user.count() ).toBe( 5 );
			} );

			it( "countWhere", function() {
				expect( user.countWhere( lastName = "Doe", firstName = "Jane" ) ).toBe( 1 );
			} );

			it( "deleteById (single)", function() {
				user.deleteById( 1 );
				expect( function() {
					user.findOrFail( 1 );
				} ).toThrow( type = "EntityNotFound" );
			} );

			it( "deleteById (array)", function() {
				user.deleteById( [ 2, 3 ] );
				expect( function() {
					user.findOrFail( 2 );
				} ).toThrow( type = "EntityNotFound" );
				expect( function() {
					user.findOrFail( 3 );
				} ).toThrow( type = "EntityNotFound" );
			} );

			it( "deleteWhere", function() {
				user.deleteWhere( lastName = "Doe", firstName = "Jane" );
				expect( function() {
					user.findOrFail( 1 );
				} ).notToThrow( type = "EntityNotFound" );
				expect( function() {
					user.findOrFail( 2 );
				} ).notToThrow( type = "EntityNotFound" );
				expect( function() {
					user.findOrFail( 3 );
				} ).toThrow( type = "EntityNotFound" );
			} );

			it( "exists", function() {
				expect( user.exists() ).toBeTrue();
				expect( user.exists( 1 ) ).toBeTrue();
				expect( user.exists( 6 ) ).toBeFalse();
			} );

			it( "findAllWhere", function() {
				var users = user.findAllWhere( { "lastName" : "Doe" } );
				expect( users ).toHaveLength( 2, "Two users should exist in the database and be returned." );
				expect( users[ 1 ].getId() ).toBe( 2 );
				expect( users[ 1 ].getUsername() ).toBe( "johndoe" );
				expect( users[ 2 ].getId() ).toBe( 3 );
				expect( users[ 2 ].getUsername() ).toBe( "janedoe" );
			} );

			it( "findAllWhere (with sort order)", function() {
				var users = user.findAllWhere( { "lastName" : "Doe" }, "username asc" );
				expect( users ).toHaveLength( 2, "Two users should exist in the database and be returned." );
				expect( users[ 1 ].getId() ).toBe( 3 );
				expect( users[ 1 ].getUsername() ).toBe( "janedoe" );
				expect( users[ 2 ].getId() ).toBe( 2 );
				expect( users[ 2 ].getUsername() ).toBe( "johndoe" );
			} );

			it( "findWhere", function() {
				var john = user.findWhere( { firstName : "John" } );
				expect( john.getId() ).toBe( 2 );
				expect( john.getUsername() ).toBe( "johndoe" );
			} );

			it( "get", function() {
				// this is a double get because user is a provider
				var john = user.get().get( 2 );
				expect( john ).notToBeNull();
				expect( john.getId() ).toBe( 2 );
				expect( john.getUsername() ).toBe( "johndoe" );
			} );

			it( "get (returns null)", function() {
				// this is a double get because user is a provider
				expect( user.get().get( 21234124 ) ).toBeNull();
			} );

			it( "get( 0 ) returns a new entity", function() {
				// this is a double get because user is a provider
				var newUser = user.get().get( 0 );
				expect( newUser.isLoaded() ).toBeFalse();
			} );

			it( "getAll", function() {
				var users = user.getAll();
				expect( users[ 1 ].getId() ).toBe( 1 );
				expect( users[ 1 ].getUsername() ).toBe( "elpete" );
				expect( users[ 2 ].getId() ).toBe( 2 );
				expect( users[ 2 ].getUsername() ).toBe( "johndoe" );
				expect( users[ 3 ].getId() ).toBe( 3 );
				expect( users[ 3 ].getUsername() ).toBe( "janedoe" );
			} );

			it( "getAll (sort order)", function() {
				var users = user.getAll( sortOrder = "username desc" );
				expect( users[ 1 ].getId() ).toBe( 5 );
				expect( users[ 1 ].getUsername() ).toBe( "michaelscott" );
				expect( users[ 2 ].getId() ).toBe( 2 );
				expect( users[ 2 ].getUsername() ).toBe( "johndoe" );
				expect( users[ 3 ].getId() ).toBe( 3 );
				expect( users[ 3 ].getUsername() ).toBe( "janedoe" );
				expect( users[ 4 ].getId() ).toBe( 4 );
				expect( users[ 4 ].getUsername() ).toBe( "elpete2" );
			} );

			it( "getAll (id list)", function() {
				var users = user.getAll( "2,3" );
				expect( users[ 1 ].getId() ).toBe( 2 );
				expect( users[ 1 ].getUsername() ).toBe( "johndoe" );
				expect( users[ 2 ].getId() ).toBe( 3 );
				expect( users[ 2 ].getUsername() ).toBe( "janedoe" );
			} );

			it( "getAll (id array)", function() {
				var users = user.getAll( [ "2", "3" ] );
				expect( users[ 1 ].getId() ).toBe( 2 );
				expect( users[ 1 ].getUsername() ).toBe( "johndoe" );
				expect( users[ 2 ].getId() ).toBe( 3 );
				expect( users[ 2 ].getUsername() ).toBe( "janedoe" );
			} );

			it( "new", function() {
				var newUser = user.new();
				expect( newUser.isLoaded() ).toBeFalse();
			} );

			it( "new (with properties)", function() {
				var newUser = user.new( { username : "new_username" } );
				expect( newUser.isLoaded() ).toBeFalse();
				expect( newUser.getUsername() ).toBe( "new_username" );
			} );

			it( "populate", function() {
				var newUser = user.new();
				newUser.populate( { username : "new_username" } );
				expect( newUser.getUsername() ).toBe( "new_username" );
			} );

			describe( "criteria builder compatibility", function() {
				it( "between", function() {
					var rightNow = dateFormat( now(), "mm/dd/yyyy" );
					var lastWeek = dateFormat( dateAdd( "d", -7, rightNow ), "mm/dd/yyyy" );
					var actual   = user
						.newCriteria()
						.between( "created_date", rightNow, lastWeek )
						.getSQL();
					expect( actual ).toBe(
						"SELECT `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`type`, `users`.`username` FROM `users` WHERE `users`.`created_date` BETWEEN ? AND ?"
					);
				} );

				it( "eqProperty", function() {
					var actual = user
						.newCriteria()
						.eqProperty( "created_date", "modified_date" )
						.getSQL();
					expect( actual ).toBe(
						"SELECT `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`type`, `users`.`username` FROM `users` WHERE `users`.`created_date` = `users`.`modified_date`"
					);
				} );

				it( "isEQ", function() {
					var actual = user
						.newCriteria()
						.isEQ( "username", "elpete" )
						.getSQL();
					expect( actual ).toBe(
						"SELECT `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`type`, `users`.`username` FROM `users` WHERE `users`.`username` = ?"
					);
				} );

				it( "isGT", function() {
					var actual = user
						.newCriteria()
						.isGT( "created_date", now() )
						.getSQL();
					expect( actual ).toBe(
						"SELECT `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`type`, `users`.`username` FROM `users` WHERE `users`.`created_date` > ?"
					);
				} );

				it( "gtProperty", function() {
					var actual = user
						.newCriteria()
						.gtProperty( "modified_date", "created_date" )
						.getSQL();
					expect( actual ).toBe(
						"SELECT `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`type`, `users`.`username` FROM `users` WHERE `users`.`modified_date` > `users`.`created_date`"
					);
				} );

				it( "isGE", function() {
					var actual = user
						.newCriteria()
						.isGE( "created_date", now() )
						.getSQL();
					expect( actual ).toBe(
						"SELECT `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`type`, `users`.`username` FROM `users` WHERE `users`.`created_date` >= ?"
					);
				} );

				it( "geProperty", function() {
					var actual = user
						.newCriteria()
						.geProperty( "modified_date", "created_date" )
						.getSQL();
					expect( actual ).toBe(
						"SELECT `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`type`, `users`.`username` FROM `users` WHERE `users`.`modified_date` >= `users`.`created_date`"
					);
				} );

				it( "idEQ", function() {
					var actual = user
						.newCriteria()
						.idEQ( 1 )
						.getSQL();
					expect( actual ).toBe(
						"SELECT `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`type`, `users`.`username` FROM `users` WHERE `users`.`id` = ?"
					);
				} );

				it( "like", function() {
					var actual = user
						.newCriteria()
						.like( "username", "e%" )
						.getSQL();
					expect( actual ).toBe(
						"SELECT `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`type`, `users`.`username` FROM `users` WHERE `users`.`username` LIKE ?"
					);
				} );

				it( "ilike", function() {
					var actual = user
						.newCriteria()
						.ilike( "username", "e%" )
						.getSQL();
					expect( actual ).toBe(
						"SELECT `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`type`, `users`.`username` FROM `users` WHERE `users`.`username` ILIKE ?"
					);
				} );

				it( "isIn", function() {
					var actual = user
						.newCriteria()
						.isIn( "id", [ 2, 3 ] )
						.getSQL();
					expect( actual ).toBe(
						"SELECT `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`type`, `users`.`username` FROM `users` WHERE `users`.`id` IN (?, ?)"
					);
				} );

				it( "isNull", function() {
					var actual = user
						.newCriteria()
						.isNull( "country_id" )
						.getSQL();
					expect( actual ).toBe(
						"SELECT `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`type`, `users`.`username` FROM `users` WHERE `users`.`country_id` IS NULL"
					);
				} );

				it( "isNotNull", function() {
					var actual = user
						.newCriteria()
						.isNotNull( "country_id" )
						.getSQL();
					expect( actual ).toBe(
						"SELECT `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`type`, `users`.`username` FROM `users` WHERE `users`.`country_id` IS NOT NULL"
					);
				} );

				it( "isLT", function() {
					var actual = user
						.newCriteria()
						.isLT( "created_date", now() )
						.getSQL();
					expect( actual ).toBe(
						"SELECT `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`type`, `users`.`username` FROM `users` WHERE `users`.`created_date` < ?"
					);
				} );

				it( "ltProperty", function() {
					var actual = user
						.newCriteria()
						.ltProperty( "created_date", "modified_date" )
						.getSQL();
					expect( actual ).toBe(
						"SELECT `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`type`, `users`.`username` FROM `users` WHERE `users`.`created_date` < `users`.`modified_date`"
					);
				} );

				it( "isLE", function() {
					var actual = user
						.newCriteria()
						.isLE( "created_date", now() )
						.getSQL();
					expect( actual ).toBe(
						"SELECT `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`type`, `users`.`username` FROM `users` WHERE `users`.`created_date` <= ?"
					);
				} );

				it( "leProperty", function() {
					var actual = user
						.newCriteria()
						.leProperty( "created_date", "modified_date" )
						.getSQL();
					expect( actual ).toBe(
						"SELECT `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`type`, `users`.`username` FROM `users` WHERE `users`.`created_date` <= `users`.`modified_date`"
					);
				} );

				it( "neProperty", function() {
					var actual = user
						.newCriteria()
						.neProperty( "created_date", "modified_date" )
						.getSQL();
					expect( actual ).toBe(
						"SELECT `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`type`, `users`.`username` FROM `users` WHERE `users`.`created_date` <> `users`.`modified_date`"
					);
				} );

				it( "maxResults", function() {
					var actual = user
						.newCriteria()
						.maxResults( 10 )
						.getSQL();
					expect( actual ).toBe(
						"SELECT `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`type`, `users`.`username` FROM `users` LIMIT 10"
					);
				} );

				it( "firstResult", function() {
					var actual = user
						.newCriteria()
						.firstResult( 10 )
						.getSQL();
					expect( actual ).toBe(
						"SELECT `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`type`, `users`.`username` FROM `users` OFFSET 10"
					);
				} );

				it( "order", function() {
					var actual = user
						.newCriteria()
						.order( "username" )
						.getSQL();
					expect( actual ).toBe(
						"SELECT `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`type`, `users`.`username` FROM `users` ORDER BY `users`.`username` ASC"
					);
				} );

				it( "list", function() {
					var users = user
						.newCriteria()
						.isIn( "id", [ 2, 3 ] )
						.list();
					expect( users[ 1 ].getId() ).toBe( 2 );
					expect( users[ 1 ].getUsername() ).toBe( "johndoe" );
					expect( users[ 2 ].getId() ).toBe( 3 );
					expect( users[ 2 ].getUsername() ).toBe( "janedoe" );
				} );

				it( "get", function() {
					var john = user
						.newCriteria()
						.isIn( "id", [ 2, 3 ] )
						.get();
					expect( john.getId() ).toBe( 2 );
					expect( john.getUsername() ).toBe( "johndoe" );
				} );

				it( "count", function() {
					var userCount = user
						.newCriteria()
						.isIn( "id", [ 2, 3 ] )
						.count();
					expect( userCount ).toBe( 2 );
				} );
			} );
		} );
	}

}
