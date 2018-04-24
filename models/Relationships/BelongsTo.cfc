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
        if ( isQuickEntity( entity ) ) {
            arguments.entity = entity.getKeyValue();
        }

        return getOwning().setAttribute( getForeignKey(), entity );
    }

    function disassociate() {
        return getOwning().clearAttribute( name = getForeignKey(), setToNull = true );
    }

}
