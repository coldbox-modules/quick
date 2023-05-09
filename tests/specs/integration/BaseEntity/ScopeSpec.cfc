component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Scope Spec", function() {
			it( "looks for missing methods as scopes", function() {
				var users = getInstance( "User" ).latest().get();
				expect( users ).toHaveLength( 5, "Five users should exist in the database and be returned." );
				expect( users[ 1 ].getUsername() ).toBe( "michaelscott" );
				expect( users[ 2 ].getUsername() ).toBe( "elpete2" );
				expect( users[ 3 ].getUsername() ).toBe( "janedoe" );
				expect( users[ 4 ].getUsername() ).toBe( "johndoe" );
				expect( users[ 5 ].getUsername() ).toBe( "elpete" );
			} );

			it( "sends through extra parameters as arguments", function() {
				var users = getInstance( "User" ).ofType( "admin" ).get();
				expect( users ).toHaveLength( 2, "Two users should exist in the database and be returned." );
				expect( users[ 1 ].getUsername() ).toBe( "elpete" );
			} );

			it( "allows for default arguments if none are passed in", function() {
				var users = getInstance( "User" ).ofType().get();
				expect( users ).toHaveLength( 3, "Two users should exist in the database and be returned." );
				expect( users[ 1 ].getUsername() ).toBe( "johndoe" );
				expect( users[ 2 ].getUsername() ).toBe( "janedoe" );
				expect( users[ 3 ].getUsername() ).toBe( "michaelscott" );
			} );

			it( "can return values from scopes as well as instances", function() {
				expect( getInstance( "User" ).ofType( "admin" ).resetPasswords() ).toBe( 2 );
			} );

			it( "can use the qb `when` helper in scopes", function() {
				var users = getInstance( "User" ).ofTypeWithWhen( "admin" ).get();
				expect( users ).toHaveLength( 2, "One user should exist in the database and be returned." );
				expect( users[ 1 ].getUsername() ).toBe( "elpete" );
				expect( users[ 2 ].getUsername() ).toBe( "elpete2" );
			} );

			it( "can use scopes inside qb closures", function() {
				var users = getInstance( "User" )
					.where( function( q ) {
						q.ofType( "admin" );
					} )
					.get();
				expect( users ).toHaveLength( 2, "Two users should exist in the database and be returned." );
				expect( users[ 1 ].getUsername() ).toBe( "elpete" );
				expect( users[ 2 ].getUsername() ).toBe( "elpete2" );
			} );

			it( "uses the current table name instead of the entity table name", function() {
				var users = getInstance( "User" )
					.whereIn( "id", function( q ) {
						q.from( "my_posts" )
							.select( "user_id" )
							.whereNotNull( "published_date" );
					} )
					.orderBy( "id" )
					.get();
				expect( users ).toHaveLength( 2, "Two users should exist in the database and be returned." );
				expect( users[ 1 ].getUsername() ).toBe( "elpete" );
				expect( users[ 2 ].getUsername() ).toBe( "elpete2" );
			} );

			it( "wraps scopes in parenthesis automatically if the scope contains an or clause", function() {
				var sql = getInstance( "User" ).canView().toSQL();
				expect( sql ).toBe(
					"SELECT `users`.`city`, `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`externalID`, `users`.`favoritePost_id`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`state`, `users`.`streetOne`, `users`.`streetTwo`, `users`.`team_id`, `users`.`type`, `users`.`username`, `users`.`zip` FROM `users` WHERE (`users`.`type` <> ? OR `users`.`type` = ?)"
				);
			} );

			it( "does not wrap scopes in parenthesis automatically if the scope does not contain an or clause", function() {
				var sql = getInstance( "User" ).ofType( "admin" ).toSQL();
				expect( sql ).toBe(
					"SELECT `users`.`city`, `users`.`country_id`, `users`.`created_date`, `users`.`email`, `users`.`externalID`, `users`.`favoritePost_id`, `users`.`first_name`, `users`.`id`, `users`.`last_name`, `users`.`modified_date`, `users`.`password`, `users`.`state`, `users`.`streetOne`, `users`.`streetTwo`, `users`.`team_id`, `users`.`type`, `users`.`username`, `users`.`zip` FROM `users` WHERE `users`.`type` = ?"
				);
			} );
		} );
	}

}
