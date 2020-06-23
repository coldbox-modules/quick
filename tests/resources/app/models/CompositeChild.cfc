component table="composite_children" extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="composite_a";
    property name="composite_b";

    function parent() {
        return belongsTo(
            "Composite",
            [ "composite_a", "composite_b" ],
            [ "a", "b" ]
        );
    }
}
