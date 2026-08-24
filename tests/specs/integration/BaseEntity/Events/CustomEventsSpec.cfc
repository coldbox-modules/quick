component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		controller
			.getInterceptorService()
			.registerInterceptor(
				interceptorObject = this,
				interceptorName   = "CustomEventsSpec",
				customPoints      = [
					"onSongCreated",
					"onSongSaved",
					"onMediaSaved"
				]
			);
	}

	function afterAll() {
		controller.getInterceptorService().unregister( "CustomEventsSpec" );
		super.afterAll();
	}

	function run() {
		describe( "custom entity events", function() {
			beforeEach( function() {
				variables.customEvents = [];
			} );

			it( "dispatches string and array interception points for lifecycle events", function() {
				var song = getInstance( "Song" ).create( {
					title        : "Rainbow Connection",
					download_url : "https://open.spotify.com/track/1SJ4ycWow4yz6z4oFz8NAG"
				} );

				expect( variables.customEvents ).toBe( [
					"onSongCreated",
					"onSongSaved",
					"onMediaSaved"
				] );
				expect( variables.customEventEntity.getId() ).toBe( song.getId() );
			} );
		} );
	}

	function onSongCreated( event, interceptData ) {
		variables.customEvents.append( "onSongCreated" );
		variables.customEventEntity = arguments.interceptData.entity;
	}

	function onSongSaved( event, interceptData ) {
		variables.customEvents.append( "onSongSaved" );
		variables.customEventEntity = arguments.interceptData.entity;
	}

	function onMediaSaved( event, interceptData ) {
		variables.customEvents.append( "onMediaSaved" );
		variables.customEventEntity = arguments.interceptData.entity;
	}

}
