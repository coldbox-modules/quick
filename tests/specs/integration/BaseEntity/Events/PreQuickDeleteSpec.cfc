component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "preQuickDelete spec", function() {
            beforeEach( function() {
                variables.interceptData = {};
            } );

            it( "announces a preQuickDelete interception point", function() {
                fail( "test not implemented yet" );
            } );

            it( "calls any preQuickDelete method on the component", function() {
                fail( "test not implemented yet" );
            } );
        } );
    }

    function preQuickDelete( event, interceptData, buffer, rc, prc ) {
        variables.interceptData = arguments.interceptData;
    }

}
