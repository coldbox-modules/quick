component extends="quick.models.BaseEntity" accessors="true" table="products_b" {

    property name="id";
    property name="name";
    property name="itemNumber";
    property name="createdDate";
    property name="modifiedDate";
    property name="deletedDate";

    function keyType(){
        return variables._wirebox.getInstance( "UUIDKeyType@quick" );
    }

    function skus(){
        return hasMany( "ProductSKU" );
    }

}