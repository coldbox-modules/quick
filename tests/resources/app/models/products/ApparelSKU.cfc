component extends="ProductSKU" accessors="true" table="apparel_skus" joinColumn="id" discriminatorValue="apparel" {

    property name="id";
    property name="cost";
    property name="color";
    property name="size1";
    property name="size1Description";
    property name="size1Index";
    property name="createdDate";
    property name="modifiedDate";
    property name="deletedDate";

    function keyType(){
        return variables._wirebox.getInstance( "UUIDKeyType@quick" );
    }

}