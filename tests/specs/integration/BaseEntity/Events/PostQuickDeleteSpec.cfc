component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "postQuickDelete spec", function() {
            beforeEach( function() {
                variables.interceptData = {};
            } );

            it( "announces a postQuickDelete interception point", function() {
                fail( "test not implemented yet" );
            } );

            it( "calls any postQuickDelete method on the component", function() {
                fail( "test not implemented yet" );
            } );
        } );
    }

    function postQuickDelete( event, interceptData, buffer, rc, prc ) {
        variables.interceptData = arguments.interceptData;
    }

}
