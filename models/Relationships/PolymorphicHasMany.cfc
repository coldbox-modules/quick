component accessors="true" extends="quick.models.Relationships.BaseRelationship" {

    property name="prefix";

    variables.defaultValue = [];

    function init( related, relationName, relationMethodName, owning, foreignKey, foreignKeyValue, owningKey, prefix ) {
        super.init( related, relationName, relationMethodName, owning, foreignKey, foreignKeyValue, owningKey );
        setPrefix( arguments.prefix );
        return this;
    }

    function retrieve() {
        return related
            .where( "#getPrefix()#_type", getOwning().getMapping() )
            .where( "#getPrefix()#_id", getOwning().getKeyValue() )
            .get();
    }

}