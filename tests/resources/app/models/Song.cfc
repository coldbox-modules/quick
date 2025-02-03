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
        request.preInsertCalled = {
            "entity": arguments.eventData.entity.getMemento(),
            "isLoaded": arguments.eventData.entity.isLoaded()
        };
    }

    function postInsert( eventData ) {
        request.postInsertCalled = {
            "entity": eventData.entity.getMemento(),
            "isLoaded": eventData.entity.isLoaded()
        };
    }

    function preUpdate( eventData ) {
        param request.preUpdateCalled = [];
        arrayAppend( request.preUpdateCalled, {
            "entity": eventData.entity.getMemento()
        } );
    }

    function postUpdate( eventData ) {
        param request.postUpdateCalled = [];
        arrayAppend( request.postUpdateCalled, {
            "entity": eventData.entity.getMemento()
        } );
    }

    function preSave( eventData ) {
        request.preSaveCalled = {
            "entity": arguments.eventData.entity.getMemento(),
            "isLoaded": arguments.eventData.entity.isLoaded()
        };
    }

    function postSave( eventData ) {
        request.postSaveCalled = {
            "entity": arguments.eventData.entity.getMemento(),
            "isLoaded": arguments.eventData.entity.isLoaded()
        };
    }

    function preDelete( eventData ) {
        param request.preDeleteCalled = [];
        arrayAppend( request.preDeleteCalled, {
            "entity": eventData.entity.getMemento()
        } );
    }

    function postDelete( eventData ) {
        param request.postDeleteCalled = [];
        arrayAppend( request.postDeleteCalled, {
            "entity": eventData.entity.getMemento()
        } );
    }

}
