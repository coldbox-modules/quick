component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		var interceptorService = getWireBox().getInstance( dsl = "coldbox:interceptorService" );
		interceptorService.registerInterceptor( interceptorObject = this );
	}

	function run() {
		describe( "postLoad spec", function() {
			beforeEach( function() {
				variables.interceptData = {};
			} );

			it( "announces a postLoad interception point", function() {
				var song = getInstance( "Song" ).findOrFail( 1 );
				expect( variables ).toHaveKey( "quickPostLoadCalled" );
				expect( variables.quickPostLoadCalled ).toBeStruct();
				expect( variables.quickPostLoadCalled ).toHaveKey( "entity" );
				expect( variables.quickPostLoadCalled.entity.keyValues() ).toBe( [ 1 ] );
				structDelete( variables, "quickPostLoadCalled" );
			} );

			it( "calls any preLoad method on the component", function() {
				var song = getInstance( "Song" ).findOrFail( 1 );
				expect( request ).toHaveKey( "postLoadCalled" );
				expect( request.postLoadCalled ).toBeStruct();
				expect( request.postLoadCalled ).toHaveKey( "entity" );
				expect( request.postLoadCalled.entity.keyValues() ).toBe( [ 1 ] );
				structDelete( request, "postLoadCalled" );
			} );
		} );
	}

	function quickPostLoad(
		event,
		interceptData,
		buffer,
		rc,
		prc
	) {
		variables.quickPostLoadCalled = arguments.interceptData;
	}

}
