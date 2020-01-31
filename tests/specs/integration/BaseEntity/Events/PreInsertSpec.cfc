component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function beforeAll() {
        super.beforeAll();
        var interceptorService = getWireBox().getInstance(
            dsl = "coldbox:interceptorService"
        );
        interceptorService.registerInterceptor( interceptorObject = this );
    }

    function run() {
        describe( "preInsert spec", function() {
            beforeEach( function() {
                variables.interceptData = {};
            } );

            it( "announces a quickPreInsert interception point", function() {
                var song = getInstance( "Song" ).create( {
                    title: "Rainbow Connection",
                    download_url: "https://open.spotify.com/track/1SJ4ycWow4yz6z4oFz8NAG"
                } );
                expect( variables ).toHaveKey( "quickPreInsertCalled" );
                expect( variables.quickPreInsertCalled ).toBeStruct();
                expect( variables.quickPreInsertCalled ).toHaveKey( "entity" );
                expect( variables.quickPreInsertCalled.entity.getTitle() ).toBe(
                    "Rainbow Connection"
                );
                expect( variables.quickPreInsertCalled.entity.isLoaded() ).toBeFalse();
                structDelete( variables, "quickPreInsertCalled" );
            } );

            it( "calls any preInsert method on the component", function() {
                var song = getInstance( "Song" ).create( {
                    title: "Rainbow Connection",
                    download_url: "https://open.spotify.com/track/1SJ4ycWow4yz6z4oFz8NAG"
                } );
                expect( request ).toHaveKey( "preInsertCalled" );
                expect( request.preInsertCalled ).toBeStruct();
                expect( request.preInsertCalled ).toHaveKey( "entity" );
                expect( request.preInsertCalled.entity.getTitle() ).toBe(
                    "Rainbow Connection"
                );
                expect( request.preInsertCalled.entity.isLoaded() ).toBeFalse();
                structDelete( request, "preInsertCalled" );
            } );

            it( "can influence the values being inserted", function() {
                var song = getInstance( "Song" ).create( {
                    title: "Bohemian Rhapsody",
                    download_url: "https://open.spotify.com/album/3BHe7LbW5yRjyqXNJ3A6mW"
                } );
                expect( song.refresh().getCreatedDate() ).toBe(
                    createDate( 1975, 10, 31 )
                );
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
        variables.quickPreInsertCalled = duplicate( arguments.interceptData );
        if ( arguments.interceptData.entity.getTitle() == "Bohemian Rhapsody" ) {
            arguments.interceptData.entity.assignAttribute(
                "createdDate",
                createDate( 1975, 10, 31 )
            );
        }
    }

}
