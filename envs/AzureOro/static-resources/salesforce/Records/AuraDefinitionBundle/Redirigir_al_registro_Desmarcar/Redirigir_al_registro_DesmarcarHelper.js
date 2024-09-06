({
		toast : function() {
        var toastEvent = $A.get("e.force:showToast"); 
            toastEvent.setParams({
                "type": 'Success',
                "message": "Cuenta desmarcada como auditada",
                "mode": "dismissible", 
                "title": "Correcto"
             });
        toastEvent.fire();
	}
})