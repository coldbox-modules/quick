component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function beforeAll() {
        super.beforeAll();
        var interceptorService = getWireBox().getInstance(
            dsl = "coldbox:interceptorService"
        );
        interceptorService.registerInterceptor( interceptorObject = this );
    }

    function run() {
        describe( "postSave spec", function() {
            it( "announces a quickPostSave interception point on insert", function() {
                var song = getInstance( "Song" ).create( {
                    "title": "Rainbow Connection",
                    "downloadUrl": "https://open.spotify.com/track/1SJ4ycWow4yz6z4oFz8NAG"
                } );

                expect( variables ).toHaveKey( "quickPostSaveCalled" );
                expect( variables.quickPostSaveCalled ).toBeStruct();
                expect( variables.quickPostSaveCalled ).toHaveKey( "entity" );
                expect( variables.quickPostSaveCalled.entity.getDownloadUrl() ).toBe(
                    "https://open.spotify.com/track/1SJ4ycWow4yz6z4oFz8NAG"
                );
                expect( variables.quickPostSaveCalled.entity.isLoaded() ).toBeTrue();
                structDelete( variables, "quickPostSaveCalled" );
            } );

            it( "announces a quickPostSave interception point on update", function() {
                var song = getInstance( "Song" ).findOrFail( 1 );
                expect( song.getDownloadUrl() ).toBe(
                    "https://open.spotify.com/track/4Nd5HJn4EExnLmHtClk4QV"
                );

                song.update( {
                    "downloadUrl": "https://open.spotify.com/track/0GHGd3jYqChGNxzjqgRZSv"
                } );

                expect( variables ).toHaveKey( "quickPostSaveCalled" );
                expect( variables.quickPostSaveCalled ).toBeStruct();
                expect( variables.quickPostSaveCalled ).toHaveKey( "entity" );
                expect( variables.quickPostSaveCalled.entity.getDownloadUrl() ).toBe(
                    "https://open.spotify.com/track/0GHGd3jYqChGNxzjqgRZSv"
                );
                structDelete( variables, "quickPostSaveCalled" );
            } );

            it( "calls any postSave method on the component on insert", function() {
                var song = getInstance( "Song" ).create( {
                    "title": "Rainbow Connection",
                    "downloadUrl": "https://open.spotify.com/track/1SJ4ycWow4yz6z4oFz8NAG"
                } );

                expect( request ).toHaveKey( "postSaveCalled" );
                expect( request.postSaveCalled ).toBeStruct();
                expect( request.postSaveCalled ).toHaveKey( "entity" );
                expect( request.postSaveCalled.entity.getDownloadUrl() ).toBe(
                    "https://open.spotify.com/track/1SJ4ycWow4yz6z4oFz8NAG"
                );
                expect( request.postSaveCalled.entity.isLoaded() ).toBeTrue();
                structDelete( request, "postSaveCalled" );
            } );

            it( "calls any postSave method on the component on update", function() {
                var song = getInstance( "Song" ).findOrFail( 1 );
                expect( song.getDownloadUrl() ).toBe(
                    "https://open.spotify.com/track/4Nd5HJn4EExnLmHtClk4QV"
                );

                song.update( {
                    "downloadUrl": "https://open.spotify.com/track/0GHGd3jYqChGNxzjqgRZSv"
                } );

                expect( request ).toHaveKey( "postSaveCalled" );
                expect( request.postSaveCalled ).toBeStruct();
                expect( request.postSaveCalled ).toHaveKey( "entity" );
                expect( request.postSaveCalled.entity.getDownloadUrl() ).toBe(
                    "https://open.spotify.com/track/0GHGd3jYqChGNxzjqgRZSv"
                );
                structDelete( request, "postSaveCalled" );
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
        variables.quickPostSaveCalled = duplicate( arguments.interceptData );
    }

}
