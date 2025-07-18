/**
 * Abstract BaseEntity used to wire up objects and their properties to database tables.
 *
 * @doc_abstract true
 */
component accessors="true" {

	/*====================================
    =            Dependencies            =
    ====================================*/

	/**
	 * The WireBox injector.  Used to inject other entities.
	 */
	property
		name      ="_wirebox"
		inject    ="wirebox"
		persistent="false";

	/**
	 * The default CacheBox cache.
	 */
	property
		name      ="_cache"
		inject    ="cachebox:quickMeta"
		persistent="false";

	/**
	 * A string helper library.
	 */
	property
		name      ="_str"
		inject    ="Str@str"
		persistent="false";

	/**
	 * The ColdBox Interceptor service.  Used to announce lifecycle hooks as interception points.
	 */
	property
		name      ="_interceptorService"
		inject    ="box:interceptorService"
		persistent="false";

	/*===========================================
    =            Metadata Properties            =
    ===========================================*/

	/**
	 * The name of the entity.
	 */
	property name="_entityName" persistent="false";

	/**
	 * The WireBox mapping for the entity. This is added by a beforeInstanceAutowire interception point.
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
	 * An array of relationships to automatically eager load.
	 * Use with caution as it is easy to over fetch using this.
	 */
	property name="_with" persistent="false";

	/**
	 * A struct of query options for query executions.
	 */
	property name="_queryOptions" persistent="false";

	/**
	 * Boolean flag to prevent inserts and updates on the entity.
	 */
	property
		name      ="_readonly"
		default   ="false"
		persistent="false";

	/**
	 * The primary key name for the entity.
	 */
	property
		name      ="_key"
		default   ="id"
		persistent="false";

	/**
	 * A map of alias names to attribute options.
	 */
	property name="_attributes" persistent="false";

	/**
	 * The unparsed metadata for the entity. Saved to pass on to created entities and avoid unnecessary processing.
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

	/**
	 * A cache of resolved cast components.
	 */
	property name="_casterCache" persistent="false";

	/**
	 * A cache of casted attributes.
	 */
	property name="_castCache" persistent="false";

	/*=====================================
    =            Instance Data            =
    =====================================*/

	/**
	 * The current attribute values.
	 */
	property name="_data" persistent="false";

	/**
	 * The original values of the attributes. Used if the entity is reset.
	 */
	property name="_originalAttributes" persistent="false";

	/**
	 * A hash of the original attributes and their values. Used to check if the entity has been edited.
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
	 * Discriminated chilrent property
	 **/
	property name="_discriminations" persistent="false";

	/**
	 * Flag for whether to load child entities
	 */
	property name="_loadChildren" persistent="false";

	/**
	 * An set of relationship method names that the entity does not want automatic relationship constraints.
	 */
	property name="_withoutRelationshipConstraints" persistent="false";

	/**
	 * A boolean flag representing that guarding against not loaded entities should be skipped.
	 */
	property name="_ignoreNotLoadedGuard" persistent="false";

	/**
	 * A boolean flag representing if the entity and any QuickBuilder instances
	 * created from it are allowed to lazy load relationships.
	 */
	property
		name      ="_preventLazyLoading"
		persistent="false"
		inject    ="box:setting:preventLazyLoading@quick";

	/**
	 * A callback function called when a lazy loading violation occurs.
	 * It is passed the entity and relation name that caused the violation.
	 */
	property
		name      ="_lazyLoadingViolationCallback"
		persistent="false"
		inject    ="box:setting:lazyLoadingViolationCallback@quick";

	/**
	 * A boolean flag representing that events should not be fired.
	 */
	property name="_withoutFiringEvents" persistent="false";


	/**
	 * An array of virtual attribute key names that have been add to this entity
	 */
	property name="_virtualAttributes" persistent="false";


	/**
	 * A boolean flag indicating that the entity has been loaded from the database.
	 */
	property
		name      ="_loaded"
		persistent="false"
		default   ="false";



	/**
	 * The current alias version used for hasManyThrough aliases
	 */
	property
		name      ="_aliasPrefix"
		persistent="false"
		default   ="";

	/**
	 * Used to determine if a component is a Quick entity without resorting to isInstanceOf
	 */
	this.isQuickEntity = true;

	/**
	 * Initializes the entity with default properties and optional metadata.
	 *
	 * @meta    An optional struct of metadata.  Used to avoid processing the metadata again.
	 * @shallow When passed as true, the initial query instantiation and recursion in to child classes will not be performed
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function init( struct meta = {}, boolean shallow = false ) {
		variables._loadShallow = arguments.shallow;
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
		variables._globalScopeExclusions          = [];
		param variables._key                      = "id";
		param variables._meta                     = {};
		param variables._data                     = {};
		param variables._relationshipsData        = {};
		param variables._relationshipsLoaded      = {};
		param variables._with                     = [];
		variables._withoutRelationshipConstraints = createObject( "java", "java.util.HashSet" ).init();
		variables._applyingGlobalScopes           = false;
		variables._globalScopesApplied            = false;
		variables._ignoreNotLoadedGuard           = false;
		variables._withoutFiringEvents            = false;
		param variables._preventLazyLoading       = false;
		if ( isNull( variables._lazyLoadingViolationCallback ) ) {
			variables._lazyLoadingViolationCallback = ( entity, relationName ) => {
				throw(
					type    = "QuickLazyLoadingException",
					message = "Attempted to lazy load the [#arguments.relationName#] relationship on the entity [#arguments.entity.mappingName()#] but lazy loading is disabled. This is usually caused by the N+1 problem and is a sign that you are missing an eager load."
				);
			};
		}
		param variables._nullValues        = {};
		param variables._casts             = {};
		param variables._castCache         = {};
		param variables._casterCache       = {};
		param variables._loaded            = false;
		param variables._aliasPrefix       = "";
		param variables._hasParentEntity   = false;
		param variables._parentDefinition  = {};
		param variables._discriminators    = [];
		param variables._loadChildren      = true;
		param variables._queryOptions      = {};
		param variables._attributes        = {};
		param variables._columns           = {};
		param variables._virtualAttributes = [];
		variables._saving                  = false;
		return this;
	}

	/**
	 * Processes the metadata and fires an `instanceReady` event
	 * after dependency injection (DI) is completed.
	 * (This method is called automatically by WireBox.)
	 */
	public void function onDIComplete() {
		metadataInspection();
		if ( !variables._loadShallow ) {
			setUpMementifier();
			fireEvent( "instanceReady", { entity : this } );
		}
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
		return variables._wirebox.getInstance( "AutoIncrementingKeyType@quick" );
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
	 *
	 * @return  String
	 */
	public string function entityName() {
		return variables._entityName;
	}

	/**
	 * Returns the WireBox mapping for this entity.
	 *
	 * @return  String
	 */
	public string function mappingName() {
		return variables._mapping;
	}

	/**
	 * Returns the table name for this entity.
	 *
	 * @return  String
	 */
	public string function tableName() {
		return variables._table;
	}

	/**
	 * Returns the table name for this entity.
	 *
	 * @return  String
	 */
	public string function tableAlias() {
		return listLen( variables._table, " " ) > 1 ? listLast( variables._table, " " ) : variables._table;
	}

	public any function withAlias( required string alias ) {
		variables._table = listFirst( variables._table, " " ) & " " & arguments.alias;
		return this;
	}

	/**
	 * Qualifies a column with the entity's table name.
	 *
	 * @column  The column to qualify.
	 *
	 * @return  string
	 */
	public string function qualifyColumn(
		required string column,
		string tableName        = tableName(),
		boolean useParentLookup = true
	) {
		if (
			findNoCase( ".", arguments.column ) != 0 ||
			!hasAttribute( arguments.column ) ||
			isVirtualAttribute( arguments.column )
		) {
			return arguments.column;
		}

		return ( isParentAttribute( arguments.column ) && arguments.useParentLookup )
		 ? variables._meta.parentDefinition.meta.table & "." & retrieveColumnForAlias( arguments.column )
		 : listLast( arguments.tableName, " " ) & "." & retrieveColumnForAlias( arguments.column );
	}

	/**
	 * Returns the qualified key name for this entity.
	 *
	 * @doc_generic  String
	 * @return       [String]
	 */
	public array function retrieveQualifiedKeyNames() {
		return keyNames().map( function( keyName ) {
			return this.qualifyColumn( keyName );
		} );
	}

	/**
	 * Returns the aliased name for the primary key column.
	 *
	 * @doc_generic String
	 * @return      [String]
	 */
	public array function keyNames() {
		return arrayWrap( variables._key );
	}

	/**
	 * Returns the column name for the primary key.
	 *
	 * @doc_generic  String
	 * @return       [String]
	 */
	public array function keyColumns() {
		return keyNames().map( function( keyName ) {
			return retrieveColumnForAlias( keyName );
		} );
	}

	/**
	 * Returns the value of the primary key for this entity.
	 *
	 * @doc_generic  any
	 * @return       [any]
	 */
	public array function keyValues() {
		guardAgainstNotLoaded( "This instance is not loaded so the `keyValues` cannot be retrieved." );
		return keyNames().map( function( keyName ) {
			return retrieveAttribute( keyName );
		} );
	}

	/**
	 * Retrieves a struct of the current attributes with their associated values.
	 *
	 * @aliased     Uses attribute aliases as the keys instead of column names.
	 * @withoutKey  Excludes the keyName attribute from the returned struct.
	 * @withNulls   Includes null values in the returned struct.
	 */
	public struct function retrieveAttributesData(
		boolean aliased    = false,
		boolean withoutKey = false,
		boolean withNulls  = false
	) {
		syncVariablesScopeWithData();
		return variables._data.reduce( function( acc, key, value ) {
			if ( isVirtualAttribute( key ) ) {
				return acc;
			}
			if ( withoutKey && arrayContainsNoCase( keyNames(), retrieveAliasForColumn( key ) ) ) {
				return acc;
			}
			if ( isNull( value ) || ( isNullAttribute( key ) && withNulls ) ) {
				acc[ aliased ? retrieveAliasForColumn( key ) : retrieveColumnForAlias( key ) ] = javacast( "null", "" );
			} else {
				acc[ aliased ? retrieveAliasForColumn( key ) : retrieveColumnForAlias( key ) ] = value;
			}
			return acc;
		}, {} );
	}

	/**
	 * Syncs the values found in the variables scope (due to accessors) in to data
	 */
	private void function syncVariablesScopeWithData() {
		for ( var key in retrieveAttributeNames( withVirtualColumns = false ) ) {
			if ( variables.keyExists( key ) && !isReadOnlyAttribute( key ) ) {
				assignAttribute( key, variables[ key ] );
			}
		}
	}

	/**
	 * Retrieves an array of the attribute names.
	 *
	 * @asColumnNames          If true, returns an array of column names instead of aliases.
	 * @withVirtualAttributes  If true, returns virtual attributes as well as normal attributes.
	 *
	 * @doc_generic  string
	 * @return       [string]
	 */
	public array function retrieveAttributeNames(
		boolean asColumnNames          = false,
		boolean withVirtualAttributes  = false,
		boolean withExcludedAttributes = false
	) {
		return variables._attributes.reduce( function( items, key, value ) {
			if ( value.exclude && !withExcludedAttributes ) {
				return items;
			}

			if ( value.virtual && !withVirtualAttributes ) {
				return items;
			}
			items.append(
				asColumnNames
				 ? value.isParentColumn
				 ? ( getParentDefinition().meta.table & "." & value.column )
				 : value.column
				 : key
			);
			return items;
		}, [] );
	}

	/**
	 * Retrieves an array of the attribute names.
	 *
	 * @withVirtualAttributes  If true, returns virtual attributes as well as normal attributes.
	 *
	 * @doc_generic  string
	 * @return       [string]
	 */
	public array function retrieveColumnNames( boolean withVirtualAttributes = false ) {
		arguments.asColumnNames = true;
		return retrieveAttributeNames( argumentCollection = arguments );
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
	public any function forceClearAttribute( required string name, boolean setToNull = false ) {
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
		boolean force     = false
	) {
		var alias  = retrieveAliasForColumn( arguments.name );
		var column = retrieveColumnForAlias( arguments.name );
		if ( arguments.force ) {
			if ( !variables._attributes.keyExists( alias ) ) {
				var clearedAttr                              = paramAttribute( { "name" : arguments.name } );
				variables._attributes[ clearedAttr.name ]    = clearedAttr;
				variables._columns[ clearedAttr.column ]     = clearedAttr;
				variables._meta.attributes[ arguments.name ] = variables._attributes[ arguments.name ];
				variables._meta.originalMetadata.properties.append( variables._attributes[ arguments.name ] );
			}
		}
		if ( arguments.setToNull ) {
			variables._data[ column ] = javacast( "null", "" );
			variables[ alias ]        = javacast( "null", "" );
		} else {
			variables._data[ column ] = variables._nullValues[ alias ];
			variables[ alias ]        = variables._nullValues[ alias ];
		}
		return this;
	}

	/**
	 * Assigns a struct of key / value pairs as the attributes data.
	 * This method also marks an entity as not loaded if the attributes struct is empty.
	 * This method does not:
	 * 1. Use relationship setters
	 * 2. Call custom attribute setters
	 * 3. Check for the existence of the attribute
	 *
	 * @attributes  The struct of key / value pairs to set.
	 *
	 * @return      quick.models.BaseEntity
	 */
	public any function assignAttributesData( struct attributes = {} ) {
		if ( arguments.attributes.isEmpty() ) {
			variables._loaded = false;
			variables._data   = {};
			return this;
		}

		populateAttributes( arguments.attributes );

		return this;
	}

	/**
	 * Populates a struct of key / value pairs as the attributes data.
	 * This method does not:
	 * 1. Use relationship setters
	 * 2. Call custom attribute setters
	 * 3. Check for the existence of the attribute
	 *
	 * @attributes  The struct of key / value pairs to set.
	 *
	 * @return      quick.models.BaseEntity
	 */
	public any function populateAttributes( struct attributes = {} ) {
		for ( var key in arguments.attributes ) {
			if ( !hasAttribute( key ) ) {
				continue;
			}
			variables._data[ retrieveColumnForAlias( key ) ] = (
				!arguments.attributes.keyExists( key ) || isNull( arguments.attributes[ key ] )
			) ? javacast( "null", "" ) : castValueForGetter( key, arguments.attributes[ key ] );
			variables[ retrieveAliasForColumn( key ) ] = (
				!arguments.attributes.keyExists( key ) || isNull( arguments.attributes[ key ] )
			) ? javacast( "null", "" ) : castValueForGetter( key, arguments.attributes[ key ] );
		}
	}

	/**
	 * Sets attributes data from a struct of key / value pairs.
	 * This method does the following, in order:
	 * 1. Guard against read-only attributes
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
		struct attributes                   = {},
		boolean ignoreNonExistentAttributes = false,
		any include                         = [],
		any exclude                         = []
	) {
		// if they passed in a list instead of an array for include or exclude, convert it to an array
		if ( isSimpleValue( arguments.include ) ) {
			arguments.include = listToArray( arguments.include );
		}

		if ( isSimpleValue( arguments.exclude ) ) {
			arguments.exclude = listToArray( arguments.exclude );
		}

		for ( var key in arguments.attributes ) {
			// Include List?
			if ( include.len() && !include.findNoCase( key ) ) {
				continue;
			}

			// exclude list?
			if ( exclude.len() && exclude.findNoCase( key ) ) {
				continue;
			}

			guardAgainstReadOnlyAttribute( key );

			if ( isNull( arguments.attributes[ key ] ) || !structKeyExists( arguments.attributes, key ) ) {
				if ( hasAttribute( key ) ) {
					clearAttribute( key, true );
				} else if ( !arguments.ignoreNonExistentAttributes ) {
					guardAgainstNonExistentAttribute( key );
				}
				continue;
			}
			var value = arguments.attributes[ key ];
			var rs    = tryRelationshipSetter( "set#key#", { "1" : value } );
			if ( !isNull( rs ) ) {
				continue;
			}
			if ( hasAttribute( key ) ) {
				variables._data[ retrieveColumnForAlias( key ) ] = value;
				invoke(
					this,
					"set#retrieveAliasForColumn( key )#",
					{ "1" : value }
				);
			} else if ( !arguments.ignoreNonExistentAttributes ) {
				guardAgainstNonExistentAttribute( key );
			}
		}
		return this;
	}

	/**
	 * Alias for fill.
	 *
	 * Sets attributes data from a struct of key / value pairs.
	 * This method does the following, in order:
	 * 1. Guard against read-only attributes
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
	public any function populate( required struct attributes, boolean ignoreNonExistentAttributes = false ) {
		return fill( argumentCollection = arguments );
	}

	/**
	 * Hydrates an entity from a struct of data.
	 * Hydrating an entity fills the entity and then marks it as loaded.
	 *
	 * @attributes  A struct of key / value pairs.
	 *
	 * @return      quick.models.BaseEntity
	 */
	public any function hydrate( required struct attributes ) {
		guardAgainstMissingKeys( arguments.attributes );
		return assignAttributesData( arguments.attributes )
			.assignOriginalAttributes( arguments.attributes )
			.markLoaded();
	}

	/**
	 * Hydrates a new collection of entities from an array of structs.
	 *
	 * @mementos  An array of structs to hydrate into entities.
	 */
	public any function hydrateAll( array mementos = [] ) {
		return newCollection(
			arguments.mementos.map( function( memento ) {
				return newEntity().hydrate( memento );
			} )
		);
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
		return structKeyExists( variables._attributes, retrieveAliasForColumn( arguments.name ) ) || arrayContainsNoCase(
			keyNames(),
			name
		);
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
		return variables._attributes.keyExists( arguments.alias ) ? variables._attributes[ arguments.alias ].column : arguments.alias;
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
		return variables._columns.keyExists( arguments.column ) ? variables._columns[ arguments.column ].name : arguments.column;
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
		structDelete( variables, "_originalAttributesHash" );
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
		var keys = arguments.attributes.keyArray().filter( hasAttribute );
		arraySort( keys, "textnocase" );
		return hash(
			keys.map( function( key ) {
					var valueIsNotNull = structKeyExists( attributes, arguments.key ) &&
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
		fireEvent( "postLoad", { entity : this } );
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
		param variables._originalAttributesHash = computeAttributesHash( variables._originalAttributes );
		return compare( variables._originalAttributesHash, computeAttributesHash( retrieveAttributesData() ) ) != 0;
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
		any defaultValue      = "",
		boolean bypassGetters = true
	) {
		// If the value exists in the variables scope and is not read-only,
		// ensure that the value in the variables scope is also set as the
		// value in the attributes struct.
		if (
			variables.keyExists( retrieveAliasForColumn( arguments.name ) ) &&
			!isReadOnlyAttribute( arguments.name )
		) {
			forceAssignAttribute( arguments.name, variables[ retrieveAliasForColumn( arguments.name ) ] );
		}

		// If there is no value set for the attribute, return the default value.
		if ( !variables._data.keyExists( retrieveColumnForAlias( arguments.name ) ) ) {
			return castValueForGetter( arguments.name, arguments.defaultValue );
		}

		// Retrieve the value either from the custom getter
		// or directly from the attributes struct
		var data = !arguments.bypassGetters && variables.keyExists( "get" & retrieveAliasForColumn( arguments.name ) ) ? invoke(
			this,
			"get" & retrieveAliasForColumn( arguments.name )
		) : variables._data[ retrieveColumnForAlias( arguments.name ) ];

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
		boolean force = false,
		boolean cast  = true
	) {
		if ( arguments.force ) {
			if ( !variables._attributes.keyExists( retrieveAliasForColumn( arguments.name ) ) ) {
				var attr                                     = paramAttribute( { "name" : arguments.name } );
				variables._attributes[ attr.name ]           = attr;
				variables._columns[ attr.column ]            = attr;
				variables._meta.attributes[ arguments.name ] = variables._attributes[ arguments.name ];
				variables._meta.originalMetadata.properties.append( variables._attributes[ arguments.name ] );
			}
		} else {
			guardAgainstNonExistentAttribute( arguments.name );
			guardAgainstReadOnlyAttribute( arguments.name );
		}

		// If the value passed in is a Quick entity, use its first `keyValues` as the value.
		if (
			!isNull( arguments.value ) && isStruct( arguments.value ) && structKeyExists(
				arguments.value,
				"isQuickEntity"
			)
		) {
			guardAgainstKeyLengthMismatch( arguments.value.keyValues(), 1 );
			arguments.value = castValueForSetter( arguments.name, arguments.value.keyValues()[ 1 ] );
		}

		variables._data[ retrieveColumnForAlias( arguments.name ) ] = arguments.cast ? castValueForSetter(
			arguments.name,
			isNull( arguments.value ) ? javacast( "null", "" ) : arguments.value
		) : ( isNull( arguments.value ) ? javacast( "null", "" ) : arguments.value );
		variables[ retrieveAliasForColumn( arguments.name ) ] = arguments.cast ? castValueForSetter(
			arguments.name,
			isNull( arguments.value ) ? javacast( "null", "" ) : arguments.value
		) : ( isNull( arguments.value ) ? javacast( "null", "" ) : arguments.value );

		return this;
	}

	/**
	 * Retrieve an array of qualified column names.
	 *
	 * @doc_generic  string
	 * @return       [string]
	 */
	public array function retrieveQualifiedColumns() {
		var attributes = retrieveColumnNames();
		arraySort( attributes, "textnocase" );
		return attributes.map( function( column ) {
			return this.qualifyColumn( column );
		} );
	}

	/*=====================================
    =            Query Methods            =
    =====================================*/

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
			return variables._wirebox.getInstance(
				name          = mappingName(),
				initArguments = { meta : structCopy( variables._meta ) }
			);
		}
		// Custom named instance
		return variables._wirebox.getInstance( arguments.name );
	}

	/**
	 * Creates a new child entity for a discriminated parent.
	 *
	 * @discriminatorValue  The value to indentify the child entity.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function newChildEntity( required string discriminatorValue ) {
		if ( !isDiscriminatedParent() ) {
			throw(
				type    = "QuickNonDiscriminatedParent",
				message = "Entity [#entityName()#] is not a discriminated parent entity, so no child entities can be defined.",
				detail  = "Add a [discriminatorColumn] metadata attribute to the component to make it a discriminated parent."
			);
		}

		if ( !structKeyExists( getDiscriminations(), arguments.discriminatorValue ) ) {
			throw(
				type    = "QuickMissingDiscriminator",
				message = "Discriminator value [#arguments.discriminatorValue#] is not defined on parent entity [#entityName()#].",
				detail  = "Available discriminations are: #structKeyList( getDiscriminations(), ", " )#"
			);
		}

		return variables._wirebox.getInstance( name = getDiscriminations()[ arguments.discriminatorValue ].mapping );
	}

	/**
	 * Resets the entity to a fresh state.
	 *
	 * @toNew   If true, marks the entity as unloaded.  Otherwise it uses the previous loaded value.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function reset( boolean toNew = false ) {
		assignAttributesData( arguments.toNew ? {} : variables._originalAttributes );
		if ( arguments.toNew ) {
			assignOriginalAttributes( {} );
		}
		variables._relationshipsData   = {};
		variables._relationshipsLoaded = {};
		variables._loaded              = arguments.toNew ? false : variables._loaded;

		return this;
	}

	/**
	 * Resets an entity to a new state.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function resetToNew() {
		arguments.toNew = true;
		return reset( argumentCollection = arguments );
	}

	/**
	 * Retrieves a new entity from the database with the same key value
	 * as the current entity.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function fresh() {
		return newQuery()
			.where( function( q ) {
				arrayZipEach( [ keyNames(), keyValues() ], function( keyName, keyValue ) {
					q.where( keyName, keyValue );
				} );
			} )
			.first();
	}

	/**
	 * Refreshes the attributes data for the entity
	 * with data from the database.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function refresh() {
		variables._relationshipsData   = {};
		variables._relationshipsLoaded = {};
		assignAttributesData(
			newQuery()
				.from( tableName() )
				.where( function( q ) {
					arrayZipEach( [ keyNames(), keyValues() ], function( keyName, keyValue ) {
						q.where( this.qualifyColumn( keyName ), keyValue );
					} );
				} )
				.first()
				.retrieveAttributesData()
		);
		return this;
	}

	/**
	 * Return a clone of this entity.
	 *
	 * @markLoaded   If true, marks the entity as loaded. If this is true the postLoad event will NOT be fired.
	 *
	 * @return 	quick.models.BaseEntity
	 */
	public any function clone( boolean markLoaded = false ) {
		var entityClone = this.newEntity().fill( this.retrieveAttributesData() );
		if ( arguments.markLoaded ) {
			// do not us markLoaded() here as I do not want to fire the postLoad event
			entityClone.set_loaded( true );
		}

		return entityClone;
	}



	/*===========================================
    =            Persistence Methods            =
    ===========================================*/

	/**
	 * Saves the entity to the database.
	 * If the entity is not loaded, it inserts the data into the database.
	 * Otherwise it updates the database.
	 *
	 * @options Any options to pass to `queryExecute`. Default: {}.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function save( struct options = {} ) {
		if ( hasParentEntity() ) {
			var parentDefinition = getParentDefinition();
			if ( isLoaded() ) {
				var parent = variables._wirebox
					.getInstance( parentDefinition.meta.fullName )
					.set_LoadChildren( false )
					.findOrFail( keyValues(), arguments.options );
			} else {
				var parent = variables._wirebox.getInstance( parentDefinition.meta.fullName );
			}

			parent.fill( retrieveAttributesData(), true ).save( arguments.options );

			assignAttributesData( {
				"#parentDefinition.key#"        : parent.keyValues()[ 1 ],
				"#parentDefinition.joinColumn#" : parent.keyValues()[ 1 ]
			} );
		}
		guardNoAttributes();
		guardReadOnly();
		mergeAttributesFromCastCache();
		fireEvent(
			"preSave",
			{
				entity  : this,
				options : arguments.options
			}
		);
		variables._saving = true;
		var builder       = newQuery();
		if ( variables._loaded ) {
			fireEvent(
				"preUpdate",
				{
					"entity"             : this,
					"newAttributes"      : get_data(),
					"originalAttributes" : get_originalAttributes(),
					"options"            : arguments.options
				}
			);
			builder
				.where( function( q ) {
					arrayZipEach( [ keyNames(), keyValues() ], function( keyName, keyValue ) {
						q.where( keyName, keyValue );
					} );
				} )
				.update(
					retrieveAttributesData( withoutKey = true )
						.filter( canUpdateAttribute )
						.map( function( key, value, attributes ) {
							return builder.generateQueryParamStruct(
								key,
								isNull( value ) ? javacast( "null", "" ) : value
							);
						} ),
					arguments.options
				);
			assignOriginalAttributes( retrieveAttributesData() );
			markLoaded();
			fireEvent(
				"postUpdate",
				{
					"entity"  : this,
					"options" : arguments.options
				}
			);
		} else {
			retrieveKeyType().preInsert( this, builder );
			fireEvent(
				"preInsert",
				{
					"entity"     : this,
					"builder"    : builder,
					"attributes" : retrieveAttributesData(),
					"options"    : arguments.options
				}
			);
			var attrs = retrieveAttributesData()
				.filter( canInsertAttribute )
				.map( function( key, value, attributes ) {
					return builder.generateQueryParamStruct( key, isNull( value ) ? javacast( "null", "" ) : value );
				} );
			guardEmptyAttributeData( attrs );

			var result = builder.insert( attrs, arguments.options );

			if ( hasParentEntity() ) {
				result.result[ getParentDefinition().joincolumn ] = variables._data[ getParentDefinition().joinColumn ];
			}
			retrieveKeyType().postInsert( this, result );
			assignOriginalAttributes( retrieveAttributesData() );
			markLoaded();
			fireEvent(
				"postInsert",
				{
					"entity"  : this,
					"options" : arguments.options
				}
			);
		}
		variables._saving = false;
		fireEvent(
			"postSave",
			{
				"entity"  : this,
				"options" : arguments.options
			}
		);

		// re-cast
		for ( var key in variables._castCache ) {
			var castedValue = castValueForGetter(
				key,
				variables._castCache[ key ],
				true
			);
			variables._data[ retrieveColumnForAlias( key ) ] = castedValue;
			variables[ retrieveAliasForColumn( key ) ]       = castedValue;
		}

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
		fireEvent( "preDelete", { entity : this } );
		guardAgainstNotLoaded(
			"This instance is not loaded so it cannot be deleted. " &
			"Did you maybe mean to use `deleteAll`?"
		);

		newQuery()
			.where( function( q ) {
				arrayZipEach( [ keyNames(), keyValues() ], function( keyName, keyValue ) {
					q.where( keyName, keyValue );
				} );
			} )
			.delete();

		if ( hasParentEntity() ) {
			var parentEntity = variables._wirebox
				.getInstance( getParentDefinition().meta.fullName )
				.set_LoadChildren( false )
				.find( keyValues() );

			if ( !isNull( parentEntity ) ) {
				parentEntity.delete();
			}
		}

		variables._loaded = false;
		fireEvent( "postDelete", { entity : this } );
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
	public any function update( struct attributes = {}, boolean ignoreNonExistentAttributes = false ) {
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
	 * @options                      Any options to pass to `queryExecute`. Default: {}.
	 *
	 * @throws                       QuickReadOnlyException
	 *
	 * @return                       quick.models.BaseEntity
	 */
	public any function create(
		struct attributes                   = {},
		boolean ignoreNonExistentAttributes = false,
		struct options                      = {}
	) {
		return newEntity().fill( arguments.attributes, arguments.ignoreNonExistentAttributes ).save( arguments.options );
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
		for ( var functionName in variables._meta.functionNames ) {
			if ( compareNoCase( functionName, arguments.name ) == 0 ) {
				return true;
			}
		}
		return false;
	}

	/**
	 * Sets automatic relationships constraints to false for the
	 * duration of the callback.
	 *
	 * @callback  The callback to run without any automatic relationship constraints.
	 */
	public any function withoutRelationshipConstraints( required string relationshipName, required any callback ) {
		variables._withoutRelationshipConstraints.add( lCase( arguments.relationshipName ) );
		try {
			return arguments.callback();
		} finally {
			variables._withoutRelationshipConstraints.remove( lCase( arguments.relationshipName ) );
		}
	}

	/**
	 * Marks this entity and any QuickBuilder instances created from it as
	 * not being allowed to lazy load relationships.
	 */
	public any function preventLazyLoading( function callback ) {
		if ( isNull( arguments.callback ) ) {
			arguments.callback = ( entity, relationName ) => {
				throw(
					type    = "QuickLazyLoadingException",
					message = "Attempted to lazy load the [#arguments.relationName#] relationship on the entity [#arguments.entity.mappingName()#] but lazy loading is disabled. This is usually caused by the N+1 problem and is a sign that you are missing an eager load."
				);
			}
		}
		variables._preventLazyLoading           = true;
		variables._lazyLoadingViolationCallback = arguments.callback;
		return this;
	}

	/**
	 * Marks this entity and any QuickBuilder instances created from it as
	 * being allowed to lazy load relationships.
	 */
	public any function allowLazyLoading() {
		variables._preventLazyLoading = false;
		return this;
	}


	private boolean function shouldSkipRelationshipConstraints( required string relationMethodName ) {
		if ( variables._withoutRelationshipConstraints.contains( lCase( relationMethodName ) ) ) {
			variables._withoutRelationshipConstraints.remove( lCase( relationMethodName ) );
			return true;
		}

		for ( var stackFrame in callStackGet() ) {
			if ( variables._withoutRelationshipConstraints.contains( lCase( stackFrame[ "Function" ] ) ) ) {
				return true;
			}
		}

		return false;
	}

	/**
	 * Does not fire events for the duration of the callback.
	 *
	 * @callback  The callback to run without any events firing.
	 */
	public any function withoutFiringEvents( required any callback ) {
		variables._withoutFiringEvents = true;
		try {
			return arguments.callback();
		} finally {
			variables._withoutFiringEvents = false;
		}
	}

	/**
	 * Loads a single relationship or an array of relationships by name.
	 * Use this method if you need to load the relationship, but don't
	 * need the relationship value returned.  If the relationship is already
	 * loaded, it is not reloaded unless the `force` parameter is true.
	 *
	 * @name    A single relationship name or an array of relationship names.
	 * @force   Always load the relationship, even if it is already loaded.
	 *
	 * @return  quick.models.BaseEntity;
	 */
	public any function loadRelationship(
		required any name,
		boolean force    = false,
		boolean parallel = false
	) {
		arguments.name = arrayWrap( arguments.name );
		if ( arguments.name.len() > 1 && arguments.parallel ) {
			var threadNames = [];
			for ( var n in arguments.name ) {
				var threadName = "#n#_#replace( createUUID(), "-", "", "all" )#";
				threadNames.append( threadName );
				cfthread(
					action           = "run",
					name             = "#threadName#",
					relationshipName = "#n#",
					entity           = this
				) {
					var relationship = invoke( attributes.entity, attributes.relationshipName );
					relationship.setRelationMethodName( attributes.relationshipName );
					assignRelationship( attributes.relationshipName, relationship.get() );
				}
			}
			cfthread(
				action  = "join",
				name    = "#threadNames.toList()#",
				timeout = "#60 * 1000#"
			);
		} else {
			for ( var n in arguments.name ) {
				if ( arguments.force || !isRelationshipLoaded( n ) ) {
					var relationship = invoke( this, n );
					relationship.setRelationMethodName( n );
					assignRelationship( n, relationship.get() );
				}
			}
		}
		return this;
	}

	/**
	 * Loads a single relationship or an array of relationships by name.
	 * Use this method if you need to load the relationship, but don't
	 * need the relationship value returned. This method will load each
	 * relationship, even if it is already loaded.
	 *
	 * @name    A single relationship name or an array of relationship names.
	 *
	 * @return  quick.models.BaseEntity;
	 */
	public any function forceLoadRelationship( required any name, boolean parallel = false ) {
		arguments.force = true;
		return loadRelationship( argumentCollection = arguments );
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
		return variables._relationshipsData.keyExists( arguments.name ) ? variables._relationshipsData[ arguments.name ] : javacast(
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
		variables._relationshipsData   = {};
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
		variables._relationshipsLoaded.delete( arguments.name );
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
	 * WHERE users.id [localKey] = 'posts.userId' [foreignKey]
	 * ```
	 *
	 * @relationName        The WireBox mapping for the related entity.
	 * @foreignKey          The column name on the `parent` entity that refers to
	 *                      the `localKey` on the `related` entity.
	 * @localKey            The column name on the `realted` entity that is referred
	 *                      to by the `foreignKey` of the `parent` entity.
	 * @relationMethodName  The method name called to retrieve this relationship.
	 *                      Uses a stack backtrace to determine by default.
	 *
	 * @return              quick.models.Relationships.BelongsTo
	 */
	private BelongsTo function belongsTo(
		required string relationName,
		any foreignKey,
		any localKey,
		string relationMethodName
	) {
		param arguments.relationMethodName = lCase( callStackGet()[ 2 ][ "Function" ] );

		guardAgainstNotLoaded(
			"This instance is not loaded so it cannot access the [#arguments.relationMethodName#] relationship.  Either load the entity from the database using a query executor (like `first`) or base your query off of the [#arguments.relationName#] entity directly and use the `has` or `whereHas` methods to constrain it based on data in [#entityName()#]."
		);

		var related = variables._wirebox.getInstance( arguments.relationName );

		// ACF doesn't let us use param with functions. ¯\_(ツ)_/¯
		if ( isNull( arguments.foreignKey ) ) {
			arguments.foreignKey = related
				.keyNames()
				.map( function( keyName ) {
					return related.entityName() & keyName;
				} );
		}
		arguments.foreignKey     = arrayWrap( arguments.foreignKey );
		param arguments.localKey = related.keyNames();
		arguments.localKey       = arrayWrap( arguments.localKey );

		guardAgainstKeyLengthMismatch( arguments.foreignKey, arguments.localKey );

		return variables._wirebox.getInstance(
			name          = "BelongsTo@quick",
			initArguments = {
				"related"            : related,
				"relationName"       : arguments.relationName,
				"relationMethodName" : arguments.relationMethodName,
				"parent"             : this,
				"foreignKeys"        : arguments.foreignKey,
				"localKeys"          : arguments.localKey,
				"withConstraints"    : !shouldSkipRelationshipConstraints( arguments.relationMethodName )
			}
		);
	}

	/**
	 * Returns a HasOne relationship between this entity and the entity defined by `relationName`.
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
	 *                      Uses a stack backtrace to determine by default.
	 *
	 * @return              quick.models.Relationships.HasOne
	 */
	private HasOne function hasOne(
		required string relationName,
		any foreignKey,
		any localKey,
		string relationMethodName
	) {
		param arguments.relationMethodName = lCase( callStackGet()[ 2 ][ "Function" ] );

		guardAgainstNotLoaded(
			"This instance is not loaded so it cannot access the [#arguments.relationMethodName#] relationship.  Either load the entity from the database using a query executor (like `first`) or base your query off of the [#arguments.relationName#] entity directly and use the `has` or `whereHas` methods to constrain it based on data in [#entityName()#]."
		);

		var related = variables._wirebox.getInstance( arguments.relationName );

		if ( isNull( arguments.foreignKey ) ) {
			arguments.foreignKey = keyNames().map( function( keyName ) {
				return entityName() & keyName;
			} );
		}
		arguments.foreignKey     = arrayWrap( arguments.foreignKey );
		param arguments.localKey = keyNames();
		arguments.localKey       = arrayWrap( arguments.localKey );

		return variables._wirebox.getInstance(
			name          = "HasOne@quick",
			initArguments = {
				"related"            : related,
				"relationName"       : arguments.relationName,
				"relationMethodName" : arguments.relationMethodName,
				"parent"             : this,
				"foreignKeys"        : arguments.foreignKey,
				"localKeys"          : arguments.localKey,
				"withConstraints"    : !shouldSkipRelationshipConstraints( arguments.relationMethodName )
			}
		);
	}

	/**
	 * Returns a HasMany relationship between this entity and the entity defined by `relationName`.
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
	 *                      Uses a stack backtrace to determine by default.
	 *
	 * @return              quick.models.Relationships.HasMany
	 */
	private HasMany function hasMany(
		required string relationName,
		any foreignKey,
		any localKey,
		string relationMethodName
	) {
		param arguments.relationMethodName = lCase( callStackGet()[ 2 ][ "Function" ] );

		guardAgainstNotLoaded(
			"This instance is not loaded so it cannot access the [#arguments.relationMethodName#] relationship.  Either load the entity from the database using a query executor (like `first`) or base your query off of the [#arguments.relationName#] entity directly and use the `has` or `whereHas` methods to constrain it based on data in [#entityName()#]."
		);

		var related = variables._wirebox.getInstance( arguments.relationName );

		if ( isNull( arguments.foreignKey ) ) {
			arguments.foreignKey = keyNames().map( function( keyName ) {
				return entityName() & keyName;
			} );
		}
		arguments.foreignKey     = arrayWrap( arguments.foreignKey );
		param arguments.localKey = keyNames();
		arguments.localKey       = arrayWrap( arguments.localKey );

		return variables._wirebox.getInstance(
			name          = "HasMany@quick",
			initArguments = {
				"related"            : related,
				"relationName"       : arguments.relationName,
				"relationMethodName" : arguments.relationMethodName,
				"parent"             : this,
				"foreignKeys"        : arguments.foreignKey,
				"localKeys"          : arguments.localKey,
				"withConstraints"    : !shouldSkipRelationshipConstraints( arguments.relationMethodName )
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
	 *                      Uses a stack backtrace to determine by default.
	 *
	 * @return              quick.models.Relationships.BelongsToMany
	 */
	private BelongsToMany function belongsToMany(
		required string relationName,
		string table,
		any foreignPivotKey,
		any relatedPivotKey,
		any parentKey,
		any relatedKey,
		string relationMethodName
	) {
		param arguments.relationMethodName = lCase( callStackGet()[ 2 ][ "Function" ] );

		guardAgainstNotLoaded(
			"This instance is not loaded so it cannot access the [#arguments.relationMethodName#] relationship.  Either load the entity from the database using a query executor (like `first`) or base your query off of the [#arguments.relationName#] entity directly and use the `has` or `whereHas` methods to constrain it based on data in [#entityName()#]."
		);

		var related = variables._wirebox.getInstance( arguments.relationName );

		param arguments.table = generateDefaultPivotTableString( related.tableName(), tableName() );

		if ( isNull( arguments.foreignPivotKey ) ) {
			arguments.foreignPivotKey = keyNames().map( function( keyName ) {
				return entityName() & keyName;
			} );
		}
		arguments.foreignPivotKey = arrayWrap( arguments.foreignPivotKey );

		if ( isNull( arguments.relatedPivotKey ) ) {
			arguments.relatedPivotKey = related
				.keyNames()
				.map( function( keyName ) {
					return related.entityName() & keyName;
				} );
		}
		arguments.relatedPivotKey = arrayWrap( arguments.relatedPivotKey );

		param arguments.parentKey = keyNames();
		arguments.parentKey       = arrayWrap( arguments.parentKey );

		param arguments.relatedKey = related.keyNames();
		arguments.relatedKey       = arrayWrap( arguments.relatedKey );

		return variables._wirebox.getInstance(
			name          = "BelongsToMany@quick",
			initArguments = {
				"related"            : related,
				"relationName"       : arguments.relationName,
				"relationMethodName" : arguments.relationMethodName,
				"parent"             : this,
				"table"              : arguments.table,
				"foreignPivotKeys"   : arguments.foreignPivotKey,
				"relatedPivotKeys"   : arguments.relatedPivotKey,
				"parentKeys"         : arguments.parentKey,
				"relatedKeys"        : arguments.relatedKey,
				"withConstraints"    : !shouldSkipRelationshipConstraints( arguments.relationMethodName )
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
	private string function generateDefaultPivotTableString( required string tableA, required string tableB ) {
		arguments.tableA = listFirst( arguments.tableA, " " );
		arguments.tableB = listFirst( arguments.tableB, " " );
		return compareNoCase( arguments.tableA, arguments.tableB ) < 0 ? lCase(
			"#arguments.tableA#_#arguments.tableB#"
		) : lCase( "#arguments.tableB#_#arguments.tableA#" );
	}

	/**
	 * Returns a HasManyThrough relationship between this entity and the entities
	 * in the `relationships` array as a chain from left to right.
	 *
	 * @relationships       An array of relationships names.  The relationships
	 *                      are resolved from left to right.  Each relationship
	 *                      will be resolved from the previously resolved relationship,
	 *                      starting with the current entity.
	 *
	 *                      For example, if the entity is a `Country` entity and
	 *                      the relationships array is `[ "users", "posts" ]`
	 *                      then it would call `users()` on Country and `posts`
	 *                      on the result on `Country.users()`.
	 *
	 *                      There must be at least two relationships in the array
	 *                      to use `hasManyThrough`.  Otherwise, just use `hasMany`
	 *                      or `belongsToMany`.
	 * @relationMethodName  The method name called to retrieve this relationship.
	 *                      Uses a stack backtrace to determine by default.
	 *
	 * @throw               RelationshipsLengthMismatch
	 *
	 * @return              quick.models.Relationships.HasManyThrough
	 */
	private HasManyDeep function hasManyThrough(
		required array relationships,
		string relationMethodName,
		boolean nested
	) {
		if ( arguments.relationships.len() <= 1 ) {
			throw(
				type    = "RelationshipsLengthMismatch",
				message = "A hasManyThrough relationship must have at least two relationships." &
				"If you only need one, use `hasMany` or `belongsToMany` instead."
			);
		}

		param arguments.relationMethodName = lCase( callStackGet()[ 2 ][ "Function" ] );
		arguments.nested                   = shouldSkipRelationshipConstraints( arguments.relationMethodName );

		guardAgainstNotLoaded(
			"This instance is not loaded so it cannot access the [#arguments.relationMethodName#] relationship.  Either load the entity from the database using a query executor (like `first`) or base your query off of the [#arguments.relationships[ arguments.relationships.len() ]#] entity directly and use the `has` or `whereHas` methods to constrain it based on data in [#entityName()#]."
		);

		var related     = "";
		var parent      = this;
		var through     = [];
		var foreignKeys = [];
		var localKeys   = [];

		var predecessor = this;
		for ( var i = 1; i <= arguments.relationships.len(); i++ ) {
			var relationName = arguments.relationships[ i ];
			var relationship = predecessor.ignoreLoadedGuard( function() {
				return predecessor.withoutRelationshipConstraints( relationName, function() {
					return invoke( predecessor, relationName );
				} );
			} );

			// TODO: need a better way to ensure uniqueness
			param request.loopCount = 1;
			var newAlias            = "#relationName#_#request.loopCount++#";
			relationship.withAlias( newAlias );

			var updatedArgs = relationship.appendToDeepRelationship( through, foreignKeys, localKeys, i );
			through         = updatedArgs.through;
			foreignKeys     = updatedArgs.foreignKeys;
			localKeys       = updatedArgs.localKeys;

			if ( i == arguments.relationships.len() ) {
				related = relationship.getRelationshipBuilder();
			} else {
				through.append( relationship.getRelationshipBuilder() );
				predecessor = relationship.getRelated();
			}
		}

		return this.ignoreLoadedGuard( function() {
			return hasManyDeep(
				relationName       = related,
				through            = through,
				foreignKeys        = foreignKeys,
				localKeys          = localKeys,
				relationMethodName = relationMethodName,
				nested             = nested
			);
		} );
	}

	/**
	 * Returns a HasOneThrough relationship between this entity and the entities
	 * in the `relationships` array as a chain from left to right.
	 *
	 * @relationships       An array of relationships names.  The relationships
	 *                      are resolved from left to right.  Each relationship
	 *                      will be resolved from the previously resolved relationship,
	 *                      starting with the current entity.
	 *
	 *                      For example, if the entity is a `Post` entity and
	 *                      the relationships array is `[ "author", "country" ]`
	 *                      then it would call `author()` on Post and `country`
	 *                      on the result on `Post.author()`.
	 *
	 *                      There must be at least two relationships in the array
	 *                      to use `hasOneThrough`.  Otherwise, just use `hasOne`.
	 * @relationMethodName  The method name called to retrieve this relationship.
	 *                      Uses a stack backtrace to determine by default.
	 *
	 * @throw               RelationshipsLengthMismatch
	 *
	 * @return              quick.models.Relationships.HasOneThrough
	 */
	private HasOneThrough function hasOneThrough( required array relationships, string relationMethodName ) {
		if ( arguments.relationships.len() <= 1 ) {
			throw(
				type    = "RelationshipsLengthMismatch",
				message = "A hasOneThrough relationship must have at least two relationships." &
				"If you only need one, use `hasOne` instead."
			);
		}

		param arguments.relationMethodName = lCase( callStackGet()[ 2 ][ "Function" ] );

		guardAgainstNotLoaded(
			"This instance is not loaded so it cannot access the [#arguments.relationMethodName#] relationship.  Either load the entity from the database using a query executor (like `first`) or base your query off of the [#arguments.relationships[ arguments.relationships.len() ]#] entity directly and use the `has` or `whereHas` methods to constrain it based on data in [#entityName()#]."
		);

		// this is set here for the first case where the previousEntity is
		// `this` entity and we don't want to double prefix
		var aliasPrefix      = variables._aliasPrefix;
		var previousEntity   = this;
		var relationshipsMap = arguments.relationships.reduce( function( map, relation, index ) {
			var mirroredIndex = relationships.len() == 2 ? ( index == 1 ? 2 : 1 ) : ( index + ( relationships.len() - 1 ) ) % (
				relationships.len() + 1
			);
			mirroredIndex = mirroredIndex == 0 ? index : mirroredIndex;
			previousEntity.set_aliasPrefix( aliasPrefix & mirroredIndex & "_" );
			var relationship = previousEntity.ignoreLoadedGuard( function() {
				return invoke( previousEntity, relation );
			} );
			relationship.applyAliasSuffix( "_" & aliasPrefix & mirroredIndex );
			map[ relation ] = relationship;
			previousEntity  = relationship.getRelated();
			return map;
		}, structNew( "ordered" ) );

		return variables._wirebox.getInstance(
			name          = "HasOneThrough@quick",
			initArguments = {
				"related"            : relationshipsMap[ relationships[ relationships.len() ] ].getRelated(),
				"relationName"       : relationships[ relationships.len() ],
				"relationMethodName" : arguments.relationMethodName,
				"parent"             : this,
				"relationships"      : arguments.relationships,
				"relationshipsMap"   : relationshipsMap,
				"withConstraints"    : !shouldSkipRelationshipConstraints( arguments.relationMethodName )
			}
		);
	}

	/**
	 * Returns a BelongsToThrough relationship between this entity and the entities
	 * in the `relationships` array as a chain from left to right.
	 *
	 * @relationships       An array of relationships names.  The relationships
	 *                      are resolved from left to right.  Each relationship
	 *                      will be resolved from the previously resolved relationship,
	 *                      starting with the current entity.
	 *
	 *                      For example, if the entity is a `Post` entity and
	 *                      the relationships array is `[ "author", "country" ]`
	 *                      then it would call `author()` on Post and `country`
	 *                      on the result on `Post.author()`.
	 *
	 *                      There must be at least two relationships in the array
	 *                      to use `belongsToThrough`.  Otherwise, just use `hasOne`.
	 * @relationMethodName  The method name called to retrieve this relationship.
	 *                      Uses a stack backtrace to determine by default.
	 *
	 * @throw               RelationshipsLengthMismatch
	 *
	 * @return              quick.models.Relationships.BelongsToThrough
	 */
	private BelongsToThrough function belongsToThrough( required array relationships, string relationMethodName ) {
		if ( arguments.relationships.len() <= 1 ) {
			throw(
				type    = "RelationshipsLengthMismatch",
				message = "A belongsToThrough relationship must have at least two relationships." &
				"If you only need one, use `belongsTo` instead."
			);
		}

		param arguments.relationMethodName = lCase( callStackGet()[ 2 ][ "Function" ] );

		guardAgainstNotLoaded(
			"This instance is not loaded so it cannot access the [#arguments.relationMethodName#] relationship.  Either load the entity from the database using a query executor (like `first`) or base your query off of the [#arguments.relationships[ arguments.relationships.len() ]#] entity directly and use the `has` or `whereHas` methods to constrain it based on data in [#entityName()#]."
		);

		// this is set here for the first case where the previousEntity is
		// `this` entity and we don't want to double prefix
		var aliasPrefix      = variables._aliasPrefix;
		var previousEntity   = this;
		var relationshipsMap = arguments.relationships.reduce( function( map, relation, index ) {
			var mirroredIndex = relationships.len() == 2 ? ( index == 1 ? 2 : 1 ) : ( index + ( relationships.len() - 1 ) ) % (
				relationships.len() + 1
			);
			mirroredIndex = mirroredIndex == 0 ? index : mirroredIndex;
			previousEntity.set_aliasPrefix( aliasPrefix & mirroredIndex & "_" );
			var relationship = previousEntity.ignoreLoadedGuard( function() {
				return invoke( previousEntity, relation );
			} );
			relationship.applyAliasSuffix( "_" & aliasPrefix & mirroredIndex );
			map[ relation ] = relationship;
			previousEntity  = relationship.getRelated();
			return map;
		}, structNew( "ordered" ) );

		param arguments.relationMethodName = lCase( callStackGet()[ 2 ][ "Function" ] );

		return variables._wirebox.getInstance(
			name          = "BelongsToThrough@quick",
			initArguments = {
				"related"            : relationshipsMap[ relationships[ relationships.len() ] ].getRelated(),
				"relationName"       : relationships[ relationships.len() ],
				"relationMethodName" : arguments.relationMethodName,
				"parent"             : this,
				"relationships"      : arguments.relationships,
				"relationshipsMap"   : relationshipsMap,
				"withConstraints"    : !shouldSkipRelationshipConstraints( arguments.relationMethodName )
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
	 *                      Uses a stack backtrace to determine by default.
	 *
	 * @return              quick.models.Relationships.PolymorphicHasMany
	 */
	private PolymorphicHasMany function polymorphicHasMany(
		required string relationName,
		required string name,
		string type,
		any id,
		any localKey,
		string relationMethodName
	) {
		param arguments.relationMethodName = lCase( callStackGet()[ 2 ][ "Function" ] );

		guardAgainstNotLoaded(
			"This instance is not loaded so it cannot access the [#arguments.relationMethodName#] relationship.  Either load the entity from the database using a query executor (like `first`) or base your query off of the [#arguments.relationName#] entity directly and use the `has` or `whereHas` methods to constrain it based on data in [#entityName()#]."
		);

		var related = variables._wirebox.getInstance( arguments.relationName );

		param arguments.type     = arguments.name & "_type";
		param arguments.id       = arguments.name & "_id";
		arguments.id             = arrayWrap( arguments.id );
		param arguments.localKey = keyNames();
		arguments.localKey       = arrayWrap( arguments.localKey );

		return variables._wirebox.getInstance(
			name          = "PolymorphicHasMany@quick",
			initArguments = {
				"related"            : related,
				"relationName"       : arguments.relationName,
				"relationMethodName" : arguments.relationMethodName,
				"parent"             : this,
				"type"               : arguments.type,
				"ids"                : arguments.id,
				"localKeys"          : arguments.localKey,
				"withConstraints"    : !shouldSkipRelationshipConstraints( arguments.relationMethodName )
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
	 * WHERE posts.id [localKey] = 'comments.commentable_id' [id]
	 * ```
	 *
	 * @name                The name given to the polymorphic relationship.  Defaults to `relationMethodName`.
	 * @type                The column name that defines the type of the polymorphic relationship. Defaults to `#name#_type`.
	 * @id                  The column name that defines the id of the polymorphic relationship. Defaults to `#name#_id`.
	 * @localKey            The column name on the `realted` entity that is referred to by the `foreignKey` of the `parent` entity.
	 * @relationMethodName  The method name called to retrieve this relationship. Uses a stack backtrace to determine by default.
	 *
	 * @return              quick.models.Relationships.PolymorphicBelongsTo
	 */
	private PolymorphicBelongsTo function polymorphicBelongsTo(
		string name,
		string type,
		any id,
		any localKey,
		string relationMethodName
	) {
		param arguments.relationMethodName = lCase( callStackGet()[ 2 ][ "Function" ] );
		param arguments.name               = arguments.relationMethodName;

		guardAgainstNotLoaded(
			"This instance is not loaded so it cannot access the [#arguments.relationMethodName#] relationship.  Either load the entity from the database using a query executor (like `first`) or base your query off of the related polymorphic entity directly and use the `has` or `whereHas` methods to constrain it based on data in [#entityName()#]."
		);

		param arguments.type = arguments.name & "_type";
		param arguments.id   = arguments.name & "_id";
		arguments.id         = arrayWrap( arguments.id );

		var relationName = retrieveAttribute( arguments.type, "" );
		if ( relationName == "" ) {
			return variables._wirebox.getInstance(
				name          = "PolymorphicBelongsTo@quick",
				initArguments = {
					"related"            : this.resetQuery(),
					"relationName"       : relationName,
					"relationMethodName" : arguments.relationMethodName,
					"parent"             : this,
					"foreignKeys"        : arguments.id,
					"localKeys"          : [],
					"type"               : arguments.type,
					"withConstraints"    : !shouldSkipRelationshipConstraints( arguments.relationMethodName )
				}
			);
		}

		var related              = variables._wirebox.getInstance( relationName );
		param arguments.localKey = related.keyNames();
		arguments.localKey       = arrayWrap( arguments.localKey );

		return variables._wirebox.getInstance(
			name          = "PolymorphicBelongsTo@quick",
			initArguments = {
				"related"            : related,
				"relationName"       : relationName,
				"relationMethodName" : arguments.name,
				"parent"             : this,
				"foreignKeys"        : arguments.id,
				"localKeys"          : arguments.localKey,
				"type"               : arguments.type,
				"withConstraints"    : !shouldSkipRelationshipConstraints( arguments.relationMethodName )
			}
		);
	}

	public HasManyDeep function hasManyDeep(
		required any relationName,
		required array through,
		required array foreignKeys,
		required array localKeys,
		boolean nested = false,
		string relationMethodName
	) {
		param arguments.relationMethodName = lCase( callStackGet()[ 2 ][ "Function" ] );

		var related = "";
		if ( isClosure( arguments.relationName ) || isCustomFunction( arguments.relationName ) ) {
			related = arguments.relationName();
		} else if ( !isSimpleValue( arguments.relationName ) ) {
			related = arguments.relationName;
		} else {
			var parts = arguments.relationName.split( "\s(?:[Aa][Ss]\s)?" );
			related   = variables._wirebox.getInstance( trim( parts[ 1 ] ) );
			if ( arrayLen( parts ) > 1 ) {
				related.withAlias( trim( parts[ 2 ] ) );
			}
		}

		if ( !structKeyExists( related, "isBuilder" ) ) {
			related = related.newQuery();
		}

		guardAgainstNotLoaded(
			"This instance is not loaded so it cannot access the [#arguments.relationMethodName#] relationship.  Either load the entity from the database using a query executor (like `first`) or base your query off of the [#related.getEntity().entityName()#] entity directly and use the `has` or `whereHas` methods to constrain it based on data in [#entityName()#]."
		);

		var throughParents = arguments.through.map( function( throughEntityName ) {
			var throughEntity = "";
			if ( isClosure( throughEntityName ) || isCustomFunction( throughEntityName ) ) {
				throughEntity = throughEntityName();
			} else if ( !isSimpleValue( throughEntityName ) ) {
				throughEntity = throughEntityName;
			} else {
				var parts = throughEntityName.split( "\s(?:[Aa][Ss]\s)?" );
				if ( variables._wirebox.containsInstance( trim( parts[ 1 ] ) ) ) {
					throughEntity = variables._wirebox.getInstance( trim( parts[ 1 ] ) );
					if ( arrayLen( parts ) > 1 ) {
						throughEntity.withAlias( trim( parts[ 2 ] ) );
					}
				} else {
					// turn parts into a CFML array
					throughEntity = variables._wirebox.getInstance( "PivotTable@quick" )
					throughEntity.setTable( trim( parts[ 1 ] ) );
					if ( arrayLen( parts ) > 1 ) {
						throughEntity.withAlias( trim( parts[ 2 ] ) );
					}
				}
			}

			if ( !structKeyExists( throughEntity, "isBuilder" ) ) {
				throughEntity = throughEntity.newQuery();
			}

			return throughEntity;
		} );

		return variables._wirebox.getInstance(
			name          = "HasManyDeep@quick",
			initArguments = {
				"related"            : related,
				"relationName"       : related.getEntity().entityName(),
				"relationMethodName" : arguments.relationMethodName,
				"parent"             : this,
				"throughParents"     : throughParents,
				"foreignKeys"        : arguments.foreignKeys,
				"localKeys"          : arguments.localKeys,
				"nested"             : arguments.nested,
				"withConstraints"    : !shouldSkipRelationshipConstraints( arguments.relationMethodName )
			}
		);
	}

	private HasManyDeepBuilder function newHasManyDeepBuilder( string relationMethodName ) {
		param arguments.relationMethodName = lCase( callStackGet()[ 2 ][ "Function" ] );
		return variables._wirebox.getInstance(
			"HasManyDeepBuilder@quick",
			{
				"parent"             : this,
				"relationMethodName" : arguments.relationMethodName
			}
		);
	}

	/*=======================================
    =            QB Utilities            =
    =======================================*/

	/**
	 * Configures a new query builder and returns it.
	 *
	 * @return  quick.models.QuickBuilder
	 */
	public any function newQuery() {
		var newBuilder = variables._wirebox
			.getInstance( "QuickBuilder@quick" )
			.setEntity( this )
			.setReturnFormat( "array" )
			.set_preventLazyLoading( variables._preventLazyLoading )
			.set_lazyLoadingViolationCallback( variables._lazyLoadingViolationCallback )
			.mergeDefaultOptions( variables._queryOptions )
			.from( tableName() )
			.addSelect( retrieveQualifiedColumns() )
			.with( variables._with );

		if ( variables._meta.originalMetadata.keyExists( "grammar" ) ) {
			newBuilder.setGrammar( variables._wirebox.getInstance( variables._meta.originalMetadata.grammar ) );
		}

		newBuilder.applyInheritanceJoins();

		return newBuilder;
	}

	/**
	 * Checks if an entity is another entity.
	 *
	 * @otherEntity  The entity to compare.
	 *
	 * @return       Boolean
	 */
	public boolean function isSameAs( required any otherEntity ) {
		if ( entityName() != arguments.otherEntity.entityName() ) {
			return false;
		}

		if ( tableName() != arguments.otherEntity.tableName() ) {
			return false;
		}

		return keyValues().reduce( function( same, value, i ) {
			if ( !same ) {
				return false;
			}
			return value == otherEntity.keyValues()[ i ];
		}, true );
	}

	/**
	 * Returns true if an entity is not another entity.
	 *
	 * @otherEntity  The entity to check.
	 *
	 * @return       Boolean
	 */
	public boolean function isNotSameAs( required any otherEntity ) {
		return !isSameAs( arguments.otherEntity );
	}

	/*=====================================
    =            Magic Methods            =
    =====================================*/

	/**
	 * Quick tries a lot of things when encountering a missing method.
	 * Here they are in order:
	 *
	 * 1. `get{missingMethodName}` methods.
	 * 2. `set{missingMethodName}` methods
	 * 3. `scope{missingMethodName}` methods
	 * 4. Relationship getters
	 * 5. Relationship setters
	 * 6. Forwarding the method call to qb
	 *
	 * If none of those steps are successful, it throws a `QuickMissingMethod` exception.
	 *
	 * @missingMethodName       The method name that is missing.
	 * @missingMethodArguments  The arguments passed to the missing method call.
	 *
	 * @throws                  QuickMissingMethod
	 *
	 * @return                  any
	 */
	public any function onMissingMethod( required string missingMethodName, struct missingMethodArguments = {} ) {
		var columnValue = tryAttributeAccessor( arguments.missingMethodName, arguments.missingMethodArguments );
		if ( !isNull( columnValue ) ) {
			return columnValue;
		}
		var rg = tryRelationshipGetter( arguments.missingMethodName, arguments.missingMethodArguments );
		if ( !isNull( rg ) ) {
			return rg;
		}
		var rs = tryRelationshipSetter( arguments.missingMethodName, arguments.missingMethodArguments );
		if ( !isNull( rs ) ) {
			return rs;
		}
		if ( relationshipIsNull( arguments.missingMethodName ) ) {
			return javacast( "null", "" );
		}

		try {
			return forwardToQB( arguments.missingMethodName, arguments.missingMethodArguments );
		} catch ( QBMissingMethod e ) {
			throw(
				type    = "QuickMissingMethod",
				message = arrayToList(
					[
						"Quick couldn't figure out what to do with [#arguments.missingMethodName#].",
						"The error returned was: #e.message#",
						"We tried checking columns, aliases, scopes, and relationships locally.",
						"We also forwarded the call on to qb to see if it could do anything with it, but it couldn't."
					],
					" "
				),
				extendedInfo = serializeJSON( e )
			);
		}
	}

	/**
	 * Attempts to use a attribute getter or setter.
	 *
	 * @missingMethodName       The potential attribute name.
	 * @missingMethodArguments  The arguments passed to the missing method call.
	 *
	 * @return                  any
	 */
	private any function tryAttributeAccessor( required string missingMethodName, struct missingMethodArguments = {} ) {
		var getAttributeValue = tryAttributeGetter( arguments.missingMethodName );
		if ( !isNull( getAttributeValue ) ) {
			return getAttributeValue;
		}
		var setAttributeValue = tryAttributeSetter( arguments.missingMethodName, arguments.missingMethodArguments );
		if ( !isNull( setAttributeValue ) ) {
			return this;
		}
		return;
	}

	/**
	 * Attempts to retrieve the value of a potential attribute.
	 *
	 * @missingMethodName  The potential attribute name.
	 *
	 * @return             any
	 */
	private any function tryAttributeGetter( required string missingMethodName ) {
		if ( !variables._str.startsWith( arguments.missingMethodName, "get" ) ) {
			return;
		}

		var columnName = variables._str.slice( arguments.missingMethodName, 4 );

		if ( hasAttribute( columnName ) || variables._casts.keyExists( columnName ) ) {
			return retrieveAttribute( retrieveColumnForAlias( columnName ) );
		}

		return;
	}

	/**
	 * Attempts to set the missing method arguments as the value of an attribute.
	 *
	 * @missingMethodName       The potential attribute name.
	 * @missingMethodArguments  Any arguments to pass to set for the potential attribute.
	 */
	private any function tryAttributeSetter( required string missingMethodName, struct missingMethodArguments = {} ) {
		if ( !variables._str.startsWith( arguments.missingMethodName, "set" ) ) {
			return;
		}

		var columnName = variables._str.slice( arguments.missingMethodName, 4 );
		if ( !hasAttribute( columnName ) && !variables._casts.keyExists( columnName ) ) {
			return;
		}
		assignAttribute( columnName, arguments.missingMethodArguments[ 1 ] );
		return this;
	}

	/**
	 * Attempts to retrieve a relationship and executes it.
	 *
	 * @missingMethodName       The potential relationship name.
	 * @missingMethodArguments  Any arguments to pass to the potential relationship.
	 *
	 * @return                  any
	 */
	private any function tryRelationshipGetter( required string missingMethodName, struct missingMethodArguments = {} ) {
		if ( !variables._str.startsWith( arguments.missingMethodName, "get" ) ) {
			return;
		}

		var relationshipName = variables._str.slice( arguments.missingMethodName, 4 );

		if ( !hasRelationship( relationshipName ) ) {
			return;
		}

		if ( !isRelationshipLoaded( relationshipName ) && variables._preventLazyLoading ) {
			variables._lazyLoadingViolationCallback( this, relationshipName );
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

	/**
	 * Attempts to save a new relation to a relationship.
	 *
	 * @missingMethodName       The potential relationship name.
	 * @missingMethodArguments  Any arguments to pass to the potential relationship.
	 *
	 * @return                  any
	 */
	private any function tryRelationshipSetter( required string missingMethodName, struct missingMethodArguments = {} ) {
		if ( !variables._str.startsWith( arguments.missingMethodName, "set" ) ) {
			return;
		}

		var relationshipName = variables._str.slice( arguments.missingMethodName, 4 );

		if ( !hasRelationship( relationshipName ) ) {
			return;
		}

		var relationship = ignoreLoadedGuard( function() {
			return invoke( this, relationshipName );
		} );

		if (
			relationship.relationshipClass != "BelongsTo" &&
			relationship.relationshipClass != "PolymorphicBelongsTo"
		) {
			guardAgainstNotLoaded(
				"This instance is not loaded so it cannot set the [#relationshipName#] relationship.  " &
				"Save the new entity first before trying to save related entities."
			);
		}

		clearRelationship( relationshipName );

		return relationship.applySetter( argumentCollection = arguments.missingMethodArguments );
	}

	/**
	 * Checks if a relationship exists but is unloaded.
	 *
	 * @missingMethodName  The potential relationship name.
	 *
	 * @return             Boolean
	 */
	private boolean function relationshipIsNull( required string missingMethodName ) {
		if ( !variables._str.startsWith( arguments.missingMethodName, "get" ) ) {
			return false;
		}
		return variables._relationshipsLoaded.keyExists( variables._str.slice( arguments.missingMethodName, 4 ) );
	}

	/**
	 * Attempts to call a query scope on the entity.
	 *
	 * @missingMethodName       The potential scope name.
	 * @missingMethodArguments  Any arguments to pass to the potential scope.
	 *
	 * @return                  any
	 */
	public any function tryScopes(
		required string missingMethodName,
		struct missingMethodArguments = {},
		any builder                   = this,
		array exclusions              = []
	) {
		if ( !structKeyExists( variables, "scope#arguments.missingMethodName#" ) ) {
			return;
		}

		if ( arrayContains( arguments.exclusions, lCase( arguments.missingMethodName ) ) ) {
			return this;
		}

		var scopeArgs = { "1" : arguments.builder };
		// this is to allow default arguments to be set for scopes
		if ( !structIsEmpty( arguments.missingMethodArguments ) ) {
			for ( var i = 1; i <= structCount( arguments.missingMethodArguments ); i++ ) {
				scopeArgs[ i + 1 ] = arguments.missingMethodArguments[ i ];
			}
		}
		var result = javacast( "null", "" );

		arguments.builder.withScoping( function() {
			result = invoke(
				this,
				"scope#missingMethodName#",
				scopeArgs
			);
		} );

		return isNull( result ) ? arguments.builder : result;
	}

	/**
	 * Lifecycle function to apply global scopes to the entity.
	 * It is expected to override this method in your entity if you
	 * need to specify global scopes to load.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function applyGlobalScopes() {
		return this;
	}


	/**
	 * If the quickbuilder instance exists return it, else create it, cache it and return it
	 *
	 * @return  quick.models.QuickBuilder
	 */
	public QuickBuilder function getQuickBuilder() {
		if ( !isDefined( "variables._quickBuilder" ) ) {
			variables._quickBuilder = newQuery();
		}

		return variables._quickBuilder;
	}

	/**
	 * Forwards a missing method call on to qb.
	 *
	 * @missingMethodName       The potential scope name.
	 * @missingMethodArguments  Any arguments to pass to the potential scope.
	 *
	 * @return                  any
	 */
	private any function forwardToQB( required string missingMethodName, struct missingMethodArguments = {} ) {
		return invoke(
			// create the builder instance if it has not be instantiated yet
			getQuickBuilder(),
			arguments.missingMethodName,
			arguments.missingMethodArguments
		);
	}

	/**
	 * Returns a new collection of the given entities.
	 * It is expected to override this method in your entity if you
	 * need to specify a different collection to return.
	 *
	 * You can also call this method with no arguments to get
	 * an empty collection.
	 *
	 * @entities  The array of entities returned by the query.
	 *
	 * @return    any
	 */
	public any function newCollection( array entities = [] ) {
		return arguments.entities;
	}

	/**
	 * Set up the memento struct for mementifier.
	 *
	 * @return  void
	 */
	private void function setUpMementifier() {
		param this.memento = {};
		var defaults       = {
			"defaultIncludes" : retrieveAttributeNames( withVirtualAttributes = true ),
			"defaultExcludes" : [],
			"neverInclude"    : [],
			"defaults"        : {},
			"mappers"         : {},
			"trustedGetters"  : true,
			"ormAutoIncludes" : false
		};
		structAppend( defaults, this.memento, true );
		this.memento = defaults;
	}

	/**
	 * Special ColdBox method that is called and rendered if this component
	 * is returned from a handler action method.
	 *
	 * @return  struct
	 */
	public struct function $renderdata() {
		return getMemento();
	}

	/*=======================================
    =            Other Utilities            =
    =======================================*/

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

	/**
	 * Inspects the entity for the required metadata information.
	 * Quick uses a lot of metadata about the entity to do its job.
	 * Since metadata inspection can be expensive (especially inherited
	 * metadata), Quick tries to keep the original metadata around
	 * through creating new entities and executing queries.
	 */
	private void function metadataInspection() {
		param variables._table = variables._str.plural( variables._str.snake( listFirst( variables._mapping, "@" ) ) );

		if ( !isStruct( variables._meta ) || structIsEmpty( variables._meta ) ) {
			variables._meta = duplicate(
				variables._cache.getOrSet( "quick-metadata:#variables._mapping#", function() {
					var util                   = variables._wirebox.getUtility();
					var meta                   = {};
					meta[ "originalMetadata" ] = util.getInheritedMetadata( this );
					meta[ "localMetadata" ]    = getMetadata( this );
					if (
						!meta[ "localMetadata" ].keyExists( "accessors" ) ||
						meta[ "localMetadata" ].accessors == false
					) {
						throw(
							type    = "QuickAccessorsMissing",
							message = 'This instance is missing `accessors="true"` in the component metadata.  This is required for Quick to work properly.  Please add it to your component metadata and reinit your application.'
						);
					}
					meta[ "fullName" ]                                 = meta.originalMetadata.fullname;
					param meta.originalMetadata.mapping                = listLast( meta.originalMetadata.fullname, "." );
					meta[ "mapping" ]                                  = meta.originalMetadata.mapping;
					param meta.originalMetadata.entityName             = listLast( meta.originalMetadata.name, "." );
					meta[ "entityName" ]                               = meta.originalMetadata.entityName;
					param meta.originalMetadata.table                  = variables._str.plural( variables._str.snake( meta.entityName ) );
					meta[ "table" ]                                    = meta.originalMetadata.table;
					param meta.originalMetadata.readonly               = false;
					meta[ "readonly" ]                                 = meta.originalMetadata.readonly;
					param meta.originalMetadata.joincolumn             = "";
					param meta.originalMetadata.discriminatorValue     = "";
					param meta.originalMetadata.singleTableInheritance = false;
					param meta.originalMetadata.extends                = "";
					param meta.originalMetadata.functions              = [];
					meta[ "hasParentEntity" ]                          = !!len( meta.originalMetadata.joincolumn );
					if ( meta.hasParentEntity ) {
						var reference = variables._wirebox.getInstance(
							name          = meta.localMetadata.extends.fullName,
							initArguments = { "meta" : {}, "shallow" : true }
						);

						meta[ "parentDefinition" ] = {
							"meta"       : reference.get_Meta(),
							"key"        : reference.keyNames()[ 1 ],
							"joincolumn" : meta.originalMetadata.joincolumn
						};

						if ( len( meta.originalMetadata.discriminatorValue ) ) {
							try {
								var parentMeta                                 = getComponentMetadata( meta.parentDefinition.meta.fullName );
								meta.parentDefinition[ "discriminatorValue" ]  = meta.originalMetadata.discriminatorValue;
								meta.parentDefinition[ "discriminatorColumn" ] = parentMeta.discriminatorColumn;
							} catch ( any e ) {
								throw(
									type    = "QuickChildInstantiationException",
									message = "Failed to instantiate child entity [#meta.fullName#]. This may be due to a configuration error in the parent/child relationships. The root cause was #e.message#",
									detail  = e.detail
								);
							}
						}
					}

					var baseEntityFunctionNames = variables._cache.getOrSet( "quick-metadata:BaseEntity", function() {
						return arrayReduce(
							getComponentMetadata( "quick.models.BaseEntity" ).functions,
							function( acc, func ) {
								arguments.acc[ arguments.func.name ] = "";
								return arguments.acc;
							},
							{}
						);
					} );
					meta[ "functionNames" ] = generateFunctionNameArray(
						from    = meta.originalMetadata.functions,
						without = baseEntityFunctionNames
					);

					param meta.originalMetadata.properties = [];

					meta[ "attributes" ] = generateAttributesFromProperties(
						meta.hasParentEntity ? meta.localMetadata.properties : meta.originalMetadata.properties
					);
					if ( structKeyExists( meta.localMetadata, "discriminatorColumn" ) ) {
						meta.attributes[ meta.localMetaData.discriminatorColumn ] = paramAttribute( { "name" : meta.localMetaData.discriminatorColumn } );
					}
					arrayWrap( variables._key ).each( function( key ) {
						if ( !meta.attributes.keyExists( key ) ) {
							var keyProp                     = paramAttribute( { "name" : key } );
							meta.attributes[ keyProp.name ] = keyProp;
						}
					} );
					meta[ "casts" ] = generateCastsFromProperties( meta.originalMetadata.properties );
					guardKeyHasNoDefaultValue( meta.attributes );
					return meta;
				} )
			);
		}

		variables._fullName        = variables._meta.fullName;
		variables._entityName      = variables._meta.entityName;
		variables._table           = variables._meta.table;
		variables._hasParentEntity = variables._meta.hasParentEntity;

		if ( variables._hasParentEntity ) {
			variables._parentDefinition = variables._meta.parentDefinition;
			variables._key              = variables._parentDefinition.joincolumn;
		}

		param variables._queryOptions = {};
		if ( variables._queryOptions.isEmpty() && variables._meta.originalMetadata.keyExists( "datasource" ) ) {
			variables._queryOptions = { datasource : variables._meta.originalMetadata.datasource };
		}
		variables._readonly = variables._meta.readonly;
		explodeAttributesMetadata( variables._meta.attributes );
		variables._casts = variables._meta.casts;
	}

	/**
	 * Creates an array of all the function names in the metadata.
	 *
	 * @functions    An array of function definitions.
	 *
	 * @doc_generic  String
	 * @return       [String]
	 */
	private array function generateFunctionNameArray( required array from, struct without = {} ) {
		return arguments.from.reduce( function( acc, func ) {
			if ( !without.keyExists( func.name ) ) {
				acc.append( func.name );
			}
			return acc;
		}, [] );
	}

	/**
	 * Creates an internal attribute struct for each persistent property
	 * on the entity.
	 *
	 * @properties  The array of properties on the entity.
	 *
	 * @return      A struct of attributes for the entity.
	 */
	private struct function generateAttributesFromProperties( required array properties ) {
		return arguments.properties.reduce( function( acc, prop ) {
			var newProp = paramAttribute( arguments.prop );
			if ( !newProp.persistent ) {
				return arguments.acc;
			}
			arguments.acc[ newProp.name ] = newProp;
			return arguments.acc;
		}, {} );
	}

	private struct function generateCastsFromProperties( required array properties ) {
		return arguments.properties.reduce( function( acc, prop ) {
			if ( !arguments.prop.keyExists( "casts" ) || arguments.prop.casts == "" ) {
				return arguments.acc;
			}
			arguments.acc[ arguments.prop.name ] = arguments.prop.casts;
			return arguments.acc;
		}, {} );
	}

	/**
	 * Creates a virtual attribute for the given name.
	 *
	 * @name    The attribute name to create.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function appendVirtualAttribute( required string name, boolean excludeFromMemento = false ) {
		if ( !variables._attributes.keyExists( retrieveAliasForColumn( arguments.name ) ) ) {
			var attr = paramAttribute( {
				"name"    : arguments.name,
				"virtual" : true,
				"exclude" : arguments.excludeFromMemento
			} );
			variables._attributes[ attr.name ]           = attr;
			variables._columns[ attr.column ]            = attr;
			variables._meta.attributes[ arguments.name ] = variables._attributes[ arguments.name ];
			variables._meta.originalMetadata.properties.append( variables._attributes[ arguments.name ] );
			variables._virtualAttributes.append( arguments.name );
		}
		return this;
	}

	public any function addSubselect( required string name, required any subselect ) {
		return getQuickBuilder().addSubselect( argumentCollection = arguments );
	}

	public boolean function isVirtualAttribute( name ) {
		return variables._attributes.keyExists( retrieveAliasForColumn( arguments.name ) ) &&
		variables._attributes[ retrieveAliasForColumn( arguments.name ) ].virtual;
	}

	public boolean function isParentAttribute( required string column ) {
		return variables._attributes[ retrieveAliasForColumn( arguments.column ) ].isParentColumn;
	}

	/**
	 * Creates the internal attribute struct from an existing struct.
	 * The only required field on the passed in struct is `name`.
	 *
	 * @prop    The attribute struct to param.
	 *
	 * @return  An attribute struct with all the keys needed.
	 */
	private struct function paramAttribute( required struct attr ) {
		param attr.column                  = arguments.attr.name;
		param attr.persistent              = true;
		param attr.nullValue               = "";
		param attr.convertToNull           = true;
		param attr.casts                   = "";
		param attr.readOnly                = false;
		param attr.sqltype                 = "";
		param attr.insert                  = true;
		param attr.update                  = true;
		param attr.virtual                 = false;
		param attr.exclude                 = false;
		param attr.isParentColumn          = false;
		variables._nullValues[ attr.name ] = attr.nullValue;
		return arguments.attr;
	}

	/**
	 * Sets up some other helper structs for Quick to quickly check metadata.
	 *
	 * @attributes  The attributes to explode
	 */
	private any function explodeAttributesMetadata( required struct attributes ) {
		for ( var alias in arguments.attributes ) {
			var attr                           = paramAttribute( arguments.attributes[ alias ] );
			variables._attributes[ attr.name ] = attr;
			variables._columns[ attr.column ]  = attr;
			if ( attr.convertToNull ) {
				variables._nullValues[ alias ] = attr.nullValue;
			}
		}

		if ( hasParentEntity() ) {
			explodeParentAttributes();
		}

		return this;
	}

	/*=================================
    =       Subclass Inheritance      =
    =================================*/

	public boolean function hasParentEntity() {
		return variables._hasParentEntity;
	}

	public boolean function isDiscriminatedChild() {
		return hasParentEntity() && variables._meta.localMetadata.keyExists( "discriminatorValue" );
	}

	public boolean function isDiscriminatedParent() {
		return variables._meta.localMetadata.keyExists( "discriminatorColumn" )
		&& variables._discriminators.len() > 0;
	}

	public function getParentDefinition() {
		return hasParentEntity() ? variables._parentDefinition : javacast( "null", 0 );
	}

	public function getDiscriminations() {
		return variables._cache.getOrSet( "quick-metadata:#variables._mapping#-discriminations", function() {
			return variables._discriminators.reduce( function( acc, dsl ) {
				var childClass = variables._wirebox.getInstance(
					dsl           = dsl,
					initArguments = { "meta" : {}, "shallow" : true }
				);
				var childMeta = childClass.get_Meta().localMetaData;
				// Ensure if polymorphic association that a join column and discriminator value are passed.
				// Can be ignored for singleTableInheritance since there's no join
				if (
					!isSingleTableInheritance() && (
						!structKeyExists( childMeta, "joincolumn" ) ||
						!structKeyExists( childMeta, "discriminatorValue" )
					)
				) {
					throw(
						type    = "QuickParentInstantiationException",
						message = "Failed to instantiate the parent entity [#variables._meta.fullName#]. The discriminated child class [#childMeta.fullName#] did not contain either a `joinColumn` or `discriminatorValue` attribute"
					);
				}
				var childAttributes = childClass
					.get_Attributes()
					.reduce( function( acc, attr, data ) {
						if ( !data.isParentColumn && !data.virtual && !data.exclude ) {
							acc.append( data );
						}
						return acc;
					}, [] );

				var localColumns = this.retrieveQualifiedColumns();
				var childColumns = childClass
					.retrieveQualifiedColumns()
					.filter( function( column ) {
						return !arrayContainsNoCase( localColumns, column );
					} );

				acc[ childMeta.discriminatorValue ] = {
					"mapping"    : childMeta.fullName,
					"table"      : ( childMeta.keyExists( "table" ) ? childMeta.table : variables._meta.table ),
					"joincolumn" : (
						childMeta.keyExists( "joinColumn" ) ? childClass.qualifyColumn(
							column          = childMeta.joinColumn,
							useParentLookup = false
						) : ""
					),
					"attributes"   : childAttributes,
					"childColumns" : childColumns
				};
				return acc;
			}, {} );
		} );
	}

	/**
	 * Appends parent attributes as first class attributes
	 **/
	private function explodeParentAttributes() {
		if ( !hasParentEntity() ) return;

		var parentDefinition = getParentDefinition();

		var attr                           = paramAttribute( { "name" : parentDefinition.joincolumn } );
		variables._attributes[ attr.name ] = variables._attributes[ attr.name ] ?: attr;
		variables._columns[ attr.column ]  = variables._columns[ attr.column ] ?: attr;

		parentDefinition.meta.attributes
			.keyArray()
			.each( function( alias ) {
				// Note: bracket notation here on `attributes` as ACF 2016 will sometimes show a null for the dot notation key
				var duplicateAttr                           = structCopy( parentDefinition.meta[ "attributes" ][ alias ] );
				duplicateAttr.isParentColumn                = true;
				variables._attributes[ duplicateAttr.name ] = duplicateAttr;
				variables._columns[ duplicateAttr.column ]  = duplicateAttr;
			} );

		if ( isDiscriminatedChild() ) {
			var discriminatorAttr = paramAttribute( {
				"name"           : parentDefinition.discriminatorColumn,
				"column"         : parentDefinition.discriminatorColumn,
				"isParentColumn" : true
			} );
			variables._attributes[ discriminatorAttr.name ] = discriminatorAttr;
			variables._columns[ discriminatorAttr.column ]  = discriminatorAttr;
			assignAttribute( parentDefinition.discriminatorColumn, parentDefinition.discriminatorValue );
		}
	}

	/*=================================
    =            Read-Only            =
    =================================*/

	/**
	 * Throws an exception if an entity is marked as read-only
	 *
	 * @throws  QuickReadOnlyException
	 */
	public void function guardReadOnly() {
		if ( isReadOnly() ) {
			throw( type = "QuickReadOnlyException", message = "[#entityName()#] is marked as a read-only entity." );
		}
	}

	/**
	 * Returns true if an entity is marked as read-only.
	 *
	 * @return  Boolean
	 */
	private boolean function isReadOnly() {
		return variables._readonly;
	}

	/**
	 * Throws an exception if any read-only attributes are provided.
	 *
	 * @attributes  The attributes to check if they are read-only.
	 *
	 * @throws      QuickReadOnlyException
	 */
	public void function guardAgainstReadOnlyAttributes( required struct attributes ) {
		for ( var name in arguments.attributes ) {
			guardAgainstReadOnlyAttribute( name );
		}
	}

	/**
	 * Throws an exception if an attribute does not exists on the entity.
	 *
	 * @name    The attribute name to check.
	 *
	 * @throws  AttributeNotFound
	 */
	private void function guardAgainstNonExistentAttribute( required string name ) {
		if ( !hasAttribute( arguments.name ) ) {
			throw(
				type    = "AttributeNotFound",
				message = "The [#arguments.name#] attribute was not found on the [#entityName()#] entity"
			);
		}
	}

	/**
	 * Throws an exception if the provided alias is a read-only attribute.
	 *
	 * @name    The name of the attribute to check.
	 *
	 * @throws  QuickReadOnlyException
	 */
	private void function guardAgainstReadOnlyAttribute( required string name ) {
		if ( isReadOnlyAttribute( arguments.name ) ) {
			throw(
				type    = "QuickReadOnlyException",
				message = "[#arguments.name#] is a read-only property on [#entityName()#]"
			);
		}
	}

	/**
	 * Returns true if an attribute is marked as read-only.
	 *
	 * @name    The name of the attribute to check.
	 *
	 * @return  Boolean
	 */
	private boolean function isReadOnlyAttribute( required string name ) {
		var alias = retrieveAliasForColumn( arguments.name );
		return variables._attributes.keyExists( alias ) &&
		variables._attributes[ alias ].readOnly;
	}

	/**
	 * Throws an exception if the entity does not have any attributes defined.
	 *
	 * @throws  QuickNoAttributesException
	 */
	private void function guardNoAttributes() {
		if ( retrieveAttributeNames().isEmpty() ) {
			throw(
				type    = "QuickNoAttributesException",
				message = "[#entityName()#] does not have any attributes specified."
			);
		}
	}

	/**
	 * Throws an exception if there are no attributes data to insert.
	 *
	 * @attrs   The attributes struct to check.
	 *
	 * @throws  QuickNoAttributesDataException
	 */
	private void function guardEmptyAttributeData( required struct attrs ) {
		if ( arguments.attrs.isEmpty() ) {
			throw(
				type    = "QuickNoAttributesDataException",
				message = "[#entityName()#] does not have any attributes data for insert."
			);
		}
	}

	/**
	 * Throws an exception if the entity is not loaded.
	 *
	 * @errorMessage  The error message to throw.
	 *
	 * @throws        QuickEntityNotLoaded
	 */
	private void function guardAgainstNotLoaded( required string errorMessage ) {
		if ( !variables._ignoreNotLoadedGuard && !isLoaded() ) {
			throw( type = "QuickEntityNotLoaded", message = arguments.errorMessage );
		}
	}

	/**
	 * Ignores the loaded entity guard for the duration of the callback.
	 *
	 * @callback  The callback to run without any loaded entity guarding.
	 */
	public any function ignoreLoadedGuard( required any callback ) {
		variables._ignoreNotLoadedGuard = true;
		try {
			var retval                      = arguments.callback();
			variables._ignoreNotLoadedGuard = false;
			return isNull( retval ) ? javacast( "null", "" ) : retval;
		} finally {
			variables._ignoreNotLoadedGuard = false;
		}
	}

	/**
	 * Throws an exception if the key has a default value.
	 *
	 * @throws  QuickEntityDefaultedKey
	 */
	private void function guardKeyHasNoDefaultValue( required struct attributes ) {
		for ( var keyName in keyNames() ) {
			if ( attributes.keyExists( keyName ) ) {
				if ( attributes[ keyName ].keyExists( "default" ) ) {
					throw(
						type    = "QuickEntityDefaultedKey",
						message = "The key value [#keyName#] has a default value. Default values on keys prevents Quick from working as expected. Remove the default value to continue."
					);
				}
			}
		}
	}

	/**
	 * Throws an exception if the number of values passed in does not
	 * match the number of keys passed in.
	 *
	 * @values  An array of values to check the length matches
	 *
	 * @throws  KeyLengthMismatch
	 *
	 * @return  void
	 */
	public void function guardAgainstKeyLengthMismatch( required array actual, any expectedLength = keyNames().len() ) {
		if ( isArray( arguments.expectedLength ) ) {
			arguments.expectedLength = arguments.expectedLength.len();
		}

		if ( arguments.actual.len() != expectedLength ) {
			throw(
				type    = "KeyLengthMismatch",
				message = "The number of values passed in [#arguments.actual.len()#]" &
				"does not match the number expected [#expectedLength#]."
			);
		}
	}

	/**
	 * Throws an exception if the struct of attributes doesn't contain the keys for this entity.
	 *
	 * @attributes  The key / value pairs to check for the entity's keys.
	 *
	 * @throws  MissingHydrationKey
	 *
	 * @return  void
	 */
	public void function guardAgainstMissingKeys( required struct attributes ) {
		for ( var key in keyNames() ) {
			if ( !arguments.attributes.keyExists( key ) ) {
				throw(
					type    = "MissingHydrationKey",
					message = "An entity cannot be hydrated without its key values.  Missing: #key#"
				);
			}
		}
	}

	/*==============================
    =            Events          =
    ==============================*/

	/**
	 * Fires a Quick lifecycle event.
	 * This will call the lifecycle event on the entity, if it exists.
	 * It will also announce an interception point with the same name
	 * prefixed with `quick`.
	 *
	 * @eventName  The name of the lifecycle event to announce.
	 * @eventData  The data associated with the lifecycle event.
	 */
	public void function fireEvent( required string eventName, struct eventData = {} ) {
		if ( variables._withoutFiringEvents ) {
			return;
		}

		arguments.eventData.entityName = entityName();
		if ( eventMethodExists( arguments.eventName ) ) {
			invoke(
				this,
				arguments.eventName,
				{ eventData : arguments.eventData }
			);
		}
		if ( !isNull( variables._interceptorService ) ) {
			variables._interceptorService.processState( "quick" & arguments.eventName, arguments.eventData );
		}
	}

	/**
	 * Returns true if the event method exists on the entity.
	 *
	 * @eventName  The name of the event being announced.
	 *
	 * @return     Boolean
	 */
	private boolean function eventMethodExists( required string eventName ) {
		return variables.keyExists( arguments.eventName );
	}

	/**
	 * Returns true if an attribute has a defined sql type.
	 *
	 * @name    The name of the attribute to check.
	 *
	 * @return  Boolean
	 */
	public boolean function attributeHasSqlType( required string name ) {
		var alias = retrieveAliasForColumn( arguments.name );
		return variables._attributes.keyExists( alias ) &&
		variables._attributes[ alias ].sqltype != "";
	}

	/**
	 * Returns the sql type for an attribute.
	 *
	 * @name    The name of the attribute to retrieve.
	 *
	 * @return  String
	 */
	public string function retrieveSqlTypeForAttribute( required string name ) {
		var alias = retrieveAliasForColumn( arguments.name );
		return variables._attributes[ alias ].sqltype;
	}

	/**
	 * Returns true if an attribute currently has its configured null value.
	 *
	 * @key     The attribute to check.
	 *
	 * @return  Boolean
	 */
	public boolean function isNullAttribute( required string key ) {
		return isNullValue( key, retrieveAttribute( key ) );
	}

	/**
	 * Checks if a value is considered null for a given key.
	 * This is needed for cases where an empty string is a valid value
	 * for a column.  You can define the null value for a property
	 * to be a custom value.  This function checks if the passed in value
	 * matches the configured null value.
	 *
	 * By default, the null value for a column is an empty string ("").
	 *
	 * @key     The attribute name to check.
	 * @value   The value to check.  If no value is passed, it uses the current value.
	 *
	 * @return  Boolean
	 */
	public boolean function isNullValue( required string key, any value ) {
		if ( !isDefined( "arguments.value" ) ) {
			// There is potential for the value of an attribute to be an actuall null value
			// We must use isDefined instead of cfparam as returning a null value from invoke
			// into the 'default' argument of cfparam will raise an exception
			arguments.value = invoke( this, "get" & arguments.key );
		}

		if ( isNull( arguments.value ) ) {
			return true;
		}

		var alias = retrieveAliasForColumn( arguments.key );
		if ( !isSimpleValue( arguments.value ) ) {
			return false;
		}

		return variables._nullValues.keyExists( alias ) &&
		compare( variables._nullValues[ alias ], arguments.value ) == 0;
	}

	/**
	 * Casts a value when retrieving it as a getter.
	 * Casting values lets you store it in the database in one format,
	 * but use it in your entity as a different.  One example is a boolean
	 * which is stored as a bit in the database.
	 *
	 * @key     The attribute name to check for casts.
	 * @value   The value to potentially cast.
	 *
	 * @return  any
	 */
	private any function castValueForGetter(
		required string key,
		any value,
		boolean forceCast = false
	) {
		arguments.key = retrieveAliasForColumn( arguments.key );

		if ( structKeyExists( variables._castCache, arguments.key ) AND !arguments.forceCast ) {
			return variables._castCache[ arguments.key ];
		}

		if ( !structKeyExists( variables._casts, arguments.key ) ) {
			return arguments.value;
		}

		if ( !isVirtualAttribute( arguments.key ) && isNullValue( arguments.key, arguments.value ) ) {
			return arguments.value;
		}

		var castMapping = variables._casts[ arguments.key ];
		if ( !variables._casterCache.keyExists( arguments.key ) ) {
			variables._casterCache[ arguments.key ] = variables._wirebox.getInstance( dsl = castMapping );
		}
		var caster                            = variables._casterCache[ arguments.key ];
		variables._castCache[ arguments.key ] = caster.get(
			entity = this,
			key    = arguments.key,
			value  = isNull( arguments.value ) ? javacast( "null", "" ) : arguments.value
		);
		return variables._castCache[ arguments.key ];
	}

	/**
	 * Casts a value when setting an attribute.
	 * Casting values lets you store it in the database in one format,
	 * but use it in your entity as a different.  One example is a boolean
	 * which is stored as a bit in the database.
	 *
	 * @key     The attribute name to check for casts.
	 * @value   The value to potentially cast.
	 *
	 * @return  any
	 */
	private any function castValueForSetter( required string key, any value ) {
		if ( isNull( arguments.value ) ) {
			return javacast( "null", "" );
		}

		if ( variables._saving ) {
			return arguments.value;
		}

		if ( isNullValue( arguments.key, arguments.value ) ) {
			return arguments.value;
		}

		arguments.key = retrieveAliasForColumn( arguments.key );
		if ( !structKeyExists( variables._casts, arguments.key ) ) {
			return arguments.value;
		}

		variables._castCache[ arguments.key ] = arguments.value;
		return variables._castCache[ arguments.key ];
	}

	/**
	 * Merges the attributes from the cast cache into the attributes.
	 *
	 * @return  quick.models.BaseEntity
	 */
	private any function mergeAttributesFromCastCache() {
		syncVariablesScopeWithData();
		for ( var key in variables._castCache ) {
			var castedValue = variables._castCache[ key ];
			if ( !variables._casterCache.keyExists( key ) ) {
				var castMapping               = variables._casts[ key ];
				variables._casterCache[ key ] = variables._wirebox.getInstance( dsl = castMapping );
			}
			var caster = variables._casterCache[ key ];
			var attrs  = caster.set( this, key, castedValue );
			if ( !isStruct( attrs ) ) {
				attrs = { "#key#" : attrs };
			}
			for ( var column in attrs ) {
				assignAttribute(
					name  = column,
					value = isNull( attrs[ column ] ) ? javacast( "null", "" ) : attrs[ column ],
					cast  = false
				);
			}
		}
		return this;
	}

	public any function convertToCastedValue( required string key, any value ) {
		if ( !variables._casts.keyExists( arguments.key ) ) {
			return isNull( arguments.value ) ? javacast( "null", "" ) : arguments.value;
		}

		if ( !variables._casterCache.keyExists( arguments.key ) ) {
			var castMapping                         = variables._casts[ arguments.key ];
			variables._casterCache[ arguments.key ] = variables._wirebox.getInstance( dsl = castMapping );
		}
		var caster = variables._casterCache[ arguments.key ];
		return caster.set(
			this,
			arguments.key,
			isNull( arguments.value ) ? javacast( "null", "" ) : arguments.value
		);
	}

	/**
	 * Checks if an attribute can be updated.
	 *
	 * @name    The name of the attribute to check.
	 *
	 * @return  Boolean
	 */
	private boolean function canUpdateAttribute( required string name ) {
		var alias = retrieveAliasForColumn( arguments.name );
		return variables._attributes.keyExists( alias ) &&
		variables._attributes[ alias ].update &&
		!variables._attributes[ alias ].isParentColumn;
	}

	/**
	 * Checks if an attribute can be inserted.
	 *
	 * @name    The name of the attribute to check.
	 *
	 * @return  Boolean
	 */
	private boolean function canInsertAttribute( required string name ) {
		var alias = retrieveAliasForColumn( arguments.name );
		return variables._attributes.keyExists( alias ) &&
		variables._attributes[ alias ].insert &&
		!variables._attributes[ alias ].isParentColumn;
	}

	public boolean function canConvertToNull( required string name ) {
		var alias = retrieveAliasForColumn( arguments.name );
		return variables._attributes.keyExists( alias ) &&
		variables._attributes[ alias ].convertToNull;
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
		return isArray( arguments.value ) ? arguments.value : [ arguments.value ];
	}

	/**
	 * Accepts an array of arrays and calls a callback passing each item of
	 * the same index from each of the arrays.
	 *
	 * @arrays    An array of arrays.  All arrays must have the same length.
	 * @callback  The callback to call.  It will be passed an item from each
	 *            array passed in at the same index.
	 *
	 * @throws    ArrayZipLengthMismatch
	 *
	 * @return    The original array of arrays passed in.
	 */
	private array function arrayZipEach( required array arrays, required any callback ) {
		if ( arguments.arrays.isEmpty() ) {
			return arguments.arrays;
		}

		var lengths = arguments.arrays.map( function( arr ) {
			return arr.len();
		} );
		if ( unique( lengths ).len() > 1 ) {
			throw(
				type    = "ArrayZipLengthMismatch",
				message = "The arrays do not have the same length. Lengths: [#serializeJSON( lengths )#]"
			);
		}

		for ( var i = 1; i <= arguments.arrays[ 1 ].len(); i++ ) {
			var args = {};
			for ( var j = 1; j <= arguments.arrays.len(); j++ ) {
				args[ j ] = arguments.arrays[ j ][ i ];
			}
			callback( argumentCollection = args );
		}

		return arguments.arrays;
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
		return arraySlice( createObject( "java", "java.util.HashSet" ).init( arguments.items ).toArray(), 1 );
	}

	/**
	 * Returns true if the object wants to use single table inheritence (STI)
	 * which is similar to discriminated entities, however there won't be a join column
	 * since the data for each sub entity originates from a single table
	 */
	public boolean function isSingleTableInheritance() {
		return variables._meta.originalMetadata.singleTableInheritance;
	}

}
