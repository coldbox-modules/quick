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
    extends="quick.models.Relationships.BaseRelationship"
    accessors="true"
{

    /**
     * An array of relationships between the parent entity and the related entity.
     */
    property name="relationships" type="array";

    /**
     * A dictionary of relationship name to relationship component.
     */
    property name="relationshipsMap" type="struct";

    /**
     * A shortcut to access the entity closest to the parent entity.
     * This is the result of the first relationship in the `relationships` chain.
     */
    property name="closestToParent";

    /**
     * Creates a HasManyThrough relationship.
     *
     * @related             The related entity instance.
     * @relationName        The WireBox mapping for the related entity.
     * @relationMethodName  The method name called to retrieve this relationship.
     * @parent              The parent entity instance for the relationship.
     * @relationships       An array of relationships between the parent entity
     *                      and the related entity.
     * @relationshipsMap    A dictionary of relationship name to relationship component.
     *
     * @returns             quick.models.Relationships.HasManyThrough
     */
    public HasManyThrough function init(
        required any related,
        required string relationName,
        required string relationMethodName,
        required any parent,
        required array relationships,
        required struct relationshipsMap,
        boolean withConstraints = true
    ) {
        variables.relationships = arguments.relationships;
        variables.relationshipsMap = arguments.relationshipsMap;
        variables.closestToParent = variables.relationshipsMap[
            variables.relationships[ 1 ]
        ];

        return super.init(
            related = arguments.related,
            relationName = arguments.relationName,
            relationMethodName = arguments.relationMethodName,
            parent = arguments.parent,
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
        variables.closestToParent.applyThroughConstraints(
            variables.related
        );
        return this;
    }

    /**
     * Adds a join to the intermediate tables for the relationship.
     *
     * @return  quick.models.Relationships.HasManyThrough
     */
    public HasManyThrough function performJoin( any base = variables.related ) {
        // no arrayReverse in ACF means for loops. :-(
        for ( var index = variables.relationships.len(); index > 1; index-- ) {
            var relationshipName = variables.relationships[ index ];
            var relation = variables.relationshipsMap[ relationshipName ];
            relation.applyThroughJoin( arguments.base );
        }
        return this;
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
        var foreignKeys = variables.closestToParent.getForeignKeys();
        var qualifiedForeignKeyList = foreignKeys
            .reduce( function( acc, foreignKey, i ) {
                if ( i != 1 ) {
                    acc.append( "," );
                }
                acc.append(
                    variables.closestToParent.qualifyColumn(
                        foreignKey
                    )
                );
                return acc;
            }, [] )
            .toList();
        variables.related
            .selectRaw(
                "CONCAT(#qualifiedForeignKeyList#) AS __QuickThroughKey__"
            )
            .appendReadOnlyAttribute( "__QuickThroughKey__" )
            .where( function( q1 ) {
                getKeys( entities, variables.closestToParent.getLocalKeys() ).each( function( keys ) {
                    q1.orWhere( function( q2 ) {
                        arrayZipEach( [ foreignKeys, keys ], function( foreignKey, keyValue ) {
                            q2.where(
                                variables.closestToParent.qualifyColumn(
                                    foreignKey
                                ),
                                keyValue
                            );
                        } );
                    } );
                } );
            } );
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
            var key = variables.closestToParent
                .getLocalKeys()
                .map( function( localKey ) {
                    return entity.retrieveAttribute( localKey );
                } )
                .toList();
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
            var key = result.retrieveAttribute( "__QuickThroughKey__" );
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
            performJoin( q );
            q.where( function( q2 ) {
                arrayZipEach(
                    [
                        variables.parent.keyNames(),
                        variables.closestToParent.getForeignKeys()
                    ],
                    function( localKey, foreignKey ) {
                        q2.whereColumn(
                            variables.parent.qualifyColumn( localKey ),
                            variables.closestToParent.qualifyColumn(
                                foreignKey
                            )
                        );
                    }
                );
            } );
        } );
    }

    /**
     * Sets an alias for the relationship.
     * This is ignored for `hasManyThrough` because each of the relationship
     * components inside `relationshipsMap` will already be aliased.
     *
     * @alias   The alias to use.
     *
     * @return  quick.models.Relationships.HasManyThrough
     */
    public HasManyThrough function applyAlias( required string alias ) {
        return this;
    }

    /**
     * Applies the join for relationship in a `hasManyThrough` chain.
     *
     * @base    The query to apply the join to.
     *
     * @return  void
     */
    public void function applyThroughJoin( required any base ) {
        performJoin( arguments.base );
        variables.closestToParent.applyThroughJoin(
            arguments.base
        );
    }

}
