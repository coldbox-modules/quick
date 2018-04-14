component extends="quick.models.Relationships.BaseRelationship" {

    function onDIComplete() {
        setDefaultValue( collect() );
    }

    function apply() {
        getRelated().where( getOwningKey(), getForeignKeyValue() );
    }

    function retrieve() {
        return getRelated().get();
    }

    function fromGroup( items ) {
        return collect( items );
    }

    function save( entity ) {
        getOwning().clearRelationship( getRelationMethodName() );
        return entity.setAttribute( getOwningKey(), getForeignKeyValue() ).save();
    }

    function create( attributes ) {
        getOwning().clearRelationship( getRelationMethodName() );
        return wirebox.getInstance( getRelationName() )
            .setAttributesData( attributes )
            .setAttribute( getOwningKey(), getForeignKeyValue() )
            .save();
    }

}
