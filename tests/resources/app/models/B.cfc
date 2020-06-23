component table="b" extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="a_id";
    property name="name";

    function a() {
        return belongsTo( "a" );
    }

}
