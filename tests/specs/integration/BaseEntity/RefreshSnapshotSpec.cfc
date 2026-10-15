component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Result-set refresh snapshots", function() {
			it( "retrieves fresh projected entities with aliased primary keys", function() {
				var user = getInstance( "AliasedPrimaryKeyUser" ).withFullName().findOrFail( 1 );
				queryExecute( "UPDATE `users` SET `first_name` = ? WHERE `id` = ?", [ "Aliased", 1 ] );

				var fresh = user.fresh();
				expect( fresh.getUserID() ).toBe( 1 );
				expect( fresh.getFullName() ).toBe( "Aliased Peterson" );
				expect( fresh.isLoaded() ).toBeTrue();
				expect( fresh.isDirty( "userID" ) ).toBeFalse();
				expect( fresh.isDirty( "firstName" ) ).toBeFalse();
				expect( fresh.get_refreshQuery() ).toBeSameInstanceAs( user.get_refreshQuery() );
				expect( fresh.fresh().getUserID() ).toBe( 1 );
				expect( user.getFirstName() ).toBe( "Eric" );
			} );

			it( "shares an isolated projection snapshot across get results", function() {
				assertSharedSnapshot( "get" );
			} );

			it( "shares an isolated projection snapshot across paginated results", function() {
				assertSharedSnapshot( "paginate" );
			} );

			it( "shares an isolated projection snapshot across simple paginated results", function() {
				assertSharedSnapshot( "simplePaginate" );
			} );

			it( "takes a separate snapshot for each chunk", function() {
				var users = [];
				getInstance( "User" )
					.withFullName()
					.whereIn( "id", [ 1, 2 ] )
					.orderBy( "id" )
					.chunk( 1, function( batch ) {
						users.append( batch, true );
					} );

				expect( users ).toHaveLength( 2 );
				expect( users[ 1 ].get_refreshQuery() ).notToBeSameInstanceAs( users[ 2 ].get_refreshQuery() );
				assertIndependentRefresh( users );
			} );

			it( "does not clone snapshots when rows have no virtual result data", function() {
				var query = getInstance( "User" ).whereIn( "id", [ 1, 2 ] );
				prepareMock( query.getQB() ).$( "clone" ).$throws( type = "UnexpectedRefreshSnapshot" );
				if ( structKeyExists( query.getQB(), "cloneWithoutWheres" ) ) {
					prepareMock( query.getQB() ).$( "cloneWithoutWheres" ).$throws( type = "UnexpectedRefreshSnapshot" );
				}
				var users = query.get();
				expect( users ).toHaveLength( 2 );
			} );

			it( "preserves bound projections and refresh behavior for directly hydrated entities", function() {
				var query       = getInstance( "UserWithGlobalScope" ).whereUsername( "elpete" ).activateGlobalScopes();
				var rows        = query.getQB().get();
				var user        = query.loadEntity( rows[ 1 ] );
				var snapshotSQL = user.get_refreshQuery().toSQL();
				query.where( "id", -1 );
				expect( user.get_refreshQuery().toSQL() ).toBe( snapshotSQL );
				queryExecute( "UPDATE `users` SET `username` = ? WHERE `id` = ?", [ "direct_hydration", user.getId() ] );
				user.refresh();
				expect( user.getUsername() ).toBe( "direct_hydration" );
				expect( user.getBoundCountryName() ).toBe( "United States" );
			} );

			it( "does not reuse snapshots between separate reads", function() {
				var query      = getInstance( "User" ).withFullName().whereIn( "id", [ 1, 2 ] );
				var firstRead  = query.get();
				var secondRead = query.get();
				expect( firstRead[ 1 ].get_refreshQuery() ).notToBeSameInstanceAs( secondRead[ 1 ].get_refreshQuery() );
			} );

			it( "refreshes stale nested filters while retaining bound global projections and snapshot isolation", function() {
				var user = getInstance( "UserWithGlobalScope" )
					.whereUsername( "elpete" )
					.where( function( query ) {
						query
							.where( "id", 1 )
							.orWhere( function( nested ) {
								nested.where( "id", 2 ).orWhere( "id", 3 );
							} );
					} )
					.firstOrFail();
				var snapshot         = user.get_refreshQuery();
				var snapshotSQL      = snapshot.toSQL();
				var snapshotBindings = duplicate( snapshot.getBindings() );
				queryExecute( "UPDATE `users` SET `username` = ? WHERE `id` = ?", [ "refreshed_user", user.getId() ] );

				user.refresh();
				expect( user.getUsername() ).toBe( "refreshed_user" );
				expect( user.getBoundCountryName() ).toBe( "United States" );
				var fresh = user.fresh();
				expect( fresh.getUsername() ).toBe( "refreshed_user" );
				expect( fresh.getCountryName() ).toBe( "United States" );
				expect( fresh.getBoundCountryName() ).toBe( "United States" );
				expect( snapshot.toSQL() ).toBe( snapshotSQL );
				expect( snapshot.getBindings() ).toBe( snapshotBindings );
			} );
		} );
	}

	private void function assertSharedSnapshot( required string method ) {
		var query = getInstance( "User" )
			.withFullName()
			.whereIn( "id", [ 1, 2 ] )
			.orderBy( "id" );
		var result = invoke( query, arguments.method );
		var users  = arguments.method == "get" ? result : result.results;

		expect( users ).toHaveLength( 2 );
		expect( users[ 1 ].get_refreshQuery() ).toBeSameInstanceAs( users[ 2 ].get_refreshQuery() );
		var snapshotSQL = users[ 1 ].get_refreshQuery().toSQL();
		query.reselect( "id" ).where( "id", -1 );
		expect( users[ 1 ].get_refreshQuery().toSQL() ).toBe( snapshotSQL );
		assertIndependentRefresh( users );
	}

	private void function assertIndependentRefresh( required array users ) {
		var secondFullName = arguments.users[ 2 ].getFullName();
		var secondID       = arguments.users[ 2 ].getId();
		queryExecute(
			"UPDATE `users` SET `first_name` = ? WHERE `id` = ?",
			[
				"Snapshot",
				arguments.users[ 1 ].getId()
			]
		);
		arguments.users[ 1 ].refresh();
		expect( arguments.users[ 1 ].getFullName() ).toBe( "Snapshot Peterson" );
		arguments.users[ 2 ].refresh();
		expect( arguments.users[ 2 ].getId() ).toBe( secondID );
		expect( arguments.users[ 2 ].getFullName() ).toBe( secondFullName );
		var freshUser = arguments.users[ 2 ].fresh();
		expect( freshUser.getId() ).toBe( secondID );
		expect( freshUser.getFullName() ).toBe( secondFullName );
	}

}
