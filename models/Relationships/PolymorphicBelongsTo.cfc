component extends="quick.models.Relationships.BaseRelationship" {

    function apply() {
        getRelated().where( getForeignKey(), getForeignKeyValue() );
    }

    function retrieve() {
        return getRelated().first();
    }

}