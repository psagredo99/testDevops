public class AsistenteOportunidadesController {
    private final Order pedido;
    public static String idCuentaSF;
    public static Map<String, Product2> choosenProductMap = new Map<String, Product2>(); //Mapa de productos seleccionados en las líneas encasillados por su I
    public static Set<Id> prodTarifaClienteSet = new Set<Id>(); //Set de Ids de productos que tiene tarifas específicas para el cliente seleccionado
    public static Map<String, Decimal> stockProductMap = new Map<String, Decimal>();
    Public Static Id idUIsuario = UserInfo.getUserId();
    
    @AuraEnabled
    public static List<Account> getAccounts(String query)
    {
        List<Account> accList = Database.query(query);
        return accList;
    }
    
    @AuraEnabled
    public static List<AsistenteOportunidadesController.ProductWrapper> getAllFavoritos()
    {
        list<Product2> lProductos = new list<Product2>();
        list<string> lIds = new list<string>();
        for(Servicios_Favoritos__c pf : [select Servicio__c
                                       from Servicios_Favoritos__c
                                       where Usuario__c = :idUIsuario])
        {
            lIds.add(pf.Servicio__c);
        }

        if(lIds.size() > 0)
        {
            lProductos = [select Id, Name, ProductCode,Family,Grupo_de_Servicios__c
                          from Product2
                          where id in:lIds AND IsActive = true ORDER BY Family ASC];
            
         }

       
        
         List<AsistenteOportunidadesController.ProductWrapper> wrapperList = new List<AsistenteOportunidadesController.ProductWrapper>();


        //Recorremos el listado de productos y nos montamos el wrapper que añadimos a una lista y será lo que se devuelva
        for(Product2 productData : lProductos)
        {
            AsistenteOportunidadesController.ProductWrapper wrapper = new AsistenteOportunidadesController.ProductWrapper();
            wrapper.producto = productData;
            wrapper.Precio = 0;
            
         

            wrapperList.add(wrapper);
        }
         System.debug('WrapperList' + wrapperList);
        return wrapperList;
    }
    
     @AuraEnabled
    public static void addFavouriteProduct(string idProduct)
    {
        Servicios_Favoritos__c pf = new Servicios_Favoritos__c();
        pf.Usuario__c = idUIsuario;
        pf.Servicio__c = idProduct;
        insert pf;
    }
     @AuraEnabled
    public static void deleteFavouriteProduct(string idProduct)
    {
        System.debug('El usuario es: ' + idUIsuario + 'Con el producto... ' + idProduct);
        list<Servicios_Favoritos__c> pf = [select id from Servicios_Favoritos__c where Usuario__c=:idUIsuario and Servicio__c=:idProduct];
        delete pf;
    }
    

   
    @AuraEnabled
    public static String cargarDatosPedido(String idPedido)
    {
        System.debug('--------- AsistentePedidosController: CargarDatospedido ---------');
        String result = '';

        try
        {
            //La respuesta de la función
            Map<String, Object> resultMap = new Map<String, Object>();

            List<Opportunity> pedidoList = [SELECT Id, Name, AccountId
                                      FROM Opportunity
                                      WHERE Id = :idPedido
                                      LIMIT 1];

            System.debug('--------- Slect ---------');
            if(pedidoList != null && pedidoList.size() > 0)
            {
                Opportunity pedido = pedidoList[0];

                resultMap.put('pedido', pedido);
                
                if(String.isNotBlank(pedido.AccountId))
                {
                    resultMap.put('idCuenta', pedido.AccountId);

                }

                List<OpportunityLineItem> lineas = [SELECT Id, Name,Quantity,Description,Discount,ServiceDate,OpportunityId,ListPrice,UnitPrice,TotalPrice,Product2Id,Subtotal
                                          FROM OpportunityLineItem 
                                          WHERE OpportunityId = :idPedido];

                
                Set<Id> productIdSet = new Set<Id>();
                
                Decimal totalPedido = 0;
                for(OpportunityLineItem linea : lineas)
                {

                    if(String.isNotBlank(linea.Product2Id))
                    {
                        system.debug('Tiene esta ID: ' +linea.Product2.Id);
                        productIdSet.add(linea.Product2.Id);
                        choosenProductMap.put(linea.Product2.Id, new Product2(Id = linea.Product2.Id, Name = linea.Product2.Name, ProductCode = linea.Product2.ProductCode, Family = linea.Product2.Family, Grupo_de_Servicios__c = linea.Product2.Grupo_de_Servicios__c));
                    }

                   

                    totalPedido += linea.TotalPrice;
                }
                resultMap.put('importeTotalPedido', totalPedido);
                resultMap.put('totalProductosPedido', lineas.size());


                List<ChoosenProductWrapper> lineaWrapperList = lineasToWrapperList(lineas, null);
                resultMap.put('productData', lineaWrapperList);

            }
            result = JSON.serialize(resultMap);

        }
        catch(Exception e)
        {
            result = 'ERROR: Línea ' + e.getLineNumber() + ', ' + e.getMessage();
        }

        return result;
    }

  
    @AuraEnabled
    public static String getOrgUrl(String id)
    {
        Id objectOrigen = id;
        String s = URL.getSalesforceBaseUrl().toExternalForm();
        String tipoObjeto = '';
        if(id != null)
        {
            if(Test.isRunningTest())
            {
                tipoObjeto = 'Opportunity';
            }
            else
            {

                tipoObjeto = String.valueOf(objectOrigen.getSObjectType());
            }
        }
        if(tipoObjeto == 'Opportunity' || tipoObjeto == 'Account')
        {
            s = URL.getSalesforceBaseUrl().toExternalForm() + '>' + tipoObjeto;
        }
        return s;
    }
   
    

    /*
     *  Método de busqueda de productos según ciertos criterios, como pueden ser que su nombre contenga "X"
     *  @param  query       Condicionales para la quey de productos a devolver.
     *  @param  idCuenta    Identificativo de la cuenta para obtener su lista de precios, por ende los productos.
     *
     *  @return List<List<AsistentePedidosController.ProductWrapper>> Wrapper personalizado con datos de interés.
     */
    @AuraEnabled
    public static List<AsistenteOportunidadesController.ProductWrapper> buscadorProductos(String query, String idCuenta)
    {

        idCuentaSF = idCuenta;
       

       
        List<Product2> lstProductos = new List<Product2>();

        if(query == null)
        {
            lstProductos = [SELECT Id, Name, ProductCode,Family,Grupo_de_Servicios__c
                            FROM Product2
                            WHERE IsActive = true
                            ORDER BY Family ASC];
            
             System.debug('Primera Busqueda' + lstProductos);
        }else
        {
            String sql = 'Select Id, Name, ProductCode,Family,Grupo_de_Servicios__c' + 
                     ' from Product2 ' + query + 
                     ' AND IsActive = true' + 
                     ' ORDER BY Family ASC LIMIT 20';

            lstProductos = Database.query(sql);
        }

        Set<Id> productIDs = new Set<Id>();
        for(Product2 prod : lstProductos)
        {
            
            productIDs.add(prod.Id);
            
        }


        List<AsistenteOportunidadesController.ProductWrapper> wrapperList = new List<AsistenteOportunidadesController.ProductWrapper>();


        //Recorremos el listado de productos y nos montamos el wrapper que añadimos a una lista y será lo que se devuelva
        for(Product2 productData : lstProductos)
        {
            AsistenteOportunidadesController.ProductWrapper wrapper = new AsistenteOportunidadesController.ProductWrapper();
            wrapper.producto = productData;
            wrapper.Precio = 0;
            
         

            wrapperList.add(wrapper);
        }
         System.debug('WrapperList' + wrapperList);
        return wrapperList;
    }

    /*
     *  Método que genera el pedido y sus líneas,
     *  vuelve a generar los datos de los productos seleccionados (para que así cada línea tenga un ID de OrderItem asignada)
     *  y finalmente genera el PDF con los datos del pedido.
     *
     *  Si cualquiera de estos paso falla, devolverá una cadena de "ERROR: (Mensaje de error)".
     *  Si todo va bien, devolverá un mapa serializado con los datos de los productos seleccionados por un lado y el ID del documento generado por el otro.
     *
     *  @param  idPedido    ID del pedido (estaría indformado en el caso de haber vuelto al paso anterior y volver al último paso de nuevo).
     *  @param  idCuenta    ID de la cuenta seleccionada.
     *  @param  lineasData  Listado los datos de los productos seleccionados. Lista wrappers ChoosenProduct serializada.
     *  @param  fecha       Fecha del pedido seleccionada.
     *  @param  direccion   Dirección del pedido. EntidadCG_NavDireccionEnvio__c serializada.
     *  @param  descripcion Descripción del pedido.
     */
    
    @AuraEnabled
    public static  List<ChoosenProductWrapper> buscadorServicios(String IdOportunidad){
         List<ChoosenProductWrapper> choosenProductList = new List<ChoosenProductWrapper>();
        
         System.debug('oportunidad:' + IdOportunidad);
        
        List<OpportunityLineItem> lineas = [SELECT Id, Name,Quantity,Description,Discount,ServiceDate,OpportunityId,ListPrice,UnitPrice,TotalPrice,Product2Id,Subtotal
                                          FROM OpportunityLineItem 
                                          WHERE OpportunityId = :IdOportunidad];
      
        for(OpportunityLineItem linea : lineas){
            System.debug('Lineaa:' + linea.Product2Id);
            
            List<Product2> Productos = [SELECT Id, Name,ProductCode,Family,Grupo_de_Servicios__c
                                          FROM Product2 
                                          WHERE Id = :linea.Product2Id];
            for(Product2 producto : Productos){
                 choosenProductMap.put(producto.Id, new Product2(Id = producto.Id, Name = producto.Name, ProductCode = producto.ProductCode, Family = producto.Family, Grupo_de_Servicios__c = producto.Grupo_de_Servicios__c));
              
            }
           
        }
        System.debug('Lineas:' + lineas);
        choosenProductList = lineasToWrapperList(lineas, null);
         System.debug('Lineas2:' + choosenProductList);
        return choosenProductList;
    }
    
    @AuraEnabled
    public static String EliminarServicio(String idOportunidad,Map<String, Object> item){
          //La respuesta de la función
        Map<String, String> resultMap = new Map<String, String>();

        String result = '';

       

        //Savepoint sp = Database.setSavepoint();

        try
        {
           

          
            
            Date fechaDate = date.today();
          

            List<OpportunityLineItem> lineasPedidoSF = new List<OpportunityLineItem>();
            
         
              lineasPedidoSF = [SELECT Id,OpportunityId
                                          FROM OpportunityLineItem 
                                          WHERE OpportunityId = :idOportunidad];
            
            List<Database.SaveResult> pedidoSaveResults = new List<Database.SaveResult>();
         

            result = checkSaveResults(pedidoSaveResults, result);

            //Si no ha habido ningún problema con el pedido, prosigue con la creación/actualización/eliminación de líneas
            if(String.isBlank(result))
            {
            
                Set<String> IDsLineasSFenWrapper = new Set<String>();                             
                    
                    
                  system.debug('Que contiene item ' + item);
                String idLinea = String.valueOf(item.get('Id'));
                system.debug('Que contiene linea ' + idLinea);
                IDsLineasSFenWrapper.add(idLinea);
                       
                  
                List<OpportunityLineItem> lineasToDelete = new List<OpportunityLineItem>();
                for(OpportunityLineItem linea : lineasPedidoSF)
                {
                    if(IDsLineasSFenWrapper.contains(linea.Id))
                    {
                        lineasToDelete.add(linea);
                    }
                }
                System.debug('Antes de borrar');
                if(lineasToDelete.size() > 0)
                {
                  
                    delete lineasToDelete;
                }
                
                
               
                

                
               
                
                

                if(String.isBlank(result))
                {

                    List<OpportunityLineItem> lineasPedido = new List<OpportunityLineItem>();
                   
                          
                    result = JSON.serialize(resultMap);
                    //}

                }
            }

        }
        catch(Exception e)
        {
            // Rollback database.
            //Database.rollback(sp);
            result += 'ERROR: Line ' + e.getLineNumber() + ', ' + e.getMessage();
        }
        System.debug('Retornaaa?');
        return result;
       
    }
    
    
    @AuraEnabled
    public static String ActualizarServicio(String idOportunidad,Map<String, Object> item){
              //La respuesta de la función
        Map<String, String> resultMap = new Map<String, String>();

        String result = '';
		
        
        
       

        //Savepoint sp = Database.setSavepoint();

        try
        {
           

          
            
            Date fechaDate = date.today();
          

            List<OpportunityLineItem> lineasPedidoSF = new List<OpportunityLineItem>();
            
         
              lineasPedidoSF = [SELECT Id,OpportunityId,UnitPrice
                                          FROM OpportunityLineItem 
                                          WHERE OpportunityId = :idOportunidad];
            
            List<Database.SaveResult> pedidoSaveResults = new List<Database.SaveResult>();
         

            result = checkSaveResults(pedidoSaveResults, result);

            //Si no ha habido ningún problema con el pedido, prosigue con la creación/actualización/eliminación de líneas
            if(String.isBlank(result))
            {
            
                Set<String> IDsLineasSFenWrapper = new Set<String>();                             
                    
                    
                  system.debug('Que contiene item ' + item);
                String idLinea = String.valueOf(item.get('Id'));
                system.debug('Que contiene linea ' + idLinea);
                IDsLineasSFenWrapper.add(idLinea);
                       
                  
                List<OpportunityLineItem> lineasToActualizar = new List<OpportunityLineItem>();
                for(OpportunityLineItem linea : lineasPedidoSF)
                {
                    if(IDsLineasSFenWrapper.contains(linea.Id))
                    {
                        linea.UnitPrice =  Decimal.valueOf(String.valueOf(item.get('TotalPrice')));
                       
                        lineasToActualizar.add(linea);
                    }
                }
                System.debug('Antes de actulizar');
                if(lineasToActualizar.size() > 0)
                {
                  
                    update lineasToActualizar;
                }
                
                
               
                

                
               
                
                

                if(String.isBlank(result))
                {

                    List<OpportunityLineItem> lineasPedido = new List<OpportunityLineItem>();
                   
                          
                    result = JSON.serialize(resultMap);
                    //}

                }
            }

        }
        catch(Exception e)
        {
            // Rollback database.
            //Database.rollback(sp);
            result += 'ERROR: Line ' + e.getLineNumber() + ', ' + e.getMessage();
        }
        System.debug('Retornaaa?');
        return result;
    }
    
    
    @AuraEnabled  
    public static String AnadirServicio(String idOportunidad, Map<String, Object> item){
         Map<String, String> resultMap = new Map<String, String>();

        String result = '';
        System.debug('Segun entra: ' + item);
       
        try
        {
           
            Date fechaDate = date.today();
            List<Database.SaveResult> pedidoSaveResults = new List<Database.SaveResult>();
         

            
            System.debug('Justo antes de Guardar');
            result = checkSaveResults(pedidoSaveResults, result);
            System.debug('Justo Despues de Guardar');
            //Si no ha habido ningún problema con el pedido, prosigue con la creación/actualización/eliminación de líneas
            if(String.isBlank(result))
            {
            
                

                // Creamos las líneas del pedido.
                List<OpportunityLineItem> lineasToInsert = new List<OpportunityLineItem>();
                 
              
              
                Double TotalLineas = 0;
                Set<String> IDsLineasSFenWrapper = new Set<String>();
               
               
                System.debug('Item' + item);
                String datosProd = JSON.serializePretty(item.get('producto'));
                System.debug('Producto' + datosProd);
                OpportunityLineItem linea = new OpportunityLineItem();
                linea.OpportunityId = idOportunidad;
                linea.Quantity = 1;
                linea.Discount = 0;   
                
                
                
                
                linea.ServiceDate = fechaDate;
                
                //linea.ListPrice = 0;
                linea.UnitPrice = Decimal.valueOf(String.valueOf(item.get('TotalPrice')));
                //linea.TotalPrice = linea.UnitPrice * linea.Quantity;
                System.debug('Siq eu llega no' + item);
                
                if(item.get('producto') != null)
                {
                    Map<String, Object> prodData = (Map<String, Object>)JSON.deserializeUntyped(datosProd);
                    Product2 prod = (Product2) JSON.deserialize(datosProd, Product2.class);
                    
                    List<PricebookEntry> priceBookIdEntry = [SELECT Id
                                                             FROM PricebookEntry
                                                             WHERE Product2Id = :prod.Id AND Pricebook2Id = :'01s68000003RdvfAAC'];
                    
                    linea.PricebookEntryId = priceBookIdEntry[0].id;
                    
                    linea.Product2Id = prod.Id;
                    //linea.ProductCode =prod.ProductCode;
                    //linea.Name= prod.Name;  
                    choosenProductMap.put(String.valueOf(prodData.get('Id')), (Product2) JSON.deserialize(datosProd, Product2.class));
                    
                    
                    
                }
                
                
                
                
                
                
                
                
                
                
                
                String idLinea = String.valueOf(item.get('Id'));
                
                if(idLinea != null && String.isNotBlank(idLinea) && idLinea != '""' && idLinea != 'null')
                {
                    linea.Id = idLinea;
                }
                
                
                
                
                
                lineasToInsert.add(linea);
                
                

                               
                       
                   
                
                
               
                System.debug('Vayaaa');
                
                
                
                //Si en el listado de líneas (WRAPPER) no están las líneas existentes en SF del pedido actual, las borra
               
                
                  System.debug('Antes de Insertar' + lineasToInsert);
                if(lineasToInsert.size() > 0)
                {
                    List<Database.SaveResult> lineInsResult = Database.insert (lineasToInsert, true);
                    result += checkSaveResults(lineInsResult, result);
                }
                
               
                

                if(String.isBlank(result))
                {

                    List<OpportunityLineItem> lineasPedido = new List<OpportunityLineItem>();
                    lineasPedido.addAll(lineasToInsert);
                          
                    result = JSON.serialize(resultMap);
                    //}

                }
            }

        }
        catch(Exception e)
        {
            // Rollback database.
            //Database.rollback(sp);
            result += 'ERROR: Line ' + e.getLineNumber() + ', ' + e.getMessage();
        }
        System.debug('Retornaaa?');
        return result;

    }
  
    @AuraEnabled
    public static String guardarBorrador(String idOportunidad, String lineasData)
    {
       
        
        //La respuesta de la función
        Map<String, String> resultMap = new Map<String, String>();

        String result = '';

        // lineasData: productos seleccionados.
        List<Object> lstLineasObj = (List<Object>)JSON.deserializeUntyped(lineasData);
        List<Map<String, Object>> lstLineasData = new List<Map<String, Object>>();
        for(Object instance : (List<Object>)lstLineasObj)
        {
            lstLineasData.add((Map<String, Object>)instance);
        }

        //Savepoint sp = Database.setSavepoint();

        try
        {
           

            // Id salesforceRTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Salesforce').getRecordTypeId();

              
           
            //PricebookEntry entry = new PricebookEntry(Id = '01s68000003RdvfAAC');
            
            
            
            
            
           
            


          
            
            Date fechaDate = date.today();
          

            List<OpportunityLineItem> lineasPedidoSF = new List<OpportunityLineItem>();
            
         
              lineasPedidoSF = [SELECT Id,OpportunityId
                                          FROM OpportunityLineItem 
                                          WHERE OpportunityId = :IdOportunidad];
            
            List<Database.SaveResult> pedidoSaveResults = new List<Database.SaveResult>();
         

            // for(String idDivision : pedidosDivision)
            // {
            //     Order division = new Order(Id=idDivision);
            //     division.Pedido_rotura__c    = idPedido;
            //     System.debug('++ Update pedido: '+ division);
            //     update division;
            // }
            System.debug('Justo antes de Guardar');
            result = checkSaveResults(pedidoSaveResults, result);
            System.debug('Justo Despues de Guardar');
            //Si no ha habido ningún problema con el pedido, prosigue con la creación/actualización/eliminación de líneas
            if(String.isBlank(result))
            {
                System.debug('Entra?');
                

                // Creamos las líneas del pedido.
                List<OpportunityLineItem> lineasToInsert = new List<OpportunityLineItem>();
                 
                List<OpportunityLineItem> lineasToUpdate = new List<OpportunityLineItem>();
              
                Double TotalLineas = 0;
                Set<String> IDsLineasSFenWrapper = new Set<String>();
                System.debug('Llegaaaaaaaaa' + lstLineasData);
                for(Map<String, Object> item : lstLineasData)
                {
                    System.debug('Item' + item);
                    String datosProd = JSON.serializePretty(item.get('producto'));
                    System.debug('Producto' + datosProd);
                    OpportunityLineItem linea = new OpportunityLineItem();
                    linea.OpportunityId = idOportunidad;
                    linea.Quantity = 1;
                    linea.Discount = 0;   
                    
                    
                    
                  
                    linea.ServiceDate = fechaDate;
                                        
                    //linea.ListPrice = 0;
                    linea.UnitPrice = Decimal.valueOf(String.valueOf(item.get('TotalPrice')));
                    //linea.TotalPrice = linea.UnitPrice * linea.Quantity;
                    System.debug('Siq eu llega no' + item);
                        
                     if(item.get('producto') != null)
                    {
                        Map<String, Object> prodData = (Map<String, Object>)JSON.deserializeUntyped(datosProd);
                        Product2 prod = (Product2) JSON.deserialize(datosProd, Product2.class);
                        
                         List<PricebookEntry> priceBookIdEntry = [SELECT Id
                                                 FROM PricebookEntry
                                                 WHERE Product2Id = :prod.Id AND Pricebook2Id = :'01s68000003RdvfAAC'];
                        
                            linea.PricebookEntryId = priceBookIdEntry[0].id;

                        linea.Product2Id = prod.Id;
                        //linea.ProductCode =prod.ProductCode;
                        //linea.Name= prod.Name;  
                        choosenProductMap.put(String.valueOf(prodData.get('Id')), (Product2) JSON.deserialize(datosProd, Product2.class));
                      


                    }
                    
                    



                   
                   
                   
                    
                    
                
                    String idLinea = String.valueOf(item.get('Id'));

                    if(idLinea != null && String.isNotBlank(idLinea) && idLinea != '""' && idLinea != 'null')
                    {
                        linea.Id = idLinea;
                    }

                    
                     

                    if(String.isNotBlank(linea.Id))
                    {
                        IDsLineasSFenWrapper.add(linea.Id);
                        lineasToUpdate.add(linea);
                    }
                    else
                    {
                        lineasToInsert.add(linea);
                    }
                   

                               
                       
                   
                }
                
               
                System.debug('Vayaaa');
                
                List<OpportunityLineItem> lineasToDelete = new List<OpportunityLineItem>();
                for(OpportunityLineItem linea : lineasPedidoSF)
                {
                    if(!IDsLineasSFenWrapper.contains(linea.Id))
                    {
                        lineasToDelete.add(linea);
                    }
                }
                System.debug('Antes de borrar');
                if(lineasToDelete.size() > 0)
                {
                  
                    delete lineasToDelete;
                }
                
                //Si en el listado de líneas (WRAPPER) no están las líneas existentes en SF del pedido actual, las borra
               
                
                  System.debug('Antes de Insertar' + lineasToInsert);
                if(lineasToInsert.size() > 0)
                {
                    List<Database.SaveResult> lineInsResult = Database.insert (lineasToInsert, true);
                    result += checkSaveResults(lineInsResult, result);
                }
                
               
                System.debug('Antes de updatear');
                if(lineasToUpdate.size() > 0)
                {
                    List<Database.SaveResult> lineUpdResult = Database.update (lineasToUpdate, true);
                    result += checkSaveResults(lineUpdResult, result);
                }
                

                if(String.isBlank(result))
                {

                    List<OpportunityLineItem> lineasPedido = new List<OpportunityLineItem>();
                    lineasPedido.addAll(lineasToInsert);
                          
                    result = JSON.serialize(resultMap);
                    //}

                }
            }

        }
        catch(Exception e)
        {
            // Rollback database.
            //Database.rollback(sp);
            result += 'ERROR: Line ' + e.getLineNumber() + ', ' + e.getMessage();
        }
        System.debug('Retornaaa?');
        return result;
    }

  

    @AuraEnabled
    public static String cargarPlantilla(String idPedido)
    {

        String result = '';

        try
        {
            result = idPedido;
        }
        catch(Exception e)
        {
            result += 'ERROR: Line ' + e.getLineNumber() + ', ' + e.getMessage();
        }

        return result;
    }

    public static List<ChoosenProductWrapper> lineasToWrapperList(List<OpportunityLineItem> lineas, String accountId)
    {
        String res = 'OK';

        Set<Id> productIDs = new Set<Id>();

        List<ChoosenProductWrapper> choosenProductList = new List<ChoosenProductWrapper>();

        Integer prodPosition = 1;
        for(OpportunityLineItem linea : lineas)
        {
            
            ChoosenProductWrapper choosenProduct = new ChoosenProductWrapper();
            choosenProduct.Cantidad = linea.Quantity;
            choosenProduct.Discount = linea.Discount;
            choosenProduct.Id = linea.Id;
            choosenProduct.Subtotal = linea.Subtotal;
            choosenProduct.UnitPrice = linea.UnitPrice;
            choosenProduct.TotalPrice = linea.UnitPrice * linea.Quantity;
            choosenProduct.Descripcion = linea.Description;          
            choosenProduct.producto = choosenProductMap.get(linea.Product2Id);
            choosenProduct.Name = linea.Name;
            choosenProduct.NumItem = prodPosition;
         
          
            
           
            choosenProductList.add(choosenProduct);
            
            prodPosition++;
        }

        return choosenProductList;
    }

    

  

   

   

    //obtenemos el último precio ofrecido para este producto
 

   
  
  
    
    public static String checkSaveResults(List<Database.SaveResult> saveResults, String result)
    {
        for(Database.SaveResult saveResult : saveResults)
        {

            if(!saveResult.isSuccess())
            {

                if(String.isBlank(result))
                {
                    result = 'ERROR: ';
                }

                for(Database.Error error : saveResult.getErrors())
                {
                    result += error.getMessage() + '\n';
                }
            }
        }

        return result;
    }

   
  

   

    public class ProductWrapper
    {
        @AuraEnabled
        public Product2 producto{ get; set; }
        
         @AuraEnabled
        public double Precio{ get; set; }

        // @AuraEnabled public List<Tarifa__c> tarifas {get;set;}
    }

    public class ChoosenProductWrapper
    {
           
        @AuraEnabled
        public String Id{ get; set; }
        
        @AuraEnabled
        public String Name{ get; set; }

        @AuraEnabled
        public Decimal Cantidad{ get; set; }

        @AuraEnabled
        public Decimal UnitPrice{ get; set; }

        @AuraEnabled
        public Decimal Subtotal{ get; set; }

        
        @AuraEnabled
        public Decimal TotalPrice{ get; set; }

        @AuraEnabled
        public Decimal PrecioCaja{ get; set; }

        @AuraEnabled
        public Decimal Discount{ get; set; }

        @AuraEnabled
        public String Descripcion{ get; set; }

        @AuraEnabled
        public Integer NumItem{ get; set; }

        @AuraEnabled
        public Product2 producto{ get; set; }


        @AuraEnabled
        public String Pricebook2Id{ get; set; }   
        
      

    }

}