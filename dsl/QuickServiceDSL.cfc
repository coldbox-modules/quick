component {

    function init( required injector ) {
        variables.injector = arguments.injector;
        return this;
    }

    function process( required definition, targetObject ) {
        return variables.injector.getInstance(
            name = "BaseService@quick",
            initArguments = {
                entity = variables.injector.getInstance( listRest( definition.dsl, ":" ) )
            }
        );
    }

}
