component {

    function onMissingMethod( missingMethodName, missingMethodArguments ) {
        invoke( variables.related, missingMethodName, missingMethodArguments );
        return this;
    }

}