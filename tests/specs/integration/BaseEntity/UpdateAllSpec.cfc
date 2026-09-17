component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		controller
			.getInterceptorService()
			.registerInterceptor( interceptorObject = this, interceptorName = "UpdateAllSpec" );
	}

	function afterAll() {
		controller.getInterceptorService().unregister( "UpdateAllSpec" );
		super.afterAll();
	}

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

			it( "discards irrelevant ordering before an unbounded bulk update", function() {
				structDelete( request, "updateAllSpecPreQBExecute" );

				getInstance( "Post" ).orderByDesc( "createdDate" ).updateAll( { "body" : "The new body" } );

				expect( request.updateAllSpecPreQBExecute ).toHaveLength( 1 );
				expect( request.updateAllSpecPreQBExecute[ 1 ].sql ).notToInclude( "ORDER BY" );
			} );

			it( "preserves ordering that selects rows for a limited bulk update", function() {
				structDelete( request, "updateAllSpecPreQBExecute" );

				getInstance( "Post" )
					.orderByDesc( "createdDate" )
					.limit( 1 )
					.updateAll( { "body" : "The new body" } );

				expect( request.updateAllSpecPreQBExecute ).toHaveLength( 1 );
				expect( request.updateAllSpecPreQBExecute[ 1 ].sql ).toInclude( "ORDER BY" );
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

	function preQBExecute(
		event,
		interceptData,
		buffer,
		rc,
		prc
	) {
		param request.updateAllSpecPreQBExecute = [];
		request.updateAllSpecPreQBExecute.append( duplicate( arguments.interceptData ) );
	}

}
