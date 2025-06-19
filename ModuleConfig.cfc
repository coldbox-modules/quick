component {

	this.name         = "quick";
	this.author       = "Eric Peterson";
	this.webUrl       = "https://github.com/coldbox-modules/quick";
	this.dependencies = [ "qb", "str", "mementifier" ];
	this.cfmapping    = "quick";

	function configure() {
		settings = {
			"defaultGrammar"               : "AutoDiscover@qb",
			"defaultQueryOptions"          : {},
			"preventDuplicateJoins"        : true,
			"preventLazyLoading"           : false,
			"lazyLoadingViolationCallback" : ( entity, relationName ) => {
				throw(
					type    = "QuickLazyLoadingException",
					message = "Attempted to lazy load the [#arguments.relationName#] relationship on the entity [#arguments.entity.mappingName()#] but lazy loading is disabled. This is usually caused by the N+1 problem and is a sign that you are missing an eager load."
				);
			},
			"metadataCache" : {
				"name"       : "quickMeta",
				"provider"   : "coldbox.system.cache.providers.CacheBoxColdBoxProvider",
				"properties" : {
					"objectDefaultTimeout"  : 0, // no timeout
					"useLastAccessTimeouts" : false, // no last access timeout
					"maxObjects"            : 300,
					"objectStore"           : "ConcurrentStore"
				}
			}
		};

		interceptorSettings = {
			customInterceptionPoints : [
				"quickInstanceReady",
				"quickPreLoad",
				"quickPostLoad",
				"quickPreSave",
				"quickPostSave",
				"quickPreInsert",
				"quickPostInsert",
				"quickPreUpdate",
				"quickPostUpdate",
				"quickPreDelete",
				"quickPostDelete"
			]
		};

		binder.map( "quick.models.BaseEntity" ).to( "#moduleMapping#.models.BaseEntity" );

		binder.getInjector().registerDSL( "quickService", "#moduleMapping#.dsl.QuickServiceDSL" );
	}

	function onLoad() {
		binder
			.map( alias = "QuickQB@quick", force = true )
			.to( "#moduleMapping#.models.QuickQB" )
			.initArg( name = "grammar", dsl = settings.defaultGrammar )
			.initArg( name = "preventDuplicateJoins", value = settings.preventDuplicateJoins )
			.initArg( name = "defaultOptions", value = settings.defaultQueryOptions )
			.initArg( name = "utils", dsl = "QueryUtils@qb" )
			.initArg( name = "sqlCommenter", ref = "ColdBoxSQLCommenter@qb" )
			.initArg( name = "returnFormat", value = "array" );

		if ( isSimpleValue( settings.metadataCache ) ) {
			settings.metadataCache = { "name" : settings.metadataCache };
		}

		if ( settings.metadataCache.name != "quickMeta" ) {
			binder.map( "cachebox:quickMeta" ).toDSL( "cachebox:#settings.metadataCache.name#" );
		} else {
			wirebox.getCachebox().createCache( argumentCollection = settings.metadataCache );
		}
	}

	function onUnload() {
		var cacheBox = wirebox.getCachebox();
		if ( cacheBox.cacheExists( settings.metadataCache.name ) ) {
			cacheBox.getCache( settings.metadataCache.name ).clearAll();
		}
	}


	/**
	 * This interceptor ensures that the `_mapping` property for a Quick entity
	 * is correctly set to the mapping used in WireBox.
	 *
	 * @event          The current request context
	 * @interceptData  The intercept data for `afterInstanceAutowire`.
	 *                 { mapping, target, targetID, injector }
	 */
	function beforeInstanceAutowire( event, interceptData ) {
		if ( structKeyExists( interceptData.target, "isQuickEntity" ) ) {
			interceptData.target.set_mapping( interceptData.targetID );
		}
	}

}
