component accessors="true" extends="quick.models.Relationships.BaseRelationship" {

    property name="prefix";

    variables.defaultValue = [];

    function init( related, relationName, relationMethodName, owning, foreignKey, foreignKeyValue, owningKey, prefix ) {
        setPrefix( arguments.prefix );
        super.init( related, relationName, relationMethodName, owning, foreignKey, foreignKeyValue, owningKey );
        return this;
    }

    function apply() {
        getRelated()
            .where( "#getPrefix()#_type", getOwning().getMapping() )
            .where( "#getPrefix()#_id", getOwning().getKeyValue() );
    }

    function retrieve() {
        return getRelated().get();
    }

}