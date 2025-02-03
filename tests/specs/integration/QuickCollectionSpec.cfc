component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		controller
			.getInterceptorService()
			.registerInterceptor( interceptorObject = this, interceptorName = "QuickCollectionSpec" );
	}

	function afterAll() {
		controller.getInterceptorService().unregister( "QuickCollectionSpec" );
		super.afterAll();
	}

	function run() {
		describe( "Quick Collection Spec", function() {
			beforeEach( function() {
				variables.queries = [];
			} );

			it(
				title = "can load a relationship lazily",
				body  = function() {
					var posts = getInstance( "CollectionPost" ).all();
					expect( variables.queries ).toHaveLength( 1 );
					expectAll( posts.get() ).toSatisfy( function( post ) {
						return !post.isRelationshipLoaded( "author" );
					}, "The relationship should not be loaded." );
					posts.load( "author" );
					expect( variables.queries ).toHaveLength( 2 );
					expectAll( posts.get() ).toSatisfy( function( post ) {
						return post.isRelationshipLoaded( "author" );
					}, "The relationship should now be loaded." );
				},
				skip = server.keyExists( "boxlang" )
			);
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
