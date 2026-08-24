component
	extends  ="quick.models.Relationships.Pivot"
	accessors="true"
	readonly ="false"
{

	property name="customPostPk" column="custom_post_pk";
	property name="tagId"       column="tag_id";
	property name="context";
	property name="active" casts="BooleanCast@quick";
	property name="createdDate"  column="created_date";
	property name="modifiedDate" column="modified_date";

	function describe() {
		return "#getContext()#:#getTagId()#";
	}

}
