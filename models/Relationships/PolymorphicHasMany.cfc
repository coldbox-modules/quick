component accessors="true" extends="quick.models.Relationships.BaseRelationship" {

    property name="prefix";

    function init( wirebox, related, relationName, relationMethodName, owning, foreignKey, foreignKeyValue, owningKey, prefix ) {
        setPrefix( arguments.prefix );
        super.init( wirebox, related, relationName, relationMethodName, owning, foreignKey, foreignKeyValue, owningKey );
        return this;
    }

    function onDIComplete() {
        setDefaultValue( collect() );
    }

    function apply() {
        getRelated()
            .where( "#getPrefix()#_type", getOwning().getMapping() )
            .where( "#getPrefix()#_id", getOwning().getKeyValue() );
    }

    function fromGroup( items ) {
        return collect( items );
    }

    function retrieve() {
        return getRelated().get();
    }

}
