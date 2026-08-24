component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Query Spec", function() {
			it( "returns all records as array", function() {
				var users = getInstance( "User" ).all();
				expect( users ).toHaveLength( 5, "Five users should exist in the database and be returned." );
				expect( users[ 1 ].getId() ).toBe( 1 );
				expect( users[ 1 ].getUsername() ).toBe( "elpete" );
				expect( users[ 2 ].getId() ).toBe( 2 );
				expect( users[ 2 ].getUsername() ).toBe( "johndoe" );
				expect( users[ 3 ].getId() ).toBe( 3 );
				expect( users[ 3 ].getUsername() ).toBe( "janedoe" );
				expect( users[ 4 ].getId() ).toBe( 4 );
				expect( users[ 4 ].getUsername() ).toBe( "elpete2" );
				expect( users[ 5 ].getId() ).toBe( 5 );
				expect( users[ 5 ].getUsername() ).toBe( "michaelscott" );
			} );

			it( "can execute an arbitrary get query", function() {
				var users = getInstance( "User" ).where( "username", "elpete" ).get();
				expect( users ).toHaveLength( 1, "One user should be returned." );
				expect( users[ 1 ].getId() ).toBe( 1 );
				expect( users[ 1 ].getUsername() ).toBe( "elpete" );
			} );

			it( "can execute an arbitrary first query", function() {
				var user = getInstance( "User" ).where( "username", "elpete" ).first();
				expect( user.getId() ).toBe( 1 );
				expect( user.getUsername() ).toBe( "elpete" );
			} );

			it( "can use a QuickBuilder instance anywhere a QueryBuilder instance is accepted", function() {
				var users = getInstance( "User" )
					.whereIn( "username", getInstance( "User" ).select( "username" ).where( "type", "admin" ) )
					.get();

				expect( users ).toHaveLength( 2, "Two users should be returned." );
				expect( users[ 1 ].getId() ).toBe( 1 );
				expect( users[ 1 ].getUsername() ).toBe( "elpete" );
				expect( users[ 2 ].getId() ).toBe( 4 );
				expect( users[ 2 ].getUsername() ).toBe( "elpete2" );
			} );

			it( "can pass simple values directly to QuickQB update", function() {
				var sql = getInstance( "User" )
					.newQuery()
					.getQB()
					.where( "id", 1 )
					.update( values = { "username" : "someValue" }, toSql = true );

				expect( sql ).toInclude( "UPDATE `users` SET `username` = ?" );
			} );

			it( "can upsert records through the entity query API", function() {
				var result = getInstance( "User" ).upsert(
					values = [
						{
							"id"        : 1,
							"username"  : "elpete",
							"firstName" : "Updated",
							"lastName"  : "Peterson"
						},
						{
							"id"        : 99,
							"username"  : "new-user",
							"firstName" : "New",
							"lastName"  : "User"
						}
					],
					target     = "id",
					update     = [ "firstName" ],
					matchNulls = false
				);

				expect( result ).toBeStruct();
				expect( result ).toHaveKey( "query" );
				expect( result ).toHaveKey( "result" );
				expect( getInstance( "User" ).findOrFail( 1 ).getFirstName() ).toBe( "Updated" );
				expect( getInstance( "User" ).findOrFail( 99 ).getFirstName() ).toBe( "New" );
			} );

			it( "guards read-only entities and attributes when upserting", function() {
				expect( function() {
					getInstance( "Referral" ).upsert(
						values = [ { "id" : 1, "type" : "external" } ],
						target = "id",
						update = [ "type" ],
						toSql  = true
					);
				} ).toThrow( "QuickReadOnlyException" );

				expect( function() {
					getInstance( "Link" ).upsert(
						values = [
							{
								"link_id"     : 1,
								"url"         : "https://example.com",
								"createdDate" : now()
							}
						],
						target = "link_id",
						update = [ "url" ],
						toSql  = true
					);
				} ).toThrow( "QuickReadOnlyException" );

				expect( function() {
					getInstance( "Link" ).upsert(
						values = [
							{
								"link_id" : 1,
								"url"     : "https://example.com"
							}
						],
						target = "link_id",
						update = { "createdDate" : now() },
						toSql  = true
					);
				} ).toThrow( "QuickReadOnlyException" );
			} );

			it( "can force an upsert of read-only attributes like updateAll", function() {
				var sql = getInstance( "Link" ).upsert(
					values = [
						{
							"link_id"     : 1,
							"url"         : "https://example.com",
							"createdDate" : now()
						}
					],
					target = "link_id",
					update = { "createdDate" : now() },
					toSql  = true,
					force  = true
				);

				expect( sql ).toInclude( "`created_date`" );
			} );
		} );
	}

}
