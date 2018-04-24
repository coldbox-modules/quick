component {

    this.name = "quick";
    this.author = "Eric Peterson";
    this.webUrl = "https://github.com/coldbox-modules/quick";
    this.dependencies = [ "qb", "str", "cfcollection" ];
    this.cfmapping = "quick";

    function configure() {
        settings = {
            defaultGrammar = "BaseGrammar",
            automaticValidation = true
        };

        interceptorSettings = {
            customInterceptionPoints = [
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
    }

    function onLoad() {
        // remap to force the return format to be QuickCollection
        binder.map( alias = "QueryBuilder@qb", force = true )
            .to( "qb.models.Query.QueryBuilder" )
            .initArg( name = "grammar", dsl = "#settings.defaultGrammar#@qb" )
            .initArg( name = "utils", dsl = "QueryUtils@qb" )
            .initArg( name = "returnFormat", value = function( q ) {
                return wirebox.getInstance(
                    name = "QuickCollection@quick",
                    initArguments = { collection = q }
                );
            } );
    }
}
