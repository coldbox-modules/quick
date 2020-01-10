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
component extends="quick.models.Relationships.HasOneOrMany" {

    /**
     * Creates a Polymorphic HasOneOrMany relationship.
     *
     * @related             The related entity instance.
     * @relationName        The WireBox mapping for the related entity.
     * @relationMethodName  The method name called to retrieve this relationship.
     * @parent              The parent entity instance for the relationship.
     * @type                The name of the column that contains the entity type
     *                      of the polymorphic relationship.
     * @id                  The foreign key on the parent entity.
     * @localKey            The local primary key on the parent entity.
     *
     * @return              quick.models.Relationships.PolymorphicHasOneOrMany
     */
    public PolymorphicHasOneOrMany function init(
        required any related,
        required string relationName,
        required string relationMethodName,
        required any parent,
        required string type,
        required string id,
        required string localKey
    ) {
        variables.morphType = arguments.type;
        variables.morphClass = arguments.parent.get_entityName();

        return super.init(
            related = arguments.related,
            relationName = arguments.relationName,
            relationMethodName = arguments.relationMethodName,
            parent = arguments.parent,
            foreignKey = arguments.id,
            localKey = arguments.localKey
        );
    }

    /**
     * Adds the constraints to the related entity.
     *
     * @return  quick.models.Relationships.PolymorphicHasOneOrMany
     */
    public PolymorphicHasOneOrMany function addConstraints() {
        super.addConstraints();
        variables.related.where( variables.morphType, variables.morphClass );
        return this;
    }

    /**
     * Adds the constraints for eager loading.
     *
     * @entities  The entities being eager loaded.
     *
     * @return    quick.models.Relationships.PolymorphicHasOneOrMany
     */
    public PolymorphicHasOneOrMany function addEagerConstraints( required array entities ) {
        super.addEagerConstraints( arguments.entities );
        variables.related.where( variables.morphType, variables.morphClass );
        return this;
    }

}
