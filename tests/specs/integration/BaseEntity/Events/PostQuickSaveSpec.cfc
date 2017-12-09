component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "postQuickSave spec", function() {
            beforeEach( function() {
                variables.interceptData = {};
            } );

            it( "announces a postQuickSave interception point", function() {
                fail( "test not implemented yet" );
            } );

            it( "calls any postQuickSave method on the component", function() {
                fail( "test not implemented yet" );
            } );
        } );
    }

    function postQuickSave( event, interceptData, buffer, rc, prc ) {
        variables.interceptData = arguments.interceptData;
    }

}
