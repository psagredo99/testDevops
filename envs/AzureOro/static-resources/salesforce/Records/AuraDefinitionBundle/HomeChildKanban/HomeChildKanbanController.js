/*
 * Copyright (c) 2018, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

({
    handleRecordUpdated : function(component, event, helper){       
        var currentRec = component.get('v.record');
        console.log('Aimar 0');
        if(!$A.util.isUndefinedOrNull(currentRec)){
            console.log('Aimar 1');
            var recFlds = currentRec.fields;
            var evtSrc = event.getSource();
            console.log('Aimar 2');
            if(evtSrc.getLocalId() == 'refreshButton'){
                console.log('Aimar 3');
                helper.spinnerHelper(component, true);
                $A.util.addClass(evtSrc,'refreshSpin');
                window.setTimeout($A.getCallback(function(){
                    if(component.isValid()){
                        $A.util.removeClass(evtSrc,'refreshSpin');
                    }
                }), 400);
            }
            console.log('Aimar 4');
            var recId = component.get('v.recordId');
            //console.log('Aimar 4.1: ' + JSON.stringify(recFlds));
            var objName = recFlds.KanbanDev_Child_Object__c.value;           
            var objRelField = recFlds.KanbanDev_Relation_Field__c.value;            
            var objFields = recFlds.KanbanDev_Fields_To_Show__c.value;            
            var kanbanPicklistField = recFlds.KanbanDev_Group_By__c.value;            
            var ExcVal = recFlds.KanbanDev_Exclude_From_Group_By__c.value;          
            var KbObjNameField = recFlds.KanbanDev_Name_Field__c.value;
            var ExcFVal = ExcVal ? ExcVal.split(';') : '';
            console.log('Aimar 5' + ExcFVal);
            
            if(ExcFVal != ''){
                console.log('Aimar 6');
                for(var i=0; i<ExcFVal.length; i++){
                    ExcFVal[i] = ExcFVal[i].trim();
                }
            }
            var agrFld = recFlds.KanbanDev_Summarize_By__c.value;
            //kanbanDev__Summarize_By__c
            var agrFldFval = agrFld ? agrFld : null;
            console.log('Aimar 7');
            if(objName && objFields && kanbanPicklistField){
                console.log('Aimar 8');
                //alert(recId + objName + objRelField + objFields + kanbanPicklistField);
                var action = component.get('c.getKanban');
                console.log('Aimar 9');
                action.setParams({
                    'objName' : objName,
                    'objFields' : objFields.split(';'),
                    'kabnanField' : kanbanPicklistField,
                    'summField' : agrFldFval,
                    'ParentRecId' : recId,
                    'relField' : objRelField,
                    'ExcVal' : ExcFVal,
                    'KbObjNameField' : KbObjNameField
                });
                
                action.setCallback(this, function(resp){
                    /*console.log(resp.getState());
                console.log(resp.getError());
                console.clear();
                console.log(resp.getReturnValue()); */          
                helper.spinnerHelper(component, false);
                console.log('Aimar 10');
                if(resp.getState() === 'SUCCESS'){
                    console.log('Aimar 11');
                    var rVal = resp.getReturnValue();
                    component.set('v.isSuccess', rVal.isSuccess);
                    console.log('Aimar 12');
                    if(rVal.isSuccess){
                        console.log('Aimar 13');
                        for(var i=0; i<rVal.records.length; i++){
                            rVal.records[i].kanbanfield = rVal.records[i][kanbanPicklistField];
                        }
                        component.set('v.kwrap',rVal);
                    }else{
                        component.set('v.errorMessage', rVal.errorMessage);
                    }
                }
            });
            $A.enqueueAction(action);
        }
        }
    },
    childChanged : function(component, event, helper) {
        var recFlds = component.get('v.record').fields;
        var data = event.getParam('KanbanChildChange');
        if(data.from != data.to){
            //helper.spinnerHelper(component, true);
            var objFields = recFlds.KanbanDev_Fields_To_Show__c.value.split(';');
            var recsMap = component.get('v.kwrap');
            var rec = recsMap.records[data.from][data.pos];
            var nameInToast;
            var simpleRecord = component.get('v.simpleRecord');
            if(!$A.util.isUndefinedOrNull(simpleRecord.KanbanDev_Name_Field__c) && simpleRecord.KanbanDev_Name_Field__c != 'false'){
                if($A.util.isUndefinedOrNull(rec[simpleRecord.KanbanDev_Name_Field__c])){
                    nameInToast = component.get('v.kwrap').cObjName;
                }else{
                	nameInToast = rec[simpleRecord.KanbanDev_Name_Field__c];    
                }
            }else{
                nameInToast = component.get('v.kwrap').cObjName;
            }
            var kfld = recFlds.KanbanDev_Group_By__c.value;
            var sfield = recFlds.KanbanDev_Summarize_By__c.value;
            
            if(rec[sfield] && !isNaN(rec[sfield])){
                var smap = recsMap.rollupData;
                smap[data.from] = smap[data.from] - rec[sfield];
                smap[data.to] = smap[data.to] + rec[sfield];
                recsMap.rollupData = smap;
            }
            
            rec[kfld] = data.to;
            recsMap.records[data.to].unshift(rec);
            recsMap.records[data.from].splice(data.pos, 1);
            
            component.set('v.kwrap',recsMap);
            var toastEvent = $A.get("e.force:showToast");
            var action = component.get('c.updateRec');
            action.setParams({
                'recId' : rec.Id,
                'recField' : kfld,
                'recVal' : data.to
            });
            action.setCallback(this, function(res){
                //helper.spinnerHelper(component, false);
                if(res.getState() === 'SUCCESS' && res.getReturnValue() === 'true'){
                    toastEvent.setParams({
                        "title": "Success!",
                        "type" : "success",
                        "duration" : 400,
                        "message": nameInToast+' moved to '+ data.to
                    });
                    toastEvent.fire();
                }else{
                    var em = 'An Unknown Error Occured';
                    if(res.getState() === 'SUCCESS' && res.getReturnValue() != 'true'){
                        em = res.getReturnValue();
                    }else if(res.getState() === 'ERROR'){
                        var errors = res.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                em = errors[0].message;
                            }
                        } else {
                            em = 'An Unknown Error Occured';
                        }
                    }
                    toastEvent.setParams({
                        "title": "Error",
                        "type" : "error",
                        "duration" : 400,
                        "message": em
                    });
                    toastEvent.fire();
                    var rec = recsMap.records[data.to][0];
                    rec[kfld] = data.from;
                    recsMap.records[data.to].splice(0, 1);
                    recsMap.records[data.from].splice(data.pos, 0, rec);
                    component.set('v.kwrap',recsMap);
                }
            });
            $A.enqueueAction(action);
        }
    },
    childDelete : function(component, event, helper) {
        var data = event.getParam('KanbanChildDelete');
        component.set('v.delInfo', data);
        helper.modalHelper(component, 'srModal', 'modalBkdrp', true);
    },
    deleteRecord : function(component, event, helper) {
        var recFlds = component.get('v.record').fields;
        helper.modalHelper(component, 'srModal', 'modalBkdrp', false);
        helper.spinnerHelper(component, true);
        var data = component.get('v.delInfo');
        console.log(data);
        var recsMap = component.get('v.kwrap');
        var rec = recsMap.records[data.from][data.pos];
        console.log(rec);
        var action = component.get('c.deleteRec');
        var sfield = recFlds.KanbanDev_Summarize_By__c.value;
        action.setParams({
            'obj' : rec
        });
        action.setCallback(this, function(res){
            helper.spinnerHelper(component, false);
            var state = res.getState();
            var toastEvent = $A.get("e.force:showToast");
            if(state === 'SUCCESS'){
                recsMap.records[data.from].splice(data.pos, 1);
                
                if(rec[sfield] && !isNaN(rec[sfield])){
                    var smap = recsMap.rollupData;
                    smap[data.from] = smap[data.from] - rec[sfield];
                    recsMap.rollupData = smap;
                }
                toastEvent.setParams({
                    "title": "Success",
                    "type" : "success",
                    "duration" : 400,
                    "message" : "The record has been delete successfully."
                });
                toastEvent.fire();
                component.set('v.kwrap',recsMap);
                
            }else if(state === 'ERROR'){
                var errors = res.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        em = errors[0].message;
                    }
                }else{
                    em = 'An Unknown Error Occured';
                }
                toastEvent.setParams({
                    "title": "Error",
                    "type" : "error",
                    "duration" : 400,
                    "message" : em
                });
                toastEvent.fire();
            }
            
        });
        $A.enqueueAction(action);
    },
    closeModal : function(component, event, helper) {
        helper.modalHelper(component, 'srModal', 'modalBkdrp', false);
        component.set('v.delInfo', null);
    },
    initiateNewRecordCreation : function(component, event, helper) {
        var recordId = component.get('v.recordId');
        if($A.util.isUndefinedOrNull(recordId)){
            var simpleRecord = component.get('v.simpleRecord');
            var createRecordEvent = $A.get("e.force:createRecord");
            createRecordEvent.setParams({
                "entityApiName": simpleRecord.For_Object__c
            });
            createRecordEvent.fire();
        }else{
            var simpleRecord = component.get('v.simpleRecord');
            var createRecordEvent = $A.get("e.force:createRecord");
            var recObj = {};
            recObj[simpleRecord.KanbanDev_Relation_Field__c] = recordId;
            createRecordEvent.setParams({
                "entityApiName": simpleRecord.KanbanDev_Child_Object__c,
                "defaultFieldValues": recObj
            });
            createRecordEvent.fire();
        }
    }/*,
    navToRelatedList : function(component, event, helper){
        var recordId = component.get('v.recordId');
        if(!$A.util.isUndefinedOrNull(recordId)){
            var simpleRecord = component.get('v.simpleRecord');
            var relatedListEvent = $A.get("e.force:navigateToRelatedList");
            relatedListEvent.setParams({
                "relatedListId": simpleRecord.kanbanDev__Child_Object__c,
                "parentRecordId": recordId
            });
            relatedListEvent.fire();
        }
    }*/
})