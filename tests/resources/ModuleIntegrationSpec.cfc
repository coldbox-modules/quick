component extends="coldbox.system.testing.BaseTestCase" {

    function beforeAll() {
        super.beforeAll();

        getController().getModuleService()
            .registerAndActivateModule( "quick", "testingModuleRoot" );
    }

    /**
     * @beforeEach
     */
    function setupIntegrationTest() {
        setup();
    }

    /**
     * @aroundEach
     */
    function useDatabaseTransactions( spec ) {
        transaction action="begin" {
            try { arguments.spec.body(); }
            catch ( any e ) {
                if ( e.type == "database" ) {
                    throw( message = e.detail );
                }
                rethrow;
            }
            finally { transaction action="rollback"; }
        }
    }

}
