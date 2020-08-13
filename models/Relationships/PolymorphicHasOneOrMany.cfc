/**
 * Abstract HasOneOrMany used to provide shared methods across
 * `hasOne` and `hasMany` relationships.
 *
 * A polymorphic relationship is one where the related entity can belong to
 * more than one type of entity.  As such, the type of entity it is related
 * to is stored alongside the foreign key values.
 *
 * @doc_abstract true
 */
component extends="quick.models.Relationships.HasOneOrMany" accessors="true" {

	/**
	 * The name of the column that contains the entity type
	 * of the polymorphic relationship.
	 */
	property name="morphType" type="string";

	/**
	 * The mapping for the morphed entity.
	 */
	property name="morphMapping" type="string";

	/**
	 * Used to check for the type of relationship more quickly than using isInstanceOf.
	 */
	this.relationshipClass = "PolymorphicHasOneOrMany";

	/**
	 * Creates a Polymorphic HasOneOrMany relationship.
	 *
	 * @related             The related entity instance.
	 * @relationName        The WireBox mapping for the related entity.
	 * @relationMethodName  The method name called to retrieve this relationship.
	 * @parent              The parent entity instance for the relationship.
	 * @type                The name of the column that contains the entity type
	 *                      of the polymorphic relationship.
	 * @ids                 The foreign key on the parent entity.
	 * @localKeys           The local primary key on the parent entity.
	 *
	 * @return              quick.models.Relationships.PolymorphicHasOneOrMany
	 */
	public PolymorphicHasOneOrMany function init(
		required any related,
		required string relationName,
		required string relationMethodName,
		required any parent,
		required string type,
		required array ids,
		required array localKeys,
		boolean withConstraints = true
	) {
		variables.morphType    = arguments.type;
		variables.morphMapping = arguments.parent.mappingName();

		return super.init(
			related            = arguments.related,
			relationName       = arguments.relationName,
			relationMethodName = arguments.relationMethodName,
			parent             = arguments.parent,
			foreignKeys        = arguments.ids,
			localKeys          = arguments.localKeys,
			withConstraints    = arguments.withConstraints
		);
	}

	/**
	 * Adds the constraints to the related entity.
	 *
	 * @return  quick.models.Relationships.PolymorphicHasOneOrMany
	 */
	public PolymorphicHasOneOrMany function addConstraints() {
		super.addConstraints();
		variables.related.where( variables.morphType, variables.morphMapping );
		return this;
	}

	/**
	 * Adds the constraints for eager loading.
	 *
	 * @entities  The entities being eager loaded.
	 *
	 * @return    quick.models.Relationships.PolymorphicHasOneOrMany
	 */
	public boolean function addEagerConstraints( required array entities ) {
		if ( !super.addEagerConstraints( arguments.entities ) ) {
			return false;
		}
		variables.related.where( variables.morphType, variables.morphMapping );
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
		return tap( super.addCompareConstraints( arguments.base ), function( q ) {
			q.where( variables.related.qualifyColumn( variables.morphType ), variables.morphMapping );
		} );
	}

	/**
	 * Applies the join for relationship in a `hasManyThrough` chain.
	 *
	 * @base    The query to apply the join to.
	 *
	 * @return  void
	 */
	public void function applyThroughJoin( required any base ) {
		arguments.base.join( variables.parent.tableName(), function( j ) {
			arrayZipEach(
				[
					variables.foreignKeys,
					variables.localKeys
				],
				function( foreignKey, localKey ) {
					j.on( variables.related.qualifyColumn( foreignKey ), variables.parent.qualifyColumn( localKey ) );
					j.where( variables.related.qualifyColumn( variables.morphType ), variables.morphMapping );
				}
			);
		} );
	}

}
