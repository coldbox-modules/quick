/**
 * Represents a hasManyThrough relationship.
 *
 * This is a relationship where the parent entity has zero or more of the related
 * entity.  The related entity is found through an intermediate entity.
 * The inverse of this relationship is also a `hasManyThrough` relationship.
 *
 * For instance, a `User` may have zero or more `Role` entities associated
 * to it.  A `Role` can have zero or more `Permission` entities associated
 * to it.  Therefore, a `User` "has many" `Permissions` "through" `Role`.
 * This would be modeled in Quick by adding a method to the `User` entity
 * that returns a `HasManyThrough` relationship instance.
 *
 * ```
 * function permissions() {
 *     returns hasManyThrough( "Permission", "Role" );
 * }
 * ```
 */
component
    accessors="true"
    extends="quick.models.Relationships.BaseRelationship"
{

    /**
     * Creates a HasManyThrough relationship.
     *
     * @related             The related entity instance.
     * @relationName        The WireBox mapping for the related entity.
     * @relationMethodName  The method name called to retrieve this relationship.
     * @parent              The parent entity instance for the relationship.
     * @intermediate        The intermediate entity instance for the relationship.
     * @firstKey            The key on the intermediate table linking it to the
     *                      parent entity.
     * @secondKey           The key on the related entity linking it to the
     *                      intermediate entity.
     * @localKey            The local primary key on the parent entity.
     * @secondLocalKey      The local primary key on the intermediate entity.
     *
     * @returns             quick.models.Relationships.HasManyThrough
     */
    public HasManyThrough function init(
        required any related,
        required string relationName,
        required string relationMethodName,
        required any parent,
        required any intermediate,
        required string firstKey,
        required string secondKey,
        required string localKey,
        required string secondLocalKey,
        boolean withConstraints = true
    ) {
        variables.throughParent = arguments.intermediate;
        variables.farParent = arguments.parent;

        variables.firstKey = arguments.firstKey;
        variables.secondKey = arguments.secondKey;
        variables.localKey = arguments.localKey;
        variables.secondLocalKey = arguments.secondLocalKey;

        return super.init(
            related = arguments.related,
            relationName = arguments.relationName,
            relationMethodName = arguments.relationMethodName,
            parent = arguments.intermediate,
            withConstraints = arguments.withConstraints
        );
    }

    /**
     * Adds the constraints to the related entity.
     *
     * @return  quick.models.Relationships.HasManyThrough
     */
    public HasManyThrough function addConstraints() {
        performJoin();
        variables.related.where(
            getQualifiedFirstKeyName(),
            "=",
            variables.farParent.retrieveAttribute(
                variables.localKey
            )
        );
        return this;
    }

    /**
     * Adds a join to the intermediate table for the relationship.
     *
     * @return  quick.models.Relationships.HasManyThrough
     */
    public HasManyThrough function performJoin( any base = variables.related ) {
        arguments.base
            .join(
                variables.throughParent.tableName(),
                getQualifiedParentKeyName(),
                getQualifiedFarKeyName()
            )
            .addSelect(
                variables.throughParent.qualifyColumn(
                    variables.firstKey
                )
            );

        return this;
    }

    /**
     * Get the qualified column name for the `foreignKey` (the key linking the
     * related entity to the intermediate entity on the related table).
     *
     * @returns  string
     */
    public string function getQualifiedFarKeyName() {
        return getQualifiedForeignKeyName();
    }

    /**
     * Get the qualified column name for the `foreignKey` (the key linking the
     * related entity to the intermediate entity on the related table).
     *
     * @returns  string
     */
    public string function getQualifiedForeignKeyName() {
        return variables.related.qualifyColumn( variables.secondKey );
    }

    /**
     * Get the qualified column name for the `firstKey` (the key linking the
     * parent entity to the intermediate entity on the intermediate table).
     *
     * @returns  string
     */
    function getQualifiedFirstKeyName() {
        return variables.throughParent.qualifyColumn(
            variables.firstKey
        );
    }

    /**
     * Get the qualified column name for the `secondLocalKey` (the primary key
     * of the intermediate entity on the intermediate table.
     *
     * @returns  string
     */
    public string function getQualifiedParentKeyName() {
        return variables.throughParent.qualifyColumn(
            variables.secondLocalKey
        );
    }

    /**
     * Returns the result of the relationship.
     *
     * @doc_generic  quick.models.BaseEntity
     * @return       [quick.models.BaseEntity]
     */
    public array function getResults() {
        return this.get();
    }

    /**
     * Returns the result of the relationship.
     * Automatically eager loads any related entities.
     *
     * @doc_generic  quick.models.BaseEntity
     * @return       [quick.models.BaseEntity]
     */
    public array function get() {
        return variables.related.get();
    }

    /**
     * Adds the constraints for eager loading.
     *
     * @entities  The entities being eager loaded.
     *
     * @return    quick.models.Relationships.HasManyThrough
     */
    public HasManyThrough function addEagerConstraints(
        required array entities
    ) {
        performJoin();
        variables.related.whereIn(
            getQualifiedFirstKeyName(),
            getKeys( arguments.entities, variables.localKey )
        );
        return this;
    }

    /**
     * Initializes the relation to the null value for each entity in an array.
     *
     * @entities     The entities to initialize the relation.
     * @relation     The name of the relation to initialize.
     *
     * @doc_generic  quick.models.BaseEntity
     * @return       [quick.models.BaseEntity]
     */
    public array function initRelation(
        required array entities,
        required string relation
    ) {
        return arguments.entities.map( function( entity ) {
            return arguments.entity.assignRelationship( relation, [] );
        } );
    }

    /**
     * Matches the array of entity results to an array of entities for a relation.
     * Any matched records are populated into the matched entity's relation.
     *
     * @entities     The entities being eager loaded.
     * @results      The relationship results.
     * @relation     The relation name being loaded.
     *
     * @doc_generic  quick.models.BaseEntity
     * @return       [quick.models.BaseEntity]
     */
    public array function match(
        required array entities,
        required array results,
        required string relation
    ) {
        var dictionary = buildDictionary( arguments.results );
        arguments.entities.each( function( entity ) {
            var key = entity.retrieveAttribute( variables.localKey );
            if ( structKeyExists( dictionary, key ) ) {
                entity.assignRelationship( relation, dictionary[ key ] );
            }
        } );
        return arguments.entities;
    }

    /**
     * Builds a dictionary mapping the `firstKey` value to related results.
     *
     * @results      The array of entities from retrieving the relationship.
     *
     * @doc_generic  any,quick.models.BaseEntity
     * @return       {any: quick.models.BaseEntity}
     */
    public struct function buildDictionary( required array results ) {
        return arguments.results.reduce( function( dict, result ) {
            var key = arguments.result.retrieveAttribute(
                variables.firstKey
            );
            if ( !structKeyExists( arguments.dict, key ) ) {
                arguments.dict[ key ] = [];
            }
            arrayAppend( arguments.dict[ key ], arguments.result );
            return arguments.dict;
        }, {} );
    }

    /**
     * Gets the query used to check for relation existance.
     *
     * @base    The base entity for the query.
     *
     * @return  quick.models.BaseEntity | qb.models.Query.QueryBuilder
     */
    public any function addCompareConstraints( any base = variables.related ) {
        return tap( arguments.base.select(), function( q ) {
            performJoin( arguments.q );
            arguments.q.whereColumn(
                variables.farParent.qualifyColumn(
                    variables.localKey
                ),
                variables.throughParent.qualifyColumn(
                    variables.firstKey
                )
            );
        } );
    }

}
