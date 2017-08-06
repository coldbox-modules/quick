component extends="quick.models.Relationships.BaseRelationship" {

    variables.defaultValue = [];

    function apply() {
        getRelated().where( getForeignKey(), getForeignKeyValue() );
    }

    function retrieve() {
        return getRelated().get();
    }

    function save( entity ) {
        getOwning().clearRelationship( getRelationMethodName() );
        return entity.setAttribute( getForeignKey(), getForeignKeyValue() ).save();
    }

    function create( attributes ) {
        getOwning().clearRelationship( getRelationMethodName() );
        return wirebox.getInstance( getRelationName() )
            .setAttributes( attributes )
            .setAttribute( getForeignKey(), getForeignKeyValue() )
            .save();
    }

}