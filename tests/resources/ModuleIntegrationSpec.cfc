component extends="coldbox.system.testing.BaseTestCase" {

    function beforeAll() {
        super.beforeAll();

        getController().getModuleService()
            .registerAndActivateModule( "quick", "testingModuleRoot" );

        param url.reloadDatabase = false;
        param request.reloadDatabase = false;
        if ( url.reloadDatabase && !request.reloadDatabase ) {
            refreshDatabase();
            request.reloadDatabase = true;
        }
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
                rethrow;
            }
            finally { transaction action="rollback"; }
        }
    }

    private void function refreshDatabase() {
        getController().getModuleService()
            .registerAndActivateModule( "cfmigrations", "testingModuleRoot" );
        var migrationService = application.wirebox.getInstance( "MigrationService@cfmigrations" );
        migrationService.setMigrationsDirectory( "/tests/resources/database/migrations" );
        migrationService.setDefaultGrammar( "MySQLGrammar@qb" );
        migrationService.setSchema( "quick" );
        migrationService.reset();
        migrationService.install();
        migrationService.up();
    }

}
