component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "preQuickInsert spec", function() {
            beforeEach( function() {
                variables.interceptData = {};
            } );

            it( "announces a preQuickInsert interception point", function() {
                fail( "test not implemented yet" );
            } );

            it( "calls any preQuickInsert method on the component", function() {
                fail( "test not implemented yet" );
            } );
        } );
    }

    function preQuickInsert( event, interceptData, buffer, rc, prc ) {
        variables.interceptData = arguments.interceptData;
    }

}
