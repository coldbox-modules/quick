interface displayname="IConcatenatableRelationship" {

	public struct function appendToDeepRelationship(
		required array through,
		required array foreignKeys,
		required array localKeys,
		required numeric position
	);

}
