component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Module Activation", function() {
			it( "can activate the module", function() {
				expect( getController().getModuleService().isModuleRegistered( "quick" ) ).toBeTrue(
					"The quick module has not been registered"
				);
			} );

			it( "reuses an application-supplied parallel eager-loading executor", function() {
				var asyncManager = getController().getAsyncManager();
				expect( asyncManager.hasExecutor( "quick-test-parallel-eager-loading" ) ).toBeTrue();
				expect( asyncManager.hasExecutor( "quick-parallel-eager-loading" ) ).toBeFalse();
				expect( asyncManager.getExecutor( "quick-test-parallel-eager-loading" ).getMaximumPoolSize() ).toBe( 3 );
			} );
		} );
	}

}
