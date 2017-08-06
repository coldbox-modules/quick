component extends="quick.models.Relationships.BaseRelationship" {

    function apply() {
        getRelated().where( getOwningKey(), getForeignKeyValue() );
    }

    function retrieve() {
        return getRelated().first();
    }

}