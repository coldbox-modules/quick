component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function beforeAll() {
        super.beforeAll();
        var interceptorService = getWireBox().getInstance( dsl = "coldbox:interceptorService" );
        interceptorService.registerInterceptor( interceptorObject = this );
    }

    function run() {
        describe( "postDelete spec", function() {
            it( "announces a quickPostDelete interception point", function() {
                structDelete( request, "quickPostDeleteCalled" );
                var song = getInstance( "Song" ).findOrFail( 1 );

                song.delete();

                expect( request ).toHaveKey( "quickPostDeleteCalled" );
                expect( request.quickPostDeleteCalled ).toBeArray();
                expect( request.quickPostDeleteCalled ).toHaveLength( 1 );
                expect( request.quickPostDeleteCalled[ 1 ] ).toBeStruct();
                expect( request.quickPostDeleteCalled[ 1 ] ).toHaveKey( "entity" );
                expect( request.quickPostDeleteCalled[ 1 ].entity.getId() ).toBe( 1 );
                structDelete( request, "quickPostDeleteCalled" );
            } );

            it( "calls any postDelete method on the component", function() {
                structDelete( request, "postDeleteCalled" );
                var song = getInstance( "Song" ).findOrFail( 1 );

                song.delete();

                expect( request ).toHaveKey( "postDeleteCalled" );
                expect( request.postDeleteCalled ).toBeArray();
                expect( request.postDeleteCalled ).toHaveLength( 1 );
                expect( request.postDeleteCalled[ 1 ] ).toBeStruct();
                expect( request.postDeleteCalled[ 1 ] ).toHaveKey( "entity" );
                expect( request.postDeleteCalled[ 1 ].entity.getId() ).toBe( 1 );
                structDelete( request, "postDeleteCalled" );
            } );

            it( "fires the quickPostDelete interceptor for every record updated in a bulk update", function() {
                structDelete( request, "quickPostDeleteCalled" );

                getInstance( "Song" ).deleteAll();

                expect( request ).toHaveKey( "quickPostDeleteCalled" );
                expect( request.quickPostDeleteCalled ).toBeArray();
                expect( request.quickPostDeleteCalled ).toHaveLength( 2 );
                var onlyTitles = arrayMap( request.quickPostDeleteCalled, function( eventData ) {
                    return eventData.entity.getTitle();
                } );
                arraySort( onlyTitles, "textnocase" );
                expect( onlyTitles ).toBe( [
                    "Ode to Joy",
                    "Open Arms"
                ] );
                structDelete( request, "quickPostDeleteCalled" );
            } );

            it( "fires the postDelete method on the component for every record updated in a bulk update", function() {
                structDelete( request, "postDeleteCalled" );

                getInstance( "Song" ).deleteAll();

                expect( request ).toHaveKey( "postDeleteCalled" );
                expect( request.postDeleteCalled ).toBeArray();
                expect( request.postDeleteCalled ).toHaveLength( 2 );
                var onlyTitles = arrayMap( request.postDeleteCalled, function( eventData ) {
                    return eventData.entity.getTitle();
                } );
                arraySort( onlyTitles, "textnocase" );
                expect( onlyTitles ).toBe( [
                    "Ode to Joy",
                    "Open Arms"
                ] );
                structDelete( request, "postDeleteCalled" );
            } );
        } );
    }

    function quickPostDelete( event, interceptData, buffer, rc, prc ) {
        param request.quickPostDeleteCalled = [];
        arrayAppend( request.quickPostDeleteCalled, duplicate( arguments.interceptData ) );
    }

}
