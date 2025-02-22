component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		controller
			.getInterceptorService()
			.registerInterceptor( interceptorObject = this, interceptorName = "PreDeleteSpec" );
	}

	function afterAll() {
		controller.getInterceptorService().unregister( "PreDeleteSpec" );
		super.afterAll();
	}

	function run() {
		describe( "preDelete spec", function() {
			it( "announces a quickPreDelete interception point", function() {
				structDelete( request, "quickPreDeleteCalled" );
				var song = getInstance( "Song" ).findOrFail( 1 );

				song.delete();

				expect( request ).toHaveKey( "quickPreDeleteCalled" );
				expect( request.quickPreDeleteCalled ).toBeArray();
				expect( request.quickPreDeleteCalled ).toHaveLength( 1 );
				expect( request.quickPreDeleteCalled[ 1 ] ).toBeStruct();
				expect( request.quickPreDeleteCalled[ 1 ] ).toHaveKey( "entity" );
				expect( request.quickPreDeleteCalled[ 1 ].entity.id ).toBe( 1 );
				structDelete( request, "quickPreDeleteCalled" );
			} );

			it( "calls any preDelete method on the component", function() {
				structDelete( request, "preDeleteCalled" );
				var song = getInstance( "Song" ).findOrFail( 1 );

				song.delete();

				expect( request ).toHaveKey( "preDeleteCalled" );
				expect( request.preDeleteCalled ).toBeArray();
				expect( request.preDeleteCalled ).toHaveLength( 1 );
				expect( request.preDeleteCalled[ 1 ] ).toBeStruct();
				expect( request.preDeleteCalled[ 1 ] ).toHaveKey( "entity" );
				expect( request.preDeleteCalled[ 1 ].entity.id ).toBe( 1 );
				structDelete( request, "preDeleteCalled" );
			} );
		} );
	}

	function quickPreDelete(
		event,
		interceptData,
		buffer,
		rc,
		prc
	) {
		param request.quickPreDeleteCalled = [];
		arrayAppend( request.quickPreDeleteCalled, { "entity" : arguments.interceptData.entity.getMemento() } );
	}

}
