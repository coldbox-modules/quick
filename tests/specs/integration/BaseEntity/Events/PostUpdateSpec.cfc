component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function beforeAll() {
        super.beforeAll();
        var interceptorService = getWireBox().getInstance( dsl = "coldbox:interceptorService" );
        interceptorService.registerInterceptor( interceptorObject = this );
    }

    function run() {
        describe( "postUpdate spec", function() {
            it( "announces a quickPostUpdate interception point", function() {
                structDelete( request, "quickPostUpdateCalled" );
                var song = getInstance( "Song" ).findOrFail( 1 );
                expect( song.getDownloadUrl() ).toBe( "https://open.spotify.com/track/4Nd5HJn4EExnLmHtClk4QV" );

                song.update( { "downloadUrl" = "https://open.spotify.com/track/0GHGd3jYqChGNxzjqgRZSv" } );

                expect( request ).toHaveKey( "quickPostUpdateCalled" );
                expect( request.quickPostUpdateCalled ).toBeArray();
                expect( request.quickPostUpdateCalled ).toHaveLength( 1 );
                expect( request.quickPostUpdateCalled[ 1 ] ).toBeStruct();
                expect( request.quickPostUpdateCalled[ 1 ] ).toHaveKey( "entity" );
                expect( request.quickPostUpdateCalled[ 1 ].entity.getDownloadUrl() ).toBe( "https://open.spotify.com/track/0GHGd3jYqChGNxzjqgRZSv" );
                structDelete( request, "quickPostUpdateCalled" );
            } );

            it( "calls any postUpdate method on the component", function() {
                structDelete( request, "postUpdateCalled" );
                var song = getInstance( "Song" ).findOrFail( 1 );
                expect( song.getDownloadUrl() ).toBe( "https://open.spotify.com/track/4Nd5HJn4EExnLmHtClk4QV" );

                song.update( { "downloadUrl" = "https://open.spotify.com/track/0GHGd3jYqChGNxzjqgRZSv" } );

                expect( request ).toHaveKey( "postUpdateCalled" );
                expect( request.postUpdateCalled ).toBeArray();
                expect( request.postUpdateCalled ).toHaveLength( 1 );
                expect( request.postUpdateCalled[ 1 ] ).toBeStruct();
                expect( request.postUpdateCalled[ 1 ] ).toHaveKey( "entity" );
                expect( request.postUpdateCalled[ 1 ].entity.getDownloadUrl() ).toBe( "https://open.spotify.com/track/0GHGd3jYqChGNxzjqgRZSv" );
                structDelete( request, "postUpdateCalled" );
            } );

            it( "fires the quickPostUpdate interceptor for every record updated in a bulk update", function() {
                structDelete( request, "quickPostUpdateCalled" );

                getInstance( "Song" ).updateAll( {
                    "modifiedDate" = now()
                } );

                expect( request ).toHaveKey( "quickPostUpdateCalled" );
                expect( request.quickPostUpdateCalled ).toBeArray();
                expect( request.quickPostUpdateCalled ).toHaveLength( 2 );
                var onlyTitles = arrayMap( request.quickPostUpdateCalled, function( eventData ) {
                    return eventData.entity.getTitle();
                } );
                arraySort( onlyTitles, "textnocase" );
                expect( onlyTitles ).toBe( [
                    "Ode to Joy",
                    "Open Arms"
                ] );
                structDelete( request, "quickPostUpdateCalled" );
            } );

            it( "fires the postUpdate method on the component for every record updated in a bulk update", function() {
                structDelete( request, "postUpdateCalled" );

                getInstance( "Song" ).updateAll( {
                    "modifiedDate" = now()
                } );

                expect( request ).toHaveKey( "postUpdateCalled" );
                expect( request.postUpdateCalled ).toBeArray();
                expect( request.postUpdateCalled ).toHaveLength( 2 );
                var onlyTitles = arrayMap( request.postUpdateCalled, function( eventData ) {
                    return eventData.entity.getTitle();
                } );
                arraySort( onlyTitles, "textnocase" );
                expect( onlyTitles ).toBe( [
                    "Ode to Joy",
                    "Open Arms"
                ] );
                structDelete( request, "postUpdateCalled" );
            } );
        } );
    }

    function quickPostUpdate( event, interceptData, buffer, rc, prc ) {
        param request.quickPostUpdateCalled = [];
        arrayAppend( request.quickPostUpdateCalled, duplicate( arguments.interceptData ) );
    }

}
