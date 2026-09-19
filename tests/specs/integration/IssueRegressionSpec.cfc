component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Issue regressions", function() {
			it( "passes a Quick query to qb using getQB (issue 226)", function() {
				var users = getInstance( "User" ).whereId( 1 ).select( "id" );
				var rows  = getInstance( "QueryBuilder@qb" )
					.from( "users" )
					.whereIn( "id", users.getQB() )
					.get();
				expect( rows ).toHaveLength( 1 );
				expect( rows[ 1 ].id ).toBe( 1 );
			} );

			it( "retains retrieveQuery for qb subquery interoperability (issue 226)", function() {
				var users = getInstance( "User" )
					.whereId( 1 )
					.asQuery()
					.reselect( "id" );
				var rows = getInstance( "QueryBuilder@qb" )
					.from( "users" )
					.whereIn( "id", users.retrieveQuery() )
					.get();
				expect( rows ).toHaveLength( 1 );
				expect( rows[ 1 ].id ).toBe( 1 );
			} );

			it( "returns null from a known virtual attribute getter (issue 363)", function() {
				var user = getInstance( "User" ).appendVirtualAttribute( "missingValue" );
				user.clearAttribute( "missingValue", true );
				expect( isNull( user.getMissingValue() ) ).toBe( isNull( user.retrieveAttribute( "missingValue" ) ) );
			} );

			it( "returns null from a column alias getter (issue 363)", function() {
				var user = getInstance( "User" );
				user.clearAttribute( "firstName", true );
				expect( isNull( user.getFirst_Name() ) ).toBe( isNull( user.retrieveAttribute( "firstName" ) ) );
			} );

			it( "still throws for unknown attribute getters (issue 363)", function() {
				expect( function() {
					getInstance( "User" ).getDefinitelyNotAnAttribute();
				} ).toThrow( "QuickMissingMethod" );
			} );

			it( "accepts a qb subquery as a where value (issue 362)", function() {
				var subquery = getInstance( "QueryBuilder@qb" )
					.from( "users" )
					.select( "id" )
					.where( "id", 1 );
				var user = getInstance( "User" ).whereId( subquery ).firstOrFail();
				expect( user.getId() ).toBe( 1 );
			} );

			it( "accepts a Quick subquery as a where value (issue 362)", function() {
				var subquery = getInstance( "User" ).select( "id" ).whereId( 1 );
				var user     = getInstance( "User" ).where( "id", "=", subquery ).firstOrFail();
				expect( user.getId() ).toBe( 1 );
			} );

			it( "accepts a SQL expression as a where value (issue 362)", function() {
				var expression = getInstance( "QueryBuilder@qb" ).raw( "1" );
				var user       = getInstance( "User" ).whereId( expression ).firstOrFail();
				expect( user.getId() ).toBe( 1 );
			} );

			it( "allows attaching no related entities (issue 364)", function() {
				var post        = getInstance( "Post" ).firstOrFail();
				var beforeCount = post.tags().count();
				post.tags().attach( [] );
				expect( post.tags().count() ).toBe( beforeCount );
			} );
		} );
	}

}
