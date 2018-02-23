component extends="quick.models.Relationships.BaseRelationship" {

    function onDIComplete() {
        setDefaultValue( javacast( "null", "" ) );
    }

    function apply() {
        getRelated().where( getOwningKey(), getForeignKeyValue() );
    }

    function retrieve() {
        return related.first();
    }

    function fromGroup( items ) {
        return items[ 1 ];
    }

    function associate( entity ) {
        if ( isInstanceOf( entity, "quick.models.BaseEntity" ) ) {
            arguments.entity = entity.getKeyValue();
        }

        return getOwning().setAttribute( getForeignKey(), entity );
    }

    function disassociate() {
        return getOwning().clearAttribute( name = getForeignKey(), setToNull = true );
    }

}
