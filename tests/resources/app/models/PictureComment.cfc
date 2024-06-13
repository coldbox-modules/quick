component 
    accessors="true"
    extends="Comment"
    table="pictureComments"
    joincolumn="FK_comment"
    discriminatorValue="picture"
{
    property name="filename";
}