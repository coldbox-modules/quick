component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

	function beforeAll() {
		super.beforeAll();
		controller.getInterceptorService().registerInterceptor( interceptorObject = this );
	}

	function run() {
		describe( "Eager Loading Spec", function() {
			beforeEach( function() {
				variables.queries = [];
			} );

			it( "can load a relationship for an entity", function() {
				var elpete = variables.fixtures
					.with( "User" )
					.asEntity()
					.find( "elpete" );
				expect( elpete.isRelationshipLoaded( "posts" ) ).toBeFalse();
				elpete.loadRelationship( "posts" );
				expect( elpete.isRelationshipLoaded( "posts" ) ).toBeTrue();
			} );

			it( "does not reload an already loaded relationship", function() {
				var elpete = variables.fixtures
					.with( "User" )
					.asEntity()
					.find( "elpete" );
				expect( elpete.isRelationshipLoaded( "posts" ) ).toBeFalse();
				elpete.loadRelationship( "posts" );
				elpete.loadRelationship( "posts" );
				expect( elpete.isRelationshipLoaded( "posts" ) ).toBeTrue();
				debug( variables.queries );
				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed" );
			} );

			it( "does reload an already loaded relationship when using the forceLoadRelationship method", function() {
				var elpete = variables.fixtures
					.with( "User" )
					.asEntity()
					.find( "elpete" );
				expect( elpete.isRelationshipLoaded( "posts" ) ).toBeFalse();
				elpete.forceLoadRelationship( "posts" );
				elpete.forceLoadRelationship( "posts" );
				expect( elpete.isRelationshipLoaded( "posts" ) ).toBeTrue();
				debug( variables.queries );
				expect( variables.queries ).toHaveLength( 3, "Only three queries should have been executed" );
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
