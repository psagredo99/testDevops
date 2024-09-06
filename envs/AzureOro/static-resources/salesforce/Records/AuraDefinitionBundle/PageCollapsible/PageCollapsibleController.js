({
    toggleSection : function(component, event, helper) {
        component.set('v.isSidebarCollapsed', !component.get('v.isSidebarCollapsed'));
    },
    toggleMain : function(component, event, helper) {
        component.set('v.isMainCollapsed', !component.get('v.isMainCollapsed'));
    }
})