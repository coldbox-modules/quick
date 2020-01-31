component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Module Activation", function() {
            it( "can activate the module", function() {
                expect(
                    getController()
                        .getModuleService()
                        .isModuleRegistered( "quick" )
                ).toBeTrue( "The quick module has not been registered" );
            } );
        } );
    }

}
