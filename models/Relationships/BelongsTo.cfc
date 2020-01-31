/**
 * Represents a belongsTo relationship.
 *
 * This is a relationship where the related entity belongs to
 * exactly one of the parent entity. The inverse of this relationship
 * is a `hasMany` relationship.
 *
 * For instance, a `Post` may belong to a `User` which we can call an author.
 * This would be modeled in Quick by adding a method to the `Post` entity
 * that returns a `BelongsTo` relationship instance.
 *
 * ```
 * function author() {
 *     returns belongsTo( "User" );
 * }
 * ```
 */
component extends="quick.models.Relationships.BaseRelationship" {

    /**
     * Creates a belongsTo relationship.
     *
     * @related             The related entity instance.
     * @relationName        The WireBox mapping for the related entity.
     * @relationMethodName  The method name called to retrieve this relationship.
     * @parent              The parent entity instance for the relationship.
     *                      In a `BelongsTo` relationship, this is also referred
     *                      to internally as `child`.
     * @foreignKey          The column name on the `parent` entity that refers to
     *                      the `ownerKey` on the `related` entity.
     * @ownerKey            The column name on the `realted` entity that is referred
     *                      to by the `foreignKey` of the `parent` entity.
     *
     * @return              quick.models.Relationships.BelongsTo
     */
    public BelongsTo function init(
        required any related,
        required string relationName,
        required string relationMethodName,
        required any parent,
        required string foreignKey,
        required string ownerKey
    ) {
        variables.ownerKey = arguments.ownerKey;
        variables.foreignKey = arguments.foreignKey;
        variables.child = arguments.parent;

        return super.init(
            related = arguments.related,
            relationName = arguments.relationName,
            relationMethodName = arguments.relationMethodName,
            parent = arguments.parent
        );
    }

    /**
     * Returns the result of the relationship.
     *
     * @return  quick.models.BaseEntity | null
     */
    public any function getResults() {
        if ( variables.child.isNullAttribute( variables.foreignKey ) ) {
            return javacast( "null", "" );
        }
        return variables.related.first();
    }

    /**
     * Adds the constraints to the related entity.
     *
     * @return  void
     */
    public void function addConstraints() {
        var table = variables.related.get_Table();
        variables.related.where(
            "#table#.#variables.ownerKey#",
            "=",
            variables.child.retrieveAttribute( variables.foreignKey )
        );
    }

    /**
     * Adds the constraints for eager loading.
     *
     * @entities  The entities being eager loaded.
     *
     * @return    quick.models.Relationships.BelongsTo
     */
    public BelongsTo function addEagerConstraints( required array entities ) {
        var key = variables.related.get_Table() & "." & variables.ownerKey;
        variables.related.whereIn(
            key,
            getEagerEntityKeys( arguments.entities )
        );
        return this;
    }

    /**
     * Returns an array of entity keys for the entities being eager loaded.
     *
     * @entities     The entities being eager loaded.
     *
     * @doc_generic  any
     * @return       [any]
     */
    public array function getEagerEntityKeys( required array entities ) {
        return arguments.entities
            .reduce( function( keys, entity ) {
                if (
                    !isNull(
                        arguments.entity.retrieveAttribute(
                            variables.foreignKey
                        )
                    )
                ) {
                    var key = arguments.entity.retrieveAttribute(
                        variables.foreignKey
                    );
                    if ( key != "" ) {
                        arguments.keys[ key ] = {};
                    }
                }
                return arguments.keys;
            }, {} )
            .keyArray();
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
        arguments.entities.each( function( entity ) {
            arguments.entity.assignRelationship(
                relation,
                javacast( "null", "" )
            );
        } );
        return arguments.entities;
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
        var dictionary = arguments.results.reduce( function( dict, result ) {
            var key = arguments.result.retrieveAttribute(
                variables.ownerKey
            );
            arguments.dict[ key ] = arguments.result;
            return arguments.dict;
        }, {} );

        arguments.entities.each( function( entity ) {
            var foreignKeyValue = arguments.entity.retrieveAttribute(
                variables.foreignKey
            );
            if ( structKeyExists( dictionary, foreignKeyValue ) ) {
                arguments.entity.assignRelationship(
                    relation,
                    dictionary[ foreignKeyValue ]
                );
            }
        } );

        return arguments.entities;
    }

    /**
     * Associates the given entity when the relationship is used as a setter.
     *
     * Relationships on entities can be called with `set` in front of it.
     * If it is, a `BelongsTo` relationship forwards the call to `associate`.
     *
     * @entity  The entity or entity id to associate as the new owner.
     *          If an entity is passed, it is also cached in the child entity
     *          as the value for the relationship.
     *
     * @return  quick.models.BaseEntity
     */
    function applySetter() {
        return associate( argumentCollection = arguments );
    }

    /**
     * Sets a new entity as the parent of the relationship.
     * For example, if a Post belongs to a User, associate will set
     * the foreign key on the Post table to the User's id.
     *
     * @entity  The entity or entity id to associate as the new owner.
     *          If an entity is passed, it is also cached in the child entity
     *          as the value for the relationship.
     *
     * @return  quick.models.BaseEntity
     */
    public any function associate( required any entity ) {
        var ownerKeyValue = isSimpleValue( arguments.entity ) ? arguments.entity : arguments.entity.retrieveAttribute(
            variables.ownerKey
        );
        variables.child.forceAssignAttribute(
            variables.foreignKey,
            ownerKeyValue
        );
        if ( !isSimpleValue( arguments.entity ) ) {
            variables.child.assignRelationship(
                variables.relationMethodName,
                arguments.entity
            );
        }
        return variables.child;
    }

    /**
     * Removes an entity as the parent of the relationship.
     * For example, if a Post belongs to a User, dissociate will set the
     * foreign key column on the Post entity to null.
     *
     * @return  quick.models.BaseEntity
     */
    function dissociate() {
        return variables.child
            .forceClearAttribute(
                name = variables.foreignKey,
                setToNull = true
            )
            .clearRelationship( variables.relationMethodName );
    }

}
