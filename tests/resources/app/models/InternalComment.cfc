component 
    accessors="true"
    extends="Comment"
    table="internalComments"
    joincolumn="FK_comment"
    discriminatorValue="internal"
{
    property name="reason";
}