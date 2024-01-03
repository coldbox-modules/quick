component extends="quick.models.BaseEntity" accessors="true" table="product_skus" discriminatorColumn="designation" {

    property name="id";
    property name="productId";
    property name="designation";
    property name="createdDate";
    property name="modifiedDate";
    property name="deletedDate";

    variables._discriminators = [
        "ApparelSKU"
    ];

    function keyType(){
        return variables._wirebox.getInstance( "UUIDKeyType@quick" );
    }

    function product(){
        return belongsTo( "Product@core" );
    }

}