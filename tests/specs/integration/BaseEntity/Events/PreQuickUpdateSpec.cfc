component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "preQuickUpdate spec", function() {
            beforeEach( function() {
                variables.interceptData = {};
            } );

            it( "announces a preQuickUpdate interception point", function() {
                fail( "test not implemented yet" );
            } );

            it( "calls any preQuickUpdate method on the component", function() {
                fail( "test not implemented yet" );
            } );
        } );
    }

    function preQuickUpdate( event, interceptData, buffer, rc, prc ) {
        variables.interceptData = arguments.interceptData;
    }

}
