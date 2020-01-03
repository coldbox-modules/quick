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

    function setRelationMethodName( name ) {
        variables.relationMethodName = arguments.name;
        return this;
    }

    function getEager() {
        return variables.related.get();
    }

    function first() {
        return variables.related.first();
    }

    function firstOrFail() {
        return variables.related.firstOrFail();
    }

    function find( id ) {
        return variables.related.find( arguments.id );
    }

    function findOrFail( id ) {
        return variables.related.findOrFail( arguments.id );
    }

    function all() {
        return variables.related.all();
    }

    /**
    * get()
    * @hint wrapper for getResults() on relationship types that have them, which is most of them. get() implemented for consistency with QB and Quick
    */
    function get() {
        return getResults();
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
