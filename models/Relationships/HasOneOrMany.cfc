/**
 * Abstract HasOneOrMany used to provide shared methods across
 * `hasOne` and `hasMany` relationships.
 *
 * @doc_abstract true
 */
component
    extends="quick.models.Relationships.BaseRelationship"
    accessors="true"
{

    /**
     * Creates a HasOneOrMany relationship.
     *
     * @related             The related entity instance.
     * @relationName        The WireBox mapping for the related entity.
     * @relationMethodName  The method name called to retrieve this relationship.
     * @parent              The parent entity instance for the relationship.
     * @foreignKey          The foreign key on the parent entity.
     * @localKey            The local primary key on the parent entity.
     *
     * @return              quick.models.Relationships.HasOneOrMany
     */
    public HasOneOrMany function init(
        required any related,
        required string relationName,
        required string relationMethodName,
        required any parent,
        required string foreignKey,
        required string localKey
    ) {
        variables.localKey = arguments.localKey;
        variables.foreignKey = arguments.foreignKey;

        return super.init(
            related = related,
            relationName = relationName,
            relationMethodName = relationMethodName,
            parent = parent
        );
    }

    /**
     * Adds the constraints to the related entity.
     *
     * @return  quick.models.Relationships.HasOneOrMany
     */
    public HasOneOrMany function addConstraints() {
        variables.related
            .retrieveQuery()
            .where( variables.foreignKey, "=", getParentKey() )
            .whereNotNull( variables.foreignKey );
        return this;
    }

    /**
     * Adds the constraints for eager loading.
     *
     * @entities  The entities being eager loaded.
     *
     * @return    quick.models.Relationships.HasOneOrMany
     */
    public HasOneOrMany function addEagerConstraints( required array entities ) {
        variables.related
            .retrieveQuery()
            .whereIn(
                variables.foreignKey,
                getKeys( arguments.entities, variables.localKey )
            );
        return this;
    }

    /**
     * Matches the array of entity results to a single value for the relation.
     * The matched record is populated into the matched entity's relation.
     *
     * @entities     The entities being eager loaded.
     * @results      The relationship results.
     * @relation     The relation name being loaded.
     *
     * @doc_generic  quick.models.BaseEntity
     * @return       [quick.models.BaseEntity]
     */
    public array function matchOne(
        required array entities,
        required array results,
        required string relation
    ) {
        arguments.type = "one";
        return matchOneOrMany( argumentCollection = arguments );
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
    public array function matchMany(
        required array entities,
        required array results,
        required string relation
    ) {
        arguments.type = "many";
        return matchOneOrMany( argumentCollection = arguments );
    }

    /**
     * Matches the array of entity results to either an array of entities for a
     * "many" relation type or a single entity for a "one" relation type.
     * Any matched records are populated into the matched entity's relation.
     *
     * @entities     The entities being eager loaded.
     * @results      The relationship results.
     * @relation     The relation name being loaded.
     * @type         The type of the relation value, "many" or "one".
     *
     * @doc_generic  quick.models.BaseEntity
     * @return       [quick.models.BaseEntity]
     */
    public array function matchOneOrMany(
        required array entities,
        required array results,
        required string relation,
        required string type
    ) {
        var dictionary = buildDictionary( arguments.results );
        arguments.entities.each( function( entity ) {
            var key = arguments.entity.retrieveAttribute(
                variables.localKey
            );
            if ( structKeyExists( dictionary, key ) ) {
                arguments.entity.assignRelationship(
                    relation,
                    getRelationValue( dictionary, key, type )
                );
            }
        } );
        return arguments.entities;
    }

    /**
     * Builds a dictionary mapping the `foreignKey` value to related results.
     *
     * @results      The array of entities from retrieving the relationship.
     *
     * @doc_generic  any,quick.models.BaseEntity
     * @return       {any: quick.models.BaseEntity}
     */
    public struct function buildDictionary( required array results ) {
        return arguments.results.reduce( function( dict, result ) {
            var key = arguments.result.retrieveAttribute(
                variables.foreignKey
            );
            if ( !structKeyExists( arguments.dict, key ) ) {
                arguments.dict[ key ] = [];
            }
            arrayAppend( arguments.dict[ key ], arguments.result );
            return arguments.dict;
        }, {} );
    }

    /**
     * Retrieves the value for the key from the dictionary.
     * Also, returns either the first result for a "one" type or the entire
     * array of results for a "many" type.
     *
     * @dictionary  A dictionary mapping the `foreignKey` value to related results.
     * @key         The `foreignKey` value to look up in the dictionary.
     * @type        The type of the relation value, "many" or "one".
     *
     * @return      quick.models.BaseEntity | [quick.models.BaseEntity]
     */
    public any function getRelationValue(
        required struct dictionary,
        required string key,
        required string type
    ) {
        var value = arguments.dictionary[ arguments.key ];
        return arguments.type == "one" ? value[ 1 ] : value;
    }

    /**
     * Retrieves the parent's local key value.
     *
     * @return   any
     */
    public any function getParentKey() {
        return variables.parent.retrieveAttribute( variables.localKey );
    }

    /**
     * Associates the given entity when the relationship is used as a setter.
     *
     * Relationships on entities can be called with `set` in front of it.
     * If it is, a `HasOne` or `HasMany` relationship forwards the call to `saveMany`.
     *
     * @entities
     *
     * @return    quick.models.BaseEntity
     */
    public array function applySetter() {
        variables.related.updateAll(
            attributes = {
                "#variables.foreignKey#": {
                    "value": "",
                    "cfsqltype": "varchar",
                    "null": true,
                    "nulls": true
                }
            },
            force = true
        );
        return saveMany( argumentCollection = arguments );
    }

    /**
     * Associates each of the passed in entities with the parent entity.
     *
     * @entities      An single entity or array of entities to be associated.
     *
     * @doc_abstract  quick.models.BaseEntity
     * @return        [quick.models.BaseEntity]
     */
    public array function saveMany( required any entities ) {
        arguments.entities = isArray( arguments.entities ) ? arguments.entities : [
            arguments.entities
        ];

        return arguments.entities.map( function( entity ) {
            return save( arguments.entity );
        } );
    }

    /**
     * Associates an entity or key value for an entity to the parent entity.
     *
     * @entity   An entity or key value for an entity to associate.
     *
     * @return   quick.models.BaseEntity
     */
    public any function save( required any entity ) {
        if ( isSimpleValue( arguments.entity ) ) {
            arguments.entity = variables.related
                .newEntity()
                .set_loaded( true )
                .forceAssignAttribute(
                    variables.related.keyName(),
                    arguments.entity
                );
        }
        setForeignAttributesForCreate( arguments.entity );
        return arguments.entity.save();
    }

    /**
     * Creates a new entity, associates it to the parent entity, and returns it.
     *
     * @attributes  The attributes for the new related entity.
     *
     * @return      quick.models.BaseEntity
     */
    public any function create( struct attributes = {} ) {
        var newInstance = variables.related
            .newEntity()
            .fill( arguments.attributes );
        setForeignAttributesForCreate( newInstance );
        return newInstance.save();
    }

    /**
     * Sets the parent key value as the foreign key for the entity.
     *
     * @entity   The entity to associate.
     *
     * @return   quick.models.BaseEntity
     */
    public any function setForeignAttributesForCreate( required any entity ) {
        return arguments.entity.forceAssignAttribute(
            getForeignKeyName(),
            getParentKey()
        );
    }

    /**
     * Returns just the column name of foreign key.
     *
     * @return   string
     */
    public string function getForeignKeyName() {
        return arrayLast( listToArray( getQualifiedForeignKeyName(), "." ) );
    }

    /**
     * Returns the fully-qualified column name of foreign key.
     *
     * @return   string
     */
    public string function getQualifiedForeignKeyName() {
        return variables.foreignKey;
    }

    /**
     * Returns the last value in an array or null if the array is empty.
     *
     * @arr      An array of items.
     *
     * @return   any
     */
    private any function arrayLast( required array arr ) {
        return arguments.arr.isEmpty() ? javacast( "null", "" ) : arguments.arr[
            arguments.arr.len()
        ];
    }

}
