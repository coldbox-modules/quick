component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function beforeAll() {
        super.beforeAll();
        var interceptorService = getWireBox().getInstance( dsl = "coldbox:interceptorService" );
        interceptorService.registerInterceptor( interceptorObject = this );
    }

    function run() {
        describe( "preLoad spec", function() {
            beforeEach( function() {
                variables.interceptData = {};
            } );

            it( "announces a preLoad interception point", function() {
                var song = getInstance( "Song" ).findOrFail( 1 );
                expect( variables ).toHaveKey( "quickPreLoadCalled" );
                expect( variables.quickPreLoadCalled ).toBeStruct();
                expect( variables.quickPreLoadCalled ).toHaveKey( "id" );
                expect( variables.quickPreLoadCalled.id ).toBe( 1 );
                expect( variables.quickPreLoadCalled ).toHaveKey( "metadata" );
                structDelete( variables, "quickPreLoadCalled" );
            } );

            it( "calls any preLoad method on the component", function() {
                var song = getInstance( "Song" ).findOrFail( 1 );
                expect( request ).toHaveKey( "preLoadCalled" );
                expect( request.preLoadCalled ).toBeStruct();
                expect( request.preLoadCalled ).toHaveKey( "id" );
                expect( request.preLoadCalled.id ).toBe( 1 );
                expect( request.preLoadCalled ).toHaveKey( "metadata" );
                structDelete( request, "preLoadCalled" );
            } );
        } );
    }

    function quickPreLoad( event, interceptData, buffer, rc, prc ) {
        variables.quickPreLoadCalled = arguments.interceptData;
    }

}
