component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="parentId";

    function parent() {
        return belongsTo( "Category", "parentId", "id" ).withDefault();  // Return a new entity if no match found.
    }

}
