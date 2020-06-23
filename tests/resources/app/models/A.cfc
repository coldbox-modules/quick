component table="a" extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="name";

    function b() {
        return hasMany( "b" );
    }

}
