({
	init : function(component, event, helper) {
       
        helper.toast(component);
        
      
    
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
        
      /*setTimeout(()=>{
      	let quickActionClose = $A.get("e.force:refreshView");
      	quickActionClose.fire();
    	},1000);*/
                     
		
	}

})