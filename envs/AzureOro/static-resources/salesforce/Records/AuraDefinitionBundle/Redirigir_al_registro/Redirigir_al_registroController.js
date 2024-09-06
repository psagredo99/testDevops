({
	init : function(component, event, helper) {
       
        helper.toast(component);
    
                var dismissActionPanel = $A.get("e.force:closeQuickAction"); 
        		dismissActionPanel.fire();
                $A.get('e.force:refreshView').fire();
        
        /*var navEvt = $A.get("e.force:navigateToSObject");
		navEvt.setParams({
		  "recordId": component.get("v.recordId"),
		});
		navEvt.fire(); */
        
      /*setTimeout(()=>{
      	let quickActionClose = $A.get("e.force:refreshView");
      	quickActionClose.fire();
    	},1000);*/
                     
		
	}

})