component extends="coldbox.system.testing.BaseTestCase" {

    function beforeAll() {
        super.beforeAll();

        getController().getModuleService()
            .registerAndActivateModule( "quick", "testingModuleRoot" );

        param url.reloadFixtures = false;
        if ( url.reloadFixtures ) {
            refreshDatabase();
            insertFixtures();
        }
        param variables.fixtures = getFixtures();
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
        migrationService.reset();
        migrationService.up();
    }

    private void function insertFixtures() {
        getFixtures().seedDatabase();
    }

    private FixtureService function getFixtures() {
        if ( !structKeyExists( request, "fixtures" ) ) {
            request.fixtures = application.wirebox.getInstance( "tests.resources.FixtureService" )
                .setFixturesDirectory( "/tests/resources/database/fixtures" );
        }
        return request.fixtures;
    }

}
