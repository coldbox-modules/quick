component accessors="true" {

    property name="related";
    property name="foreignKey";
    property name="foreignKeyValue";
    property name="owningKey";
    property name="defaultValue";

    function init( related, foreignKey, foreignKeyValue, owningKey ) {
        setRelated( arguments.related );
        setForeignKey( arguments.foreignKey );
        setForeignKeyValue( arguments.foreignKeyValue );
        setOwningKey( arguments.owningKey );

        return this;
    }

    function onMissingMethod( missingMethodName, missingMethodArguments ) {
        invoke( variables.related, missingMethodName, missingMethodArguments );
        return this;
    }

}