/**
 * Represents a belongsToMany relationship.
 *
 * This is a relationship where the related entity belongs to
 * zero or more of one of the parent entities. The inverse of this
 * relationship is also a `belongsToMany` relationship.
 *
 * For instance, a `Post` may have zero or more `Tag` entities.
 * The inverse is also true. This would be modeled in Quick by adding a
 * method to the `Post` entity that returns a `BelongsToMany` relationship instance.
 *
 * ```
 * function tags() {
 *     returns belongsToMany( "Tag" );
 * }
 * ```
 */
component extends="quick.models.Relationships.BaseRelationship" {

    /**
     * Creates a BelongsToMany relationship.
     *
     * @related             The related entity instance.
     * @relationName        The WireBox mapping for the related entity.
     * @relationMethodName  The method name called to retrieve this relationship.
     * @parent              The parent entity instance for the relationship.
     * @table               The table name used as the pivot table for the
     *                      relationship.  A pivot table is a table that stores,
     *                      at a minimum, the primary key values of each side
     *                      of the relationship as foreign keys.
     * @foreignPivotKey     The name of the column on the pivot `table` that holds
     *                      the value of the `parentKey` of the `parent` entity.
     * @relatedPivotKey     The name of the column on the pivot `table` that holds
     *                      the value of the `relatedKey` of the `ralated` entity.
     * @parentKey           The name of the column on the `parent` entity that is
     *                      stored in the `foreignPivotKey` column on `table`.
     * @relatedKey          The name of the column on the `related` entity that is
     *                      stored in the `relatedPivotKey` column on `table`.
     *
     * @return              quick.models.Relationships.BelongsToMany
     */
    public BelongsToMany function init(
        required any related,
        required string relationName,
        required string relationMethodName,
        required any parent,
        required string table,
        required string foreignPivotKey,
        required string relatedPivotKey,
        required string parentKey,
        required string relatedKey,
        boolean withConstraints = true
    ) {
        variables.table = arguments.table;
        variables.parentKey = arguments.parentKey;
        variables.relatedKey = arguments.relatedKey;
        variables.relatedPivotKey = arguments.relatedPivotKey;
        variables.foreignPivotKey = arguments.foreignPivotKey;

        return super.init(
            related = arguments.related,
            relationName = arguments.relationName,
            relationMethodName = arguments.relationMethodName,
            parent = arguments.parent,
            withConstraints = arguments.withConstraints
        );
    }

    /**
     * Returns the result of the relationship.
     *
     * @doc_generic  quick.models.BaseEntity
     * @return       [quick.models.BaseEntity]
     */
    public array function getResults() {
        return variables.related.get();
    }

    /**
     * Adds the constraints to the related entity.
     *
     * @return  void
     */
    public void function addConstraints() {
        variables.related.select(); // clear select
        performJoin();
        addWhereConstraints();
    }

    /**
     * Adds the constraints for eager loading.
     *
     * @entities  The entities being eager loaded.
     *
     * @return    void
     */
    public void function addEagerConstraints( required array entities ) {
        variables.related
            .select() // clear select
            .from( variables.table )
            .whereIn(
                getQualifiedForeignPivotKeyName(),
                getKeys( arguments.entities, variables.parentKey )
            );
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
        var dictionary = variables.buildDictionary( arguments.results );
        arguments.entities.each( function( entity ) {
            var parentKeyValue = arguments.entity.retrieveAttribute(
                variables.parentKey
            );
            if ( structKeyExists( dictionary, parentKeyValue ) ) {
                arguments.entity.assignRelationship(
                    relation,
                    dictionary[ parentKeyValue ]
                );
            }
        } );
        return arguments.entities;
    }

    /**
     * Builds a dictionary mapping the `foreignPivotKey` value to related results.
     *
     * @results      The array of entities from retrieving the relationship.
     *
     * @doc_generic  any,quick.models.BaseEntity
     * @return       {any: quick.models.BaseEntity}
     */
    public struct function buildDictionary( required array results ) {
        return arguments.results.reduce( function( dict, result ) {
            var key = arguments.result.retrieveAttribute(
                variables.foreignPivotKey
            );
            if ( !structKeyExists( arguments.dict, key ) ) {
                arguments.dict[ key ] = [];
            }
            arrayAppend( arguments.dict[ key ], arguments.result );
            return arguments.dict;
        }, {} );
    }

    /**
     * Adds a join to the pivot table for the relationship.
     *
     * @return  quick.models.Relationships.BelongsToMany
     */
    public BelongsToMany function performJoin() {
        variables.related.join(
            variables.table,
            variables.related.qualifyColumn( variables.relatedKey ),
            getQualifiedRelatedPivotKeyName()
        );
        return this;
    }

    /**
     * Adds the where constraints for the relationship.
     *
     * @return  quick.models.Relationships.BelongsToMany
     */
    public BelongsToMany function addWhereConstraints() {
        variables.related.where(
            getQualifiedForeignPivotKeyName(),
            variables.parent.retrieveAttribute( variables.parentKey )
        );
        return this;
    }

    /**
     * Get's the qualified related pivot key column name.
     * Qualified columns are "table.column".
     *
     * @return  string
     */
    public string function getQualifiedRelatedPivotKeyName() {
        return variables.table & "." & variables.relatedPivotKey;
    }

    /**
     * Get's the qualified foreign pivot key column name.
     * Qualified columns are "table.column".
     *
     * @return  string
     */
    public string function getQualifiedForeignPivotKeyName() {
        return variables.table & "." & variables.foreignPivotKey;
    }

    /**
     * Associates one or more ids of the related entity to the parent entity.
     *
     * @id      The id or array of ids of the related entity.
     *
     * @return  quick.models.BaseEntity
     */
    public any function attach( required any id ) {
        variables
            .newPivotStatement()
            .insert( variables.parseIdsForInsert( arguments.id ) );
        return variables.parent;
    }

    /**
     * Deletes one or more ids of the related entity from the pivot table
     * where the foreign key is the parent's foreign key value..
     *
     * @id      The id or array of ids of the related entity to delete.
     *
     * @return  quick.models.BaseEntity
     */
    public any function detach( required any id ) {
        var foreignPivotKeyValue = variables.parent.retrieveAttribute(
            variables.parentKey
        );
        variables
            .newPivotStatement()
            .where( variables.foreignPivotKey, foreignPivotKeyValue )
            .whereIn(
                variables.relatedPivotKey,
                variables.parseIds( arguments.id )
            )
            .delete();
        return variables.parent;
    }

    /**
     * Associates the given entity when the relationship is used as a setter.
     *
     * Relationships on entities can be called with `set` in front of it.
     * If it is, a `BelongsTo` relationship forwards the call to `associate`.
     *
     * @id      The entity or entity id to associate as the new owner.
     *          If an entity is passed, it is also cached in the child entity
     *          as the value for the relationship.
     *
     * @return  quick.models.BaseEntity
     */
    function applySetter() {
        return sync( argumentCollection = arguments );
    }

    /**
     * Uses the ids provided as the only relationships between the parent and
     * related entity. It deletes all current ids in the pivot table for the
     * parent and then attaches all the provided related ids to the parent.
     *
     * @id      The id or array of ids that should be the only relationships
     *          between the parent and related entities.
     *
     * @return  quick.models.BaseEntity
     */
    public any function sync( required any id ) {
        var foreignPivotKeyValue = variables.parent.retrieveAttribute(
            variables.parentKey
        );
        variables
            .newPivotStatement()
            .where( variables.foreignPivotKey, foreignPivotKeyValue )
            .delete();
        return variables.attach( arguments.id );
    }

    /**
     * Returns a new query based on the pivot table.
     *
     * @return  qb.models.Query.QueryBuilder
     */
    public any function newPivotStatement() {
        return variables.related
            .newQuery()
            .from( variables.table );
    }

    /**
     * Normalizes a single id or entity or an array of ids and/or entities
     * in to an array of ids.
     *
     * @value        An id, entity, or combination of either in an array.
     *
     * @doc_generic  any
     * @return       [any]
     */
    public array function parseIds( required any value ) {
        arguments.value = isArray( arguments.value ) ? arguments.value : [
            arguments.value
        ];
        return arguments.value.map( function( val ) {
            // If the value is not a simple value, we will assume
            // it is an entity and return its key value.
            if ( !isSimpleValue( arguments.val ) ) {
                return arguments.val.keyValue();
            }
            return arguments.val;
        } );
    }

    /**
     * Normalizes a single id or entity or an array of ids and/or entities
     * in to an array of struct pairs for insert into the pivot table.
     *
     * @value        An id, entity, or combination of either in an array.
     *
     * @doc_generic  any,any
     * @return       [{any: any}]
     */
    public array function parseIdsForInsert( required any value ) {
        var foreignPivotKeyValue = variables.parent.retrieveAttribute(
            variables.parentKey
        );
        arguments.value = isArray( arguments.value ) ? arguments.value : [
            arguments.value
        ];
        return arguments.value.map( function( val ) {
            // If the value is not a simple value, we will assume
            // it is an entity and return its key value.
            if ( !isSimpleValue( arguments.val ) ) {
                arguments.val = arguments.val.keyValue();
            }
            var insertRecord = {};
            insertRecord[ variables.foreignPivotKey ] = foreignPivotKeyValue;
            insertRecord[ variables.relatedPivotKey ] = arguments.val;
            return insertRecord;
        } );
    }

    /**
     * Gets the query used to check for relation existance.
     *
     * @base    The base entity for the query.
     *
     * @return  qb.models.Query.QueryBuilder
     */
    public QueryBuilder function addCompareConstraints(
        any base = variables.parent
    ) {
        return arguments.base
            .newQuery()
            .select( variables.parent.raw( 1 ) )
            .from( variables.table )
            .whereColumn(
                getQualifiedForeignKeyName(),
                variables.parent.retrieveQualifiedKeyName()
            );
    }

    /**
     * Returns the fully-qualified column name of foreign key.
     *
     * @return   string
     */
    public string function getQualifiedForeignKeyName() {
        return getQualifiedForeignPivotKeyName();
    }

}
