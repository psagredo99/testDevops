({
    doInit: function (component, event, helper) { 
        //console.log('doInit of component called');
        var columns = [
            {
                type: 'url',
                fieldName: 'AccountURL',
                label: 'Nombre',
                initialWidth: 450,
                typeAttributes: {
                    label: { fieldName: 'accountName' }
                }, 
                cellAttributes: {
                    iconName: { fieldName: 'ownAccount' }, iconPosition: 'right' 
                }
            },
            {
                type: 'currency',
                fieldName: 'Facturacion_PKF__c',
				label: 'Facturación PKF',
                initialWidth: 150
            },
            /*{
                type: 'text',
                fieldName: 'ShippingStreet',
                label: 'Calle',
                initialWidth: 250
            },
            {
                type: 'text',
                fieldName: 'ShippingCity',
                label: 'Ciudad',
                initialWidth: 150
            },
            {
                type: 'text',
                fieldName: 'ShippingPostalCode',
                label: 'Cod. Postal',
                initialWidth: 125
            },
            {
                type: 'text',
                fieldName: 'ShippingCountry',
                label: 'País',
                initialWidth: 100
            }*/
        ];
        component.set('v.gridColumns', columns);
        
        var trecid = component.get('v.recordId');
        //var tsObjectName= component.get('v.ltngSobjectname');
        //var tparentFieldAPIname= component.get('v.ltngParentFieldAPIName');
        //var tlabelFieldAPIName= component.get('v.ltngLabelFieldAPIName');
        if(trecid){
            helper.callToServer(
                component,
                "c.findHierarchyData",
                function(response) {
                    var expandedRows = [];
                    var apexResponse = response;
                    var roles = {};
                    //console.log('*******apexResponse:'+JSON.stringify(apexResponse));
                    var results = apexResponse;
                    roles[undefined] = { Name: "Root", _children: [] };
                    apexResponse.forEach(function(v) {
                        expandedRows.push(v.Id);
                        if(trecid == v.Id){
                            roles[v.Id] = { 
                            ownAccount: 'action:back',
                            accountName: v.Name ,
                            name: v.Id, 
                            Facturacion_PKF__c:v.Facturacion_PKF__c,
                            ShippingStreet:v.ShippingStreet,
                            ShippingCity:v.ShippingCity,
                            ShippingPostalCode:v.ShippingPostalCode,
                            ShippingCountry:v.ShippingCountry,
                            AccountURL:'/'+v.Id,
                            _children: [] };
                        } else {
                            roles[v.Id] = { 
                            ownAccount: ' ',
                            accountName: v.Name ,
                            name: v.Id, 
                            Facturacion_PKF__c:v.Facturacion_PKF__c,
                            ShippingStreet:v.ShippingStreet,
                            ShippingCity:v.ShippingCity,
                            ShippingPostalCode:v.ShippingPostalCode,
                            ShippingCountry:v.ShippingCountry,
                            AccountURL:'/'+v.Id,
                            _children: [] };
                        }
                        
                    });
                    apexResponse.forEach(function(v) {
                        roles[v.ParentId]._children.push(roles[v.Id]);   
                    });                
                    component.set("v.gridData", roles[undefined]._children);
                    //console.log('*******treegrid data:'+JSON.stringify(roles[undefined]._children));
                    
                    component.set('v.gridExpandedRows', expandedRows);
                }, 
                {
                    recId: component.get('v.recordId')
                }
            );    
        }
        //var tree = component.find('mytree');
        //tree.expandAll();
    }
})