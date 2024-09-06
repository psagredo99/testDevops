/**
 * @author            : josemaria.campins@blueway.com
 * @last modified on  : 07-20-2022
 * @last modified by  : josemaria.campins@blueway.com
 **/
({


		doSearchInicio: function (component, event, helper) {
		
			console.log("doSearchInicio");
		
           
            helper.buscadorElementosFirst(component);
		
		
	},
    
    buscadorElementosFirst: function (component) {
		console.log("doSearchInicio2");
		component.set('v.issearching', true);
        var datosProductoFAV = component.get("v.favoritoData");
         console.log('DAtos del favorito...' + datosProductoFAV.length);
		var action = component.get("c.buscadorProductos");
		action.setParams({
			"query": component.get("v.queryProductos"),
			"idCuenta": component.get("v.idCuenta")
		});

		// Add callback behavior for when response is received
		action.setCallback(this, function (response) {
			var state = response.getState();
			
			if (component.isValid() && state === "SUCCESS") {
				var data = response.getReturnValue();
				var productosQueCumplenCriterios = [];

				console.log("doSearchInicio2" + data.length);
				if (data.length == 0) {
					this.mostrarToast('Búsqueda sin resultados', ' ', '4000', 'info', 'pester');
                }else{
                    
                    data.forEach(function (item) {
						datosProductoFAV.forEach(function (item2) {
                            
							if (item.producto.Id == item2.producto.Id) {
                                console.log("Llega aentra aqui en algun momento");
								item.favorito = true;
							}
						});
					});
					
                    component.set("v.loadingFilterData", data);
                }

			} else {
				this.mostrarToast('No se ha procesado la operación', 'La busqueda no ha devuelto un resultado correcto.', '5000', 'warning', 'sticky');
			}

			component.set('v.issearching', false);

		});

		// Send action off to be executed
		$A.enqueueAction(action);

	},

	//*BUSQUEDA DE PRODUCTOS
	buscadorElementos: function (component) {
		console.log("doSearchInicio2");
		component.set('v.issearching', true);
        var datosProductoFAV = component.get("v.favoritoData");
        console.log('DAtos del favorito...' + datosProductoFAV.length);
		var action = component.get("c.buscadorProductos");
		action.setParams({
			"query": component.get("v.queryProductos"),
			"idCuenta": component.get("v.idCuenta")
		});

		// Add callback behavior for when response is received
		action.setCallback(this, function (response) {
			var state = response.getState();
			
			if (component.isValid() && state === "SUCCESS") {
				var data = response.getReturnValue();
				var productosQueCumplenCriterios = [];

				console.log("doSearchInicio2" + data.length);
				if (data.length == 0) {
					this.mostrarToast('Búsqueda sin resultados', ' ', '4000', 'info', 'pester');
				}

				var busquedaTexto = component.find('buscadorTexto').get('v.value');
				if (busquedaTexto == '') {
					component.set("v.loadingFilterData", null);
				} else {
			
					
					data.forEach(function (item) {
						datosProductoFAV.forEach(function (item2) {
                            console.log("que contiene item 2" + item2);
							if (item.producto.Id == item2.Id) {
                                console.log("Llega aentra aqui en algun momento");
								item.favorito = true;
							}
						});
					});
					console.log("1");

					component.set("v.loadingFilterData", data);
					console.log("2");
                    
				}

			} else {
				this.mostrarToast('No se ha procesado la operación', 'La busqueda no ha devuelto un resultado correcto.', '5000', 'warning', 'sticky');
			}

			component.set('v.issearching', false);

		});

		// Send action off to be executed
		$A.enqueueAction(action);
        
        
       

	},
    
    cargarServicios: function(component, event, helper){
    
    	console.log("doSearchInicio2");
		component.set('v.issearching', true);
        var datosProductoFAV = component.get("v.favoritoData");
        var idRecord = component.get("v.recordId");
       
		var action = component.get("c.buscadorServicios");
    
       
		action.setParams({
			"IdOportunidad": idRecord
			
		});

		// Add callback behavior for when response is received
		action.setCallback(this, function (response) {
			var state = response.getState();
			
			if (component.isValid() && state === "SUCCESS") {
				var data = response.getReturnValue();
				
				if (data.length == 0) {
					this.mostrarToast('Búsqueda sin resultados', ' ', '4000', 'info', 'pester');
                }else{
                    component.set("v.productData", data);
                }

			} else {
				this.mostrarToast('No se ha procesado la operación', 'La busqueda no ha devuelto un resultado correcto.', '5000', 'warning', 'sticky');
			}

			component.set('v.issearching', false);

		});

		// Send action off to be executed
		$A.enqueueAction(action);
    
    
	},




	




	inicializarPrecios: function (component, helper, item, data, num, index, cantidad) {

		 console.log('JMCB que lleva Data helper ' + data);
		console.log('JMCB que lleva Data Item ' + item.Cantidad);
		
		item.Descuento = 0;
		

	
		
		item.CantidadAnterior = item.Cantidad;
		var itemNew = {};
		itemNew.producto = item.producto;
            
      
        console.log('JMCB que lleva Data helper ' + data);  
        
        if (num == null) {
            data[index] = item
        } else {
            data.push(item);
        }  
        
        console.log('JMCB que lleva Data ' + data);
        component.set("v.productData", data);
       	
                 
                
	},

	

	// ====================================================================================================================================
	// ===================================================          AUXILIARES          ===================================================
	// ====================================================================================================================================

	round10: function (number) {
		var roundedNumber = number != undefined && number != 0 ? Math.round(number * 100) / 100 : 0;

		//Si el número realmente no ha cambiado (de 40.0 a 40 por ej.), deja el que había
		if (roundedNumber == number) {
			roundedNumber = number;
		}
		return roundedNumber;
	},
	round1000: function (number) {

		var roundedNumber = number != undefined && number != 0 ? Math.round(number * 10000) / 10000 : 0;

		//Si el número realmente no ha cambiado (de 40.0 a 40 por ej.), deja el que había
		if (roundedNumber == number) {
			roundedNumber = number;
		}
		return roundedNumber;
	},

	formatDate: function (paramDate) {

		var d = new Date(paramDate),
			month = '' + (d.getMonth() + 1),
			day = '' + d.getDate(),
			year = d.getFullYear();

		if (month.length < 2) month = '0' + month;
		if (day.length < 2) day = '0' + day;
		//console.log('FECHA FORMATEADA : ' + d);
		return [day, month, year].join('-');
	},

	goToURL: function (component, url) {

		var urlEvent = $A.get("e.force:navigateToURL");
		urlEvent.setParams({
			"url": url
		});
		urlEvent.fire();
	},


	formatearDireccion: function (arrayDir) {

		var strDir = '';

		arrayDir.forEach(function (record) {

			if (record != null && record != '') {
				if (strDir != '') {
					strDir += ', ';
				}

				strDir += record;
			}
		})


		return strDir;

	},

	goToSObject: function (component) {

		//var selectedItem = event.currentTarget;
		//var selectedRowID = selectedItem.dataset.record;

		//console.log("SelectedRowID: " + selectedRowID);


		var idRecord = component.get("v.recordId");

		var urlEvent = $A.get("e.force:navigateToSObject");
		urlEvent.setParams({
			"recordId": idRecord,
			"slideDevName": "detail"
		});
		urlEvent.fire();

	},

	quitarCaracterEspecialATexto: function (s) {

		var s1 = 'ÃÀÁÄÂÈÉËÊÌÍÏÎÒÓÖÔÙÚÜÛãàáäâèéëêìíïîòóöôùúüûÑñÇç';
		var s2 = 'AAAAAEEEEIIIIOOOOUUUUaaaaaeeeeiiiioooouuuunncc';

		for (var i = 0; i < s1.length; i++) s = s.replace(new RegExp(s1.charAt(i), 'g'), s2.charAt(i));

		return s;
	},

	getUrl: function (component, event, helper) {

		var action = component.get("c.getOrgUrl");
		var id = component.get("v.recordId");


		action.setParams({
			"id": id
		});


		// Add callback behavior for when response is received
		action.setCallback(this, function (response) {



			var state = response.getState();

			if (component.isValid() && state === "SUCCESS") {

				var data = response.getReturnValue();
				var split = data.split(">");
				var url = split[0];
				console.log("url JMCB " + url);
				var type = split[1];
				if (url.includes('lightning')) {
					component.set('v.IsCommunity', false);
				} else {
					component.set('v.IsCommunity', true);
				}
				component.set("v.url", url);
				component.set("v.tipoObjeto", type);

				if (type == "Order") {
					var action = component.get("c.cargarDatosPedido");
					action.setParams({
						"idPedido": id
					});

					action.setCallback(this, function (response) {
						var state = response.getState();
						var responseData = response.getReturnValue();

						if (component.isValid() && state === "SUCCESS" && !response.getReturnValue().includes('ERROR:')) {


							responseData = JSON.parse(responseData);

							component.set("v.idPedido", component.get("v.recordId"));
							component.set("v.idCuenta", responseData.idCuenta);
							component.set("v.AccountId", responseData.idCuenta);
							component.set("v.pedido", responseData.pedido);
							component.set("v.nombreCuenta", responseData.nombreCuenta);
							component.set("v.datePedido", responseData.datePedido);
							component.set("v.descPedido", responseData.descPedido);
							component.set("v.numDocumentoExterno", responseData.numDocumentoExterno);
							component.set("v.horaPedido", responseData.horaPedido);
							component.set("v.urgente", responseData.urgente);
							component.set("v.siguienteDeshabilitado", false);
							component.set("v.productData", responseData.productData);
							component.set("v.importeTotalPedido", responseData.importeTotalPedido);
							component.set("v.totalProductosPedido",responseData.totalProductosPedido);
							component.set("v.direccionSeleccionadaEntrada", responseData.direccion);

							

							var query = "SELECT Name,Id,CG_IsClienteBloqueado__c FROM Account WHERE Id = '" + responseData.idCuenta + "'";
							component.set("v.queryCuentas", query);
							helper.getAccounts(component);
							helper.asignarCuenta(component,event,helper,responseData.idCuenta);
							
							
						} else {
							helper.mostrarToast('Error', 'Ha ocurrido un error en la carga de datos:\n' + responseData, '5000', 'error', 'sticky');
						}
					});

					$A.enqueueAction(action);
				} else if (type == "Account") {
					component.set("v.pedido.AccountId", id);
					var query = "SELECT Name,Id,CG_IsClienteBloqueado__c FROM Account WHERE Id = '" + id + "'";
					component.set("v.queryCuentas", query);
					helper.getAccounts(component);
					helper.asignarCuenta(component, event, helper, id);

				}

				// component.set("v.pedidoData", pedidoData);
			}
		});

		// Send action off to be executed
		$A.enqueueAction(action);

	},
	asignarCuenta: function (component, event, helper, idCuenta) {

		var value;
		if (idCuenta != null) {
			value = idCuenta;
		} else {
			value = event.getSource().get("v.value")[0];
		}
		component.set("v.idCuenta", value);


		if (value != null && value.length > 0) {

			var action = component.get("c.direccionesDisponibles");
			action.setParams({
				"idCuenta": value
			});

			// Add callback behavior for when response is received
			action.setCallback(this, function (response) {
				var state = response.getState();

				if (component.isValid() && state === "SUCCESS") {
					var dataJSON = response.getReturnValue();
					var data = JSON.parse(dataJSON);


					data.direcciones.forEach(function (dir) {
                        console.log("aqui da el error verdad");
						if (dir.CG_NavDireccion__c == null && dir.CG_NavPoblacion__c == null) {
							var arrayDir = [dir.CG_Direccion__c, dir.CG_Population__c, dir.CG_PostalCode__c, dir.CG_Country__c];
							dir.cadenaDireccion = helper.formatearDireccion(arrayDir);
						} else {
							var arrayDir = [dir.CG_NavDireccion__c, dir.CG_NavPoblacion__c, dir.CG_AddressPostalCode__c, dir.CG_AddressCountryRegionCode__c];
							dir.cadenaDireccion = helper.formatearDireccion(arrayDir);
						}
					});
					component.set("v.direccionData", data.direcciones);
					component.set("v.direccionSeleccionada", JSON.stringify(data.direcciones[0]));
					if (data.direcciones.length == 0) {
						helper.mostrarToast('¡¡CUENTA SIN DIRECCIONES!!', 'El pedido se enviará a la dirección de facturación del cliente. ', '6000', 'warning', 'dismissible');
						component.set("v.direccion", dir.cadenaDireccion);
						component.set("v.direccionSeleccionada", JSON.stringify(dir));

						component.set("v.idCuenta", dir.CG_Account__r.Id);
						component.set("v.nombreCuenta", dir.CG_Account__r.Name);

						var pedidoData = component.get("v.pedidoData");
						pedidoData.Direccion = data.direcciones[0];

						component.set("v.pedidoData", pedidoData);

					} else {
						var dir;
						var direccionEntrada = component.get("v.direccionSeleccionadaEntrada");
						var direccionesOrdenadas =[];
						console.log("JMCB direccion");
						
						//Por defecto selecciona la diracción generada a partir de la de facturación (al no estar consolidada carece de ID)
						data.direcciones.forEach(function (record)
						{
							if (direccionEntrada.includes(record.Id)) {
								dir = record;
								direccionesOrdenadas.push(dir);
							}
						});
						
						data.direcciones.forEach(function (record)
						{
							if (direccionEntrada.includes(record.Id)) {
								
							} else
							{
								direccionesOrdenadas.push(record);
							}
						});
						
						component.set("v.direccionData", direccionesOrdenadas);

						//Si por lo que sea no tiene la de facturación, recoge la primera
						if (dir == null) {
							dir = data.direcciones[0];
						}

						component.set("v.direccion",dir.cadenaDireccion);
						console.log("JMCB " +  JSON.stringify(dir));
						component.set("v.direccionSeleccionada", JSON.stringify(dir));

						component.set("v.idCuenta", dir.CG_Account__r.Id);
						component.set("v.nombreCuenta", dir.CG_Account__r.Name);

						var pedidoData = component.get("v.pedidoData");
						pedidoData.Direccion = dir;

						component.set("v.pedidoData", pedidoData);

					}
					// i.Lougedo: cambio restricción porque hay cuentas que no tienen direcciones y se tiene que poder lanzar el pedido
					//if(component.get("v.datePedido") != null && component.get("v.direccion") != null && component.get("v.nombreCuenta") != null){

					// if(component.get("v.datePedido") != null && component.get("v.nombreCuenta") != null){
					// 	component.set("v.siguienteDeshabilitado" , false);
					// 	//alert(component.get("v.nombreCuenta") + ' - ' + component.get("v.datePedido"));
					// }
					// else{
					// 	component.set("v.siguienteDeshabilitado" , false);
					// 	//alert(component.get("v.nombreCuenta") + ' - ' + component.get("v.datePedido"));
					// }

				}
				
			});

			$A.enqueueAction(action);
		} else {
			component.set("v.nombreCuenta", null);
			component.set("v.nombreDireccion", null);
			component.set("v.direccionData", null);
			component.set("v.direccionSeleccionada", null);

			// component.set("v.siguienteDeshabilitado" , true);
		}
		setTimeout(() => {
		
		}, 500);
		if (component.get("v.pedido.AccountId") != null && component.get("v.pedido.AccountId") != '') {
			component.set("v.siguienteDeshabilitado", false);
		} else {
			component.set("v.siguienteDeshabilitado", true);
		}

		console.log("JMCB FIN ASIGNAR CUENTA");

	},

	mostrarToast: function (t_title, t_message, t_duration, t_type, t_mode) {

		var toastEvent = $A.get("e.force:showToast");
		toastEvent.setParams({
			title: t_title,
			message: t_message,
			duration: t_duration,
			key: 'info_alt',
			type: t_type,
			mode: t_mode
		});
		toastEvent.fire();
	},

	init: function (component) {
		// Find the component whose aura:id is "flowData"
		var flow = component.find("flowData");
		// In that component, start your flow. Reference the flow's API Name.
		flow.startFlow("Prueba_VF_para_CMP");
	},
    
    getAllFavoritos: function (component) {


		var action = component.get("c.getAllFavoritos");
		action.setParams({
		});

		// Add callback behavior for when response is received
		action.setCallback(this, function (response) {
			var state = response.getState();
			//console.log('getAllFavoritos response: ' + state);
			if (component.isValid() && state === "SUCCESS") {
                console.log('favorito1' + response.getReturnValue());
				component.set("v.favoritoData", response.getReturnValue());
				component.set("v.favoritoDataFilter", response.getReturnValue());
			}
			
		});

		console.log('favorito' + component.get("v.favoritoData"));

		$A.enqueueAction(action);
	},

	guardadoProductosFavoritos: function (component) {
		var action = component.get("c.guardarProductosFavoritos");
		action.setParams({
			"jsonFavoritos": component.get("v.favoritoData"),
			"datosProductos": component.get("v.loadingFilterData")

		});

		action.setCallback(this, function (response) {
			component.set("v.favoritoDataFilter", component.get("{!v.favoritoData}"));
			var state = response.getState();
			//console.log('guardadoProductosFavoritos response: ' + state);

			if (component.isValid() && state === "SUCCESS") {
				var data = response.getReturnValue();
				//console.log("DATA : " + JSON.stringify(data));

				component.set("v.loadingFilterData", data);
			}

		});
		$A.enqueueAction(action);
	},

	eliminarProductosFavoritos: function (component) {
		var action = component.get("c.eliminarProductosFavoritos");
		action.setParams({
			"idCuenta": component.get("v.recordId"),
			"jsonFavoritos": component.get("v.favoritoData"),
			"datosProductos": component.get("v.loadingFilterData")

		});
		action.setCallback(this, function (response) {
			component.set("v.favoritoDataFilter", component.get("{!v.favoritoData}"));
			var state = response.getState();
			//console.log('eliminarProductosFavoritos response: ' + state);

			if (component.isValid() && state === "SUCCESS") {
				var data = response.getReturnValue();
				//console.log("DATA : " + JSON.stringify(data));

				component.set("v.loadingFilterData", data);
			}

		});
		$A.enqueueAction(action);
	},




})