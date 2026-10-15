component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Result-set refresh snapshots", function() {
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
				var users = query.get();
				expect( users ).toHaveLength( 2 );
			} );

			it( "does not reuse snapshots between separate reads", function() {
				var query      = getInstance( "User" ).withFullName().whereIn( "id", [ 1, 2 ] );
				var firstRead  = query.get();
				var secondRead = query.get();
				expect( firstRead[ 1 ].get_refreshQuery() ).notToBeSameInstanceAs( secondRead[ 1 ].get_refreshQuery() );
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
