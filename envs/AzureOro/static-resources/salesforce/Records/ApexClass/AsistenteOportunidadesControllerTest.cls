@istest
public class AsistenteOportunidadesControllerTest {
        static Account padre;
    static Account account;
    static OpportunityLineItem lp;
    static Opportunity pedido;

    static Product2 producto1;
    static Product2 producto2;
    static Pricebook2 pricebook;
    static PricebookEntry pricebookentry;
    static AsistenteOportunidadesController.ChoosenProductWrapper choosenProduct;
    
    
      public static void generateData()
    {
        Id idUIsuario = UserInfo.getUserId();
        User usuario  = [SELECT Id  FROM User WHERE Id = :idUIsuario LIMIT 1];
        Date today = Date.today();

        padre = new Account();
        padre.Name = 'Padre';
        padre.type = 'Cliente';
        insert padre;
        account = new Account();
        account.Name = 'Account';
        account.type = 'Cliente';
        account.ParentId = padre.Id;
        insert account;

        producto1 = new Product2();
        producto1.Name = 'Producto1';
        producto1.ProductCode = 'Code1';
        insert producto1;
        
        producto2 = new Product2();
        producto2.Name = 'Producto2';
        producto2.ProductCode = 'Code2';
        insert producto2;
        
        
        Id pricebookId = Test.getStandardPricebookId();
        
        pricebook = new Pricebook2();
        pricebook.Name = 'Test';
        pricebook.IsActive = true;
        insert pricebook;
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = producto1.Id,
            UnitPrice = 1, IsActive = true);
            insert standardPrice;
            
            PricebookEntry price = new PricebookEntry(
                Pricebook2Id = pricebook.Id, Product2Id = producto1.Id,
            UnitPrice = 1, IsActive = true);
            insert price;

          
            
       
        
        
        
        pedido = new Opportunity();
        pedido.Name = 'Test';
        pedido.AccountId = account.Id;                          
        pedido.CloseDate = date.today();                          
        pedido.StageName = 'Nuevo';
        pedido.Pricebook2Id = pricebookId; 
        insert pedido;
        


        lp = new OpportunityLineItem();
        lp.Product2Id = producto1.Id;
        lp.Product2 = producto1;
        lp.Quantity = 1;
        lp.OpportunityId = pedido.Id;      
        lp.UnitPrice = 1;
        lp.Description ='';
        lp.PricebookEntryId = standardPrice.Id;
        insert lp;

        choosenProduct = new AsistenteOportunidadesController.ChoosenProductWrapper();
        choosenProduct.Cantidad    = lp.Quantity;
        choosenProduct.Id = lp.Id;
        choosenProduct.TotalPrice = lp.TotalPrice;
        choosenProduct.UnitPrice  = lp.UnitPrice ;
        choosenProduct.PrecioCaja = 0;
       choosenProduct.Pricebook2Id = '01s68000003RdvfAAC';
        choosenProduct.producto    = lp.Product2;
        choosenProduct.NumItem     = 0;
        choosenProduct.Descripcion = '';
    }
    
    
    @istest
    private static void getAccountsTest() {
        generateData();
        String query = 'SELECT Name,Id FROM Account  '+ account.Name;
        AsistenteOportunidadesController.getAccounts(query);
    }
    
    @istest
    private static void cargarDatosPedidoTest() {
        generateData();

        AsistenteOportunidadesController.cargarDatosPedido(pedido.Id);    
    }
    @istest
    private static void buscadorServiciosTest(){
          generateData();

        AsistenteOportunidadesController.buscadorServicios(pedido.Id);    
    }
    
    @istest
    private static void EliminarServicioTest(){
         generateData();
       
         String LineasData = '[{"Id":"' + lp.Id + '", "Cantidad":"2", "Descuento":"0", "PrecioBase":"1", "TotalPrice":"1", "ImporteTotal":"1","PrecioCaja":"1","PrecioUnitario":"1", "Descripcion":"desc", "producto":' + JSON.serialize(producto1) + '}]';
         List<Object> lstLineasObj = (List<Object>)JSON.deserializeUntyped(LineasData);
        List<Map<String, Object>> lstLineasData = new List<Map<String, Object>>();
        for(Object instance : (List<Object>)lstLineasObj)
        {
            lstLineasData.add((Map<String, Object>)instance);
        }

        
        Map<String, Object> item = lstLineasData[0];

       
        AsistenteOportunidadesController.EliminarServicio(pedido.Id,item);    
    }
    
    @istest
    private static void ActualizarServicioTest(){
         generateData();
       
         String LineasData = '[{"Id":"' + lp.Id + '", "Cantidad":"2", "Descuento":"0", "PrecioBase":"1", "TotalPrice":"1", "ImporteTotal":"1","PrecioCaja":"1","PrecioUnitario":"1", "Descripcion":"desc", "producto":' + JSON.serialize(producto1) + '}]';
         List<Object> lstLineasObj = (List<Object>)JSON.deserializeUntyped(LineasData);
        List<Map<String, Object>> lstLineasData = new List<Map<String, Object>>();
        for(Object instance : (List<Object>)lstLineasObj)
        {
            lstLineasData.add((Map<String, Object>)instance);
        }

        
        Map<String, Object> item = lstLineasData[0];

       
        AsistenteOportunidadesController.ActualizarServicio(pedido.Id,item);    
    }
    
    
    
    @istest
    private static void AnadirServicioTest(){
        generateData();
       
         String LineasData = '[{"Id":"' + lp.Id + '", "Cantidad":"2", "Descuento":"0", "PrecioBase":"1", "TotalPrice":"1", "ImporteTotal":"1","PrecioCaja":"1","PrecioUnitario":"1", "Descripcion":"desc", "producto":' + JSON.serialize(producto1) + '}]';
         List<Object> lstLineasObj = (List<Object>)JSON.deserializeUntyped(LineasData);
        List<Map<String, Object>> lstLineasData = new List<Map<String, Object>>();
        for(Object instance : (List<Object>)lstLineasObj)
        {
            lstLineasData.add((Map<String, Object>)instance);
        }

        
        Map<String, Object> item = lstLineasData[0];

       
        AsistenteOportunidadesController.AnadirServicio(pedido.Id,item);    
    }
    @istest  
    private static void getOrgUrlTest(){
        generateData();
        
        AsistenteOportunidadesController.getOrgUrl(pedido.Id);
    }
    @istest
    private static void buscadorProductosTest()
    {
        generateData();
        String query = ' WHERE IsActive = true ';

        String productoId = producto1.Id;

        AsistenteOportunidadesController.buscadorProductos(null,account.Id);
        AsistenteOportunidadesController.buscadorProductos(query,account.Id);
    }

    @istest
    private static void guardarBorradorTest()
    {
        generateData();

        String direccion = '{"attributes":{"type":"CG_Address__c"},"CG_Direccion__c":null,"CG_PostalCode__c":null,"CG_Country__c":"ES","CG_Population__c":null,"CG_Account__c":"'+account.Id+'3X000038wFhQQAU","Name":"Prueba Borrar 202012041014","cadenaDireccion":"ES"}';

        List<OpportunityLineItem> lineasPedido = new List<OpportunityLineItem>();
        lineasPedido.add(lp);
        String pedidoId = pedido.Id;
        String cuentaId = account.Id;
        String lineasData = '[{"Id":"' + lp.Id + '", "Cantidad":"2", "Descuento":"0", "PrecioBase":"1", "TotalPrice":"1", "ImporteTotal":"1","PrecioCaja":"1","PrecioUnitario":"1", "Descripcion":"desc", "producto":' + JSON.serialize(producto1) + '}]';
        String descripcion = 'Test';
        Date fecha = Date.today();
        String fechaConvertida = String.valueOf(fecha);
        String numDoc = '123';
        String tarifa = '';
        List<OpportunityLineItem> lineas = new List<OpportunityLineItem>();
        lineas.add(lp);

        Id pricebookId = Test.getStandardPricebookId();
        
        test.startTest();
        AsistenteOportunidadesController.guardarBorrador(pedidoId, lineasData); 
        test.stopTest();
        AsistenteOportunidadesController.lineasToWrapperList(lineas,account.Id);
    }

 

    @istest
    private static void cargarPlantillaTest()
    {
        generateData();

        AsistenteOportunidadesController.cargarPlantilla(pedido.Id);
    }
  
   
  
   
    // Invocamos el tester de Calibre para poder subir a producción
    // @istest
    // private static void coverturaIntegracion()
    // {
    //     AsistentePedidosController.covertura();
    // }

}