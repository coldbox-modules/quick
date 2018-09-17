component {

    property name="wirebox" inject="wirebox";

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

    function onMissingMethod( missingMethodName, missingMethodArguments ) {
        var result = invoke( variables.related, missingMethodName, missingMethodArguments );
        if ( isSimpleValue( result ) ) {
            return result;
        }
        return this;
    }

    function unique( items ) {
        return arraySlice( createObject( "java", "java.util.HashSet" ).init( items ).toArray(), 1 );
    }

}
