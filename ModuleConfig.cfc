component {

	this.name         = "quick";
	this.author       = "Eric Peterson";
	this.webUrl       = "https://github.com/coldbox-modules/quick";
	this.dependencies = [ "qb", "str", "mementifier" ];
	this.cfmapping    = "quick";

	function configure() {
		settings = {
			"defaultGrammar"        : "AutoDiscover@qb",
			"defaultReturnFormat"	: "array",
			"preventDuplicateJoins" : true,
			"metadataCache"         : {
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

		//bind QuickBuilder model
		binder
			.map( alias = "QuickBuilder@quick", force = true )
			.to( "#moduleMapping#.models.QuickBuilder" )
			.initArg( name = "defaultReturnFormat", value = settings.defaultReturnFormat );

		//bind CBORMCriteriaBuilderCompat model
		binder
			.map( alias = "CBORMCriteriaBuilderCompat@quick", force = true )
			.to( "#moduleMapping#.models.CBORMCriteriaBuilderCompat" )
			.initArg( name = "defaultReturnFormat", value = settings.defaultReturnFormat );


		//bind QuickQB model
		binder
			.map( alias = "QuickQB@quick", force = true )
			.to( "#moduleMapping#.models.QuickQB" )
			.initArg( name = "grammar", dsl = settings.defaultGrammar )
			.initArg( name = "preventDuplicateJoins", value = settings.preventDuplicateJoins )
			.initArg( name = "utils", dsl = "QueryUtils@qb" )
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
		wirebox
			.getCachebox()
			.getCache( settings.metadataCache.name )
			.clearAll();
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
