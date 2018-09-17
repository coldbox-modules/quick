component table="b" extends="quick.models.BaseEntity" {

    property name="id";
    property name="a_id";
    property name="name";

    function a() {
        return belongsTo( "a" );
    }

}
