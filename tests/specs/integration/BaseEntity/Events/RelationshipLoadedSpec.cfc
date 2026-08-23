component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		controller
			.getInterceptorService()
			.registerInterceptor( interceptorObject = this, interceptorName = "RelationshipLoadedSpec" );
	}

	function afterAll() {
		controller.getInterceptorService().unregister( "RelationshipLoadedSpec" );
		super.afterAll();
	}

	function run() {
		describe( "relationshipLoaded", function() {
			beforeEach( function() {
				variables.relationshipLoadedEvents = [];
			} );

			it( "calls a relationship-specific method for lazily loaded entities", function() {
				var user  = getInstance( "RelationshipLoadedUser" ).findOrFail( 1 );
				var posts = user.getPosts();

				expect( posts ).toHaveLength( 2 );
				posts.each( function( post ) {
					expect( post.retrieveRelationship( "loadedByUser" ).isSameAs( user ) ).toBeTrue();
				} );
			} );

			it( "calls a relationship-specific method for eagerly loaded entities", function() {
				var user = getInstance( "RelationshipLoadedUser" ).with( "posts" ).findOrFail( 1 );

				expect( user.getPosts() ).toHaveLength( 2 );
				user.getPosts()
					.each( function( post ) {
						expect( post.retrieveRelationship( "loadedByUser" ).isSameAs( user ) ).toBeTrue();
					} );
			} );

			it( "announces a relationshipLoaded interception point for each related entity", function() {
				var user = getInstance( "RelationshipLoadedUser" ).findOrFail( 1 );
				user.getPosts();

				expect( variables.relationshipLoadedEvents ).toHaveLength( 2 );
				variables.relationshipLoadedEvents.each( function( eventData ) {
					expect( eventData.relationshipName ).toBe( "posts" );
					expect( eventData.parent.isSameAs( user ) ).toBeTrue();
					expect( eventData.entity ).toBeInstanceOf( "Post" );
				} );
			} );
		} );
	}

	function quickRelationshipLoaded(
		event,
		interceptData,
		buffer,
		rc,
		prc
	) {
		variables.relationshipLoadedEvents.append( arguments.interceptData );
	}

}
