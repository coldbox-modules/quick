component accessors="true" extends="quick.models.Relationships.BaseRelationship" {

    property name="intermediate";
    property name="intermediateKey";

    function init( related, relationName, relationMethodName, owning, intermediate, foreignKey, foreignKeyValue, intermediateKey ) {
        setIntermediate( intermediate );
        setIntermediateKey( intermediateKey );
        super.init( related, relationName, relationMethodName, owning, foreignKey, foreignKeyValue, owningKey );
        return this;
    }

    function onDIComplete() {
        setDefaultValue( collect() );
    }

    function apply() {
        getRelated()
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
            .where( "#getOwning().getTable()#.#getOwningKey()#", getOwning().getKeyValue() );
    }

    function fromGroup( items ) {
        return collect( items );
    }

    function retrieve() {
        return getRelated().get();
    }

}
