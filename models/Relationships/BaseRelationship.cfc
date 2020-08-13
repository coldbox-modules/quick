/**
 * Abstract BaseRelationship used to provide shared methods across
 * other concrete relationships.
 *
 * @doc_abstract true
 */
component accessors="true" {

	/**
	 * The WireBox Injector.
	 */
	property name="wirebox" inject="wirebox";

	/**
	 * Flag to return a default model if the relation returns null.
	 */
	property
		name   ="returnDefaultEntity"
		type   ="boolean"
		default="false";

	/**
	 * Flag to return a default model if the relation returns null.
	 */
	property name="defaultAttributes";

	/**
	 * The related model we are ultimately fetching with this relationship.
	 * If a User `hasMany` Posts then Post is the related entity.
	 * s
	 */
	property name="related";

	/**
	 * The WireBox mapping used for the related entity.
	 */
	property name="relationName";

	/**
	 * The name used to define the relationship.  Usually the name of the method
	 * called that returns the relationship.
	 */
	property name="relationMethodName";

	/**
	 * The entity that the relationships is starting from.
	 * If a User `hasMany` Posts then User is the parent entity.
	 */
	property name="parent";

	/**
	 * Used to check for the type of relationship more quickly than using isInstanceOf.
	 */
	this.relationshipClass = "BaseRelationship";

	/**
	 * Creates a new relationship component to query and retrieve results.
	 *
	 * @related             The related entity instance.
	 * @relationName        The WireBox mapping for the related entity.
	 * @relationMethodName  The method name called to retrieve this relationship.
	 * @parent              The parent entity instance for the relationship.
	 * @withConstraints     Flag to automatically add the query constraints.  Default: true.
	 *
	 * @return              BaseRelationship
	 */
	public BaseRelationship function init(
		required any related,
		required string relationName,
		required string relationMethodName,
		required any parent,
		boolean withConstraints = true
	) {
		variables.returnDefaultEntity = false;
		variables.defaultAttributes   = {};

		variables.related            = arguments.related.resetQuery();
		variables.relationName       = arguments.relationName;
		variables.relationMethodName = arguments.relationMethodName;
		variables.parent             = arguments.parent;

		if ( arguments.withConstraints ) {
			variables.addConstraints();
		}

		return this;
	}

	/**
	 * Sets the relation method name for this relationship.
	 *
	 * @name     The relation method name for this relationship.
	 *
	 * @return   BaseRelationship
	 */
	public BaseRelationship function setRelationMethodName( required string name ) {
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
	public array function getKeys( required array entities, required array keys ) {
		return unique(
			arguments.entities.reduce( function( acc, entity ) {
				var keyValues = [];
				for ( var key in keys ) {
					if ( entity.isNullValue( key ) ) {
						return acc;
					}
					keyValues.append( entity.retrieveAttribute( key ) );
				}
				acc.append( keyValues.toList() );
				return acc;
			}, [] )
		).map( function( key ) {
			return key.listToArray();
		} );
	}

	/**
	 * Checks if all of the keys (usually foreign keys) on the specified entity are null. Used to determine whether we should even run a relationship query or just return null.
	 *
	 * @fields An array of field names to check on the parent entity
	 *
	 * @return true if all keys are null; false if any foreign keys have a value
	 */
	public boolean function fieldsAreNull( required any entity, required array fields ) {
		for ( var field in arguments.fields ) {
			if ( !arguments.entity.isNullValue( field ) ) {
				return false;
			}
		}
		return true;
	}

	/**
	 * Gets the query used to check for relation existance.
	 *
	 * @base    The base entity for the query.
	 *
	 * @return  quick.models.BaseEntity | qb.models.Query.QueryBuilder
	 */
	public any function addCompareConstraints( any base = variables.related ) {
		return arguments.base
			.select( variables.related.raw( 1 ) )
			.where( function( q ) {
				arrayZipEach(
					[
						getExistanceLocalKeys(),
						getExistenceCompareKeys()
					],
					function( qualifiedLocalKey, existenceCompareKey ) {
						q.whereColumn( qualifiedLocalKey, existenceCompareKey );
					}
				);
			} );
	}

	public any function nestCompareConstraints( required any base, required any nested ) {
		return arguments.base.whereExists( arguments.nested );
	}

	/**
	 * Returns the fully-qualified local key.
	 *
	 * @doc_generic  String
	 * @return       [String]
	 */
	public array function getQualifiedLocalKeys() {
		return variables.parent.retrieveQualifiedKeyNames();
	}

	/**
	 * Returns the fully-qualified local key.
	 *
	 * @doc_generic  String
	 * @return       [String]
	 */
	public array function getExistanceLocalKeys() {
		return getQualifiedLocalKeys();
	}

	/**
	 * Get the key to compare in the existence query.
	 *
	 * @doc_generic  String
	 * @return       [String]
	 */
	public array function getExistenceCompareKeys() {
		return getQualifiedForeignKeyNames();
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
		variables.defaultAttributes   = arguments.attributes;
		return this;
	}

	/**
	 * Applies a suffix to an alias for the relationship.
	 *
	 * @suffix   The suffix to append.
	 *
	 * @return  quick.models.Relationships.BaseRelationship
	 */
	public BaseRelationship function applyAliasSuffix( required string suffix ) {
		variables.related.withAlias( variables.related.tableName() & arguments.suffix );
		return this;
	}

	/**
	 * Retrieves the current query builder instance.
	 *
	 * @return  qb.models.Query.QueryBuilder
	 */
	public QuickBuilder function retrieveQuery() {
		return variables.related.retrieveQuery();
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

		if (
			isStruct( result ) &&
			!structKeyExists( result, "relationshipClass" ) &&
			( structKeyExists( result, "retrieveQuery" ) || structKeyExists( result, "isBuilder" ) )
		) {
			return this;
		}

		return result;
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
		if ( arrayIsEmpty( arguments.items ) ) {
			return arguments.items;
		}

		return arraySlice( createObject( "java", "java.util.HashSet" ).init( arguments.items ).toArray(), 1 );
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
	 * Throws an exception if the number of values passed in does not
	 * match the number of keys passed in.
	 *
	 * @values  An array of values to check the length matches
	 *
	 * @throws  KeyLengthMismatch
	 *
	 * @return  void
	 */
	public void function guardAgainstKeyLengthMismatch( required array actual, required any expectedLength ) {
		if ( isArray( arguments.expectedLength ) ) {
			arguments.expectedLength = arguments.expectedLength.len();
		}

		if ( arguments.actual.len() != expectedLength ) {
			throw(
				type    = "KeyLengthMismatch",
				message = "The number of values passed in [#arguments.actual.len()#] does not match the number expected [#expectedLength#]."
			);
		}
	}

}
