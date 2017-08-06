component extends="quick.models.Relationships.BaseRelationship" {

    variables.defaultValue = [];

    function apply() {
        getRelated().where( getOwningKey(), getForeignKeyValue() );
    }

    function retrieve() {
        return related.first();
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