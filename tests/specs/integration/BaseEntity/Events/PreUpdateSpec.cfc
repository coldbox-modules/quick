component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

	function beforeAll() {
		super.beforeAll();
		var interceptorService = getWireBox().getInstance( dsl = "coldbox:interceptorService" );
		interceptorService.registerInterceptor( interceptorObject = this );
	}

	function run() {
		describe( "preUpdate spec", function() {
			it( "announces a quickPreUpdate interception point", function() {
				structDelete( request, "quickPreUpdateCalled" );
				var song = getInstance( "Song" ).findOrFail( 1 );
				expect( song.getDownloadUrl() ).toBe( "https://open.spotify.com/track/4Nd5HJn4EExnLmHtClk4QV" );

				song.update( { "downloadUrl" : "https://open.spotify.com/track/0GHGd3jYqChGNxzjqgRZSv" } );

				expect( request ).toHaveKey( "quickPreUpdateCalled" );
				expect( request.quickPreUpdateCalled ).toBeArray();
				expect( request.quickPreUpdateCalled ).toHaveLength( 1 );
				expect( request.quickPreUpdateCalled[ 1 ] ).toBeStruct();
				expect( request.quickPreUpdateCalled[ 1 ] ).toHaveKey( "entity" );
				expect( request.quickPreUpdateCalled[ 1 ].entity.getDownloadUrl() ).toBe(
					"https://open.spotify.com/track/0GHGd3jYqChGNxzjqgRZSv"
				);
				structDelete( request, "quickPreUpdateCalled" );
			} );

			it( "calls any preUpdate method on the component", function() {
				structDelete( request, "preUpdateCalled" );
				var song = getInstance( "Song" ).findOrFail( 1 );
				expect( song.getDownloadUrl() ).toBe( "https://open.spotify.com/track/4Nd5HJn4EExnLmHtClk4QV" );

				song.update( { "downloadUrl" : "https://open.spotify.com/track/0GHGd3jYqChGNxzjqgRZSv" } );

				expect( request ).toHaveKey( "preUpdateCalled" );
				expect( request.preUpdateCalled ).toBeArray();
				expect( request.preUpdateCalled ).toHaveLength( 1 );
				expect( request.preUpdateCalled[ 1 ] ).toBeStruct();
				expect( request.preUpdateCalled[ 1 ] ).toHaveKey( "entity" );
				expect( request.preUpdateCalled[ 1 ].entity.getDownloadUrl() ).toBe(
					"https://open.spotify.com/track/0GHGd3jYqChGNxzjqgRZSv"
				);
				structDelete( request, "preUpdateCalled" );
			} );
		} );
	}

	function quickPreUpdate(
		event,
		interceptData,
		buffer,
		rc,
		prc
	) {
		param request.quickPreUpdateCalled = [];
		arrayAppend( request.quickPreUpdateCalled, duplicate( arguments.interceptData ) );
	}

}
