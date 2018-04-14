component attributecasing="snake" extends="quick.models.BaseEntity" {

    property name="id";
    property name="name";

    function posts() {
        return belongsToMany(
            relationName = "Post",
            relatedKey = "post_pk"
        );
    }

}
