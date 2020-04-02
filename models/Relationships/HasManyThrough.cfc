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
     * @intermediates       An array of intermediate entity mappings.
     * @intermediatesMap    A dictionary of entity mappings to entity component.
     * @foreignKeys         A dictionary of entity mappings to foreign keys.
     * @localKeys           A dictionary of entity mappings to local keys.
     *
     * @returns             quick.models.Relationships.HasManyThrough
     */
    public HasManyThrough function init(
        required any related,
        required string relationName,
        required string relationMethodName,
        required any parent,
        required array intermediates,
        required struct intermediatesMap,
        required struct foreignKeys,
        required struct localKeys,
        boolean withConstraints = true
    ) {
        variables.intermediates = arguments.intermediates;
        variables.intermediatesMap = arguments.intermediatesMap;
        variables.foreignKeys = arguments.foreignKeys;
        variables.localKeys = arguments.localKeys;
        variables.closestToParent = variables.intermediatesMap[
            variables.intermediates[ 1 ]
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
        variables.related.where( function( q ) {
            arrayZipEach(
                [
                    variables.foreignKeys[ variables.closestToParent.mappingName() ],
                    variables.localKeys[ variables.parent.mappingName() ]
                ],
                function( foreignKey, localKey ) {
                    q.where(
                        variables.closestToParent.qualifyColumn(
                            foreignKey
                        ),
                        variables.parent.retrieveAttribute( localKey )
                    );
                }
            );
        } );
        return this;
    }

    /**
     * Adds a join to the intermediate table for the relationship.
     *
     * @return  quick.models.Relationships.HasManyThrough
     */
    public HasManyThrough function performJoin( any base = variables.related ) {
        // no arrayReverse in ACF means for loops. :-(
        for ( var index = variables.intermediates.len(); index > 0; index-- ) {
            var intermediateMapping = variables.intermediates[ index ];
            var intermediateEntity = variables.intermediatesMap[
                intermediateMapping
            ];
            var previousEntity = index == variables.intermediates.len() ? variables.related : variables.intermediatesMap[
                variables.intermediates[ index + 1 ]
            ];
            var previousEntityMapping = previousEntity.mappingName();
            arguments.base.join( intermediateEntity.tableName(), function( j ) {
                arrayZipEach(
                    [
                        variables.localKeys[ intermediateMapping ],
                        variables.foreignKeys[ previousEntityMapping ]
                    ],
                    function( localKey, foreignKey ) {
                        j.on(
                            intermediateEntity.qualifyColumn( localKey ),
                            previousEntity.qualifyColumn( foreignKey )
                        );
                    }
                );
            } );
        }
        return this;
    }

    /**
     * Get the qualified column name for the `foreignKey` (the key linking the
     * related entity to the intermediate entity on the related table).
     *
     * @doc_generic  String
     * @return       [String]
     */
    public array function getQualifiedFarKeyNames() {
        return getQualifiedForeignKeyNames();
    }

    /**
     * Get the qualified column name for the `foreignKey` (the key linking the
     * related entity to the intermediate entity on the related table).
     *
     * @doc_generic  String
     * @return       [String]
     */
    public array function getQualifiedForeignKeyNames() {
        return variables.secondKeys.map( function( secondKey ) {
            return variables.related.qualifyColumn( secondKey );
        } );
    }

    /**
     * Get the qualified column name for the `firstKey` (the key linking the
     * parent entity to the intermediate entity on the intermediate table).
     *
     * @doc_generic  String
     * @return       [String]
     */
    public array function getQualifiedFirstKeyNames() {
        return variables.firstKeys.map( function( firstKey ) {
            return variables.throughParent.qualifyColumn(
                firstKey
            );
        } );
    }

    /**
     * Get the qualified column name for the `secondLocalKey` (the primary key
     * of the intermediate entity on the intermediate table.
     *
     * @doc_generic  String
     * @return       [String]
     */
    public array function getQualifiedParentKeyNames() {
        return variables.secondLocalKeys.map( function( secondLocalKey ) {
            return variables.throughParent.qualifyColumn(
                secondLocalKey
            );
        } );
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
        var qualifiedForeignKeyNames = variables.foreignKeys[
            variables.closestToParent.mappingName()
        ].map( function( foreignKey, i ) {
            return ( i != 1 ? "," : "" ) & variables.closestToParent.qualifyColumn(
                foreignKey
            );
        } );
        variables.related
            .selectRaw(
                "CONCAT(#qualifiedForeignKeyNames.toList()#) AS __QuickThroughKey__"
            )
            .appendReadOnlyAttribute( "__QuickThroughKey__" )
            .where( function( q1 ) {
                getKeys(
                    entities,
                    variables.localKeys[ variables.parent.mappingName() ]
                ).each( function( keys ) {
                    q1.orWhere( function( q2 ) {
                        arrayZipEach(
                            [
                                variables.foreignKeys[
                                    variables.closestToParent.mappingName()
                                ],
                                keys
                            ],
                            function( foreignKey, keyValue ) {
                                q2.where(
                                    variables.closestToParent.qualifyColumn(
                                        foreignKey
                                    ),
                                    keyValue
                                );
                            }
                        );
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
            var key = variables.localKeys[ variables.parent.mappingName() ]
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
                        variables.localKeys[ variables.parent.mappingName() ],
                        variables.foreignKeys[
                            variables.closestToParent.mappingName()
                        ]
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

}
