component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "EntityDefinitionRegistry", function() {
			beforeEach( function() {
				variables.registry = getInstance( "EntityDefinitionRegistry@quick" );
				variables.registry.clear();
			} );

			afterEach( function() {
				variables.registry.clear();
			} );

			it( "compiles one definition once", function() {
				var compilationCount = createObject( "java", "java.util.concurrent.atomic.AtomicInteger" ).init( 0 );
				var first            = variables.registry.getOrCreateDefinition( "User", () => {
					compilationCount.incrementAndGet();
					return { "token" : createUUID() };
				} );
				var second = variables.registry.getOrCreateDefinition( "User", () => {
					compilationCount.incrementAndGet();
					return { "token" : createUUID() };
				} );

				expect( compilationCount.get() ).toBe( 1 );
				expect( second.token ).toBe( first.token );
				expect( variables.registry.getStats().definitionCount ).toBe( 1 );
			} );

			it( "compiles one definition under concurrent access", function() {
				var compilationCount = createObject( "java", "java.util.concurrent.atomic.AtomicInteger" ).init( 0 );
				var definitionTokens = createObject( "java", "java.util.concurrent.ConcurrentHashMap" ).init();
				var threadNames      = [];
				var sharedKey        = "quickDefinitionRegistry#replace( createUUID(), "-", "", "all" )#";
				server[ sharedKey ]  = {
					"registry"         : variables.registry,
					"compilationCount" : compilationCount,
					"definitionTokens" : definitionTokens
				};
				try {
					for ( var index = 1; index <= 16; index++ ) {
						var threadName = "quickDefinitionRegistry#replace( createUUID(), "-", "", "all" )#";
						threadNames.append( threadName );
						cfthread(
							action    = "run",
							name      = threadName,
							sharedKey = sharedKey,
							resultKey = threadName
						) {
							var shared     = server[ attributes.sharedKey ];
							var definition = shared.registry.getOrCreateDefinition( "ConcurrentUser", () => {
								shared.compilationCount.incrementAndGet();
								sleep( 25 );
								return { "token" : createUUID() };
							} );
							shared.definitionTokens.put( attributes.resultKey, definition.token );
						}
					}
					cfthread(
						action  = "join",
						name    = threadNames.toList(),
						timeout = 10000
					);

					var tokens = {};
					for ( var threadName in threadNames ) {
						expect( cfthread[ threadName ].status ).toBe( "COMPLETED" );
						tokens[ definitionTokens.get( threadName ) ] = true;
					}
					expect( compilationCount.get() ).toBe( 1 );
					expect( definitionTokens.size() ).toBe( threadNames.len() );
					expect( structCount( tokens ) ).toBe( 1 );
				} finally {
					server.delete( sharedKey );
				}
			} );

			it( "bounds derived entries without evicting definitions", function() {
				variables.registry.getOrCreateDefinition( "User", () => {
					return { "token" : "definition" };
				} );
				for ( var index = 1; index <= 12; index++ ) {
					variables.registry.getOrCreateDerived(
						mapping = "User",
						group   = "qualifiedColumns",
						variant = "shape#formatBaseN( index, 10 )#",
						factory = () => {
							return [ index ];
						},
						limit = 4
					);
				}

				var stats = variables.registry.getStats();
				expect( stats.definitionCount ).toBe( 1 );
				expect( stats.derivedEntryCount ).toBeLTE( 4 );
				expect( stats.derivedEvictionCount ).toBeGTE( 8 );
				expect( variables.registry.hasDefinition( "User" ) ).toBeTrue();
			} );

			it( "keeps entity definitions warm when CacheBox entries are cleared", function() {
				var metadataCache = getInstance( "User" ).get_cache();
				variables.registry.clear();
				metadataCache.clearAll();

				var first            = getInstance( "User" );
				var compilationCount = variables.registry.getStats().definitionCompilationCount;
				metadataCache.clearAll();
				var second = getInstance( "User" );

				expect( compilationCount ).toBe( 1 );
				expect( variables.registry.getStats().definitionCompilationCount ).toBe( compilationCount );
				expect( second.get_Meta().mapping ).toBe( first.get_Meta().mapping );
			} );
		} );
	}

}
