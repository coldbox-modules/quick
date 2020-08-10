component {

    this.name = "quick";
    this.author = "Eric Peterson";
    this.webUrl = "https://github.com/coldbox-modules/quick";
    this.dependencies = [ "qb", "str", "mementifier" ];
    this.cfmapping = "quick";

    function configure() {
        settings = {
            "defaultGrammar" = "AutoDiscover@qb",
            "preventDuplicateJoins" = true,
            "metadataCache" = {
                "name"                  : "quickMeta",
                "provider"              : "coldbox.system.cache.providers.CacheBoxColdBoxProvider",
                "properties"            : {
                    "objectDefaultTimeout"  : 0, // no timeout
                    "useLastAccessTimeouts" : false, // no last access timeout
                    "maxObjects"            : 300,
                    "objectStore"           : "ConcurrentStore"
                }
			}
        };

        interceptorSettings = {
            customInterceptionPoints = [
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

        binder.map( "quick.models.BaseEntity" )
            .to( "#moduleMapping#.models.BaseEntity" );

        binder.getInjector().registerDSL( "quickService", "#moduleMapping#.dsl.QuickServiceDSL" );
    }

    function onLoad() {
        binder.map( alias = "QuickBuilder@quick", force = true )
            .to( "#moduleMapping#.models.QuickBuilder" )
            .initArg( name = "grammar", dsl = settings.defaultGrammar )
            .initArg( name = "preventDuplicateJoins", value = settings.preventDuplicateJoins )
            .initArg( name = "utils", dsl = "QueryUtils@qb" )
            .initArg( name = "returnFormat", value = "array" );

        if( isSimpleValue( settings.metadataCache ) ){
            settings.metadataCache = { "name" : settings.metadataCache };
        }

        if( settings.metadataCache.name != "quickMeta" ){
            binder.map( "cachebox:quickMeta" )
                    .toDSL( "cachebox:#settings.metadataCache.name#" );
        } else {
            controller.getCachebox().createCache( argumentCollection = settings.metadataCache );
        }
        
    }

    function onUnload(){
        controller.getCachebox().getCache( settings.metadataCache.name ).clearAll();
    }

    /**
     * This interception ensures that quick entity parent/child relationships are available to discriminated entities
     * @event          The current request context
     * @interceptData  The intercept data for `afterAspectsLoad`.
     */
    function afterAspectsLoad( event, interceptData ){
        param application.quickMeta = {};
        param application.quickMeta.discriminators = {};
        
        binder.getMappings().each( function( key, mapping ){
            if( !mapping.isDiscovered() ){
                mapping.process( binder, application.wirebox );
            }
            var meta = mapping.getObjectMetadata();
            if( structKeyExists( meta, "joincolumn" ) && structKeyExists( meta, "discriminatorValue" ) ){
                // retrieve the inheritance metadata and attributes
                var childClass = application.wirebox.getInstance( meta.fullName );
                var childAttributes = childClass.get_Attributes().reduce( function( acc, attr, data ){ 
                    if( !data.isParentColumn && !data.virtual && !data.exclude ){
                        acc.append( data );
                    }
                    return acc;
                 }, [] );
                var meta = childClass.get_Meta();
                var parentMeta = meta.parentDefinition.meta;
                
                if( !structKeyExists( parentMeta, "table" ) ) parentMeta = application.wirebox.getInstance( parentMeta.fullName ).get_Meta();
                
                if( !structKeyExists( application.quickMeta.discriminators, parentMeta.table ) ){
                    application.quickMeta.discriminators[ parentMeta.table ] = {};
                }

                application.quickMeta.discriminators[ parentMeta.table ][ meta.parentDefinition.discriminatorValue ] = {
                    "mapping" : meta.fullName,
                    "table" : meta.table,
                    "joincolumn" : meta.parentDefinition.joinColumn,
                    "attributes" : childAttributes
                };
            }
        } );
        
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
