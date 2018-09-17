component table="a" extends="quick.models.BaseEntity" {

    property name="id";
    property name="name";

    function b() {
        return hasMany( "b" );
    }

}
