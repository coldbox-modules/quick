component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "asQuery", function() {
			it( "can execute a QuickBuilder query as a qb query", function() {
				var results = getInstance( "User" )
					.newQuery()
					.asQuery()
					.limit( 2 )
					.get();
				expect( results ).toBeArray();
				expect( results ).toHaveLength( 2 );

				for ( var result in results ) {
					result.createdDate  = dateTimeFormat( result.createdDate, "yyyy-mm-dd hh:nn:ss" );
					result.modifiedDate = dateTimeFormat( result.modifiedDate, "yyyy-mm-dd hh:nn:ss" );
				}
				expect( results[ 1 ] ).toBeStruct();
				var expectedFirstResult = {
					"city"            : "Salt Lake City",
					"countryId"       : "02B84D66-0AA0-F7FB-1F71AFC954843861",
					"createdDate"     : "2017-07-28 02:06:36",
					"email"           : "",
					"externalID"      : "1234",
					"favoritePost_id" : 1245,
					"firstName"       : "Eric",
					"id"              : 1,
					"lastName"        : "Peterson",
					"modifiedDate"    : "2017-07-28 02:06:36",
					"password"        : "5F4DCC3B5AA765D61D8327DEB882CF99",
					"state"           : "UT",
					"streetOne"       : "123 Elm Street",
					"streetTwo"       : "",
					"teamId"          : 1,
					"type"            : "admin",
					"username"        : "elpete",
					"zip"             : "84123"
				};
				expect( results[ 2 ] ).toBeStruct();
				var expectedSecondResult = {
					"city"            : "Salt Lake City",
					"countryId"       : "02B84D66-0AA0-F7FB-1F71AFC954843861",
					"createdDate"     : "2017-07-28 02:07:16",
					"email"           : "",
					"externalID"      : "6789",
					"favoritePost_id" : "",
					"firstName"       : "John",
					"id"              : 2,
					"lastName"        : "Doe",
					"modifiedDate"    : "2017-07-28 02:07:16",
					"password"        : "5F4DCC3B5AA765D61D8327DEB882CF99",
					"state"           : "UT",
					"streetOne"       : "123 Elm Street",
					"streetTwo"       : "",
					"teamId"          : 1,
					"type"            : "limited",
					"username"        : "johndoe",
					"zip"             : "84123"
				};
				if ( hasFullNullSupport() ) {
					expect( results[ 1 ].email ).toBeNull();
					expect( results[ 1 ].streetTwo ).toBeNull();
					expect( results[ 2 ].email ).toBeNull();
					expect( results[ 2 ].favoritePost_id ).toBeNull();
					expect( results[ 2 ].streetTwo ).toBeNull();
					results[ 1 ].delete( "email" );
					results[ 1 ].delete( "streetTwo" );
					results[ 2 ].delete( "email" );
					results[ 2 ].delete( "favoritePost_id" );
					results[ 2 ].delete( "streetTwo" );
					expectedFirstResult.delete( "email" );
					expectedFirstResult.delete( "streetTwo" );
					expectedSecondResult.delete( "email" );
					expectedSecondResult.delete( "favoritePost_id" );
					expectedSecondResult.delete( "streetTwo" );
				}
				expect( results[ 1 ] ).toHaveLength( expectedFirstResult.count() );
				expect( results[ 2 ] ).toHaveLength( expectedSecondResult.count() );
				expectedFirstResult.each( ( key, value ) => expect( results[ 1 ][ key ] ).toBe( value ) );
				expectedSecondResult.each( ( key, value ) => expect( results[ 2 ][ key ] ).toBe( value ) );
			} );

			it( "can execute with subselects", function() {
				var results = getInstance( "User" )
					.newQuery()
					.withLatestPostId()
					.limit( 2 )
					.asQuery()
					.get();
				expect( results ).toBeArray();
				expect( results ).toHaveLength( 2 );
				expect( results[ 1 ] ).toBeStruct();
				expect( results[ 1 ] ).toHaveKey( "latestPostId" );
				expect( results[ 1 ][ "latestPostId" ] ).toBe( 523526 );
				expect( results[ 2 ] ).toBeStruct();
				expect( results[ 2 ] ).toHaveKey( "latestPostId" );
				if ( hasFullNullSupport() ) {
					expect( results[ 2 ][ "latestPostId" ] ).toBeNull();
				} else {
					expect( results[ 2 ][ "latestPostId" ] ).toBe( "" );
				}
			} );

			it( "can do eager loading", function() {
				var results = getInstance( "Post" )
					.newQuery()
					.with( [ "author" ] )
					.asQuery()
					.get();

				expect( results ).toBeArray();
				expect( results ).toHaveLength( 4 );

				expect( results[ 1 ] ).toBeStruct();
				expect( results[ 1 ] ).toHaveKey( "author" );
				expect( results[ 1 ][ "author" ] ).toHaveKey( "id" );
				expect( results[ 1 ][ "author" ][ "id" ] ).toBe( 4 );

				expect( results[ 2 ] ).toBeStruct();
				expect( results[ 2 ] ).toHaveKey( "author" );
				expect( results[ 2 ][ "author" ] ).toHaveKey( "id" );
				expect( results[ 2 ][ "author" ][ "id" ] ).toBe( 1 );

				expect( results[ 3 ] ).toBeStruct();
				expect( results[ 3 ] ).toHaveKey( "author" );
				expect( results[ 3 ][ "author" ] ).toBeEmpty();

				expect( results[ 4 ] ).toBeStruct();
				expect( results[ 4 ] ).toHaveKey( "author" );
				expect( results[ 4 ][ "author" ] ).toHaveKey( "id" );
				expect( results[ 4 ][ "author" ][ "id" ] ).toBe( 1 );
			} );
		} );
	}

}
