component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "postQuickUpdate spec", function() {
            beforeEach( function() {
                variables.interceptData = {};
            } );

            it( "announces a postQuickUpdate interception point", function() {
                fail( "test not implemented yet" );
            } );

            it( "calls any postQuickUpdate method on the component", function() {
                fail( "test not implemented yet" );
            } );
        } );
    }

    function postQuickUpdate( event, interceptData, buffer, rc, prc ) {
        variables.interceptData = arguments.interceptData;
    }

}
