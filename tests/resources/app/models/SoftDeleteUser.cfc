component
	extends         ="quick.models.BaseEntity"
	accessors       ="true"
	table           ="users"
	softDeletes     ="true"
{

	property name="id";
	property name="username";
	property
		name  ="deletedDate"
		column="email"
		insert="false";

	function postUpdate() {
		request.softDeleteUserPostUpdateCalled = true;
	}

}
