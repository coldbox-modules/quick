component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		controller
			.getInterceptorService()
			.registerInterceptor( interceptorObject = this, interceptorName = "PostSaveSpec" );
	}

	function afterAll() {
		controller.getInterceptorService().unregister( "PostSaveSpec" );
		super.afterAll();
	}

	function run() {
		describe( "postSave spec", function() {
			it( "announces a quickPostSave interception point on insert", function() {
				var song = getInstance( "Song" ).create( {
					"title"       : "Rainbow Connection",
					"downloadUrl" : "https://open.spotify.com/track/1SJ4ycWow4yz6z4oFz8NAG"
				} );

				expect( variables ).toHaveKey( "quickPostSaveCalled" );
				expect( variables.quickPostSaveCalled ).toBeStruct();
				expect( variables.quickPostSaveCalled ).toHaveKey( "entity" );
				expect( variables.quickPostSaveCalled.entity.downloadUrl ).toBe(
					"https://open.spotify.com/track/1SJ4ycWow4yz6z4oFz8NAG"
				);
				expect( variables.quickPostSaveCalled.isLoaded ).toBeTrue();
				structDelete( variables, "quickPostSaveCalled" );
			} );

			it( "announces a quickPostSave interception point on update", function() {
				var song = getInstance( "Song" ).findOrFail( 1 );
				expect( song.getDownloadUrl() ).toBe( "https://open.spotify.com/track/4Nd5HJn4EExnLmHtClk4QV" );

				song.update( { "downloadUrl" : "https://open.spotify.com/track/0GHGd3jYqChGNxzjqgRZSv" } );

				expect( variables ).toHaveKey( "quickPostSaveCalled" );
				expect( variables.quickPostSaveCalled ).toBeStruct();
				expect( variables.quickPostSaveCalled ).toHaveKey( "entity" );
				expect( variables.quickPostSaveCalled.entity.downloadUrl ).toBe(
					"https://open.spotify.com/track/0GHGd3jYqChGNxzjqgRZSv"
				);
				structDelete( variables, "quickPostSaveCalled" );
			} );

			it( "calls any postSave method on the component on insert", function() {
				var song = getInstance( "Song" ).create( {
					"title"       : "Rainbow Connection",
					"downloadUrl" : "https://open.spotify.com/track/1SJ4ycWow4yz6z4oFz8NAG"
				} );

				expect( request ).toHaveKey( "postSaveCalled" );
				expect( request.postSaveCalled ).toBeStruct();
				expect( request.postSaveCalled ).toHaveKey( "entity" );
				expect( request.postSaveCalled.entity.downloadUrl ).toBe(
					"https://open.spotify.com/track/1SJ4ycWow4yz6z4oFz8NAG"
				);
				expect( request.postSaveCalled.isLoaded ).toBeTrue();
				structDelete( request, "postSaveCalled" );
			} );

			it( "calls any postSave method on the component on update", function() {
				var song = getInstance( "Song" ).findOrFail( 1 );
				expect( song.getDownloadUrl() ).toBe( "https://open.spotify.com/track/4Nd5HJn4EExnLmHtClk4QV" );

				song.update( { "downloadUrl" : "https://open.spotify.com/track/0GHGd3jYqChGNxzjqgRZSv" } );

				expect( request ).toHaveKey( "postSaveCalled" );
				expect( request.postSaveCalled ).toBeStruct();
				expect( request.postSaveCalled ).toHaveKey( "entity" );
				expect( request.postSaveCalled.entity.downloadUrl ).toBe(
					"https://open.spotify.com/track/0GHGd3jYqChGNxzjqgRZSv"
				);
				structDelete( request, "postSaveCalled" );
			} );

			it( "skips events when called inside a withoutFiringEvents callback", function() {
				var song = getInstance( "Song" ).findOrFail( 1 );
				expect( song.getDownloadUrl() ).toBe( "https://open.spotify.com/track/4Nd5HJn4EExnLmHtClk4QV" );

				song.withoutFiringEvents( () => {
					song.update( { "downloadUrl" : "https://open.spotify.com/track/0GHGd3jYqChGNxzjqgRZSv" } );
				} );

				expect( request ).notToHaveKey( "postSaveCalled" );
			} );
		} );
	}

	function quickPostSave(
		event,
		interceptData,
		buffer,
		rc,
		prc
	) {
		variables.quickPostSaveCalled = {
			"entity"   : arguments.interceptData.entity.getMemento(),
			"isLoaded" : arguments.interceptData.entity.isLoaded()
		};
	}

}
