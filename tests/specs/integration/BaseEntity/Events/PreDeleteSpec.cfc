component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function beforeAll() {
        super.beforeAll();
        var interceptorService = getWireBox().getInstance( dsl = "coldbox:interceptorService" );
        interceptorService.registerInterceptor( interceptorObject = this );
    }

    function run() {
        describe( "preDelete spec", function() {
            it( "announces a quickPreDelete interception point", function() {
                structDelete( request, "quickPreDeleteCalled" );
                var song = getInstance( "Song" ).findOrFail( 1 );

                song.delete();

                expect( request ).toHaveKey( "quickPreDeleteCalled" );
                expect( request.quickPreDeleteCalled ).toBeArray();
                expect( request.quickPreDeleteCalled ).toHaveLength( 1 );
                expect( request.quickPreDeleteCalled[ 1 ] ).toBeStruct();
                expect( request.quickPreDeleteCalled[ 1 ] ).toHaveKey( "entity" );
                expect( request.quickPreDeleteCalled[ 1 ].entity.getId() ).toBe( 1 );
                structDelete( request, "quickPreDeleteCalled" );
            } );

            it( "calls any preDelete method on the component", function() {
                structDelete( request, "preDeleteCalled" );
                var song = getInstance( "Song" ).findOrFail( 1 );

                song.delete();

                expect( request ).toHaveKey( "preDeleteCalled" );
                expect( request.preDeleteCalled ).toBeArray();
                expect( request.preDeleteCalled ).toHaveLength( 1 );
                expect( request.preDeleteCalled[ 1 ] ).toBeStruct();
                expect( request.preDeleteCalled[ 1 ] ).toHaveKey( "entity" );
                expect( request.preDeleteCalled[ 1 ].entity.getId() ).toBe( 1 );
                structDelete( request, "preDeleteCalled" );
            } );

            it( "fires the quickPreDelete interceptor for every record updated in a bulk update", function() {
                structDelete( request, "quickPreDeleteCalled" );

                getInstance( "Song" ).deleteAll();

                expect( request ).toHaveKey( "quickPreDeleteCalled" );
                expect( request.quickPreDeleteCalled ).toBeArray();
                expect( request.quickPreDeleteCalled ).toHaveLength( 2 );
                var onlyTitles = arrayMap( request.quickPreDeleteCalled, function( eventData ) {
                    return eventData.entity.getTitle();
                } );
                arraySort( onlyTitles, "textnocase" );
                expect( onlyTitles ).toBe( [
                    "Ode to Joy",
                    "Open Arms"
                ] );
                structDelete( request, "quickPreDeleteCalled" );
            } );

            it( "fires the preDelete method on the component for every record updated in a bulk update", function() {
                structDelete( request, "preDeleteCalled" );

                getInstance( "Song" ).deleteAll();

                expect( request ).toHaveKey( "preDeleteCalled" );
                expect( request.preDeleteCalled ).toBeArray();
                expect( request.preDeleteCalled ).toHaveLength( 2 );
                var onlyTitles = arrayMap( request.preDeleteCalled, function( eventData ) {
                    return eventData.entity.getTitle();
                } );
                arraySort( onlyTitles, "textnocase" );
                expect( onlyTitles ).toBe( [
                    "Ode to Joy",
                    "Open Arms"
                ] );
                structDelete( request, "preDeleteCalled" );
            } );
        } );
    }

    function quickPreDelete( event, interceptData, buffer, rc, prc ) {
        param request.quickPreDeleteCalled = [];
        arrayAppend( request.quickPreDeleteCalled, duplicate( arguments.interceptData ) );
    }

}
