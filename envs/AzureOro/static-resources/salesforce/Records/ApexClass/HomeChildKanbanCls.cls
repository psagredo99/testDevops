/*
 * Copyright (c) 2018, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
public with sharing class HomeChildKanbanCls {
    
    @AuraEnabled
    public static string saveConfig(Kanban_Configuration__c obj){
        try{
            if(obj.Kanban_For__c == 'Child'){
                obj.KanbanDev_Name_Field__c = HomeChildKanbanUtil.getNameField(obj.KanbanDev_Child_Object__c);
            }else if(obj.Kanban_For__c == 'Home'){
                obj.KanbanDev_Name_Field__c = HomeChildKanbanUtil.getNameField(obj.For_Object__c);
            }
            upsert obj;
            return 'true';
        }catch(exception e){
            return e.getMessage();
        }
    }
    
    @AuraEnabled
    public static Map<string, List<HomeChildKanbanObjUtil>> getObjs(){
        Map<string, List<HomeChildKanbanObjUtil>> objmap = new Map<string, List<HomeChildKanbanObjUtil>>();
        
        List<Schema.SObjectType> objs = Schema.getGlobalDescribe().values();
        
        List<HomeChildKanbanObjUtil> sList = new List<HomeChildKanbanObjUtil>();
        List<HomeChildKanbanObjUtil> cList = new List<HomeChildKanbanObjUtil>();
        
        for(Schema.SObjectType s : objs){
            Schema.DescribeSObjectResult ds = s.getDescribe();
            if(ds.isAccessible() && ds.isQueryable()){
                HomeChildKanbanObjUtil hcu = new HomeChildKanbanObjUtil(ds.getName(), ds.getLabel());
                if(ds.isCustom()){
                    cList.add(hcu);
                }else{
                    sList.add(hcu);
                }
            }
        }
        objmap.put('standard', sList);
        objmap.put('custom', cList);
        
        return objmap;
    }
    
    @AuraEnabled
    public static Map<string, List<HomeChildKanbanCObjUtil>> getObjChilds(string objName){
        Map<string, List<HomeChildKanbanCObjUtil>> objmap = new Map<string, List<HomeChildKanbanCObjUtil>>();
        List<HomeChildKanbanCObjUtil> sList = new List<HomeChildKanbanCObjUtil>();
        List<HomeChildKanbanCObjUtil> cList = new List<HomeChildKanbanCObjUtil>();
        List<Schema.ChildRelationship> cObjs = Schema.getGlobalDescribe().get(objName).getDescribe().getChildRelationships();
        for(Schema.ChildRelationship s : cObjs){
            Schema.DescribeSObjectResult sObj = s.getChildSObject().getDescribe();
            Schema.DescribeFieldResult sFld = s.getField().getDescribe();
            if(sObj.isDeprecatedAndHidden() != true && sObj.isAccessible() && sObj.isCreateable() && sObj.isUpdateable() && sObj.isQueryable() && sFld.isFilterable() && sFld.isAccessible()){
                HomeChildKanbanCObjUtil hcu = new HomeChildKanbanCObjUtil(sObj.getName()+'~;'+sFld.getName(), sObj.getLabel()+' ('+sFld.getName()+')', sFld.getName());
                if(sObj.isCustom()){
                    cList.add(hcu);
                }else{
                    sList.add(hcu);
                }
            }
        }
        objmap.put('standard', sList);
        objmap.put('custom', cList);
        return objmap;
    }
    
    @AuraEnabled
    public static Map<string, List<HomeChildKanbanObjUtil>> getObjFlds(string objName){
        Map<string, List<HomeChildKanbanObjUtil>> objFldmap = new Map<string, List<HomeChildKanbanObjUtil>>();
        Map <String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap();
        
        List<HomeChildKanbanObjUtil> aList = new List<HomeChildKanbanObjUtil>();
        List<HomeChildKanbanObjUtil> gList = new List<HomeChildKanbanObjUtil>();
        List<HomeChildKanbanObjUtil> sList = new List<HomeChildKanbanObjUtil>();
        
        for(Schema.SObjectField sfield : fieldMap.Values())
        {
            schema.describefieldresult dfield = sfield.getDescribe();
            if(dfield.isAccessible() && dfield.isDeprecatedAndHidden() != true){
                string fldType = string.valueOf(dfield.getType());
                HomeChildKanbanObjUtil hcu = new HomeChildKanbanObjUtil(dfield.getName(), dfield.getLabel());
                aList.add(hcu);
                if(dfield.isGroupable() && dfield.isUpdateable() && fldType == 'PICKLIST'){
                    gList.add(hcu);
                }
                if(fldType == 'Double' || fldType == 'Integer' || fldType == 'Currency'){
                    sList.add(hcu);
                }
            }
        }
        objFldmap.put('all', aList);
        objFldmap.put('groupBy', gList);
        objFldmap.put('sumBy', sList);
        return objFldmap;
    }
    
    @AuraEnabled
    public static List<HomeChildKanbanObjUtil> getPickVals(String FldName, String objName){
        List<HomeChildKanbanObjUtil> plist = new List<HomeChildKanbanObjUtil>();
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap().get(FldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple)
        {
            plist.add(new HomeChildKanbanObjUtil(f.getLabel(), f.getValue()));
        }           
        return plist;
    }
    
    @AuraEnabled
    public static HomeChildKanbanUtil getKanban(String objName, List<String> objFields, String kabnanField, String ParentRecId, String relField, List<string> ExcVal, String summField, String KbObjNameField){
        //system.debug(objFields);
        if(summField != null){
            objFields.add(summField);
        }
        if(KbObjNameField != null && KbObjNameField != 'false'){
            if(Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap().get(KbObjNameField) != null){
                objFields.add(KbObjNameField);
            }
        }
        system.debug('El field es: ' + kabnanField);
        objFields.add(kabnanField);
        Set<string> obFields = new Set<string>(objFields);
        obFields.remove('Id');
        /*Checks if all the requested fields are accessible*/
        if(HomeChildKanbanUtil.checkAccessibleFLS(obFields, objName)){
            Set<string> kfldCheck = new Set<string>();
            kfldCheck.add(kabnanField);
            /*Checks if the Group By Field is Updatable*/
            if(HomeChildKanbanUtil.checkAccessibleFLS(kfldCheck, objName)){
                boolean ispdatable = HomeChildKanbanUtil.checkUpdateableFLS(kfldCheck, objName);
                
                try{
                    Schema.DescribeSObjectResult actdsc = Schema.getGlobalDescribe().get(objName).getDescribe();
                    Map<String, Schema.SObjectField> allFieldMap = actdsc.fields.getMap();
                    string agrFldName = null;
                    string sFldIsCurrency = null;
                    Map<string, decimal> aggQMap;
                    List<AggregateResult> sumQuery;
                    if(summField != null){
                        Schema.DescribeFieldResult ads = allFieldMap.get(summField).getDescribe();
                        string aftype = string.valueOf(ads.getType());                        
                        if(aftype == 'Double' || aftype == 'Integer' || aftype == 'Currency'){
                            agrFldName = ads.getLabel();
                            sFldIsCurrency = aftype;
                            aggQMap = new Map<string, decimal>(); 
                        }else{
                            return new HomeChildKanbanUtil(null, null, false, 'The field '+summField+' cannot be summarized.', null, null, null, null, null, null, null, null, null);   
                        }                          
                    }
                    
                    List<string> Pickvalslst = new List<String>();
                    List<string> PickvalslstValores = new List<String>();
                    List<OpportunityTeamMember> OpotunidadesMiembros = new List<OpportunityTeamMember>();
                    List<String> ValoresOportunidades = new List<String>();
                    Set<string> ExcVals = new Set<string>(ExcVal);
                    Map<string, list<sobject>> recMaps = new Map<string, list<sobject>>();
                    
                    for(Schema.PicklistEntry s: allFieldMap.get(kabnanField).getDescribe().getpicklistValues()){
                        if(!ExcVals.contains(s.getValue()) && s.isActive()){
                            if (s.getValue() == 'Identificada' || s.getValue() == 'Ofertada' || s.getValue() == 'En preparación'){
                                 Pickvalslst.add('\'' + s.getValue() + '\'');
                                PickvalslstValores.add(s.getValue());
                                recMaps.put(s.getValue(), new List<sobject>());
                                if(summField != null){
                                    aggQMap.put(s.getValue(), 0);    
                                }
                            }
                           
                        }
                    }
                   
                    
                    string cObName = actdsc.getLabel();
                    Schema.DescribeFieldResult utilResult = allFieldMap.get(kabnanField).getDescribe();
                    string gFldName = utilResult.getLabel();
                    boolean gFldEditable = utilResult.isUpdateable();
                    boolean isObjDeletable = actdsc.isDeletable();
                    boolean isObjectCreateable = actdsc.isCreateable();
                    
                    //For Getting a Map of field name and its type
                    Map<String, Map<String, String>> fieldTypeMap = new Map<String, Map<String, String>>();
                 
                    String qry = 'Select Id, ';
                    for(String s: obFields){
                        Schema.DescribeFieldResult currentFieldResult = allFieldMap.get(s).getDescribe();
                        string currentFieldType = string.valueOf(currentFieldResult.getType());
                        Map<String, String> currentMap = new Map<String, String>();
                        currentMap.put('type', currentFieldType);
                        if(currentFieldType == 'REFERENCE'){
                            string currentRelationName = currentFieldResult.getRelationshipName();
                            string refObjName;
                            if(currentFieldResult.isNamePointing()){
                                for(Schema.SObjectType reference : currentFieldResult.getReferenceTo()) {
                                    Schema.DescribeSObjectResult dsr = reference.getDescribe();
                                    if(dsr.isAccessible()){
                                        refObjName = dsr.getName();
                                        break;
                                    }
                                }
                                if(refObjName == null){
                                    return new HomeChildKanbanUtil(null, null, false, 'You do not have access to relational object. Please contact your administrator.', null, null, null, null, null, null, null, null, null);
                                }
                            }else{
                                refObjName = currentFieldResult.getReferenceTo()[0].getDescribe().getName();
                            }
                            string fName = HomeChildKanbanUtil.getNameField(refObjName);
                            if(fName != 'false'){
                                qry += currentRelationName+'.'+fName+' ,';
                            }else{
                                return new HomeChildKanbanUtil(null, null, false, 'You do not have access to relation object '+refObjName+'. Please contact your administrator.', null, null, null, null, null, null, null, null, null);
                            }
                            currentMap.put('relationName', currentRelationName+'~*!'+fName);
                        }
                        qry += s+' ,';
                        fieldTypeMap.put(s, currentMap);
                    }
                     
                    
                    List<Kanban_Configuration__c> kanbanConfig = [SELECT Clausula_WHERE__c FROM Kanban_Configuration__c];
                    String clausulaWhere = kanbanConfig[0].Clausula_WHERE__c;
                    String vacio = '';
                    
                    //clausulaWhere = ' Name != ""';
                       

                    qry = qry.removeEnd(',');
                    System.debug('Estados: '+Pickvalslst);
                    
                    OpotunidadesMiembros = [Select OpportunityId from OpportunityTeamMember where UserId=: UserInfo.getUserID() and Opportunity.OwnerId !=: UserInfo.getUserID() and Opportunity.StageName in('Identificada', 'En preparación', 'Ofertada')Limit 10];
                    
                    for(OpportunityTeamMember OpporMember : OpotunidadesMiembros)
                    {
                        
                         ValoresOportunidades.add('\'' + OpporMember.OpportunityId + '\'');                   
                       
                    }
                    
                  
                    
				System.debug('Oportunidades: '+ValoresOportunidades);
                    //System.debug('kanbanrecords: '+kabnanField);
                    If(String.isBlank(clausulaWhere)){
                         qry += 'From '+objName+' where '+kabnanField+ ' in' + Pickvalslst   ;
                        //Select Id, Name ,Amount ,StageName From Opportunity where StageName in ('Postpuesta','Ofertada')
                            // where id in:lIds AND IsActive = true ORDER BY Family ASC];
                        
                    }
                    else{
                        
                        if (ValoresOportunidades.Size() > 0){
                        	qry += ' From '+objName+' where '+kabnanField+' in' + Pickvalslst + ' and (OwnerId=\''+UserInfo.getUserID()+'\' or id in' + ValoresOportunidades +') and '+clausulaWhere ;
                            
                          
                        }else{
                            qry += ' From '+objName+' where '+kabnanField+' in' + Pickvalslst + ' and OwnerId=\''+UserInfo.getUserID()+'\' and '+clausulaWhere ;
                        }
                        
                        
                        System.debug('qry: '+qry);
                    }
                    
                    
                    if(ParentRecId != '' && ParentRecId != null && relField != '' && relField != null){
                        qry += ' and '+relField+'=\''+ParentRecId+'\'';
                       
                    }
                    System.debug('qry: '+qry);
                    List<sobject> Lista = database.query(qry);
                    System.debug('Lista sobject: '+Lista.size());
                    
                    for(sobject s: database.query(qry)){
                        System.debug('Debug de la linea 241 '+qry);
                        system.debug('recmap :'+recMaps);
                        recMaps.get(string.valueOf(s.get(kabnanField))).add(s);
                        system.debug('recmap get  :'+recMaps);
                        if(summField != null){
                            system.debug('recmap if summField != null:'+recMaps);
                            decimal sVal = (Decimal)s.get(summField);
                            if(sVal != null){
                                System.debug('qry linea 249: '); 
                                aggQMap.put(string.valueOf(s.get(kabnanField)), (Decimal)s.get(summField) + (Decimal)aggQMap.get(string.valueOf(s.get(kabnanField))) );    
                                System.debug('qry linea 251: ');
                            }
                        }
                    }
                    System.debug('qry linea 258: ');
                    return new HomeChildKanbanUtil(recMaps, PickvalslstValores, true, null, gFldName, cObName, agrFldName, sFldIsCurrency, aggQMap, gFldEditable, isObjDeletable, fieldTypeMap, isObjectCreateable);

                }catch (exception e){
                    System.debug('getMessage: '+ e.getMessage());
                    return new HomeChildKanbanUtil(null, null , false , e.getMessage(), null, null, null, null, null, null, null, null, null);        
                }
            }else{
                return new HomeChildKanbanUtil(null, null, false, 'You do not have access to the specified Group By field. Please contact your administrator.', null, null, null, null, null, null, null, null, null);   
            }
        }else{
            return new HomeChildKanbanUtil(null, null, false, 'You do not have access to the requested fields. Please contact your administrator.', null, null, null, null, null, null, null, null, null);   
        }       
    }
    
    @AuraEnabled
    public static string updateRec(string recId, string recField, string recVal){
        try{
            Schema.DescribeSObjectResult sObjRes = Id.valueOf(recId).getSObjectType().getDescribe();
            Schema.DescribeFieldResult fldRes = sObjRes.fields.getMap().get(recField).getDescribe();
            if(sObjRes.isAccessible() && sObjRes.isUpdateable() && fldRes.isUpdateable()){
                String sObjName = sObjRes.getName();
                sObject s = Schema.getGlobalDescribe().get(sObjName).newSObject() ;
                s.Id = recId;
                s.put(recField, recVal);
                update s;
                return 'true';
            }else{
                return 'You do not have update access to object. Please contact your administrator.';
            }
            
        }
        catch(exception e){
            return e.getMessage();
        }
    }
    
    @AuraEnabled
    public static string deleteRec(sobject obj){
        Schema.DescribeSObjectResult sObjRes = Id.valueOf(obj.Id).getSObjectType().getDescribe();
        if(sObjRes.isDeletable()){
            try{
                delete obj;
                return 'true';
            }catch(exception e){
                return e.getMessage();
            }
        }else{
            return 'You do not have permissions to delete the record. Please contact your administrator.';
        }
    }
    
    
}