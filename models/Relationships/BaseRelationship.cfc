component accessors="true" {

    property name="wirebox" inject="wirebox" getter="false" setter="false";

    property name="related";
    property name="relationName";
    property name="relationMethodName";
    property name="owning";
    property name="foreignKey";
    property name="foreignKeyValue";
    property name="owningKey";
    property name="defaultValue";

    function init( related, relationName, relationMethodName, owning, foreignKey, foreignKeyValue, owningKey ) {
        setRelated( arguments.related );
        setRelationName( arguments.relationName );
        setRelationMethodName( arguments.relationMethodName );
        setOwning( arguments.owning );
        setForeignKey( arguments.foreignKey );
        setForeignKeyValue( arguments.foreignKeyValue );
        setOwningKey( arguments.owningKey );

        apply();

        return this;
    }

    function onMissingMethod( missingMethodName, missingMethodArguments ) {
        var result = invoke( variables.related, missingMethodName, missingMethodArguments );
        if ( isSimpleValue( result ) ) {
            return result;
        }
        return this;
    }

}