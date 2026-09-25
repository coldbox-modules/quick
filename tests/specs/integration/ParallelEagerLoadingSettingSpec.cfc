component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		getController()
			.getInterceptorService()
			.registerInterceptor( interceptorObject = this, interceptorName = "ParallelEagerLoadingSettingSpec" );
	}

	function afterAll() {
		getController().getInterceptorService().unregister( "ParallelEagerLoadingSettingSpec" );
		super.afterAll();
	}

	function run() {
		describe( "Parallel eager loading module setting", function() {
			beforeEach( function() {
				variables.originalSettings = structCopy(
					getController()
						.getSetting( "ColdBoxConfig" )
						.getPropertyMixin( "moduleSettings", "variables" )
						.quick
				);
				variables.queryThreads                = [];
				request.quickSkipDatabaseTransactions = true;
				activateQuick( {} );
			} );

			afterEach( function() {
				activateQuick( variables.originalSettings );
				structDelete( request, "quickSkipDatabaseTransactions" );
			} );

			it( "defaults to sequential loading without creating an executor or coordinator", function() {
				expect( getController().getSetting( "moduleSettings" ).quick.parallelEagerLoading ).toBeFalse();
				assertSequentialLoading();
			} );

			it( "ignores a missing executor when explicitly disabled", function() {
				activateQuick( {
					"parallelEagerLoading"         : false,
					"parallelEagerLoadingExecutor" : "missing-executor"
				} );
				assertSequentialLoading();
			} );

			it( "leaves an application executor untouched when disabled and unloaded", function() {
				activateQuick( {
					"parallelEagerLoading"         : false,
					"parallelEagerLoadingExecutor" : "quick-test-parallel-eager-loading"
				} );
				assertSequentialLoading();
				getController().getModuleService().unload( "quick" );
				expect( getController().getAsyncManager().hasExecutor( "quick-test-parallel-eager-loading" ) ).toBeTrue();
			} );

			it( "creates and cleans up its own executor only when enabled", function() {
				activateQuick( { "parallelEagerLoading" : true } );
				expect( getController().getAsyncManager().hasExecutor( "quick-parallel-eager-loading" ) ).toBeTrue();
				activateQuick( { "parallelEagerLoading" : false } );
				assertSequentialLoading();
			} );
		} );
	}

	private void function activateQuick( required struct settings ) {
		getController().getModuleService().unload( "quick" );
		getController().getCacheBox().removeCache( "quickMeta" );
		getWireBox().getScope( "singleton" ).clear( "quick.models.ParallelEagerLoadingCoordinator" );
		var moduleSettings = { "defaultGrammar" : "MySQLGrammar@qb" };
		moduleSettings.append( arguments.settings, true );
		getController().getSetting( "ColdBoxConfig" ).getPropertyMixin( "moduleSettings", "variables" ).quick = moduleSettings;
		getController()
			.getModuleService()
			.registerModule(
				moduleName     = "quick",
				invocationPath = "testingModuleRoot",
				force          = true
			);
		getController().getModuleService().activateModule( "quick" );
	}

	private void function assertSequentialLoading() {
		var callingThread      = createObject( "java", "java.lang.Thread" ).currentThread().getName();
		variables.queryThreads = [];
		var posts              = getInstance( "Post" ).with( [ "author", "comments" ], true ).get();
		expect( posts ).toHaveLength( 4 );
		expect( posts[ 1 ].getAuthor() ).toBeInstanceOf( "app.models.User" );
		expect( posts[ 1 ].isRelationshipLoaded( "comments" ) ).toBeTrue();
		expect( variables.queryThreads ).toHaveLength( 3 );
		for ( var threadName in variables.queryThreads ) {
			expect( threadName ).toBe( callingThread );
		}
		expect( getController().getAsyncManager().hasExecutor( "quick-parallel-eager-loading" ) ).toBeFalse();
		expect(
			getWireBox()
				.getScope( "singleton" )
				.getSingletons()
				.containsKey( "quick.models.paralleleagerloadingcoordinator" )
		).toBeFalse();
	}

	function preQBExecute( event, interceptData ) {
		variables.queryThreads.append( createObject( "java", "java.lang.Thread" ).currentThread().getName() );
	}

}
