component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		controller
			.getInterceptorService()
			.registerInterceptor( interceptorObject = this, interceptorName = "RelationshipLoadingSpec" );
	}

	function afterAll() {
		controller.getInterceptorService().unregister( "RelationshipLoadingSpec" );
		super.afterAll();
	}

	function run() {
		describe( "Eager Loading Spec", function() {
			beforeEach( function() {
				variables.queries = [];
			} );

			it( "can load a relationship for an entity", function() {
				var elpete = getInstance( "User" ).where( "username", "elpete" ).firstOrFail();
				expect( elpete.isRelationshipLoaded( "posts" ) ).toBeFalse();
				elpete.loadRelationship( "posts" );
				expect( elpete.isRelationshipLoaded( "posts" ) ).toBeTrue();
			} );

			it( "does not reload an already loaded relationship", function() {
				var elpete = getInstance( "User" ).where( "username", "elpete" ).firstOrFail();
				expect( elpete.isRelationshipLoaded( "posts" ) ).toBeFalse();
				elpete.loadRelationship( "posts" );
				elpete.loadRelationship( "posts" );
				expect( elpete.isRelationshipLoaded( "posts" ) ).toBeTrue();
				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed" );
			} );

			it( "does reload an already loaded relationship when using the forceLoadRelationship method", function() {
				var elpete = getInstance( "User" ).where( "username", "elpete" ).firstOrFail();
				expect( elpete.isRelationshipLoaded( "posts" ) ).toBeFalse();
				elpete.forceLoadRelationship( "posts" );
				elpete.forceLoadRelationship( "posts" );
				expect( elpete.isRelationshipLoaded( "posts" ) ).toBeTrue();
				expect( variables.queries ).toHaveLength( 3, "Only three queries should have been executed" );
			} );
		} );

		describe( "Dynamic relationships", function() {
			beforeEach( function() {
				variables.queries = [];
			} );

			it( "can load a relationship based off of a subselect column", function() {
				var users = getInstance( "User" )
					.withLatestPost()
					.orderByAsc( "id" )
					.get();
				expect( users ).toHaveLength( 5 );

				var elpete = users[ 1 ];
				expect( elpete.getDynamicLatestPost() ).notToBeNull();
				expect( elpete.getDynamicLatestPost().getPost_Pk() ).toBe( 523526 );

				var johndoe = users[ 2 ];
				expect( johndoe.getDynamicLatestPost() ).toBeNull();

				var janedoe = users[ 3 ];
				expect( janedoe.getDynamicLatestPost() ).toBeNull();

				var elpete2 = users[ 4 ];
				expect( elpete2.getDynamicLatestPost() ).notToBeNull();
				expect( elpete2.getDynamicLatestPost().getPost_Pk() ).toBe( 321 );

				var michaelscott = users[ 5 ];
				expect( michaelscott.getDynamicLatestPost() ).toBeNull();

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed" );

				var postQuery = variables.queries[ 2 ];
				expect( postQuery.result.sqlparameters ).toHaveLength( 2 );
				expect( postQuery.result.sqlparameters ).toBe( [ 321, 523526 ] );
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
		arrayAppend( variables.queries, interceptData );
	}

}
