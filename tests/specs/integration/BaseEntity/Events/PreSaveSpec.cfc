component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		var interceptorService = getWireBox().getInstance( dsl = "coldbox:interceptorService" );
		interceptorService.registerInterceptor( interceptorObject = this );
	}

	function run() {
		describe( "preSave spec", function() {
			it( "announces a quickPreSave interception point on insert", function() {
				var song = getInstance( "Song" ).create( {
					"title"       : "Rainbow Connection",
					"downloadUrl" : "https://open.spotify.com/track/1SJ4ycWow4yz6z4oFz8NAG"
				} );

				expect( variables ).toHaveKey( "quickPreSaveCalled" );
				expect( variables.quickPreSaveCalled ).toBeStruct();
				expect( variables.quickPreSaveCalled ).toHaveKey( "entity" );
				expect( variables.quickPreSaveCalled.entity.getDownloadUrl() ).toBe(
					"https://open.spotify.com/track/1SJ4ycWow4yz6z4oFz8NAG"
				);
				expect( variables.quickPreSaveCalled.entity.isLoaded() ).toBeFalse();
				structDelete( variables, "quickPreSaveCalled" );
			} );

			it( "announces a quickPreSave interception point on update", function() {
				var song = getInstance( "Song" ).findOrFail( 1 );
				expect( song.getDownloadUrl() ).toBe( "https://open.spotify.com/track/4Nd5HJn4EExnLmHtClk4QV" );

				song.update( { "downloadUrl" : "https://open.spotify.com/track/0GHGd3jYqChGNxzjqgRZSv" } );

				expect( variables ).toHaveKey( "quickPreSaveCalled" );
				expect( variables.quickPreSaveCalled ).toBeStruct();
				expect( variables.quickPreSaveCalled ).toHaveKey( "entity" );
				expect( variables.quickPreSaveCalled.entity.getDownloadUrl() ).toBe(
					"https://open.spotify.com/track/0GHGd3jYqChGNxzjqgRZSv"
				);
				structDelete( variables, "quickPreSaveCalled" );
			} );

			it( "calls any preSave method on the component on insert", function() {
				var song = getInstance( "Song" ).create( {
					"title"       : "Rainbow Connection",
					"downloadUrl" : "https://open.spotify.com/track/1SJ4ycWow4yz6z4oFz8NAG"
				} );

				expect( request ).toHaveKey( "preSaveCalled" );
				expect( request.preSaveCalled ).toBeStruct();
				expect( request.preSaveCalled ).toHaveKey( "entity" );
				expect( request.preSaveCalled.entity.getDownloadUrl() ).toBe(
					"https://open.spotify.com/track/1SJ4ycWow4yz6z4oFz8NAG"
				);
				expect( request.preSaveCalled.entity.isLoaded() ).toBeFalse();
				structDelete( request, "preSaveCalled" );
			} );

			it( "calls any preSave method on the component on update", function() {
				var song = getInstance( "Song" ).findOrFail( 1 );
				expect( song.getDownloadUrl() ).toBe( "https://open.spotify.com/track/4Nd5HJn4EExnLmHtClk4QV" );

				song.update( { "downloadUrl" : "https://open.spotify.com/track/0GHGd3jYqChGNxzjqgRZSv" } );

				expect( request ).toHaveKey( "preSaveCalled" );
				expect( request.preSaveCalled ).toBeStruct();
				expect( request.preSaveCalled ).toHaveKey( "entity" );
				expect( request.preSaveCalled.entity.getDownloadUrl() ).toBe(
					"https://open.spotify.com/track/0GHGd3jYqChGNxzjqgRZSv"
				);
				structDelete( request, "preSaveCalled" );
			} );
		} );
	}

	function quickPreSave(
		event,
		interceptData,
		buffer,
		rc,
		prc
	) {
		variables.quickPreSaveCalled = duplicate( arguments.interceptData );
	}

}
