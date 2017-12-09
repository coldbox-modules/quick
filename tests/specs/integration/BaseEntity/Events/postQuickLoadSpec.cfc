component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "postQuickLoad spec", function() {
            beforeEach( function() {
                variables.interceptData = {};
            } );

            it( "announces a postQuickLoad interception point", function() {
                fail( "test not implemented yet" );
            } );

            it( "calls any postQuickLoad method on the component", function() {
                fail( "test not implemented yet" );
            } );
        } );
    }

    function postQuickLoad( event, interceptData, buffer, rc, prc ) {
        variables.interceptData = arguments.interceptData;
    }

}
