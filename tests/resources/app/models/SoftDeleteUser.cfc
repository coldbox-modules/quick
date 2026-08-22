component
	extends         ="quick.models.BaseEntity"
	accessors       ="true"
	table           ="users"
	softDeletes     ="true"
	softDeleteColumn="deletedAt"
{

	property name="id";
	property name="username";
	property name="deletedAt" column="email" insert="false";

}
