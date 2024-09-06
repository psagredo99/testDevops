({
		toast : function(component) {
        var toastEvent = $A.get("e.force:showToast"); 
            toastEvent.setParams({
                "type": 'warning',
                "message": component.get("v.msgToast"),
                "mode": "dismissible", 
                "title": "Correcto"
             });
        toastEvent.fire();
	}
})