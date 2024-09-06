/**
 * @description       : 
 * @author            : iker.lougedo
 * @group             : 
 * @last modified on  : 30-03-2023
 * @last modified by  : iker.lougedo
**/
public with sharing class ComponenteFoto
{
    public ComponenteFoto() {}

    @AuraEnabled(cacheable=true)
    public static sObject obtenerIdCampo(Id recordId, String objectApiName, String campoRecordId)
    {
        String query = 'SELECT ' +  campoRecordId + ' FROM ' +  objectApiName + ' WHERE ID = \'' + recordId + '\' LIMIT 1';
        sObject idRegistroSeleccionado = Database.query(query);
        return idRegistroSeleccionado;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> obtenerCampos(String objetoSeleccionado , String accionRapida)
    {
        List<String> query = new List<String>();
        query.add(objetoSeleccionado + '.' + accionRapida);

        List<String> camposString = new List<String>();
        List<QuickAction.DescribeQuickActionResult> result = QuickAction.DescribeQuickActions(query);

        for(QuickAction.DescribeQuickActionResult item : result)
        {
            QuickAction.DescribeLayoutSection layout = item.getLayout();
            
            for (QuickAction.DescribeLayoutRow lstRows : layout.getLayoutRows())
            {
                for (QuickAction.DescribeLayoutItem rowItem : lstRows.getLayoutItems())
                {                    
                    for (QuickAction.DescribeLayoutComponent lstcomponent : rowItem.getLayoutComponents())
                    {
                        camposString.add(lstcomponent.getValue());
                    }
                }
            }
        }

        return camposString;
    }


    @AuraEnabled(cacheable=false)
    public static sObject obtenerDatosFoto(Id idRegistroSeleccionado, String objetoSeleccionado, String campoURLFoto, String campoTextoFoto)
    {
        String query = '';
        if (campoTextoFoto != null) {
            query = 'SELECT ' +  campoURLFoto + ',' + campoTextoFoto + ' FROM ' +  objetoSeleccionado + ' WHERE ID = \'' + idRegistroSeleccionado + '\' LIMIT 1';
        }else {
            query = 'SELECT ' +  campoURLFoto + ' FROM ' +  objetoSeleccionado + ' WHERE ID = \'' + idRegistroSeleccionado + '\' LIMIT 1';
        }

        sObject datosFoto = Database.query(query);
        return datosFoto;
    }
}