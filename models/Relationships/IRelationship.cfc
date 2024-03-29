interface displayname="IRelationship" {

	/**
	 * Sets the relation method name for this relationship.
	 *
	 * @name     The relation method name for this relationship.
	 *
	 * @return   quick.models.Relationships.IRelationship
	 */
	public any function setRelationMethodName( required string name );

	/**
	 * Retrieves the entities for eager loading.
	 *
	 * @doc_generic  quick.models.BaseEntity
	 * @return       [quick.models.BaseEntity]
	 */
	public array function getEager( boolean asQuery, boolean withAliases );

	/**
	 * Adds constraints for eager loading
	 *
	 * @doc_generic  quick.models.BaseEntity
	 * @return       boolean
	 */
	public boolean function addEagerConstraints( required array entities, required any baseEntity );

	/**
	 * Gets the first matching record for the relationship.
	 * Returns null if no record is found.
	 *
	 * @return   quick.models.BaseEntity
	 */
	public any function first();

	/**
	 * Gets the first matching record for the relationship.
	 * Throws an exception if no record is found.
	 *
	 * @throws   EntityNotFound
	 *
	 * @return   quick.models.BaseEntity
	 */
	public any function firstOrFail();

	/**
	 * Finds the first matching record with a given id for the relationship.
	 * Returns null if no record is found.
	 *
	 * @id       The id of the entity to find.
	 *
	 * @return   quick.models.BaseEntity
	 */
	public any function find( required any id );

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
	public any function findOrFail( required any id );

	/**
	 * Returns all results for the related entity.
	 * Note: `all` resets any query restrictions, including relationship restrictions.
	 *
	 * @doc_generic  quick.models.BaseEntity
	 * @return       [quick.models.BaseEntity]
	 */
	public array function all();

	/**
	 * Wrapper for `getResults()` on relationship types that have them.
	 * `get()` implemented for consistency with qb and Quick.
	 *
	 * @return   quick.models.BaseEntity or [quick.models.BaseEntity]
	 */
	public any function get();

	/**
	 * Retrieves the values of the key from each entity passed.
	 *
	 * @entities  An array of entities to retrieve keys.
	 * @key       The key to retrieve from each entity.
	 * @key       The entity the keys are associated with. Used to check for null attributes.
	 *
	 * @doc_generic  any
	 * @return   [any]
	 */
	public array function getKeys(
		required array entities,
		required array keys,
		required any baseEntity
	);

	/**
	 * Checks if all of the keys (usually foreign keys) on the specified entity are null. Used to determine whether we should even run a relationship query or just return null.
	 *
	 * @fields An array of field names to check on the parent entity
	 *
	 * @return true if all keys are null; false if any foreign keys have a value
	 */
	public boolean function fieldsAreNull( required any entity, required array fields );

	/**
	 * Gets the query used to check for relation existance.
	 *
	 * @base    The base entity for the query.
	 *
	 * @return  quick.models.BaseEntity | qb.models.Query.QueryBuilder
	 */
	public any function addCompareConstraints( any base, any nested );

	public any function nestCompareConstraints( required any base, required any nested );

	/**
	 * Returns the fully-qualified local key.
	 *
	 * @doc_generic  String
	 * @return       [String]
	 */
	public array function getExistenceLocalKeys( any builder );

	/**
	 * Get the key to compare in the existence query.
	 *
	 * @doc_generic  String
	 * @return       [String]
	 */
	public array function getExistenceCompareKeys( any builder );

	/**
	 * Returns the related entity for the relationship.
	 */
	public any function getRelated();

	/**
	 * Flags the entity to return a default entity if the relation returns null.
	 *
	 * @return  quick.models.Relationships.IRelationship
	 */
	public any function withDefault( any attributes );

	/**
	 * Applies a suffix to an alias for the relationship.
	 *
	 * @suffix   The suffix to append.
	 *
	 * @return  quick.models.Relationships.IRelationship
	 */
	public any function applyAliasSuffix( required string suffix );

	/*
	 * TODO: pull this into a separate interface
	 */
	public array function getQualifiedForeignKeyNames( any builder );

	/*
	 * TODO: pull this into a separate interface
	 */
	public array function getQualifiedLocalKeys( any builder );



	/**
	 * Retrieves the current query builder instance.
	 *
	 * @return  qb.models.QueryBuilder
	 */
	public QueryBuilder function retrieveQuery();

}
