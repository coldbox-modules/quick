component extends="quick.models.Relationships.BaseRelationship" {

    function retrieve() {
        return related.find( getForeignKeyValue() );
    }

}