component {

    this.name = "quick";
    this.author = "Eric Peterson";
    this.webUrl = "https://github.com/coldbox-modules/quick";
    this.dependencies = [ "qb", "str", "mementifier" ];
    this.cfmapping = "quick";

    function configure() {
        settings = {
            defaultGrammar = "AutoDiscover"
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

		interceptors = [
			{ class="#moduleMapping#.interceptors.QuickVirtualInheritanceInterceptor" }
        ];

        binder.map( "quick.models.BaseEntity" )
            .to( "#moduleMapping#.models.BaseEntity" );

        binder.getInjector().registerDSL( "quickService", "#moduleMapping#.dsl.QuickServiceDSL" );

        var creatorType = server.keyExists( "lucee" ) ? "LuceeEntityCreator" : "ACFEntityCreator";
        binder.map( "EntityCreator@quick" )
            .to( "#moduleMapping#.extras.#creatorType#" );
    }

    function onLoad() {
        binder.map( "QuickQB@quick" )
            .to( "qb.models.Query.QueryBuilder" )
            .initArg( name = "grammar", dsl = settings.defaultGrammar )
            .initArg( name = "utils", dsl = "QueryUtils@qb" )
            .initArg( name = "returnFormat", value = "array" );

        binder.map( alias = "QuickBuilder@quick", force = true )
            .to( "#moduleMapping#.models.QuickBuilder" )
            .initArg( name = "grammar", dsl = settings.defaultGrammar )
            .initArg( name = "utils", dsl = "QueryUtils@qb" )
            .initArg( name = "returnFormat", value = "array" );
    }
}
