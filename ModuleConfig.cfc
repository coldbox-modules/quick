component {
    
    this.name = "quick";
    this.author = "";
    this.webUrl = "https://github.com/elpete/quick";
    this.dependencies = [ "qb", "str", "cfcollection" ];
    this.cfmapping = "quick";

    function configure() {
        settings = {
            defaultAttributeCasing = "none"
        };
    }

    function onLoad() {
        binder.map( alias = "builder@qb", force = true )
            .to( "qb.models.Query.Builder" )
            .initArg( name = "grammar", ref = "DefaultGrammar@qb" )
            .initArg( name = "utils", ref = "QueryUtils@qb" )
            .initArg( name = "returnFormat", value = function( q ) {
                return application.wirebox.getInstance(
                    name = "QuickCollection@quick",
                    initArguments = { collection = q }
                );
            } );
    }
}