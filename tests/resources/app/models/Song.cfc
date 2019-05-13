component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="title" nullValue="REALLY_NULL";
    property name="downloadUrl" column="download_url";
    property name="createdDate" column="created_date";
    property name="modifiedDate" column="modified_date";

    function instanceReady( eventData ) {
        request.instanceReadyCalled = eventData;
    }

    function preLoad( eventData ) {
        request.preLoadCalled = eventData;
    }

    function postLoad( eventData ) {
        request.postLoadCalled = eventData;
    }

    function preInsert( eventData ) {
        request.preInsertCalled = duplicate( eventData );
    }

    function postInsert( eventData ) {
        request.postInsertCalled = duplicate( eventData );
    }

    function preUpdate( eventData ) {
        param request.preUpdateCalled = [];
        arrayAppend( request.preUpdateCalled, duplicate( eventData ) );
    }

    function postUpdate( eventData ) {
        param request.postUpdateCalled = [];
        arrayAppend( request.postUpdateCalled, duplicate( eventData ) );
    }

    function preSave( eventData ) {
        request.preSaveCalled = duplicate( eventData );
    }

    function postSave( eventData ) {
        request.postSaveCalled = duplicate( eventData );
    }

    function preDelete( eventData ) {
        param request.preDeleteCalled = [];
        arrayAppend( request.preDeleteCalled, duplicate( eventData ) );
    }

    function postDelete( eventData ) {
        param request.postDeleteCalled = [];
        arrayAppend( request.postDeleteCalled, duplicate( eventData ) );
    }

}
