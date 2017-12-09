component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "preQuickLoad spec", function() {
            beforeEach( function() {
                variables.interceptData = {};
            } );

            it( "announces a preQuickLoad interception point", function() {
                fail( "test not implemented yet" );
            } );

            it( "calls any preQuickLoad method on the component", function() {
                fail( "test not implemented yet" );
            } );
        } );
    }

    function preQuickLoad( event, interceptData, buffer, rc, prc ) {
        variables.interceptData = arguments.interceptData;
    }

}
