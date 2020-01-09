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
     * Creates a new relationship component to query and retrieve results.
     *
     * @related             The related entity instance.
     * @relationName        The WireBox mapping for the related entity.
     * @relationMethodName  The method name called to retrieve this relationship.
     * @parent              The parent entity instance for the relationship.
     *
     * @returns             BaseRelationship
     */
    public BaseRelationship function init(
        required any related,
        required string relationName,
        required string relationMethodName,
        required any parent
    ) {
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
     * @returns  BaseRelationship
     */
    public BaseRelationship function setRelationMethodName( required string name ) {
        variables.relationMethodName = arguments.name;
        return this;
    }

    /**
     * Retrieves the entities for eager loading.
     *
     * @doc_generic  quick.models.BaseEntity
     * @returns      [quick.models.BaseEntity]
     */
    public array function getEager() {
        return variables.related.get();
    }

    /**
     * Gets the first matching record for the relationship.
     * Returns null if no record is found.
     *
     * @returns  quick.models.BaseEntity
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
     * @returns  quick.models.BaseEntity
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
     * @returns  quick.models.BaseEntity
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
     * @returns  quick.models.BaseEntity
     */
    public any function findOrFail( required any id ) {
        return variables.related.findOrFail( arguments.id );
    }

    /**
     * Returns all results for the related entity.
     * Note: `all` resets any query restrictions, including relationship restrictions.
     *
     * @doc_generic  quick.models.BaseEntity
     * @returns      [quick.models.BaseEntity]
     */
    public array function all() {
        return variables.related.all();
    }

    /**
     * Wrapper for `getResults()` on relationship types that have them.
     * `get()` implemented for consistency with qb and Quick.
     *
     * @returns  quick.models.BaseEntity or [quick.models.BaseEntity]
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
     * @returns  [any]
     */
    public array function getKeys( required array entities, required string key ) {
        return unique( arguments.entities.map( function( entity ) {
            return arguments.entity.retrieveAttribute( key );
        } ) );
    }

    /**
     * Forwards missing method calls on to the related entity.
     *
     * @missingMethodName       The missing method name.
     * @missingMethodArguments  The missing method arguments struct.
     *
     * @returns                 any
     */
    public any function onMissingMethod(
        required string missingMethodName,
        required struct missingMethodArguments
    ) {
        var result = invoke(
            variables.related,
            arguments.missingMethodName,
            arguments.missingMethodArguments
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
     * @returns      [any]
     */
    public array function unique( required array items ) {
        return arraySlice(
            createObject( "java", "java.util.HashSet" )
                .init( arguments.items )
                .toArray(),
            1
        );
    }

}
