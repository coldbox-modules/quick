component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Mass Create Spec", function() {
			it( "can mass update all entities that fit the query criteria", function() {
				var postA = getInstance( "Post" ).find( 1245 );
				var postB = getInstance( "Post" ).find( 523526 );

				expect( postA.getBody() ).notToBe( "The new body" );
				expect( postB.getBody() ).notToBe( "The new body" );

				getInstance( "Post" ).updateAll( { "body" : "The new body" } );

				postA.refresh();
				postB.refresh();

				expect( postA.getBody() ).toBe( "The new body" );
				expect( postB.getBody() ).toBe( "The new body" );
			} );

			it( "can update date values after switching to query results", function() {
				var originalDate = getInstance( "User" ).findOrFail( 1 ).getModifiedDate();
				var futureDate   = now().add( "d", 1 );

				var result = getInstance( "User" )
					.where( "id", 1 )
					.asQuery()
					.update( { "modified_date" : futureDate } );

				expect( result.result.recordCount ).toBe( 1 );
				expect( getInstance( "User" ).findOrFail( 1 ).getModifiedDate() ).notToBe( originalDate );
			} );

			it( "can update date values through the underlying query", function() {
				var originalDate = getInstance( "User" ).findOrFail( 1 ).getModifiedDate();
				var futureDate   = now().add( "d", 2 );

				var result = getInstance( "User" )
					.where( "id", 1 )
					.retrieveQuery()
					.update( { "modified_date" : futureDate } );

				expect( result.result.recordCount ).toBe( 1 );
				expect( getInstance( "User" ).findOrFail( 1 ).getModifiedDate() ).notToBe( originalDate );
			} );
		} );
	}

}
