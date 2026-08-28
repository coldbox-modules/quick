component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		controller
			.getInterceptorService()
			.registerInterceptor( interceptorObject = this, interceptorName = "PostReplicateSpec" );
	}

	function afterAll() {
		controller.getInterceptorService().unregister( "PostReplicateSpec" );
		super.afterAll();
	}

	function run() {
		describe( "postReplicate spec", function() {
			it( "announces a quickPostReplicate interception point", function() {
				var original = getInstance( "Song" ).findOrFail( 1 );
				var replica  = original.replicate();

				expect( variables ).toHaveKey( "quickPostReplicateCalled" );
				expect( variables.quickPostReplicateCalled.entity.isLoaded() ).toBeFalse();
				expect( variables.quickPostReplicateCalled.entity.getTitle() ).toBe( replica.getTitle() );
				expect( variables.quickPostReplicateCalled.original.getId() ).toBe( original.getId() );
				structDelete( variables, "quickPostReplicateCalled" );
			} );

			it( "calls a postReplicate method on the replicated component", function() {
				var original = getInstance( "Song" ).findOrFail( 1 );
				var replica  = original.replicate();

				expect( request ).toHaveKey( "postReplicateCalled" );
				expect( request.postReplicateCalled.entity.isLoaded() ).toBeFalse();
				expect( request.postReplicateCalled.entity.getTitle() ).toBe( replica.getTitle() );
				expect( request.postReplicateCalled.original.getId() ).toBe( original.getId() );
				structDelete( request, "postReplicateCalled" );
			} );
		} );
	}

	function quickPostReplicate(
		event,
		interceptData,
		buffer,
		rc,
		prc
	) {
		variables.quickPostReplicateCalled = arguments.interceptData;
	}

}
