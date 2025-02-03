component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		controller
			.getInterceptorService()
			.registerInterceptor( interceptorObject = this, interceptorName = "PostDeleteSpec" );
	}

	function afterAll() {
		controller.getInterceptorService().unregister( "PostDeleteSpec" );
		super.afterAll();
	}

	function run() {
		describe( "postDelete spec", function() {
			it( "announces a quickPostDelete interception point", function() {
				structDelete( request, "quickPostDeleteCalled" );
				var song = getInstance( "Song" ).findOrFail( 1 );

				song.delete();

				expect( request ).toHaveKey( "quickPostDeleteCalled" );
				expect( request.quickPostDeleteCalled ).toBeArray();
				expect( request.quickPostDeleteCalled ).toHaveLength( 1 );
				expect( request.quickPostDeleteCalled[ 1 ] ).toBeStruct();
				expect( request.quickPostDeleteCalled[ 1 ] ).toHaveKey( "entity" );
				expect( request.quickPostDeleteCalled[ 1 ].entity.id ).toBe( 1 );
				structDelete( request, "quickPostDeleteCalled" );
			} );

			it( "calls any postDelete method on the component", function() {
				structDelete( request, "postDeleteCalled" );
				var song = getInstance( "Song" ).findOrFail( 1 );

				song.delete();

				expect( request ).toHaveKey( "postDeleteCalled" );
				expect( request.postDeleteCalled ).toBeArray();
				expect( request.postDeleteCalled ).toHaveLength( 1 );
				expect( request.postDeleteCalled[ 1 ] ).toBeStruct();
				expect( request.postDeleteCalled[ 1 ] ).toHaveKey( "entity" );
				expect( request.postDeleteCalled[ 1 ].entity.id ).toBe( 1 );
				structDelete( request, "postDeleteCalled" );
			} );
		} );
	}

	function quickPostDelete(
		event,
		interceptData,
		buffer,
		rc,
		prc
	) {
		param request.quickPostDeleteCalled = [];
		arrayAppend( request.quickPostDeleteCalled, { "entity" : arguments.interceptData.entity.getMemento() } );
	}

}
