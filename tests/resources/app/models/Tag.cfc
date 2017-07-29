component extends="quick.models.BaseEntity" {

    function posts() {
        return belongsToMany(
            relationName = "Post",
            relatedKey = "post_pk"
        );
    }

}