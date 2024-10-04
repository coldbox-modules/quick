component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {

	/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll() {
		super.beforeAll();

		getController().getModuleService().registerAndActivateModule( "quick", "testingModuleRoot" );

		param url.reloadDatabase     = false;
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
			try {
				arguments.spec.body();
			} catch ( any e ) {
				rethrow;
			} finally {
				transaction action="rollback";
			}
		}
	}

	private void function refreshDatabase() {
		getController().getModuleService().registerAndActivateModule( "cfmigrations", "testingModuleRoot" );
		var migrationManager = getWireBox().getInstance( "QBMigrationManager@cfmigrations" );
		var migrationService = application.wirebox.getInstance( "MigrationService@cfmigrations" );
		migrationService.setMigrationsDirectory( "/tests/resources/database/migrations" );
		migrationService.setSeedsDirectory( "/tests/resources/database/seeds" );
		migrationService.setSeedEnvironments( [ "development", "testing" ] );
		migrationService.setManager(
			migrationManager
				.setDefaultGrammar( "MySQLGrammar@qb" )
				.setDatasource( "quick" )
				.setSchema( "quick" )
		);
		migrationService.install();
		migrationService.reset();
		migrationService.runAllMigrations( "up" );
	}

	function shutdownColdBox() {
		getColdBoxVirtualApp().shutdown();
	}

	/**
	 * Returns an array of the unique items of an array.
	 *
	 * @items        An array of items.
	 *
	 * @doc_generic  any
	 * @return       [any]
	 */
	public array function arrayUnique( required array items ) {
		return arraySlice( createObject( "java", "java.util.HashSet" ).init( arguments.items ).toArray(), 1 );
	}

}
