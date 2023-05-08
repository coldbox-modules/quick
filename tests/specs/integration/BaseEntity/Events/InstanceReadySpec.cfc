component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		var interceptorService = getWireBox().getInstance( dsl = "coldbox:interceptorService" );
		interceptorService.registerInterceptor( interceptorObject = this );
	}

	function run() {
		describe( "instanceReady spec", function() {
			beforeEach( function() {
				variables.interceptData = {};
			} );

			it( "announces an instanceReady interception point", function() {
				var song = getInstance( "Song" ).findOrFail( 1 );
				expect( variables ).toHaveKey( "quickInstanceReadyCalled" );
				expect( variables.quickInstanceReadyCalled ).toBeStruct();
				expect( variables.quickInstanceReadyCalled ).toHaveKey( "entity" );
				structDelete( variables, "quickInstanceReadyCalled" );
			} );

			it( "calls any preLoad method on the component", function() {
				var song = getInstance( "Song" ).findOrFail( 1 );
				expect( request ).toHaveKey( "instanceReadyCalled" );
				expect( request.instanceReadyCalled ).toBeStruct();
				expect( request.instanceReadyCalled ).toHaveKey( "entity" );
				structDelete( request, "instanceReadyCalled" );
			} );
		} );
	}

	function quickInstanceReady(
		event,
		interceptData,
		buffer,
		rc,
		prc
	) {
		variables.quickInstanceReadyCalled = arguments.interceptData;
	}

}
