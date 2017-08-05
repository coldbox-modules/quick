component accessors="true" extends="quick.models.Relationships.BaseRelationship" {

    property name="intermediate";
    property name="intermediateKey";

    variables.defaultValue = [];

    function init( related, owning, intermediate, foreignKey, foreignKeyValue, intermediateKey ) {
        super.init( related, owning, foreignKey, foreignKeyValue, owningKey );
        setIntermediate( intermediate );
        setIntermediateKey( intermediateKey );
        return this;
    }

    function retrieve() {
        return related
            .join(
                getIntermediate().getTable(),
                "#getIntermediate().getTable()#.#getIntermediate().getKey()#",
                "#getRelated().getTable()#.#getIntermediateKey()#"
            )
            .join(
                getOwning().getTable(),
                "#getOwning().getTable()#.#getOwningKey()#",
                "#getIntermediate().getTable()#.#getForeignKey()#"
            )
            .where( "#getOwning().getTable()#.#getOwningKey()#", getOwning().getKeyValue() )
            .get();
    }

}