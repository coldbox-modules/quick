/**
 * Abstract BaseEntity used to wire up objects and their properties to
 * database tables.
 *
 * @doc_abstract true
 */
component accessors="true" {

    /*====================================
    =            Dependencies            =
    ====================================*/

    /**
     * The underlying qb Query Builder for the entity.
     */
    property name="_builder" inject="provider:QuickQB@quick" persistent="false";

    /**
     * The WireBox injector.  Used to inject other entities.
     */
    property name="_wirebox" inject="wirebox" persistent="false";

    /**
     * A string helper library.
     */
    property name="_str" inject="provider:Str@str" persistent="false";

    /**
     * The configured module settings for Quick.
     */
    property
        name="_settings"
        inject="coldbox:modulesettings:quick"
        persistent="false";

    /**
     * The ColdBox Interceptor service.  Used to announce lifecycle hooks
     * as interception points.
     */
    property
        name="_interceptorService"
        inject="provider:coldbox:interceptorService"
        persistent="false";

    /**
     * An component used to create new instances of this entity.
     * This is split off in to a separate component so we can use Lucee
     * only features to speed up entity creation time.
     */
    property
        name="_entityCreator"
        inject="provider:EntityCreator@quick"
        persistent="false";

    /*===========================================
    =            Metadata Properties            =
    ===========================================*/

    /**
     * The name of the entity.
     */
    property name="_entityName" persistent="false";

    /**
     * The WireBox mapping for the entity.
     */
    property name="_mapping" persistent="false";

    /**
     * The full name of the entity.
     */
    property name="_fullName" persistent="false";

    /**
     * The table of the entity.
     */
    property name="_table" persistent="false";

    /**
     * A struct of query options for query executions.
     */
    property name="_queryOptions" persistent="false";

    /**
     * Boolean flag to prevent inserts and updates on the entity.
     */
    property name="_readonly" default="false" persistent="false";

    /**
     * The primary key name for the entity.
     */
    property name="_key" default="id" persistent="false";

    /**
     * A map of attribute names to column names.
     */
    property name="_attributes" persistent="false";

    /**
     * The unparsed metadata for the entity.
     * Saved to pass on to created entities and avoid unnecessary processing.
     */
    property name="_meta" persistent="false";

    /**
     * A map of attributes to their applicable null values.
     */
    property name="_nullValues" persistent="false";

    /**
     * A map of attributes to an optional cast type.
     */
    property name="_casts" persistent="false";

    /*=====================================
    =            Instance Data            =
    =====================================*/

    /**
     * The current attribute values.
     */
    property name="_data" persistent="false";

    /**
     * The original values of the attributes.
     * Used if the entity is reset.
     */
    property name="_originalAttributes" persistent="false";

    /**
     * A hash of the original attributes and their values.
     * Used to check if the entity has been edited.
     */
    property name="_originalAttributesHash" persistent="false";

    /**
     * A struct of relationships to their loaded data.
     */
    property name="_relationshipsData" persistent="false";

    /**
     * A map of relationships that are loaded.
     */
    property name="_relationshipsLoaded" persistent="false";

    /**
     * An array of relationships to eager load.
     */
    property name="_eagerLoad" persistent="false";

    /**
     * A boolean flag indicating that the entity has been loaded from the database.
     */
    property name="_loaded" persistent="false" default="false";

    /**
     * An array of global scopes to exclude from being applied.
     * Added using the `withoutGlobalScope` method.
     */
    property name="_globalScopeExclusions" persistent="false";

    /**
     * Initializes the entity with default properties and optional metadata.
     *
     * @meta    An optional struct of metadata.  Used to avoid processing
     *          the metadata again.
     *
     * @return  quick.models.BaseEntity
     */
    public any function init( struct meta = {} ) {
        assignDefaultProperties();
        variables._meta = arguments.meta;
        return this;
    }

    /**
     * Assigns the default properties for a new entity
     */
    private any function assignDefaultProperties() {
        assignAttributesData( {} );
        assignOriginalAttributes( {} );
        variables._globalScopeExclusions = [];
        param variables._meta = {};
        param variables._data = {};
        param variables._relationshipsData = {};
        param variables._relationshipsLoaded = {};
        param variables._eagerLoad = [];
        param variables._nullValues = {};
        param variables._casts = {};
        param variables._loaded = false;
        return this;
    }

    /**
     * Processes the metadata and fires an `instanceReady` event
     * after dependency injection (DI) is completed.
     * (This method is called automatically by WireBox.)
     */
    public void function onDIComplete() {
        metadataInspection();
        fireEvent( "instanceReady", { entity: this } );
    }

    /**
     * Returns the key type for this entity.  The value returned from this
     * function is cached for the lifecycle of the entity.
     *
     * This method should be overridden in subclasses when using a different KeyType.
     *
     * @return  quick.models.KeyTypes.KeyType
     */
    private KeyType function keyType() {
        return variables._wirebox.getInstance(
            "AutoIncrementingKeyType@quick"
        );
    }

    /**
     * Returns the cached key type for this entity.
     *
     * When specifying a custom KeyType, override the `keyType` function,
     * not this one.
     *
     * @return  quick.models.KeyTypes.KeyType
     */
    private KeyType function retrieveKeyType() {
        if ( isNull( variables.__keyType__ ) ) {
            variables.__keyType__ = keyType();
        }
        return variables.__keyType__;
    }

    /*==================================
    =            Attributes            =
    ==================================*/

    /**
     * Returns the name for this entity.
     */
    public string function entityName() {
        return variables._entityName;
    }

    /**
     * Returns the table name for this entity.
     */
    public string function tableName() {
        return variables._table;
    }

    /**
     * Returns the aliased name for the primary key column.
     *
     * @return  String
     */
    public string function keyName() {
        return variables._key;
    }

    /**
     * Returns the value of the primary key for this entity.
     *
     * @return  any
     */
    public any function keyValue() {
        guardAgainstNotLoaded(
            "This instance is not loaded so the `keyValue` cannot be retrieved."
        );
        return retrieveAttribute( keyName() );
    }

    /**
     * Retrieves a struct of the current attributes with their associated values.
     *
     * @aliased     Uses attribute aliases as the keys instead of column names.
     * @withoutKey  Excludes the keyName attribute from the returned struct.
     * @withNulls   Includes null values in the returned struct.
     */
    public struct function retrieveAttributesData(
        boolean aliased = false,
        boolean withoutKey = false,
        boolean withNulls = false
    ) {
        variables._attributes
            .keyArray()
            .each( function( key ) {
                if ( variables.keyExists( key ) && !isReadOnlyAttribute( key ) ) {
                    assignAttribute( key, variables[ key ] );
                }
            } );
        return variables._data.reduce( function( acc, key, value ) {
            if ( withoutKey && key == keyName() ) {
                return acc;
            }
            if ( isNull( value ) || ( isNullValue( key, value ) && withNulls ) ) {
                acc[ aliased ? retrieveAliasForColumn( key ) : key ] = javacast(
                    "null",
                    ""
                );
            } else {
                acc[ aliased ? retrieveAliasForColumn( key ) : key ] = value;
            }
            return acc;
        }, {} );
    }

    /**
     * Retrieves an array of the attribute names.
     *
     * @columnNames  If true, returns an array of column names instead of aliases.
     *
     * @doc_generic  string
     * @return       [string]
     */
    public array function retrieveAttributeNames( boolean columnNames = false ) {
        return variables._attributes.reduce( function( items, key, value ) {
            items.append( columnNames ? value : key );
            return items;
        }, [] );
    }

    /**
     * Clears the value of an attribute.
     * Creates the attribute if it doesn't already exist.
     *
     * @name       The name of the attribute to clear.
     * @setToNull  If true, set's the value of the attribute to null.
     *
     * @return     quick.models.BaseEntity
     */
    public any function forceClearAttribute(
        required string name,
        boolean setToNull = false
    ) {
        arguments.force = true;
        return clearAttribute( argumentCollection = arguments );
    }

    /**
     * Clears the value of an attribute.
     *
     * @name       The name of the attribute to clear.
     * @setToNull  If true, set's the value of the attribute to null.
     * @force      If true, creates the attribute if it doesn't exist.
     *
     * @return     quick.models.BaseEntity
     */
    public any function clearAttribute(
        required string name,
        boolean setToNull = false,
        boolean force = false
    ) {
        if ( arguments.force ) {
            var alias = retrieveAliasForColumn( arguments.name );
            if ( !variables._attributes.keyExists( alias ) ) {
                variables._attributes[ arguments.name ] = arguments.name;
                variables._meta.properties[ arguments.name ] = paramProperty( { "name": arguments.name } );
                variables._meta.originalMetadata.properties.append(
                    variables._meta.properties[ arguments.name ]
                );
            }
        }
        if ( arguments.setToNull ) {
            variables._data[ arguments.name ] = javacast( "null", "" );
            variables[ retrieveAliasForColumn( arguments.name ) ] = javacast(
                "null",
                ""
            );
        } else {
            variables._data.delete( arguments.name );
            variables.delete( retrieveAliasForColumn( arguments.name ) );
        }
        return this;
    }

    /**
     * Assigns a struct of key / value pairs as the attributes data.
     * This method does not:
     * 1. Use relationship setters
     * 2. Call custom attribute setters
     * 3. Check for the existence of the attribute
     *
     * @attrs   The struct of key / value pairs to set.
     *
     * @return  quick.models.BaseEntity
     */
    public any function assignAttributesData( struct attrs = {} ) {
        if ( arguments.attrs.isEmpty() ) {
            variables._loaded = false;
            variables._data = {};
            return this;
        }

        arguments.attrs.each( function( key, value ) {
            variables._data[ retrieveColumnForAlias( key ) ] = isNull( value ) ? javacast(
                "null",
                ""
            ) : castValueForGetter( key, value );
            variables[ retrieveAliasForColumn( key ) ] = isNull( value ) ? javacast(
                "null",
                ""
            ) : castValueForGetter( key, value );
        } );

        return this;
    }

    /**
     * Sets attributes data from a struct of key / value pairs.
     * This method does the following, in order:
     * 1. Guard against read only attributes
     * 2. Attempt to call a relationship setter.
     * 2. Calls custom attribute setters for attributes that exist
     * 3. Throws an error if an attribute does not exist
     *
     * @attributes                   A struct of key / value pairs.
     * @ignoreNonExistentAttributes  If true, does not throw an exception if an
     *                               attribute does not exist.  Instead, it skips
     *                               the non-existent attribute.
     *
     * @return                       quick.models.BaseEntity
     */
    public any function fill(
        required struct attributes,
        boolean ignoreNonExistentAttributes = false
    ) {
        for ( var key in arguments.attributes ) {
            guardAgainstReadOnlyAttribute( key );
            var value = arguments.attributes[ key ];
            var rs = tryRelationshipSetter( "set#key#", { "1": value } );
            if ( !isNull( rs ) ) {
                continue;
            }
            if ( hasAttribute( key ) ) {
                variables._data[ retrieveColumnForAlias( key ) ] = value;
                invoke(
                    this,
                    "set#retrieveAliasForColumn( key )#",
                    { "1": value }
                );
            } else if ( !arguments.ignoreNonExistentAttributes ) {
                guardAgainstNonExistentAttribute( key );
            }
        }
        return this;
    }

    /**
     * Returns if an entity has a given attribute.
     *
     * @name    The name of the attribute to check.  Column names will be
     *          translated to aliases.
     *
     * @return  Boolean
     */
    public boolean function hasAttribute( required string name ) {
        return structKeyExists(
            variables._attributes,
            retrieveAliasForColumn( arguments.name )
        ) || keyName() == name;
    }

    /**
     * Retrieves a column name for a given alias.
     * If the column does not exist, the given name is returned unchanged.
     *
     * @alias   The name of the alias to find an column.
     *
     * @return  string
     */
    public string function retrieveColumnForAlias( required string alias ) {
        return variables._attributes.keyExists( arguments.alias ) ? variables._attributes[
            arguments.alias
        ] : arguments.alias;
    }

    /**
     * Retrieves an alias for a given column name.
     * If the alias does not exist, the given name is returned unchanged.
     *
     * @column  The name of the column to find an alias.
     *
     * @return  string
     */
    public string function retrieveAliasForColumn( required string column ) {
        return variables._attributes.reduce( function( acc, alias, columnName ) {
            return column == arguments.columnName ? arguments.alias : arguments.acc;
        }, arguments.column );
    }

    /**
     * Stores the original attributes in the entity in case the entity
     * needs to be reset.
     *
     * @attributes  A struct of attributes data to store as the original attributes.
     *
     * @return      quick.models.BaseEntity
     */
    public any function assignOriginalAttributes( required struct attributes ) {
        variables._originalAttributes = arguments.attributes;
        return assignOriginalAttributesHash( arguments.attributes );
    }

    /**
     * Stores a hash of the attributes to detect changes to the entity.
     * You can check if an entity has changed since saving using the `isDirty` method.
     *
     * @attributes  A struct of attributes data to store as the original attributes hash.
     *
     * @return      quick.models.BaseEntity
     */
    public any function assignOriginalAttributesHash(
        required struct attributes
    ) {
        variables._originalAttributesHash = computeAttributesHash(
            arguments.attributes
        );
        return this;
    }

    /**
     * Computes an hash from a struct of key / value pairs.
     *
     * @attributes  A struct of attributes data to compute.
     *
     * @return      string
     */
    public string function computeAttributesHash( required struct attributes ) {
        var keys = arguments.attributes.keyArray();
        arraySort( keys, "textnocase" );
        return hash(
            keys
                .map( function( key ) {
                    var valueIsNotNull = structKeyExists(
                        attributes,
                        arguments.key
                    ) &&
                    !isNull( attributes[ arguments.key ] );
                    var value = valueIsNotNull ? attributes[ arguments.key ] : "";
                    return lCase( arguments.key ) & "=" & value;
                } )
                .toList( "&" )
        );
    }

    /**
     * Marks an entity as loaded from the database.
     *
     * @return  quick.models.BaseEntity
     */
    public any function markLoaded() {
        variables._loaded = true;
        return this;
    }

    /**
     * Returns if the entity has been loaded from the database.
     *
     * @return  Boolean
     */
    public boolean function isLoaded() {
        return variables._loaded;
    }

    /**
     * Returns if the entity has been edited since being loaded from the database.
     *
     * @return  Boolean
     */
    public boolean function isDirty() {
        return compare(
            variables._originalAttributesHash,
            computeAttributesHash( retrieveAttributesData() )
        ) != 0;
    }

    /**
     * Retrieves a value for an attribute.
     *
     * @name           The name of the attribute to retrieve.
     * @defaultValue   The default value to return if the attribute doesn't exist.
     * @bypassGetters  Flag to bypass custom getters.
     *
     * @return         quick.models.BaseEntity
     */
    public any function retrieveAttribute(
        required string name,
        any defaultValue = "",
        boolean bypassGetters = true
    ) {
        // If the value exists in the variables scope and is not read only,
        // ensure that the value in the variables scope is also set as the
        // value in the attributes struct.
        if (
            variables.keyExists( retrieveAliasForColumn( arguments.name ) ) &&
            !isReadOnlyAttribute( arguments.name )
        ) {
            forceAssignAttribute(
                arguments.name,
                variables[ retrieveAliasForColumn( arguments.name ) ]
            );
        }

        // If there is no value set for the attribute, return the default value.
        if (
            !variables._data.keyExists(
                retrieveColumnForAlias( arguments.name )
            )
        ) {
            return castValueForGetter( arguments.name, arguments.defaultValue );
        }

        // Retrieve the value either from the custom getter
        // or directly from the attributes struct
        var data = !arguments.bypassGetters && variables.keyExists(
            "get" & retrieveAliasForColumn( arguments.name )
        ) ? invoke( this, "get" & retrieveAliasForColumn( arguments.name ) ) : variables._data[
            retrieveColumnForAlias( arguments.name )
        ];

        return castValueForGetter( arguments.name, data );
    }

    /**
     * Sets the value of an attribute.
     * Creates the attribute if it doesn't already exist.
     *
     * @name    The name of the attribute to set.
     * @value   The new value of the attribute.
     *
     * @return  quick.models.BaseEntity
     */
    public any function forceAssignAttribute( required string name, any value ) {
        arguments.force = true;
        return assignAttribute( argumentCollection = arguments );
    }

    /**
     * Sets the value of an attribute.
     *
     * @name    The name of the attribute to set.
     * @value   The new value of the attribute.
     * @force   Creates the attribute if it doesn't exist.
     *
     * @return  quick.models.BaseEntity
     */
    public any function assignAttribute(
        required string name,
        any value,
        boolean force = false
    ) {
        if ( arguments.force ) {
            if (
                !variables._attributes.keyExists(
                    retrieveAliasForColumn( arguments.name )
                )
            ) {
                variables._attributes[ arguments.name ] = arguments.name;
                variables._meta.properties[ arguments.name ] = paramProperty( { "name": arguments.name } );
                variables._meta.originalMetadata.properties.append(
                    variables._meta.properties[ arguments.name ]
                );
            }
        } else {
            guardAgainstNonExistentAttribute( arguments.name );
            guardAgainstReadOnlyAttribute( arguments.name );
        }

        // If the value passed in is a Quick entity, use its `keyValue` as the value.
        if ( isStruct( arguments.value ) ) {
            // Check for the keyValue method that should be on a Quick entity
            // to check if the value is a Quick entity.
            if ( !structKeyExists( arguments.value, "keyValue" ) ) {
                throw(
                    type = "QuickNotEntityException",
                    message = "The value assigned to [#arguments.name#] is not a Quick entity. " &
                    "Perhaps you forgot to add `persistent=""false""` to a new property?",
                    detail = getMetadata( arguments.value ).fullname
                );
            }
            arguments.value = castValueForSetter(
                arguments.name,
                arguments.value.keyValue()
            );
        }

        variables._data[ retrieveColumnForAlias( arguments.name ) ] = castValueForSetter(
            arguments.name,
            arguments.value
        );
        variables[ retrieveAliasForColumn( arguments.name ) ] = castValueForSetter(
            arguments.name,
            arguments.value
        );

        return this;
    }

    /**
     * Qualifies a column with the entity's table name.
     *
     * @column  The column to qualify.
     *
     * @return  string
     */
    public string function qualifyColumn( required string column ) {
        if ( findNoCase( ".", arguments.column ) != 0 ) {
            return arguments.column;
        }
        return tableName() & "." & arguments.column;
    }

    /*=====================================
    =            Query Methods            =
    =====================================*/

    /**
     * Executes the configured query and returns the entities in an array.
     *
     * @doc_generic  quick.models.BaseEntity
     * @return       [quick.models.BaseEntity]
     */
    private array function getEntities() {
        applyGlobalScopes();
        return retrieveQuery()
            .get( options = variables._queryOptions )
            .map( variables.loadEntity );
    }

    /**
     * Retrieves all the entities.
     * It does this by resetting the configured query before retrieving the results.
     *
     * @return  The result of `newCollection` with the retrieved entities.
     */
    public any function all() {
        resetQuery();
        return variables.get();
    }

    /**
     * Executes the configured query, eager loads any relations, and returns
     * the entities in a new collection.
     *
     * @return  The result of `newCollection` with the retrieved entities.
     */
    public any function get() {
        return newCollection( eagerLoadRelations( getEntities() ) );
    }

    /**
     * Returns the first matching entity for the configured query.
     * If no records are found, it returns null instead.
     *
     * @return  quick.models.BaseEntity || null
     */
    public any function first() {
        applyGlobalScopes();
        var attrs = retrieveQuery().first( options = variables._queryOptions );
        return structIsEmpty( attrs ) ? javacast( "null", "" ) : loadEntity(
            attrs
        );
    }

    /**
     * Returns the entity with the id value as the primary key.
     * If no records are found, it returns null instead.
     *
     * @id      The id value to find.
     *
     * @return  quick.models.BaseEntity || null
     */
    public any function find( required any id ) {
        fireEvent( "preLoad", { id: arguments.id, metadata: variables._meta } );
        applyGlobalScopes();
        var data = retrieveQuery()
            .from( tableName() )
            .find( arguments.id, keyName(), variables._queryOptions );
        if ( structIsEmpty( data ) ) {
            return javacast( "null", "" );
        }
        return tap( loadEntity( data ), function( entity ) {
            fireEvent( "postLoad", { entity: entity } );
        } );
    }

    /**
     * Loads up an entity with data from the database.
     * 1. Assigns the key / value pairs.
     * 2. Assigns the original attributes hash.
     * 3. Marks the entity as loaded.
     *
     * @data    A struct of key / value pairs to load.
     *
     * @return  quick.models.BaseEntity
     */
    private any function loadEntity( required struct data ) {
        return newEntity()
            .assignAttributesData( arguments.data )
            .assignOriginalAttributes( arguments.data )
            .markLoaded();
    }

    /**
     * Returns the entity with the id value as the primary key.
     * If no records are found, it throws an `EntityNotFound` exception.
     *
     * @id      The id value to find.
     *
     * @throws  EntityNotFound
     *
     * @return  quick.models.BaseEntity
     */
    public any function findOrFail( required any id ) {
        var entity = variables.find( arguments.id );
        if ( isNull( entity ) ) {
            throw(
                type = "EntityNotFound",
                message = "No [#entityName()#] found with id [#arguments.id#]"
            );
        }
        return entity;
    }

    /**
     * Returns the first matching entity for the configured query.
     * If no records are found, it throws an `EntityNotFound` exception.
     *
     * @throws  EntityNotFound
     *
     * @return  quick.models.BaseEntity
     */
    public any function firstOrFail() {
        applyGlobalScopes();
        var attrs = retrieveQuery().first( options = variables._queryOptions );
        if ( structIsEmpty( attrs ) ) {
            throw(
                type = "EntityNotFound",
                message = "No [#entityName()#] found with constraints " &
                "[#serializeJSON( retrieveQuery().getBindings() )#]"
            );
        }
        return loadEntity( attrs );
    }

    /**
     * Returns if any entities exist with the configured query.
     *
     * @return  Boolean
     */
    public boolean function exists() {
        applyGlobalScopes();
        return retrieveQuery().exists();
    }

    /**
     * Returns true if any entities exist with the configured query.
     * If no entities exist, it throws an EntityNotFound exception.
     *
     * @throws  EntityNotFound
     *
     * @return  Boolean
     */
    public boolean function existsOrFail() {
        applyGlobalScopes();
        if ( !retrieveQuery().exists() ) {
            throw(
                type = "EntityNotFound",
                message = "No [#entityName()#] found with constraints " &
                "[#serializeJSON( retrieveQuery().getBindings() )#]"
            );
        }
        return true;
    }

    /**
     * Creates a new entity.  If no name is passed, the current entity is duplicated.
     *
     * @name    An optional name of an entity to create.  If no name is provided,
     *          the current entity is duplicated.
     *
     * @return  quick.models.BaseEntity
     */
    public any function newEntity( string name ) {
        if ( isNull( arguments.name ) ) {
            return variables._entityCreator.new( this );
        }
        return variables._wirebox.getInstance( arguments.name );
    }

    /**
     * Resets the entity to a fresh, unloaded state.
     *
     * @return  quick.models.BaseEntity
     */
    public any function reset( boolean toNew = false ) {
        resetQuery();
        assignAttributesData(
            arguments.toNew ? {} : variables._originalAttributes
        );
        assignOriginalAttributes(
            arguments.toNew ? {} : variables._originalAttributes
        );
        variables._relationshipsData = {};
        variables._relationshipsLoaded = {};
        variables._eagerLoad = [];
        variables._loaded = arguments.toNew ? false : variables._loaded;

        return this;
    }

    /**
     * Resets an entity to a new state.
     *
     * @return  quick.models.BaseEntity
     */
    public any function resetToNew() {
        resetQuery();
        assignAttributesData( {} );
        assignOriginalAttributes( {} );
        variables._relationshipsData = {};
        variables._relationshipsLoaded = {};
        variables._eagerLoad = [];
        variables._loaded = false;

        return this;
    }

    /**
     * Retrieves a new entity from the database with the same key value
     * as the current entity.
     *
     * @return  quick.models.BaseEntity
     */
    public any function fresh() {
        return variables
            .resetQuery()
            .find( keyValue(), keyName(), variables._queryOptions );
    }

    /**
     * Refreshes the attributes data for the entity
     * with data from the database.
     *
     * @return  quick.models.BaseEntity
     */
    public any function refresh() {
        variables._relationshipsData = {};
        variables._relationshipsLoaded = {};
        assignAttributesData(
            newQuery()
                .from( tableName() )
                .find( keyValue(), keyName(), variables._queryOptions )
        );
        return this;
    }

    /*===========================================
    =            Persistence Methods            =
    ===========================================*/

    /**
     * Saves the entity to the database.
     * If the entity is not loaded, it inserts the data into the database.
     * Otherwise it updates the database.
     *
     * @return  quick.models.BaseEntity
     */
    public any function save() {
        guardNoAttributes();
        guardReadOnly();
        fireEvent( "preSave", { entity: this } );
        if ( variables._loaded ) {
            fireEvent( "preUpdate", { entity: this } );
            newQuery()
                .where( keyName(), keyValue() )
                .update(
                    retrieveAttributesData( withoutKey = true )
                        .filter( canUpdateAttribute )
                        .map( function( key, value, attributes ) {
                            if ( isNull( value ) || isNullValue( key, value ) ) {
                                return { value: "", nulls: true, null: true };
                            }
                            if ( attributeHasSqlType( key ) ) {
                                return {
                                    value: value,
                                    cfsqltype: getSqlTypeForAttribute( key )
                                };
                            }
                            return value;
                        } ),
                    variables._queryOptions
                );
            assignOriginalAttributes( retrieveAttributesData() );
            markLoaded();
            fireEvent( "postUpdate", { entity: this } );
        } else {
            resetQuery();
            retrieveKeyType().preInsert( this );
            fireEvent(
                "preInsert",
                { entity: this, attributes: retrieveAttributesData() }
            );
            var attrs = retrieveAttributesData()
                .filter( canInsertAttribute )
                .map( function( key, value, attributes ) {
                    if ( isNull( value ) || isNullValue( key, value ) ) {
                        return { value: "", nulls: true, null: true };
                    }
                    if ( attributeHasSqlType( key ) ) {
                        return {
                            value: value,
                            cfsqltype: getSqlTypeForAttribute( key )
                        };
                    }
                    return value;
                } );
            guardEmptyAttributeData( attrs );
            var result = retrieveQuery().insert(
                attrs,
                variables._queryOptions
            );
            retrieveKeyType().postInsert( this, result );
            assignOriginalAttributes( retrieveAttributesData() );
            markLoaded();
            fireEvent( "postInsert", { entity: this } );
        }
        fireEvent( "postSave", { entity: this } );

        return this;
    }

    /**
     * Deletes the entity from the database.
     * This function can only be called on loaded entities.
     * Calling it on a non-loaded entity results in an exception.
     *
     * @throws  QuickEntityNotLoaded
     * @throws  QuickReadOnlyException
     *
     * @return  quick.models.BaseEntity
     */
    public any function delete() {
        guardReadOnly();
        fireEvent( "preDelete", { entity: this } );
        guardAgainstNotLoaded(
            "This instance is not loaded so it cannot be deleted. " &
            "Did you maybe mean to use `deleteAll`?"
        );
        newQuery().delete( keyValue(), keyName(), variables._queryOptions );
        variables._loaded = false;
        fireEvent( "postDelete", { entity: this } );
        return this;
    }

    /**
     * Fills an entity with the given attributes and then saves the entity.
     *
     * @attributes                   A struct of key / value pairs.
     * @ignoreNonExistentAttributes  If true, does not throw an exception if an
     *                               attribute does not exist.  Instead, it skips
     *                               the non-existent attribute.
     *
     * @throws                       QuickEntityNotLoaded
     * @throws                       QuickReadOnlyException
     *
     * @return                       quick.models.BaseEntity
     */
    public any function update(
        struct attributes = {},
        boolean ignoreNonExistentAttributes = false
    ) {
        guardAgainstNotLoaded(
            "This instance is not loaded so it cannot be updated. " &
            "Did you maybe mean to use `updateAll`, `create`, or `save`?"
        );
        fill( arguments.attributes, arguments.ignoreNonExistentAttributes );
        return save();
    }

    /**
     * Creates a new entity with the given attributes and then saves the entity.
     *
     * @attributes                   A struct of key / value pairs.
     * @ignoreNonExistentAttributes  If true, does not throw an exception if an
     *                               attribute does not exist.  Instead, it skips
     *                               the non-existent attribute.
     *
     * @throws                       QuickEntityNotLoaded
     * @throws                       QuickReadOnlyException
     *
     * @return                       quick.models.BaseEntity
     */
    public any function create(
        struct attributes = {},
        boolean ignoreNonExistentAttributes = false
    ) {
        return newEntity()
            .fill(
                arguments.attributes,
                arguments.ignoreNonExistentAttributes
            )
            .save();
    }

    /**
     * Updates matching entities with the given attributes
     * according to the configured query.
     *
     * @attributes  The attributes to update on the matching records.
     * @force       If true, skips read-only entity and read-only attribute checks.
     *
     * @throws      QuickReadOnlyException
     *
     * @return      { "query": QueryBuilder Return Format, "result": struct }
     */
    public struct function updateAll(
        struct attributes = {},
        boolean force = false
    ) {
        if ( !arguments.force ) {
            guardReadOnly();
            guardAgainstReadOnlyAttributes( arguments.attributes );
        }
        return retrieveQuery().update(
            arguments.attributes,
            variables._queryOptions
        );
    }

    /**
     * Deletes matching entities according to the configured query.
     *
     * @ids     An optional array of ids to add to the previously configured
     *          query.  The ids will be added to a WHERE IN statement on the
     *          primary key column.
     *
     * @throws  QuickReadOnlyException
     *
     * @return  { "query": QueryBuilder Return Format, "result": struct }
     */
    public struct function deleteAll( array ids = [] ) {
        guardReadOnly();
        if ( !arrayIsEmpty( arguments.ids ) ) {
            retrieveQuery().whereIn( keyName(), arguments.ids );
        }
        return retrieveQuery().delete( options = variables._queryOptions );
    }

    /*=====================================
    =            Relationships            =
    =====================================*/

    /**
     * Returns if the entity has a function matching the name of the relationship.
     *
     * @name    The relationship name to check.
     *
     * @return  Boolean
     */
    public boolean function hasRelationship( required string name ) {
        return arrayContainsNoCase(
            variables._meta.functionNames,
            arguments.name
        );
    }

    /**
     * Loads a single relationship or an array of relationships by name.
     * Use this method if you need to load the relationship, but don't
     * need the relationship value returned.
     *
     * @name    A single relationship name or an array of relationship names.
     *
     * @return  quick.models.BaseEntity;
     */
    public any function loadRelationship( required any name ) {
        arrayWrap( arguments.name ).each( function( n ) {
            var relationship = invoke( this, arguments.n );
            relationship.setRelationMethodName( arguments.n );
            assignRelationship( arguments.n, relationship.get() );
        } );
        return this;
    }

    /**
     * Returns if a relationship has been loaded.
     *
     * @name    The relationship name to check.
     *
     * @return  Boolean
     */
    public boolean function isRelationshipLoaded( required string name ) {
        return structKeyExists( variables._relationshipsLoaded, arguments.name );
    }

    /**
     * Retrieves the result of a loaded relationship.
     * If there is no data, returns null instead.
     *
     * @name  The relationship name to retrieve.
     *
     * @return  quick.models.BaseEntity | [quick.models.BaseEntity]
     */
    public any function retrieveRelationship( required string name ) {
        return variables._relationshipsData.keyExists(
            arguments.name
        ) ? variables._relationshipsData[ arguments.name ] : javacast(
            "null",
            ""
        );
    }

    /**
     * Assigns a result to a relationship.
     *
     * @name    The name of the relationship to assign.
     * @value   The result for the relationship.
     *
     * @return  quick.models.BaseEntity
     */
    public any function assignRelationship( required string name, any value ) {
        if ( !isNull( arguments.value ) ) {
            variables._relationshipsData[ arguments.name ] = arguments.value;
        }
        variables._relationshipsLoaded[ arguments.name ] = true;
        return this;
    }

    /**
     * Clears out any loaded relationships.
     *
     * @returns  quick.models.BaseEntity
     */
    public any function clearRelationships() {
        variables._relationshipsData = {};
        variables._relationshipsLoaded = {};
        return this;
    }

    /**
     * Clears out a loaded relationship by name.
     *
     * @name     The name of the relationship to clear.
     *
     * @returns  quick.models.BaseEntity
     */
    public any function clearRelationship( required string name ) {
        variables._relationshipsData.delete( arguments.name );
        variables._relationshipsLoaded.delete(
            arguments.name
        );
        return this;
    }

    /*=====================================
    =          Relationship Types         =
    =====================================*/

    /**
     * Returns a BelongsTo relationship between this entity and the entity
     * defined by `relationName`.
     *
     * Given a Post `belongsTo` a User and using the defaults, the SQL would be:
     * ```sql
     * SELECT *
     * FROM users [relationName.tableName()]
     * WHERE users.id [ownerKey] = 'posts.userId' [foreignKey]
     * ```
     *
     * @relationName        The WireBox mapping for the related entity.
     * @foreignKey          The column name on the `parent` entity that refers to
     *                      the `ownerKey` on the `related` entity.
     * @ownerKey            The column name on the `realted` entity that is referred
     *                      to by the `foreignKey` of the `parent` entity.
     * @relationMethodName  The method name called to retrieve this relationship.
     *                      Uses a stack backtrace to determine by default,
     *
     * @return              quick.models.Relationships.BelongsTo
     */
    private BelongsTo function belongsTo(
        required string relationName,
        string foreignKey,
        string ownerKey,
        string relationMethodName
    ) {
        var related = variables._wirebox.getInstance(
            arguments.relationName
        );

        param arguments.foreignKey = related.entityName() & related.keyName();
        param arguments.ownerKey = related.keyName();
        param arguments.relationMethodName = lCase(
            callStackGet()[ 2 ][ "Function" ]
        );

        return variables._wirebox.getInstance(
            name = "BelongsTo@quick",
            initArguments = {
                related: related,
                relationName: arguments.relationName,
                relationMethodName: arguments.relationMethodName,
                parent: this,
                foreignKey: arguments.foreignKey,
                ownerKey: arguments.ownerKey
            }
        );
    }

    /**
     * Returns a HasOne relationship between this entity and the entity
     * defined by `relationName`.
     *
     * Given a User `hasOne` UserProfile and using the defaults, the SQL would be:
     * ```sql
     * SELECT *
     * FROM userProfiles [relationName.tableName()]
     * WHERE usersProfiles.userId [foreignKey] = 'users.id' [localKey]
     * ```
     *
     * @relationName        The WireBox mapping for the related entity.
     * @foreignKey          The foreign key on the parent entity.
     * @localKey            The local primary key on the parent entity.
     * @relationMethodName  The method name called to retrieve this relationship.
     *                      Uses a stack backtrace to determine by default,
     *
     * @return              quick.models.Relationships.HasOne
     */
    private HasOne function hasOne(
        required string relationName,
        string foreignKey,
        string localKey,
        string relationMethodName
    ) {
        var related = variables._wirebox.getInstance(
            arguments.relationName
        );

        param arguments.foreignKey = entityName() & keyName();
        param arguments.localKey = keyName();
        param arguments.relationMethodName = lCase(
            callStackGet()[ 2 ][ "Function" ]
        );

        return variables._wirebox.getInstance(
            name = "HasOne@quick",
            initArguments = {
                related: related,
                relationName: arguments.relationName,
                relationMethodName: arguments.relationMethodName,
                parent: this,
                foreignKey: arguments.foreignKey,
                localKey: arguments.localKey
            }
        );
    }

    /**
     * Returns a HasMany relationship between this entity and the entity
     * defined by `relationName`.
     *
     * Given a User `hasMany` Posts and using the defaults, the SQL would be:
     * ```sql
     * SELECT *
     * FROM posts [relationName.tableName()]
     * WHERE posts.userId [foreignKey] = 'users.id' [localKey]
     * ```
     *
     * @relationName        The WireBox mapping for the related entity.
     * @foreignKey          The foreign key on the parent entity.
     * @localKey            The local primary key on the parent entity.
     * @relationMethodName  The method name called to retrieve this relationship.
     *                      Uses a stack backtrace to determine by default,
     *
     * @return              quick.models.Relationships.HasMany
     */
    private HasMany function hasMany(
        required string relationName,
        string foreignKey,
        string localKey,
        string relationMethodName
    ) {
        var related = variables._wirebox.getInstance(
            arguments.relationName
        );

        param arguments.foreignKey = entityName() & keyName();
        param arguments.localKey = keyName();
        param arguments.relationMethodName = lCase(
            callStackGet()[ 2 ][ "Function" ]
        );

        return variables._wirebox.getInstance(
            name = "HasMany@quick",
            initArguments = {
                related: related,
                relationName: arguments.relationName,
                relationMethodName: arguments.relationMethodName,
                parent: this,
                foreignKey: arguments.foreignKey,
                localKey: arguments.localKey
            }
        );
    }

    /**
     * Returns a BelongsToMany relationship between this entity and the entity
     * defined by `relationName`.
     *
     * Given a Tag `belongsToMany` Posts and using the defaults, the SQL would be:
     * ```sql
     * SELECT *
     * FROM tags [relationName.tableName()]
     * JOIN posts_tags [table]
     * ON tags.id [relatedKey] = posts_tags.tagsId [relatedPivotKey]
     * WHERE posts_tags.postId [foreignPivotKey] = 'posts.id' [parentKey]
     * ```
     *
     * @relationName        The WireBox mapping for the related entity.
     * @table               The table name used as the pivot table for the
     *                      relationship.  A pivot table is a table that stores,
     *                      at a minimum, the primary key values of each side
     *                      of the relationship as foreign keys.
     *                      Defaults to the names of both entities in alphabetic
     *                      order separated by an underscore.
     * @foreignPivotKey     The name of the column on the pivot `table` that holds
     *                      the value of the `parentKey` of the `parent` entity.
     * @relatedPivotKey     The name of the column on the pivot `table` that holds
     *                      the value of the `relatedKey` of the `ralated` entity.
     * @parentKey           The name of the column on the `parent` entity that is
     *                      stored in the `foreignPivotKey` column on `table`.
     * @relatedKey          The name of the column on the `related` entity that is
     *                      stored in the `relatedPivotKey` column on `table`.
     * @relationMethodName  The method name called to retrieve this relationship.
     *                      Uses a stack backtrace to determine by default,
     *
     * @return              quick.models.Relationships.BelongsToMany
     */
    private BelongsToMany function belongsToMany(
        required string relationName,
        string table,
        string foreignPivotKey,
        string relatedPivotKey,
        string parentKey,
        string relatedKey,
        string relationMethodName
    ) {
        var related = variables._wirebox.getInstance(
            arguments.relationName
        );

        param arguments.table = generateDefaultPivotTableString(
            related.tableName(),
            tableName()
        );
        param arguments.foreignPivotKey = entityName() & keyName();
        param arguments.relatedPivotKey = related.entityName() & related.keyName();
        param arguments.relationMethodName = lCase(
            callStackGet()[ 2 ][ "Function" ]
        );
        param arguments.parentKey = keyName();
        param arguments.relatedKey = related.keyName();

        return variables._wirebox.getInstance(
            name = "BelongsToMany@quick",
            initArguments = {
                related: related,
                relationName: arguments.relationName,
                relationMethodName: arguments.relationMethodName,
                parent: this,
                table: arguments.table,
                foreignPivotKey: arguments.foreignPivotKey,
                relatedPivotKey: arguments.relatedPivotKey,
                parentKey: arguments.parentKey,
                relatedKey: arguments.relatedKey
            }
        );
    }

    /**
     * Returns a pivot table name which is the name of the two provided tables
     * in alphabetical order separated with an underscore.
     *
     * @tableA  The first table name.
     * @tableB  The second table name.
     *
     * @return  string
     */
    private string function generateDefaultPivotTableString(
        required string tableA,
        required string tableB
    ) {
        return compareNoCase( arguments.tableA, arguments.tableB ) < 0 ? lCase(
            "#arguments.tableA#_#arguments.tableB#"
        ) : lCase( "#arguments.tableB#_#arguments.tableA#" );
    }

    /**
     * Returns a HasManyThrough relationship between this entity and the entity
     * defined by `relationName` through the entity defined by `intermediateName`.
     *
     * Given a User `hasMany` Permissions `Through` Roles and using the defaults,
     * the SQL would be:
     * ```sql
     * SELECT *
     * FROM permissions [relationName.tableName()]
     * JOIN roles [intermediate.tableName()]
     * ON roles.id [secondLocalKey] = permissions.roleId [secondKey]
     * WHERE roles.userId [firstKey] = 'users.id' [localKey]
     * ```
     *
     * @relationName        The WireBox mapping for the related entity.
     * @intermediate        The WireBox mapping for the intermediate entity
     * @firstKey            The key on the intermediate table linking it to the
     *                      parent entity.
     * @secondKey           The key on the related entity linking it to the
     *                      intermediate entity.
     * @localKey            The local primary key on the parent entity.
     * @secondLocalKey      The local primary key on the intermediate entity.
     * @relationMethodName  The method name called to retrieve this relationship.
     *                      Uses a stack backtrace to determine by default,
     *
     * @return              quick.models.Relationships.HasManyThrough
     */
    private HasManyThrough function hasManyThrough(
        required string relationName,
        required string intermediateName,
        string firstKey,
        string secondKey,
        string localKey,
        string secondLocalKey,
        string relationMethodName
    ) {
        var related = variables._wirebox.getInstance(
            arguments.relationName
        );
        var intermediate = variables._wirebox.getInstance(
            arguments.intermediateName
        );

        param arguments.firstKey = entityName() & keyName();
        param arguments.secondKey = intermediate.entityName() & intermediate.keyName();
        param arguments.localKey = keyName();
        param arguments.secondLocalKey = intermediate.keyName();
        param arguments.relationMethodName = lCase(
            callStackGet()[ 2 ][ "Function" ]
        );

        return variables._wirebox.getInstance(
            name = "HasManyThrough@quick",
            initArguments = {
                related: related,
                relationName: arguments.relationName,
                relationMethodName: arguments.relationMethodName,
                parent: this,
                intermediate: intermediate,
                firstKey: arguments.firstKey,
                secondKey: arguments.secondKey,
                localKey: arguments.localKey,
                secondLocalKey: arguments.secondLocalKey
            }
        );
    }

    /**
     * Returns a PolymorphicHasMany relationship between this entity and the entity
     * defined by `relationName`.
     *
     * Given a Post and a Video `polymorphicHasMany` Comments
     * and using the defaults, the SQL would be:
     * ```sql
     * SELECT *
     * FROM comments [relationName.tableName()]
     * WHERE comments.commentable_id [id] = 'posts.id' [localKey]
     * AND comments.commentable_type [type] = 'Post' [relationName.entityName()]
     * ```
     *
     * @relationName        The WireBox mapping for the related entity.
     * @name                The name given to the polymorphic relationship.
     * @type                The column name that defines the type of the
     *                      polymorphic relationship. Defaults to `#name#_type`.
     * @id                  The column name that defines the id of the
     *                      polymorphic relationship. Defaults to `#name#_id`.
     * @localKey            The local primary key on the parent entity.
     * @relationMethodName  The method name called to retrieve this relationship.
     *                      Uses a stack backtrace to determine by default,
     *
     * @return              quick.models.Relationships.PolymorphicHasMany
     */
    private PolymorphicHasMany function polymorphicHasMany(
        required string relationName,
        required string name,
        string type,
        string id,
        string localKey,
        string relationMethodName
    ) {
        var related = variables._wirebox.getInstance(
            arguments.relationName
        );

        param arguments.type = arguments.name & "_type";
        param arguments.id = arguments.name & "_id";
        param arguments.localKey = keyName();
        param arguments.relationMethodName = lCase(
            callStackGet()[ 2 ][ "Function" ]
        );

        return variables._wirebox.getInstance(
            name = "PolymorphicHasMany@quick",
            initArguments = {
                related: related,
                relationName: arguments.relationName,
                relationMethodName: arguments.relationMethodName,
                parent: this,
                type: arguments.type,
                id: arguments.id,
                localKey: arguments.localKey
            }
        );
    }

    /**
     * Returns a PolymorphicBelongsTo relationship between this entity and the entity
     * defined by `relationName`.
     *
     * Given a Comment `polymorphicBelongsTo` either a Post or Video
     * and using the defaults, the SQL would be:
     * ```sql
     * SELECT *
     * FROM posts [#type#.tableName()]
     * WHERE posts.id [ownerKey] = 'comments.commentable_id' [id]
     * ```
     *
     * @name                The name given to the polymorphic relationship.
     * @type                The column name that defines the type of the
     *                      polymorphic relationship. Defaults to `#name#_type`.
     * @id                  The column name that defines the id of the
     *                      polymorphic relationship. Defaults to `#name#_id`.
     * @ownerKey            The column name on the `realted` entity that is referred
     *                      to by the `foreignKey` of the `parent` entity.
     * @relationMethodName  The method name called to retrieve this relationship.
     *                      Uses a stack backtrace to determine by default,
     *
     * @return              quick.models.Relationships.PolymorphicBelongsTo
     */
    private PolymorphicBelongsTo function polymorphicBelongsTo(
        required string name,
        string type,
        string id,
        string ownerKey,
        string relationMethodName
    ) {
        param arguments.relationMethodName = lCase(
            callStackGet()[ 2 ][ "Function" ]
        );
        param arguments.name = arguments.relationMethodName;
        param arguments.type = arguments.name & "_type";
        param arguments.id = arguments.name & "_id";

        var relationName = retrieveAttribute( arguments.type, "" );
        if ( relationName == "" ) {
            return variables._wirebox.getInstance(
                name = "PolymorphicBelongsTo@quick",
                initArguments = {
                    related: this.set_EagerLoad( [] ).resetQuery(),
                    relationName: relationName,
                    relationMethodName: arguments.relationMethodName,
                    parent: this,
                    foreignKey: arguments.id,
                    ownerKey: "",
                    type: arguments.type
                }
            );
        }

        var related = variables._wirebox.getInstance( relationName );
        param arguments.ownerKey = related.keyName();

        return variables._wirebox.getInstance(
            name = "PolymorphicBelongsTo@quick",
            initArguments = {
                related: related,
                relationName: relationName,
                relationMethodName: arguments.name,
                parent: this,
                foreignKey: arguments.id,
                ownerKey: arguments.ownerKey,
                type: arguments.type
            }
        );
    }

    /**
     * Add an relation or an array of relations to be eager loaded.
     * Eager loaded relations are retrieved at the same time as loading
     * the original query decreasing the number of queries that need
     * to be ran for the same data.
     *
     * @relationName  A single relation name or array of relation
     *                names to eager load.
     *
     * @return        quick.models.BaseEntity
     */
    public any function with( required any relationName ) {
        if (
            isSimpleValue( arguments.relationName ) && arguments.relationName == ""
        ) {
            return this;
        }

        arrayAppend(
            variables._eagerLoad,
            arrayWrap( arguments.relationName ),
            true
        );

        return this;
    }

    /**
     * Eager loads the configured relations for the retrieved entities.
     * Returns the retrieved entities eager loaded with the configured
     * relationships.
     *
     * @entities     The retrieved entities to eager load.
     *
     * @doc_generic  quick.models.BaseEntity
     * @return       [quick.models.BaseEntity]
     */
    private array function eagerLoadRelations( required array entities ) {
        if ( arguments.entities.isEmpty() || variables._eagerLoad.isEmpty() ) {
            return arguments.entities;
        }

        // This is a workaround for grammars with a parameter limit.  If the grammar
        // has a `parameterLimit` public property, it is used to slice up the array
        // and work it in chunks.
        if (
            structKeyExists(
                arguments.entities[ 1 ].retrieveQuery().getGrammar(),
                "parameterLimit"
            )
        ) {
            var parameterLimit = arguments.entities[ 1 ].retrieveQuery().getGrammar().parameterLimit;
            if ( arguments.entities.len() > parameterLimit ) {
                for ( var i = 1; i < arguments.entities.len(); i += parameterLimit ) {
                    var length = min(
                        arguments.entities.len() - i + 1,
                        parameterLimit
                    );
                    var slice = arraySlice( arguments.entities, i, length );
                    eagerLoadRelations( slice );
                }
                return arguments.entities;
            }
        }

        arrayEach( variables._eagerLoad, function( relationName ) {
            entities = eagerLoadRelation( arguments.relationName, entities );
        } );

        return arguments.entities;
    }

    /**
     * Eager loads the given relation for the retrieved entities.
     * Returns the retrieved entities eager loaded with the given relation.
     *
     * @relationName  The relationship to eager load.
     * @entities      The retrieved entities to eager load the relationship.
     *
     * @doc_generic   quick.models.BaseEntity
     * @return        [quick.models.BaseEntity]
     */
    private array function eagerLoadRelation(
        required any relationName,
        required array entities
    ) {
        var callback = function() {
        };
        if ( !isSimpleValue( arguments.relationName ) ) {
            if ( !isStruct( arguments.relationName ) ) {
                throw(
                    type = "QuickInvalidEagerLoadParameter",
                    message = "Only strings or structs are supported eager load parameters.  You passed [#serializeJSON( arguments.relationName )#"
                );
            }
            for ( var key in arguments.relationName ) {
                callback = arguments.relationName[ key ];
                arguments.relationName = key;
                break;
            }
        }
        var currentRelationship = listFirst( arguments.relationName, "." );
        var relation = invoke( this, currentRelationship ).resetQuery();
        callback( relation );
        relation.addEagerConstraints( arguments.entities );
        relation.with( listRest( arguments.relationName, "." ) );
        return relation.match(
            relation.initRelation( arguments.entities, currentRelationship ),
            relation.getEager(),
            currentRelationship
        );
    }

    /*=======================================
    =            QB Utilities            =
    =======================================*/

    /**
     * Resets the configured query to new.
     *
     * @returns  quick.models.BaseEntity
     */
    public any function resetQuery() {
        variables.query = newQuery();
        return this;
    }

    /**
     * Configures a new query, assigns it to the entity, and returns it.
     *
     * @return  qb.models.Query.QueryBuilder
     */
    public QueryBuilder function newQuery() {
        if (
            variables._meta.originalMetadata.keyExists(
                "grammar"
            )
        ) {
            variables._builder.setGrammar(
                variables._wirebox.getInstance(
                    variables._meta.originalMetadata.grammar
                )
            );
        }

        return variables._builder
            .newQuery()
            .setReturnFormat( "array" )
            .setColumnFormatter( function( column ) {
                return retrieveColumnForAlias( column );
            } )
            .setParentQuery( this )
            .from( tableName() );
    }

    public any function populateQuery( required QueryBuilder query ) {
        variables.query = arguments.query.clearParentQuery();
        return this;
    }

    public QueryBuilder function retrieveQuery() {
        if ( !structKeyExists( variables, "query" ) ) {
            variables.query = newQuery();
        }
        return variables.query;
    }

    public any function addSubselect(
        required string name,
        required any subselect
    ) {
        if (
            !variables._attributes.keyExists(
                retrieveAliasForColumn( arguments.name )
            )
        ) {
            variables._attributes[ arguments.name ] = arguments.name;
            variables._meta.properties[ arguments.name ] = paramProperty( { "name": arguments.name, "update": false, "insert": false } );
            variables._meta.originalMetadata.properties.append(
                variables._meta.properties[ arguments.name ]
            );
        }

        if (
            retrieveQuery().getColumns().isEmpty() ||
            (
                retrieveQuery().getColumns().len() == 1 &&
                isSimpleValue( retrieveQuery().getColumns()[ 1 ] ) &&
                retrieveQuery().getColumns()[ 1 ] == "*"
            )
        ) {
            retrieveQuery().select( retrieveQuery().getFrom() & ".*" );
        }

        var subselectQuery = arguments.subselect;
        if ( isClosure( subselectQuery ) ) {
            subselectQuery = retrieveQuery().newQuery();
            subselectQuery = arguments.subselect( subselectQuery );
        }

        retrieveQuery().subselect(
            name,
            subselectQuery.retrieveQuery().limit( 1 )
        );
        return this;
    }

    /*=====================================
    =            Magic Methods            =
    =====================================*/

    public any function onMissingMethod(
        required string missingMethodName,
        struct missingMethodArguments = {}
    ) {
        var columnValue = tryColumnName(
            arguments.missingMethodName,
            arguments.missingMethodArguments
        );
        if ( !isNull( columnValue ) ) {
            return columnValue;
        }
        var q = tryScopes(
            arguments.missingMethodName,
            arguments.missingMethodArguments
        );
        if ( !isNull( q ) ) {
            if ( isStruct( q ) && structKeyExists( q, "retrieveQuery" ) ) {
                variables.query = q.retrieveQuery();
                return this;
            }
            return q;
        }
        var rg = tryRelationshipGetter(
            arguments.missingMethodName,
            arguments.missingMethodArguments
        );
        if ( !isNull( rg ) ) {
            return rg;
        }
        var rs = tryRelationshipSetter(
            arguments.missingMethodName,
            arguments.missingMethodArguments
        );
        if ( !isNull( rs ) ) {
            return rs;
        }
        if ( relationshipIsNull( arguments.missingMethodName ) ) {
            return javacast( "null", "" );
        }

        try {
            return forwardToQB(
                arguments.missingMethodName,
                arguments.missingMethodArguments
            );
        } catch ( QBMissingMethod e ) {
            throw(
                type = "QuickMissingMethod",
                message = arrayToList(
                    [
                        "Quick couldn't figure out what to do with [#arguments.missingMethodName#].",
                        "We tried checking columns, aliases, scopes, and relationships locally.",
                        "We also forwarded the call on the qb to see if it could do anything with it, but it couldn't."
                    ],
                    " "
                )
            )
        }
    }

    private any function tryColumnName(
        required string missingMethodName,
        struct missingMethodArguments = {}
    ) {
        var getColumnValue = tryColumnGetters( arguments.missingMethodName );
        if ( !isNull( getColumnValue ) ) {
            return getColumnValue;
        }
        var setColumnValue = tryColumnSetters(
            arguments.missingMethodName,
            arguments.missingMethodArguments
        );
        if ( !isNull( setColumnValue ) ) {
            return this;
        }
        return;
    }

    private any function tryColumnGetters( required string missingMethodName ) {
        if (
            !variables._str.startsWith(
                arguments.missingMethodName,
                "get"
            )
        ) {
            return;
        }

        var columnName = variables._str.slice(
            arguments.missingMethodName,
            4
        );

        if ( hasAttribute( columnName ) ) {
            return retrieveAttribute( retrieveColumnForAlias( columnName ) );
        }

        return;
    }

    private any function tryColumnSetters(
        required string missingMethodName,
        struct missingMethodArguments = {}
    ) {
        if (
            !variables._str.startsWith(
                arguments.missingMethodName,
                "set"
            )
        ) {
            return;
        }

        var columnName = variables._str.slice(
            arguments.missingMethodName,
            4
        );
        if ( !hasAttribute( columnName ) ) {
            return;
        }
        assignAttribute( columnName, arguments.missingMethodArguments[ 1 ] );
        return arguments.missingMethodArguments[ 1 ];
    }

    private any function tryRelationshipGetter(
        required string missingMethodName,
        struct missingMethodArguments = {}
    ) {
        if (
            !variables._str.startsWith(
                arguments.missingMethodName,
                "get"
            )
        ) {
            return;
        }

        var relationshipName = variables._str.slice(
            arguments.missingMethodName,
            4
        );

        if ( !hasRelationship( relationshipName ) ) {
            return;
        }

        if ( !isRelationshipLoaded( relationshipName ) ) {
            var relationship = invoke(
                this,
                relationshipName,
                arguments.missingMethodArguments
            );
            relationship.setRelationMethodName( relationshipName );
            assignRelationship( relationshipName, relationship.get() );
        }

        return retrieveRelationship( relationshipName );
    }

    private any function tryRelationshipSetter(
        required string missingMethodName,
        struct missingMethodArguments = {}
    ) {
        if (
            !variables._str.startsWith(
                arguments.missingMethodName,
                "set"
            )
        ) {
            return;
        }

        var relationshipName = variables._str.slice(
            arguments.missingMethodName,
            4
        );

        if ( !hasRelationship( relationshipName ) ) {
            return;
        }

        var relationship = invoke( this, relationshipName );

        return relationship.applySetter(
            argumentCollection = arguments.missingMethodArguments
        );
    }

    private boolean function relationshipIsNull( required string name ) {
        if ( !variables._str.startsWith( arguments.name, "get" ) ) {
            return false;
        }
        return variables._relationshipsLoaded.keyExists(
            variables._str.slice( arguments.name, 4 )
        );
    }

    private any function tryScopes(
        required string missingMethodName,
        struct missingMethodArguments = {}
    ) {
        if ( structKeyExists( variables, "scope#arguments.missingMethodName#" ) ) {
            if (
                arrayContains(
                    variables._globalScopeExclusions,
                    lCase( arguments.missingMethodName )
                )
            ) {
                return this;
            }
            var scopeArgs = { "1": this };
            // this is to allow default arguments to be set for scopes
            if ( !structIsEmpty( arguments.missingMethodArguments ) ) {
                for (
                    var i = 1; i <= structCount(
                        arguments.missingMethodArguments
                    ); i++
                ) {
                    scopeArgs[ i + 1 ] = arguments.missingMethodArguments[ i ];
                }
            }
            var result = invoke(
                this,
                "scope#arguments.missingMethodName#",
                scopeArgs
            );
            return isNull( result ) ? this : result;
        }
        return;
    }

    public any function applyGlobalScopes() {
        return this;
    }

    public any function withoutGlobalScope( required any name ) {
        arrayWrap( arguments.name ).each( function( n ) {
            variables._globalScopeExclusions.append(
                lCase( arguments.n )
            );
        } );
        return this;
    }

    private any function forwardToQB(
        required string missingMethodName,
        struct missingMethodArguments = {}
    ) {
        var result = invoke(
            retrieveQuery(),
            arguments.missingMethodName,
            arguments.missingMethodArguments
        );

        if ( isSimpleValue( result ) ) {
            return result;
        }

        return this;
    }

    public any function newCollection( array entities = [] ) {
        return arguments.entities;
    }

    public struct function getMemento() {
        var data = variables._attributes
            .keyArray()
            .reduce( function( acc, key ) {
                acc[ key ] = retrieveAttribute(
                    name = key,
                    bypassGetters = false
                );
                return acc;
            }, {} );
        var loadedRelations = variables._relationshipsData.reduce( function( acc, relationshipName, relation ) {
            if ( isArray( relation ) ) {
                var mementos = relation.map( function( r ) {
                    return r.getMemento();
                } );
                // ACF 11 doesn't let use directly assign the result of map
                // to a dynamic struct key. ¯\_(ツ)_/¯
                acc[ relationshipName ] = mementos;
            } else {
                acc[ relationshipName ] = relation.getMemento();
            }
            return acc;
        }, {} );
        structAppend( data, loadedRelations );
        return data;
    }

    public struct function $renderdata() {
        return getMemento();
    }

    /*=======================================
    =            Other Utilities            =
    =======================================*/

    private any function tap( required any value, required any callback ) {
        arguments.callback( arguments.value );
        return arguments.value;
    }

    private void function metadataInspection() {
        if ( !isStruct( variables._meta ) || structIsEmpty( variables._meta ) ) {
            var util = createObject(
                "component",
                "coldbox.system.core.util.Util"
            );
            variables._meta = {
                "originalMetadata": util.getInheritedMetadata( this )
            };
        }
        param variables._key = "id";
        param variables._meta.fullName = variables._meta.originalMetadata.fullname;
        variables._fullName = variables._meta.fullName;
        param variables._meta.originalMetadata.mapping = listLast(
            variables._meta.originalMetadata.fullname,
            "."
        );
        param variables._meta.mapping = variables._meta.originalMetadata.mapping;
        variables._mapping = variables._meta.mapping;
        param variables._meta.originalMetadata.entityName = listLast(
            variables._meta.originalMetadata.name,
            "."
        );
        param variables._meta.entityName = variables._meta.originalMetadata.entityName;
        variables._entityName = variables._meta.entityName;
        param variables._meta.originalMetadata.table = variables._str.plural(
            variables._str.snake( variables._entityName )
        );
        param variables._meta.table = variables._meta.originalMetadata.table;
        variables._table = variables._meta.table;
        param variables._queryOptions = {};
        if (
            variables._queryOptions.isEmpty() && variables._meta.originalMetadata.keyExists(
                "datasource"
            )
        ) {
            variables._queryOptions = {
                datasource: variables._meta.originalMetadata.datasource
            };
        }
        param variables._meta.originalMetadata.grammar = "AutoDiscover";
        param variables._meta.grammar = variables._meta.originalMetadata.grammar;
        variables._builder.setGrammar(
            variables._wirebox.getInstance( variables._meta.grammar & "@qb" )
        );
        param variables._meta.originalMetadata.readonly = false;
        param variables._meta.readonly = variables._meta.originalMetadata.readonly;
        variables._readonly = variables._meta.readonly;
        param variables._meta.originalMetadata.functions = [];
        param variables._meta.functionNames = generateFunctionNameList(
            variables._meta.originalMetadata.functions
        );
        param variables._meta.originalMetadata.properties = [];
        param variables._meta.properties = generateProperties(
            variables._meta.originalMetadata.properties
        );
        if (
            !variables._meta.properties.keyExists(
                variables._key
            )
        ) {
            var keyProp = paramProperty( { "name": variables._key } );
            variables._meta.properties[ keyProp.name ] = keyProp;
        }
        guardKeyHasNoDefaultValue();
        assignAttributesFromProperties( variables._meta.properties );
    }

    private array function generateFunctionNameList( required array functions ) {
        return arguments.functions.map( function( func ) {
            return lCase( func.name );
        } );
    }

    private struct function generateProperties( required array properties ) {
        return arguments.properties.reduce( function( acc, prop ) {
            var newProp = paramProperty( prop );
            if ( !newProp.persistent ) {
                return acc;
            }
            acc[ newProp.name ] = newProp;
            return acc;
        }, {} );
    }

    private struct function paramProperty( required struct prop ) {
        param prop.column = arguments.prop.name;
        param prop.persistent = true;
        param prop.nullValue = "";
        param prop.convertToNull = true;
        param prop.casts = "";
        param prop.readOnly = false;
        param prop.sqltype = "";
        param prop.insert = true;
        param prop.update = true;
        return arguments.prop;
    }

    private any function assignAttributesFromProperties(
        required struct properties
    ) {
        for ( var alias in arguments.properties ) {
            var options = arguments.properties[ alias ];
            variables._attributes[ alias ] = options.column;
            if ( options.convertToNull ) {
                variables._nullValues[ alias ] = options.nullValue;
            }
            if ( options.casts != "" ) {
                variables._casts[ alias ] = options.casts;
            }
        }
        return this;
    }

    /*=================================
    =            Read Only            =
    =================================*/

    private void function guardReadOnly() {
        if ( isReadOnly() ) {
            throw(
                type = "QuickReadOnlyException",
                message = "[#entityName()#] is marked as a read-only entity."
            );
        }
    }

    private boolean function isReadOnly() {
        return variables._readonly;
    }

    private void function guardAgainstReadOnlyAttributes(
        required struct attributes
    ) {
        for ( var name in arguments.attributes ) {
            guardAgainstReadOnlyAttribute( name );
        }
    }

    private void function guardAgainstNonExistentAttribute(
        required string name
    ) {
        if ( !hasAttribute( arguments.name ) ) {
            throw(
                type = "AttributeNotFound",
                message = "The [#arguments.name#] attribute was not found on the [#entityName()#] entity"
            );
        }
    }

    private void function guardAgainstReadOnlyAttribute( required string name ) {
        if ( isReadOnlyAttribute( arguments.name ) ) {
            throw(
                type = "QuickReadOnlyException",
                message = "[#arguments.name#] is a read-only property on [#entityName()#]"
            );
        }
    }

    private boolean function isReadOnlyAttribute( required string name ) {
        var alias = retrieveAliasForColumn( arguments.name );
        return variables._meta.properties.keyExists(
            alias
        ) &&
        variables._meta.properties[ alias ].readOnly;
    }

    private void function guardNoAttributes() {
        if ( retrieveAttributeNames().isEmpty() ) {
            throw(
                type = "QuickNoAttributesException",
                message = "[#entityName()#] does not have any attributes specified."
            );
        }
    }

    private void function guardEmptyAttributeData( required struct attrs ) {
        if ( arguments.attrs.isEmpty() ) {
            throw(
                type = "QuickNoAttributesDataException",
                message = "[#entityName()#] does not have any attributes data for insert."
            );
        }
    }

    private void function guardAgainstNotLoaded( required string errorMessage ) {
        if ( !isLoaded() ) {
            throw(
                type = "QuickEntityNotLoaded",
                message = arguments.errorMessage
            );
        }
    }

    private void function guardKeyHasNoDefaultValue() {
        if (
            variables._meta.properties.keyExists(
                keyName()
            )
        ) {
            if ( variables._meta.properties[ keyName() ].keyExists( "default" ) ) {
                throw(
                    type = "QuickEntityDefaultedKey",
                    message = "The key value [#keyName()#] has a default value.  Default values on keys prevents Quick from working as expected.  Remove the default value to continue."
                );
            }
        }
    }

    /*==============================
    =            Events          =
    ==============================*/

    private void function fireEvent(
        required string eventName,
        struct eventData = {}
    ) {
        arguments.eventData.entityName = entityName();
        if ( eventMethodExists( arguments.eventName ) ) {
            invoke(
                this,
                arguments.eventName,
                { eventData: arguments.eventData }
            );
        }
        if ( !isNull( variables._interceptorService ) ) {
            variables._interceptorService.processState(
                "quick" & arguments.eventName,
                arguments.eventData
            );
        }
    }

    private boolean function eventMethodExists( required string eventName ) {
        return variables.keyExists( arguments.eventName );
    }

    private boolean function attributeHasSqlType( required string name ) {
        var alias = retrieveAliasForColumn( arguments.name );
        return variables._meta.properties.keyExists(
            alias
        ) &&
        variables._meta.properties[ alias ].sqltype != "";
    }

    private string function getSqlTypeForAttribute( required string name ) {
        var alias = retrieveAliasForColumn( arguments.name );
        return variables._meta.properties[ alias ].sqltype;
    }

    public boolean function isNullAttribute( required string key ) {
        return isNullValue( key, retrieveAttribute( key ) );
    }

    public boolean function isNullValue( required string key, any value ) {
        var alias = retrieveAliasForColumn( arguments.key );
        return variables._nullValues.keyExists( alias ) &&
        compare( variables._nullValues[ alias ], arguments.value ) == 0;
    }

    private any function castValueForGetter( required string key, any value ) {
        arguments.key = retrieveAliasForColumn( arguments.key );
        if ( !structKeyExists( variables._casts, arguments.key ) ) {
            return arguments.value;
        }
        switch ( variables._casts[ arguments.key ] ) {
            case "boolean":
                return javacast( "boolean", arguments.value );
            default:
                return arguments.value;
        }
    }

    private any function castValueForSetter( required string key, any value ) {
        arguments.key = retrieveAliasForColumn( arguments.key );
        if ( !structKeyExists( variables._casts, arguments.key ) ) {
            return arguments.value;
        }
        switch ( variables._casts[ arguments.key ] ) {
            case "boolean":
                return arguments.value ? 1 : 0;
            default:
                return arguments.value;
        }
    }

    private boolean function canUpdateAttribute( required string name ) {
        var alias = retrieveAliasForColumn( arguments.name );
        return variables._meta.properties.keyExists(
            alias
        ) &&
        variables._meta.properties[ alias ].update;
    }

    private boolean function canInsertAttribute( required string name ) {
        var alias = retrieveAliasForColumn( arguments.name );
        return variables._meta.properties.keyExists(
            alias
        ) &&
        variables._meta.properties[ alias ].insert;
    }

    /**
     * Ensures the return value is an array, either by returning an array
     * or by returning the value wrapped in an array.
     *
     * @value        The value to ensure is an array.
     *
     * @doc_generic  any
     * @return       [any]
     */
    private array function arrayWrap( required any value ) {
        return isArray( arguments.value ) ? arguments.value : [
            arguments.value
        ];
    }

}
