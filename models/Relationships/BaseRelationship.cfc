/**
 * Abstract BaseRelationship used to provide shared methods across
 * other concrete relationships.
 *
 * @doc_abstract true
 */
component {

    /**
     * The WireBox Injector.
     */
    property name="wirebox" inject="wirebox";

    /**
     * Flag to return a default model if the relation returns null.
     */
    property name="returnDefaultEntity" type="boolean" default="false";

    /**
     * Flag to return a default model if the relation returns null.
     */
    property name="defaultAttributes";

    /**
     * Creates a new relationship component to query and retrieve results.
     *
     * @related             The related entity instance.
     * @relationName        The WireBox mapping for the related entity.
     * @relationMethodName  The method name called to retrieve this relationship.
     * @parent              The parent entity instance for the relationship.
     *
     * @return              BaseRelationship
     */
    public BaseRelationship function init(
        required any related,
        required string relationName,
        required string relationMethodName,
        required any parent
    ) {
        variables.returnDefaultEntity = false;
        variables.defaultAttributes = {};

        variables.related = arguments.related.resetQuery();
        variables.relationName = arguments.relationName;
        variables.relationMethodName = arguments.relationMethodName;
        variables.parent = arguments.parent;

        variables.addConstraints();

        return this;
    }

    /**
     * Sets the relation method name for this relationship.
     *
     * @name     The relation method name for this relationship.
     *
     * @return   BaseRelationship
     */
    public BaseRelationship function setRelationMethodName(
        required string name
    ) {
        variables.relationMethodName = arguments.name;
        return this;
    }

    /**
     * Retrieves the entities for eager loading.
     *
     * @doc_generic  quick.models.BaseEntity
     * @return       [quick.models.BaseEntity]
     */
    public array function getEager() {
        return variables.related.get();
    }

    /**
     * Gets the first matching record for the relationship.
     * Returns null if no record is found.
     *
     * @return   quick.models.BaseEntity
     */
    public any function first() {
        return variables.related.first();
    }

    /**
     * Gets the first matching record for the relationship.
     * Throws an exception if no record is found.
     *
     * @throws   EntityNotFound
     *
     * @return   quick.models.BaseEntity
     */
    public any function firstOrFail() {
        return variables.related.firstOrFail();
    }

    /**
     * Finds the first matching record with a given id for the relationship.
     * Returns null if no record is found.
     *
     * @id       The id of the entity to find.
     *
     * @return   quick.models.BaseEntity
     */
    public any function find( required any id ) {
        return variables.related.find( arguments.id );
    }

    /**
     * Finds the first matching record with a given id for the relationship.
     * Throws an exception if no record is found.
     *
     * @id       The id of the entity to find.
     *
     * @throws   EntityNotFound
     *
     * @return   quick.models.BaseEntity
     */
    public any function findOrFail( required any id ) {
        return variables.related.findOrFail( arguments.id );
    }

    /**
     * Returns all results for the related entity.
     * Note: `all` resets any query restrictions, including relationship restrictions.
     *
     * @doc_generic  quick.models.BaseEntity
     * @return       [quick.models.BaseEntity]
     */
    public array function all() {
        return variables.related.all();
    }

    /**
     * Wrapper for `getResults()` on relationship types that have them.
     * `get()` implemented for consistency with qb and Quick.
     *
     * @return   quick.models.BaseEntity or [quick.models.BaseEntity]
     */
    public any function get() {
        return variables.getResults();
    }

    /**
     * Retrieves the values of the key from each entity passed.
     *
     * @entities  An array of entities to retrieve keys.
     * @key       The key to retrieve from each entity.
     *
     * @doc_generic  any
     * @return   [any]
     */
    public array function getKeys(
        required array entities,
        required string key
    ) {
        return unique(
            arguments.entities.map( function( entity ) {
                return arguments.entity.retrieveAttribute( key );
            } )
        );
    }

    /**
     * Gets the query used to check for relation existance.
     *
     * @base    The base entity for the query.
     *
     * @return  quick.models.BaseEntity | qb.models.Query.QueryBuilder
     */
    public any function getRelationExistenceQuery( required any base ) {
        var q = arguments.base.newQuery();
        return q
            .select( q.raw( 1 ) )
            .whereColumn( getQualifiedLocalKey(), getExistenceCompareKey() );
    }

    /**
     * Returns the fully-qualified local key.
     *
     * @return  String
     */
    public string function getQualifiedLocalKey() {
        return variables.parent.retrieveQualifiedKeyName();
    }

    /**
     * Get the key to compare in the existence query.
     *
     * @return  String
     */
    public string function getExistenceCompareKey() {
        return getQualifiedForeignKeyName();
    }

    /**
     * Returns the related entity for the relationship.
     */
    public any function getRelated() {
        return variables.related;
    }

    /**
     * Flags the entity to return a default entity if the relation returns null.
     *
     * @return  quick.models.Relationships.BaseRelationship
     */
    public BaseRelationship function withDefault( any attributes = {} ) {
        variables.returnDefaultEntity = true;
        variables.defaultAttributes = arguments.attributes;
        return this;
    }

    /**
     * Forwards missing method calls on to the related entity.
     *
     * @missingMethodName       The missing method name.
     * @missingMethodArguments  The missing method arguments struct.
     *
     * @return                  any
     */
    function onMissingMethod( missingMethodName, missingMethodArguments ) {
        var result = invoke(
            variables.related,
            missingMethodName,
            missingMethodArguments
        );
        if ( isSimpleValue( result ) ) {
            return result;
        }

        return this;
    }

    /**
     * Returns an array of the unique items of an array.
     *
     * @items        An array of items.
     *
     * @doc_generic  any
     * @return       [any]
     */
    public array function unique( required array items ) {
        return arraySlice(
            createObject( "java", "java.util.HashSet" ).init( arguments.items ).toArray(),
            1
        );
    }

    /**
     * Calls the callback with the given value and then returns the given value.
     * Nice to avoid temporary variables.
     *
     * @value     The value to pass to the callback and as the return value.
     * @callback  The callback to execute.
     *
     * @return    any
     */
    private any function tap( required any value, required any callback ) {
        arguments.callback( arguments.value );
        return arguments.value;
    }

}
