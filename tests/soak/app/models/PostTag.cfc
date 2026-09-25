component
	extends  ="quick.models.Relationships.Pivot"
	accessors="true"
	readonly ="false"
{

	property name="postId" column="post_id";
	property name="tagId"  column="tag_id";
	property name="context";

}
