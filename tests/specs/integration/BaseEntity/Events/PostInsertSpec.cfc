component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function beforeAll() {
        super.beforeAll();
        var interceptorService = getWireBox().getInstance( dsl = "coldbox:interceptorService" );
        interceptorService.registerInterceptor( interceptorObject = this );
    }

    function run() {
        describe( "postInsert spec", function() {
            beforeEach( function() {
                variables.interceptData = {};
            } );

            it( "announces a quickPostInsert interception point", function() {
                var song = getInstance( "Song" ).create( { title: "Rainbow Connection", download_url: "https://open.spotify.com/track/1SJ4ycWow4yz6z4oFz8NAG" } );
                expect( variables ).toHaveKey( "quickPostInsertCalled" );
                expect( variables.quickPostInsertCalled ).toBeStruct();
                expect( variables.quickPostInsertCalled ).toHaveKey( "entity" );
                expect( variables.quickPostInsertCalled.entity.getTitle() ).toBe( "Rainbow Connection" );
                expect( variables.quickPostInsertCalled.entity.isLoaded() ).toBeTrue();
                structDelete( variables, "quickPostInsertCalled" );
            } );

            it( "calls any postInsert method on the component", function() {
                var song = getInstance( "Song" ).create( { title: "Rainbow Connection", download_url: "https://open.spotify.com/track/1SJ4ycWow4yz6z4oFz8NAG" } );
                expect( request ).toHaveKey( "postInsertCalled" );
                expect( request.postInsertCalled ).toBeStruct();
                expect( request.postInsertCalled ).toHaveKey( "entity" );
                expect( request.postInsertCalled.entity.getTitle() ).toBe( "Rainbow Connection" );
                expect( request.postInsertCalled.entity.isLoaded() ).toBeTrue();
                structDelete( request, "postInsertCalled" );
            } );
        } );
    }

    function quickPostInsert(
        event,
        interceptData,
        buffer,
        rc,
        prc
    ) {
        variables.quickPostInsertCalled = duplicate( arguments.interceptData );
    }

}
