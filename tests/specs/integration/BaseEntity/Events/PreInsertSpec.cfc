component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		controller
			.getInterceptorService()
			.registerInterceptor( interceptorObject = this, interceptorName = "PreInsertSpec" );
	}

	function afterAll() {
		controller.getInterceptorService().unregister( "PreInsertSpec" );
		super.afterAll();
	}

	function run() {
		describe( "preInsert spec", function() {
			beforeEach( function() {
				variables.interceptData = {};
			} );

			it( "announces a quickPreInsert interception point", function() {
				var song = getInstance( "Song" ).create( {
					title        : "Rainbow Connection",
					download_url : "https://open.spotify.com/track/1SJ4ycWow4yz6z4oFz8NAG"
				} );
				expect( variables ).toHaveKey( "quickPreInsertCalled" );
				expect( variables.quickPreInsertCalled ).toBeStruct();
				expect( variables.quickPreInsertCalled ).toHaveKey( "entity" );
				expect( variables.quickPreInsertCalled.entity.title ).toBe( "Rainbow Connection" );
				expect( variables.quickPreInsertCalled.isLoaded ).toBeFalse();
				structDelete( variables, "quickPreInsertCalled" );
			} );

			it( "calls any preInsert method on the component", function() {
				var song = getInstance( "Song" ).create( {
					title        : "Rainbow Connection",
					download_url : "https://open.spotify.com/track/1SJ4ycWow4yz6z4oFz8NAG"
				} );
				expect( request ).toHaveKey( "preInsertCalled" );
				expect( request.preInsertCalled ).toBeStruct();
				expect( request.preInsertCalled ).toHaveKey( "entity" );
				expect( request.preInsertCalled.entity.title ).toBe( "Rainbow Connection" );
				expect( request.preInsertCalled.isLoaded ).toBeFalse();
				structDelete( request, "preInsertCalled" );
			} );

			it( "can influence the values being inserted", function() {
				var song = getInstance( "Song" ).create( {
					title        : "Bohemian Rhapsody",
					download_url : "https://open.spotify.com/album/3BHe7LbW5yRjyqXNJ3A6mW"
				} );
				expect( dateFormat( song.refresh().getCreatedDate(), "MM/dd/YYYY" ) ).toBe( "10/31/1975" );
			} );
		} );
	}

	function quickPreInsert(
		event,
		interceptData,
		buffer,
		rc,
		prc
	) {
		if ( arguments.interceptData.entity.getTitle() == "Bohemian Rhapsody" ) {
			arguments.interceptData.entity.assignAttribute( "createdDate", createDate( 1975, 10, 31 ) );
		}

		variables.quickPreInsertCalled = {
			"entity"   : arguments.interceptData.entity.getMemento(),
			"isLoaded" : arguments.interceptData.entity.isLoaded()
		};
	}

}
