@isTest

public class NAV2SFJobsTest {
/** 
**
* Class NAV2SF Jobs Test
* @author: Jose M. Murillo
**º
**/
	//=====================================================================//
	//============================  CONSTANTS  ============================//
	//=====================================================================//
    public static String APEX_CLASS = Integration_Util.getRunningClassName();
    public static String APEX_METHOD = Integration_Util.getRunningMethodName();
    public static String namedCredential = 'Navision';
    // public static String namedCredential = 'NavisionPRO';
    public static String NavID;
    //public static String integration = 'NAV-ATTEST-SALESFORCE/ODataV4/Company(\'030-ITC\')/jobSF?$filter=CustomerMulticompanyID%20eq%20'+NavID;
    public static String integration = 'NAV_PKF_ATTEST_PROD_SF/OData/Company(\'030-ITC\')/jobSF?$filter=CustomerMulticompanyID%20eq%20'+NavID;
    public static String method = 'GET';
	public static Account acc;
    public static String accountId;
    
    
     public static void generateData()
     {
         	
            acc      = new Account();
        	acc.Name = 'Account';
         	acc.Multicompany_ID__c = '11570';
        	insert acc;
         	accountId = acc.Id;
         	NavID = [Select Id, Multicompany_ID__c from Account where id = :accountId].Multicompany_ID__c;
         
     }
    
    @isTest
    static void testGetJobs()
    {
        // Test.startTest();
        // Generate Data
        generateData();
        Test.setMock(HttpCalloutMock.class, new mockWSTest()); 
        NAV2SFJobs.getJobsForAccount(accountId);       
        //Test.stopTest();
    }
    
    	public class mockWSTest implements HttpCalloutMock{
		public HTTPResponse respond(HTTPRequest req) {
			System.assert(req.getEndpoint().contains('testEndpoint'));
			System.assertEquals('GET', req.getMethod());
			Map<String, String> response = new Map<String, String>();
			response.put('Status', 'OK');

			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
            res.setBody('[{"@odata.etag":"W/\"JzUyO3B3QUFBQUo3L3pBQU1RQXdBREVBTndCS0FEQUFNUUF0QURBQU5BQXpBRE1BQUFBQUFBPT05OzYzNzgwOTg4NjA7Jw==\"","No":"01017J01-0433","DescripcionProyecto":"Servicios Generales ITC","AliasProyecto":"SERVICIOS GENERALES ITC","Sociedad":"","NombreSociedad":"","Area":"","NombreArea":"","CustomerMulticompanyID":11570,"FacturaANombre":"PKF ATTEST ITC, S.L.","CIFCliente":"B95187290","FacturaAContacto":"","CargoContacto":"","TipoJob":"GEN-30 T","NombreTipoJob":"Genérico Área 30","SubTipoJob":"","NombreSubTipoJob":"","CentroTrabajo":"","NombreCentroTrabajo":"","Socio":"","NombreSocio":"","Responsable":"","NombreResponsable":"","FechaCreacion":"2017-05-23T00:00:00Z","FechaInicial":"2016-08-31T00:00:00Z","FechaFinal":"2027-08-30T00:00:00Z","EstadoProyecto":"Started","ProyectoEmpresaVinculada":false,"HonorariosPrevistos":0,"PorcentajeFacturacionEmitida":0,"HorasPrevistas":0,"PorcentajeHorasEjecutadas":0,"ComprasSubcontrataciones":0,"OrigenPKF":"No","Job_Task_Filter":"","Planning_Date_Filter":"","Posting_Date_Filter":"","ETag":"52;pwAAAAJ7/zAAMQAwADEANwBKADAAMQAtADAANAAzADMAAAAAAA==9;6378098860;"}]');
			res.setStatusCode(200);
			return res;
		}
	}
    

}