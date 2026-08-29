component {

	public any function init( required any wirebox, struct config = {} ) {
		variables.wirebox = arguments.wirebox;
		variables.config  = {
			"warmupIterations" : 5,
			"samples"          : 9,
			"iterations"       : 25,
			"databaseRows"     : 1000,
			"retainedItems"    : 250,
			"includeDatabase"  : true,
			"includeRetained"  : true,
			"only"             : []
		};
		variables.config.append( arguments.config, true );
		if ( isSimpleValue( variables.config.only ) ) {
			variables.config.only = listToArray( variables.config.only );
		}
		variables.harness = new tests.performance.BenchmarkHarness(
			warmupIterations = variables.config.warmupIterations,
			samples          = variables.config.samples,
			iterations       = variables.config.iterations
		);
		variables.userPrototype = variables.wirebox.getInstance( "User" );
		variables.aPrototype    = variables.wirebox.getInstance( "A" );
		variables.userRow       = buildUserRow();
		return this;
	}

	public struct function run() {
		var startedAt  = getTickCount();
		var benchmarks = [];
		var memory     = [];
		var errors     = [];

		if ( isSelected( "entity.instantiate" ) ) {
			benchmarks.append( benchmarkEntityInstantiation() );
		}
		if ( isSelected( "entity.instantiate_narrow" ) ) {
			benchmarks.append( benchmarkNarrowEntityInstantiation() );
		}
		if ( isSelected( "entity.instantiate_narrow_shallow_internal" ) ) {
			benchmarks.append( benchmarkInternalShallowEntityInstantiation() );
		}
		if ( isSelected( "entity.hydrate" ) ) {
			benchmarks.append( benchmarkEntityHydration() );
		}
		if ( isSelected( "entity.bind_row_existing" ) ) {
			benchmarks.append( benchmarkExistingEntityRowBinding() );
		}
		if ( isSelected( "entity.post_load_event" ) ) {
			benchmarks.append( benchmarkPostLoadEvent() );
		}
		if ( isSelected( "entity.hydrate_batch_10" ) ) {
			benchmarks.append( benchmarkBatchHydration( 10 ) );
		}
		if ( isSelected( "entity.hydrate_batch_100" ) ) {
			benchmarks.append( benchmarkBatchHydration( 100 ) );
		}
		if ( isSelected( "entity.hydrate_batch_1000" ) ) {
			benchmarks.append( benchmarkBatchHydration( 1000 ) );
		}
		if ( isSelected( "attribute.read" ) ) {
			benchmarks.append( benchmarkAttributeRead() );
		}
		if ( isSelected( "attribute.assign" ) ) {
			benchmarks.append( benchmarkAttributeAssignment() );
		}
		if ( isSelected( "attribute.runtime_overlay_deep_lookup" ) ) {
			benchmarks.append( benchmarkDeepRuntimeOverlayLookup() );
		}
		if ( isSelected( "metadata.cache_lookup" ) ) {
			benchmarks.append( benchmarkMetadataCacheLookup() );
		}
		if ( isSelected( "metadata.definition_access" ) ) {
			benchmarks.append( benchmarkMetadataDefinitionAccess() );
		}
		if ( isSelected( "metadata.qualified_columns_cached" ) ) {
			benchmarks.append( benchmarkCachedQualifiedColumns() );
		}
		if ( isSelected( "entity.attributes_snapshot" ) ) {
			benchmarks.append( benchmarkAttributesSnapshot() );
		}
		if ( isSelected( "entity.is_dirty_clean" ) ) {
			benchmarks.append( benchmarkDirtyCheck() );
		}
		if ( isSelected( "entity.memento" ) ) {
			benchmarks.append( benchmarkMementoSerialization() );
		}
		if ( isSelected( "builder.instantiate" ) ) {
			benchmarks.append( benchmarkBuilderCreation() );
		}
		if ( isSelected( "builder.clone" ) ) {
			benchmarks.append( benchmarkBuilderClone() );
		}
		if ( isSelected( "builder.compose_sql" ) ) {
			benchmarks.append( benchmarkBuilderComposition() );
		}
		if ( isSelected( "relationship.construct_has_many" ) ) {
			benchmarks.append( benchmarkRelationshipConstruction() );
		}
		if ( isSelected( "metadata.cold_compile" ) ) {
			benchmarks.append( benchmarkColdMetadataCompilation() );
		}
		if ( isSelected( "metadata.selective_cold_compile" ) ) {
			benchmarks.append( benchmarkSelectiveColdMetadataCompilation() );
		}
		if ( isSelected( "metadata.cache_mutation_control" ) ) {
			benchmarks.append( benchmarkMetadataCacheMutationControl() );
		}

		if (
			variables.config.includeDatabase &&
			( isSelected( "database.raw_rows" ) || isSelected( "database.hydrated_rows" ) )
		) {
			try {
				benchmarks.append( runDatabaseBenchmarks(), true );
			} catch ( any e ) {
				errors.append( {
					"category" : "database",
					"type"     : e.type,
					"message"  : e.message,
					"detail"   : e.detail
				} );
			}
		}

		if ( variables.config.includeRetained ) {
			if ( isSelected( "memory.entity_unloaded" ) ) {
				memory.append( measureRetainedEntities() );
			}
			if ( isSelected( "memory.entity_hydrated" ) ) {
				memory.append( measureRetainedHydratedEntities() );
			}
			if ( isSelected( "memory.entity_narrow" ) ) {
				memory.append( measureRetainedNarrowEntities() );
			}
			if ( isSelected( "memory.entity_narrow_shallow_internal" ) ) {
				memory.append( measureRetainedInternalShallowNarrowEntities() );
			}
			if ( isSelected( "memory.builder" ) ) {
				memory.append( measureRetainedBuilders() );
			}
		}

		return {
			"schemaVersion"       : 1,
			"generatedAt"         : dateTimeFormat( dateConvert( "local2Utc", now() ), "yyyy-mm-dd'T'HH:nn:ss'Z'" ),
			"durationMs"          : getTickCount() - startedAt,
			"environment"         : environmentMetadata(),
			"configuration"       : variables.config,
			"capabilities"        : variables.harness.capabilities(),
			"benchmarks"          : benchmarks,
			"memory"              : memory,
			"comparisons"         : buildComparisons( benchmarks ),
			"metadataDiagnostics" : buildMetadataDiagnostics(),
			"errors"              : errors
		};
	}

	private struct function buildMetadataDiagnostics() {
		var meta        = variables.userPrototype.get_meta();
		var diagnostics = {
			"topLevelKeys"               : structCount( meta ),
			"attributes"                 : structCount( meta.attributes ),
			"columns"                    : structCount( meta.columns ),
			"casts"                      : structCount( meta.casts ),
			"functionNames"              : arrayLen( meta.functionNames ),
			"virtualAttributes"          : arrayLen( meta.virtualAttributes ),
			"originalMetadataKeys"       : structCount( meta.originalMetadata ),
			"originalMetadataProperties" : arrayLen( meta.originalMetadata.properties ),
			"originalMetadataFunctions"  : arrayLen( meta.originalMetadata.functions ),
			"localMetadataKeys"          : structCount( meta.localMetadata ),
			"localMetadataProperties"    : arrayLen( meta.localMetadata.properties ),
			"localMetadataFunctions"     : meta.localMetadata.keyExists( "functions" )
			 ? arrayLen( meta.localMetadata.functions )
			 : 0,
			"serializedCharacters" : -1
		};
		try {
			diagnostics.serializedCharacters = len( serializeJSON( meta ) );
		} catch ( any ignored ) {
		}
		return diagnostics;
	}

	private boolean function isSelected( required string name ) {
		return arrayLen( variables.config.only ) == 0 || arrayFindNoCase( variables.config.only, arguments.name ) > 0;
	}

	private struct function benchmarkEntityInstantiation() {
		return variables.harness.measure(
			name        = "entity.instantiate",
			category    = "entity",
			description = "Create a warmed User entity through newEntity(), including WireBox DI and onDIComplete.",
			callback    = function( iterationIndex ) {
				return variables.userPrototype.newEntity();
			}
		);
	}

	private struct function benchmarkNarrowEntityInstantiation() {
		return variables.harness.measure(
			name        = "entity.instantiate_narrow",
			category    = "entity",
			description = "Create a warmed, two-attribute A entity through newEntity(), including WireBox DI and onDIComplete.",
			callback    = function( iterationIndex ) {
				return variables.aPrototype.newEntity();
			}
		);
	}

	/**
	 * Diagnostic boundary only. Quick's shallow flag skips normal post-DI memento
	 * and lifecycle setup; the returned object is not a substitute for newEntity().
	 */
	private struct function benchmarkInternalShallowEntityInstantiation() {
		return variables.harness.measure(
			name        = "entity.instantiate_narrow_shallow_internal",
			category    = "diagnostic",
			description = "Create the same A entity with Quick's internal shallow flag to isolate normal post-DI setup cost.",
			callback    = function( iterationIndex ) {
				return variables.wirebox.getInstance(
					name          = variables.aPrototype.mappingName(),
					initArguments = {
						"meta"                    : variables.aPrototype.get_meta(),
						"runtimeAttributeOverlay" : variables.aPrototype.get_runtimeAttributeOverlay(),
						"shallow"                 : true
					}
				);
			}
		);
	}

	private struct function benchmarkEntityHydration() {
		return variables.harness.measure(
			name        = "entity.hydrate",
			category    = "entity",
			description = "Create and hydrate one warmed, wide User entity from an already-materialized row.",
			callback    = function( iterationIndex ) {
				return variables.userPrototype.newEntity().hydrate( variables.userRow );
			}
		);
	}

	private struct function benchmarkExistingEntityRowBinding() {
		var entity = variables.userPrototype.newEntity();
		return variables.harness.measure(
			name        = "entity.bind_row_existing",
			category    = "hydration",
			description = "Bind one wide row and record original state on an already-constructed entity without lifecycle events.",
			iterations  = variables.config.iterations * 10,
			callback    = function( iterationIndex ) {
				return entity.assignAttributesData( variables.userRow ).assignOriginalAttributes( variables.userRow );
			}
		);
	}

	private struct function benchmarkPostLoadEvent() {
		var entity = variables.userPrototype.newEntity().assignAttributesData( variables.userRow );
		return variables.harness.measure(
			name        = "entity.post_load_event",
			category    = "hydration",
			description = "Mark an existing entity loaded and fire its postLoad lifecycle event and interception point.",
			iterations  = variables.config.iterations * 25,
			callback    = function( iterationIndex ) {
				return entity.markLoaded();
			}
		);
	}

	private struct function benchmarkBatchHydration( required numeric count ) {
		var rows = [];
		for ( var rowIndex = 1; rowIndex <= arguments.count; rowIndex++ ) {
			rows.append( variables.userRow );
		}
		return variables.harness.measure(
			name                   = "entity.hydrate_batch_#arguments.count#",
			category               = "entity",
			description            = "Hydrate #arguments.count# wide User entities through hydrateAll().",
			operationsPerIteration = arguments.count,
			iterations             = max( 1, ceiling( variables.config.iterations / max( 1, arguments.count / 20 ) ) ),
			callback               = function( iterationIndex ) {
				return variables.userPrototype.hydrateAll( rows );
			}
		);
	}

	private struct function benchmarkAttributeRead() {
		var entity = variables.userPrototype.newEntity().hydrate( variables.userRow );
		return variables.harness.measure(
			name        = "attribute.read",
			category    = "attribute",
			description = "Read one mapped attribute through retrieveAttribute().",
			iterations  = variables.config.iterations * 100,
			callback    = function( iterationIndex ) {
				return entity.retrieveAttribute( "username" );
			}
		);
	}

	private struct function benchmarkAttributeAssignment() {
		var entity = variables.userPrototype.newEntity().hydrate( variables.userRow );
		return variables.harness.measure(
			name        = "attribute.assign",
			category    = "attribute",
			description = "Assign one mapped, non-key attribute through assignAttribute().",
			iterations  = variables.config.iterations * 100,
			callback    = function( iterationIndex ) {
				return entity.assignAttribute( "username", "quick-performance-#iterationIndex#" );
			}
		);
	}

	private struct function benchmarkDeepRuntimeOverlayLookup() {
		var entity = variables.userPrototype.newEntity();
		for ( var overlayIndex = 1; overlayIndex <= 10; overlayIndex++ ) {
			entity.appendVirtualAttribute( "performanceOverlay#overlayIndex#" );
		}
		return variables.harness.measure(
			name        = "attribute.runtime_overlay_deep_lookup",
			category    = "attribute",
			description = "Resolve the oldest attribute in a ten-node runtime overlay chain.",
			iterations  = variables.config.iterations * 100,
			callback    = function( iterationIndex ) {
				return entity.hasAttribute( "performanceOverlay1" );
			}
		);
	}

	private struct function benchmarkMetadataCacheLookup() {
		var metadataCache = variables.userPrototype.get_cache();
		var cacheKey      = "quick-metadata:#variables.userPrototype.mappingName()#";
		return variables.harness.measure(
			name        = "metadata.cache_lookup",
			category    = "metadata",
			description = "Read one warmed entity definition from the configured Quick CacheBox provider.",
			iterations  = variables.config.iterations * 100,
			callback    = function( iterationIndex ) {
				return metadataCache.get( cacheKey );
			}
		);
	}

	private struct function benchmarkMetadataDefinitionAccess() {
		return variables.harness.measure(
			name        = "metadata.definition_access",
			category    = "metadata",
			description = "Read the shared entity metadata definition already bound to a warmed prototype.",
			iterations  = variables.config.iterations * 100,
			callback    = function( iterationIndex ) {
				return variables.userPrototype.get_meta();
			}
		);
	}

	private struct function benchmarkCachedQualifiedColumns() {
		variables.userPrototype.retrieveQualifiedColumns();
		return variables.harness.measure(
			name        = "metadata.qualified_columns_cached",
			category    = "metadata",
			description = "Read cached qualified columns and materialize the defensive result array.",
			iterations  = variables.config.iterations * 25,
			callback    = function( iterationIndex ) {
				return variables.userPrototype.retrieveQualifiedColumns();
			}
		);
	}

	private struct function benchmarkColdMetadataCompilation() {
		var metadataCache = variables.userPrototype.get_cache();
		return variables.harness.measure(
			name             = "metadata.cold_compile",
			category         = "metadata",
			description      = "Measure the full cold metadata path: clear Quick's cache and construct User through WireBox.",
			warmupIterations = 1,
			samples          = min( 7, variables.config.samples ),
			iterations       = 1,
			callback         = function( iterationIndex ) {
				metadataCache.clearAll();
				return variables.wirebox.getInstance( "User" );
			}
		);
	}

	private struct function benchmarkSelectiveColdMetadataCompilation() {
		var metadataCache = variables.userPrototype.get_cache();
		var cacheKey      = "quick-metadata:#variables.userPrototype.mappingName()#";
		return variables.harness.measure(
			name             = "metadata.selective_cold_compile",
			category         = "metadata",
			description      = "Evict only User metadata, then reconstruct User through WireBox while shared metadata remains warm.",
			warmupIterations = 1,
			samples          = min( 7, variables.config.samples ),
			iterations       = 1,
			callback         = function( iterationIndex ) {
				metadataCache.clear( cacheKey );
				return variables.wirebox.getInstance( "User" );
			}
		);
	}

	private struct function benchmarkMetadataCacheMutationControl() {
		var metadataCache = variables.userPrototype.get_cache();
		var cacheKey      = "quick-performance:metadata-mutation-control";
		metadataCache.set( cacheKey, true );
		return variables.harness.measure(
			name             = "metadata.cache_mutation_control",
			category         = "metadata",
			description      = "Clear and restore one trivial CacheBox entry to quantify mutation overhead in selective-cold measurements.",
			warmupIterations = 1,
			samples          = min( 7, variables.config.samples ),
			iterations       = 1,
			callback         = function( iterationIndex ) {
				metadataCache.clear( cacheKey );
				metadataCache.set( cacheKey, true );
				return true;
			}
		);
	}

	private struct function benchmarkAttributesSnapshot() {
		var entity = variables.userPrototype.newEntity().hydrate( variables.userRow );
		return variables.harness.measure(
			name        = "entity.attributes_snapshot",
			category    = "entity_state",
			description = "Synchronize accessors and copy the current wide User attribute state.",
			iterations  = variables.config.iterations * 10,
			callback    = function( iterationIndex ) {
				return entity.retrieveAttributesData();
			}
		);
	}

	private struct function benchmarkDirtyCheck() {
		var entity = variables.userPrototype.newEntity().hydrate( variables.userRow );
		return variables.harness.measure(
			name        = "entity.is_dirty_clean",
			category    = "entity_state",
			description = "Check an unchanged wide User entity with the original hash already warmed.",
			iterations  = variables.config.iterations * 10,
			callback    = function( iterationIndex ) {
				return entity.isDirty();
			}
		);
	}

	private struct function benchmarkMementoSerialization() {
		var entity = variables.userPrototype.newEntity().hydrate( variables.userRow );
		return variables.harness.measure(
			name        = "entity.memento",
			category    = "serialization",
			description = "Create a default memento for one wide User entity.",
			iterations  = variables.config.iterations * 5,
			callback    = function( iterationIndex ) {
				return entity.getMemento();
			}
		);
	}

	private struct function benchmarkBuilderCreation() {
		return variables.harness.measure(
			name        = "builder.instantiate",
			category    = "builder",
			description = "Create and initialize a QuickBuilder for a warmed User entity.",
			callback    = function( iterationIndex ) {
				return variables.userPrototype.newQuery();
			}
		);
	}

	private struct function benchmarkBuilderClone() {
		var builder = variables.userPrototype
			.newQuery()
			.where( "username", "benchmark" )
			.orderBy( "createdDate", "desc" );
		return variables.harness.measure(
			name        = "builder.clone",
			category    = "builder",
			description = "Clone a configured QuickBuilder, matching the refresh-query copy made during entity fetches.",
			callback    = function( iterationIndex ) {
				return builder.clone();
			}
		);
	}

	private struct function benchmarkBuilderComposition() {
		return variables.harness.measure(
			name        = "builder.compose_sql",
			category    = "builder",
			description = "Create a builder, add common predicates and ordering, then compile SQL without executing it.",
			callback    = function( iterationIndex ) {
				return variables.userPrototype
					.newQuery()
					.where( "username", "benchmark" )
					.whereNotNull( "createdDate" )
					.orderBy( "createdDate", "desc" )
					.limit( 25 )
					.toSQL();
			}
		);
	}

	private struct function benchmarkRelationshipConstruction() {
		var entity = variables.userPrototype.newEntity().hydrate( variables.userRow );
		return variables.harness.measure(
			name        = "relationship.construct_has_many",
			category    = "relationship",
			description = "Resolve User.posts(), including related entity, builder, relationship object, and constraints.",
			callback    = function( iterationIndex ) {
				return entity.posts();
			}
		);
	}

	private array function runDatabaseBenchmarks() {
		var databaseBenchmarks= [];
		transaction action    ="begin" {
			try {
				seedDatabaseRows( variables.config.databaseRows );
				if ( isSelected( "database.raw_rows" ) ) {
					databaseBenchmarks.append(
						variables.harness.measure(
							name                   = "database.raw_rows",
							category               = "database",
							description            = "Fetch the seeded A rows as raw structs; fixture setup is outside the timed region.",
							operationsPerIteration = variables.config.databaseRows,
							warmupIterations       = min( 2, variables.config.warmupIterations ),
							iterations             = max( 1, ceiling( variables.config.iterations / 10 ) ),
							callback               = function( iterationIndex ) {
								return variables.aPrototype
									.newQuery()
									.asQuery( false )
									.get();
							}
						)
					);
				}
				if ( isSelected( "database.hydrated_rows" ) ) {
					databaseBenchmarks.append(
						variables.harness.measure(
							name                   = "database.hydrated_rows",
							category               = "database",
							description            = "Fetch and hydrate the same seeded A rows as Quick entities.",
							operationsPerIteration = variables.config.databaseRows,
							warmupIterations       = min( 2, variables.config.warmupIterations ),
							iterations             = max( 1, ceiling( variables.config.iterations / 10 ) ),
							callback               = function( iterationIndex ) {
								return variables.aPrototype.newQuery().get();
							}
						)
					);
				}
			} finally {
				transaction action="rollback";
			}
		}
		return databaseBenchmarks;
	}

	private void function seedDatabaseRows( required numeric count ) {
		queryExecute( "DELETE FROM `a`" );
		var placeholders = [];
		var params       = [];
		for ( var rowIndex = 1; rowIndex <= arguments.count; rowIndex++ ) {
			placeholders.append( "(?)" );
			params.append( {
				"value"     : "Performance row #rowIndex#",
				"cfsqltype" : "varchar"
			} );
		}
		queryExecute( "INSERT INTO `a` (`name`) VALUES #placeholders.toList( "," )#", params );
	}

	private struct function measureRetainedEntities() {
		return variables.harness.measureRetainedHeap(
			name        = "memory.entity_unloaded",
			category    = "memory",
			description = "Approximate retained heap for live, unloaded User entities.",
			count       = variables.config.retainedItems,
			factory     = function( itemIndex ) {
				return variables.userPrototype.newEntity();
			}
		);
	}

	private struct function measureRetainedHydratedEntities() {
		return variables.harness.measureRetainedHeap(
			name        = "memory.entity_hydrated",
			category    = "memory",
			description = "Approximate retained heap for live, hydrated User entities, including a distinct source row.",
			count       = variables.config.retainedItems,
			factory     = function( itemIndex ) {
				return variables.userPrototype.newEntity().hydrate( structCopy( variables.userRow ) );
			}
		);
	}

	private struct function measureRetainedNarrowEntities() {
		return variables.harness.measureRetainedHeap(
			name        = "memory.entity_narrow",
			category    = "memory",
			description = "Approximate retained heap for live, normally initialized A entities.",
			count       = variables.config.retainedItems,
			factory     = function( itemIndex ) {
				return variables.aPrototype.newEntity();
			}
		);
	}

	private struct function measureRetainedInternalShallowNarrowEntities() {
		return variables.harness.measureRetainedHeap(
			name        = "memory.entity_narrow_shallow_internal",
			category    = "diagnostic",
			description = "Approximate retained heap for A entities without normal post-DI memento and lifecycle setup.",
			count       = variables.config.retainedItems,
			factory     = function( itemIndex ) {
				return variables.wirebox.getInstance(
					name          = variables.aPrototype.mappingName(),
					initArguments = {
						"meta"                    : variables.aPrototype.get_meta(),
						"runtimeAttributeOverlay" : variables.aPrototype.get_runtimeAttributeOverlay(),
						"shallow"                 : true
					}
				);
			}
		);
	}

	private struct function measureRetainedBuilders() {
		return variables.harness.measureRetainedHeap(
			name        = "memory.builder",
			category    = "memory",
			description = "Approximate retained heap for live QuickBuilder instances.",
			count       = variables.config.retainedItems,
			factory     = function( itemIndex ) {
				return variables.userPrototype.newQuery();
			}
		);
	}

	private struct function buildUserRow() {
		return {
			"id"              : 1,
			"username"        : "quick-performance",
			"first_name"      : "Quick",
			"last_name"       : "Benchmark",
			"password"        : "not-a-real-password",
			"country_id"      : 1,
			"team_id"         : 1,
			"created_date"    : createDateTime( 2026, 1, 1, 0, 0, 0 ),
			"modified_date"   : createDateTime( 2026, 1, 1, 0, 0, 0 ),
			"email"           : "benchmark@example.invalid",
			"type"            : "benchmark",
			"externalID"      : "performance-1",
			"favoritePost_id" : 1,
			"streetOne"       : "100 Benchmark Way",
			"streetTwo"       : "",
			"city"            : "Testville",
			"state"           : "UT",
			"zip"             : "84000"
		};
	}

	private struct function environmentMetadata() {
		var engine = {
			"name"    : "unknown",
			"version" : "unknown"
		};
		if ( server.keyExists( "lucee" ) ) {
			engine = {
				"name"    : "Lucee",
				"version" : server.lucee.version
			};
		} else if ( server.keyExists( "boxlang" ) ) {
			engine = {
				"name"    : "BoxLang",
				"version" : server.boxlang.version
			};
		} else if ( server.keyExists( "coldfusion" ) ) {
			engine = {
				"name"    : "Adobe ColdFusion",
				"version" : server.coldfusion.productVersion
			};
		}

		return {
			"engine"              : engine,
			"javaVersion"         : createObject( "java", "java.lang.System" ).getProperty( "java.version" ),
			"javaVendor"          : createObject( "java", "java.lang.System" ).getProperty( "java.vendor" ),
			"operatingSystem"     : createObject( "java", "java.lang.System" ).getProperty( "os.name" ),
			"architecture"        : createObject( "java", "java.lang.System" ).getProperty( "os.arch" ),
			"availableProcessors" : createObject( "java", "java.lang.Runtime" ).getRuntime().availableProcessors()
		};
	}

	private struct function buildComparisons( required array benchmarks ) {
		var byName = {};
		for ( var benchmark in arguments.benchmarks ) {
			byName[ benchmark.name ] = benchmark;
		}

		var comparisons = {};
		if ( byName.keyExists( "entity.instantiate" ) && byName.keyExists( "entity.hydrate" ) ) {
			comparisons[ "hydrationAddedWallTimePercent" ] = percentDifference(
				byName[ "entity.instantiate" ].wallTime.median,
				byName[ "entity.hydrate" ].wallTime.median
			);
		}
		if (
			byName.keyExists( "entity.instantiate_narrow" ) &&
			byName.keyExists( "entity.instantiate_narrow_shallow_internal" )
		) {
			comparisons[ "normalPostDISetupAddedWallTimePercent" ] = percentDifference(
				byName[ "entity.instantiate_narrow_shallow_internal" ].wallTime.median,
				byName[ "entity.instantiate_narrow" ].wallTime.median
			);
			if (
				byName[ "entity.instantiate_narrow" ].allocation.supported &&
				byName[ "entity.instantiate_narrow_shallow_internal" ].allocation.supported
			) {
				comparisons[ "normalPostDISetupAddedAllocationPercent" ] = percentDifference(
					byName[ "entity.instantiate_narrow_shallow_internal" ].allocation.summary.median,
					byName[ "entity.instantiate_narrow" ].allocation.summary.median
				);
			}
		}
		if ( byName.keyExists( "database.raw_rows" ) && byName.keyExists( "database.hydrated_rows" ) ) {
			comparisons[ "databaseHydrationAddedWallTimePercent" ] = percentDifference(
				byName[ "database.raw_rows" ].wallTime.median,
				byName[ "database.hydrated_rows" ].wallTime.median
			);
			if (
				byName[ "database.raw_rows" ].allocation.supported &&
				byName[ "database.hydrated_rows" ].allocation.supported
			) {
				comparisons[ "databaseHydrationAddedAllocationPercent" ] = percentDifference(
					byName[ "database.raw_rows" ].allocation.summary.median,
					byName[ "database.hydrated_rows" ].allocation.summary.median
				);
			}
		}
		return comparisons;
	}

	private numeric function percentDifference( required numeric baseline, required numeric candidate ) {
		return arguments.baseline == 0 ? 0 : ( ( arguments.candidate - arguments.baseline ) / arguments.baseline ) * 100;
	}

}
