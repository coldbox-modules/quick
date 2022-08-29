component 
    extends="quick.models.BaseEntity" 
    accessors="true" 
    discriminatorColumn="type"
    singleTableInheritance="true"
    table="products"
{

    property name="id";
	property name="name";
    property name="userId" column="user_id";
    property name="type";


    variables._discriminators = [
        "ProductBook",
        "ProductMusic"
    ];


    function creator() {
        return belongsTo( "User", "user_id" );
    }

}