component extends="quick.models.Relationships.BaseRelationship" {

    function retrieve() {
        return related.where( owningKey, foreignKeyValue ).first();
    }

}