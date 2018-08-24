component accessors="true" extends="quick.models.Relationships.BaseRelationship" {

    property name="intermediate";
    property name="intermediateKey";

    function init( wirebox, related, relationName, relationMethodName, owning, intermediate, foreignKey, foreignKeyValue, intermediateKey ) {
        setIntermediate( intermediate );
        setIntermediateKey( intermediateKey );
        super.init( wirebox, related, relationName, relationMethodName, owning, foreignKey, foreignKeyValue, owningKey );
        return this;
    }

    function onDIComplete() {
        setDefaultValue( collect() );
    }

    function apply() {
        getRelated()
            .join(
                getIntermediate().get_Table(),
                "#getIntermediate().get_Table()#.#getIntermediate().get_Key()#",
                "#getRelated().get_Table()#.#getIntermediateKey()#"
            )
            .join(
                getOwning().get_Table(),
                "#getOwning().get_Table()#.#getOwningKey()#",
                "#getIntermediate().get_Table()#.#getForeignKey()#"
            )
            .where( "#getOwning().get_Table()#.#getOwningKey()#", getOwning().keyValue() );
    }

    function fromGroup( items ) {
        return collect( items );
    }

    function retrieve() {
        return getRelated().get();
    }

}
