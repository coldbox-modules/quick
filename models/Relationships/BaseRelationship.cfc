component accessors="true" {

    property name="wirebox" inject="wirebox";

    property name="related";
    property name="relationName";
    property name="relationMethodName";
    property name="owning";
    property name="foreignKey";
    property name="foreignKeyValue";
    property name="owningKey";
    property name="defaultValue";

    function init( related, relationName, relationMethodName, parent ) {
        variables.related = arguments.related.resetQuery();
        variables.relationName = arguments.relationName;
        variables.relationMethodName = arguments.relationMethodName;
        variables.parent = arguments.parent;

        addConstraints();

        return this;
    }

    function getEager() {
        return variables.related.get();
    }

    function getKeys( entities, key ) {
        return unique( entities.map( function( entity ) {
            return entity.retrieveAttribute( key );
        } ) );
    }

    private function collect( items = [] ) {
        return isArray( items ) ? items : listToArray( items, "," );
    }

    function onMissingMethod( missingMethodName, missingMethodArguments ) {
        var result = invoke( variables.related, missingMethodName, missingMethodArguments );
        if ( isSimpleValue( result ) ) {
            return result;
        }
        return this;
    }

    private function isQuickEntity( entity ) {
        return getMetadata( entity ).keyExists( "quick" ) ||
            isInstanceOf( entity, "quick.models.BaseEntity" );
    }

    function unique( items ) {
        return arraySlice( createObject( "java", "java.util.HashSet" ).init( items ).toArray(), 1 );
    }

}
