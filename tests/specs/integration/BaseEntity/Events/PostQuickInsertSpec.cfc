component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "postQuickInsert spec", function() {
            beforeEach( function() {
                variables.interceptData = {};
            } );

            it( "announces a postQuickInsert interception point", function() {
                fail( "test not implemented yet" );
            } );

            it( "calls any postQuickInsert method on the component", function() {
                fail( "test not implemented yet" );
            } );
        } );
    }

    function postQuickInsert( event, interceptData, buffer, rc, prc ) {
        variables.interceptData = arguments.interceptData;
    }

}
