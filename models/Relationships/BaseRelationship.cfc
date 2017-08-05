component accessors="true" {

    property name="related";
    property name="owning";
    property name="foreignKey";
    property name="foreignKeyValue";
    property name="owningKey";
    property name="defaultValue";

    function init( related, owning, foreignKey, foreignKeyValue, owningKey ) {
        setRelated( arguments.related );
        setOwning( arguments.owning );
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