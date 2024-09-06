/**
 * @author            : josemaria.campins@blueway.com
 * @last modified on  : 07-20-2022
 * @last modified by  : josemaria.campins@blueway.com
 **/
({

	doInit: function (component, event, helper) {
        
		helper.getUrl(component, event, helper);
		helper.doSearchInicio(component, event, helper);
        helper.cargarServicios(component, event, helper)
        helper.getAllFavoritos(component);
		
		
	},

	

	doSearch: function (component, event, helper) {
		var busquedaTexto = "";

		console.log("busquedaTexto 1" + busquedaTexto);
		busquedaTexto = component.find('buscadorTexto').get('v.value');
		busquedaTexto = busquedaTexto == undefined ? '' : busquedaTexto;

		console.log("busquedaTexto 3" + busquedaTexto);

		if (busquedaTexto != '' && busquedaTexto.length > 2) {

			//Creamos la query
			var query = ' WHERE IsActive = true ';

			if (busquedaTexto != '') {
				var textSinTilde = helper.quitarCaracterEspecialATexto(busquedaTexto);

				query += " AND (";
				query += " Name LIKE '%" + busquedaTexto + "%' OR Family LIKE '%" + busquedaTexto + "%' OR Grupo_de_Servicios__c LIKE '" + busquedaTexto + "%'";
				if (busquedaTexto !== textSinTilde)
					query += " OR Name LIKE '%" + textSinTilde + "%'  OR Family LIKE '%" + busquedaTexto + "%' OR Grupo_de_Servicios__c LIKE '" + busquedaTexto + "%'";

				query += ") ";
			}
			component.set("v.queryProductos", query);
            console.log("Query productos: " + query);
			helper.buscadorElementos(component);
			//component.set('v.timer', newtimer);
		}

		if (busquedaTexto == '') {
            var query = null;
            component.set("v.queryProductos", query);
            helper.doSearchInicio(component, event, helper);
			//component.set("v.loadingFilterData", null);
		}
	},
    
    doSearchFavorito: function (component, event, helper) {
		var busquedaTexto = "";
		busquedaTexto = component.find('buscadorTextoFavorito').get('v.value');
		busquedaTexto = busquedaTexto == undefined ? '' : busquedaTexto;

		console.log("busquedaTexto 3" + busquedaTexto);
		if (busquedaTexto != '' && busquedaTexto.length > 2) {
			var textSinTilde = helper.quitarCaracterEspecialATexto(busquedaTexto);
			
			var obtainProductosFav = component.get("{!v.favoritoDataFilter}");
		
			var productsFilter = [];
			obtainProductosFav.forEach(function (prodFav) {
				console.log("Query productos: " + textSinTilde);
                console.log("Query productos1: " +   prodFav.producto.Name);
              
                console.log("Query productos2: " + prodFav.producto.Name.includes(textSinTilde.toUpperCase()));
                
				if (prodFav.producto.Name.toUpperCase().includes(textSinTilde.toUpperCase()) || prodFav.producto.Family.toUpperCase().includes(textSinTilde.toUpperCase()) || prodFav.producto.Grupo_de_Servicios__c.toUpperCase().includes(textSinTilde.toUpperCase())) {
					
					productsFilter.push(prodFav);
				}
			});
			
			component.set("v.favoritoDataFilter", productsFilter);
		}

		if (busquedaTexto == '') {
			component.set("v.favoritoDataFilter", component.get("{!v.favoritoData}"));
		}


	},
    
    addRowToSelectsFavourite: function (component, event, helper) {
        
		var rowId = event.getSource().get("v.value");
        var NumItem = component.get("v.favoritoDataFilter")
		var filterData = component.get("v.favoritoDataFilter");
		var data = component.get("v.productData");

		data = data == undefined ? data = [] : data;

		var rowToAdd = {};


		var copyFilterData = JSON.parse(JSON.stringify(filterData));

		copyFilterData.forEach(function (item, index) {
			if (item.producto.Id == rowId) {
				console.log('JMCB que lleva ' + JSON.stringify(item));
                
                console.log('JMCB que lleva de importe ' + component.get("v.importeLinea"));
                item.TotalPrice = component.get("v.importeLinea");
                console.log('JMCB que lleva ' + JSON.stringify(item));
				helper.inicializarPrecios(component, helper, item, data, data.length, 1);
                
                var action = component.get("c.AnadirServicio");
				action.setParams({
				"idOportunidad": component.get("v.recordId"),				
				"item": item
                   }); 
                action.setCallback(this, function (response) {

				var state = response.getState();
				var responseData = response.getReturnValue();
				
				if (component.isValid() && state === "SUCCESS" && !response.getReturnValue().includes('ERROR:')) {
					console.log('Llega a entrar');
					
					responseData = JSON.parse(responseData);
                    console.log('que llega en el response: ' + responseData);
					
					component.set("v.loadingFilterData", null);
				
				
                    helper.mostrarToast('Servicio añadido a la oportunidad', 'Se ha añadido el Servicio a la oportunidad correctamente.', '2000', 'success', 'dismissible');
					helper.doSearchInicio(component, event, helper);
				

					//component.set("v.step", "3");
				} else {
                    console.log('Llega a entrar mal');
					helper.mostrarToast('Error', 'Ha ocurrido un error en la creación del borrador:\n' + responseData, '5000', 'error', 'sticky');
					 

				}
				component.set("v.cargandoSpiner", false);

			});

				$A.enqueueAction(action);
				            
		//helper.getAllFavoritos(component);

			}
		});
        
		

	},
    
    addFavorito: function (component, event, helper) {

		//component.set("v.favoritoData","");
		var action = component.get("c.addFavouriteProduct");
		action.setParams({
			"idProduct": event.getSource().get("v.value")
		});

		$A.enqueueAction(action);
		helper.getAllFavoritos(component);
		console.log("Dentro");
		setTimeout(() => {
			var a = component.get('c.doSearch');
			$A.enqueueAction(a);
		}, 500);
		console.log("Dentro");
		helper.mostrarToast('Servicio añadido a favoritos', 'Se ha añadido el servicio a favoritos correctamente.', '2000', 'success', 'dismissible');
        
	},

	/*
	 *	Quitamos un producto como favorito para la cuenta.
	 */
	deleteFavorito: function (component, event, helper) {

		//component.set("v.favoritoData", "");
		var action = component.get("c.deleteFavouriteProduct");
		action.setParams({
			"idProduct": event.getSource().get("v.value")
		});
		$A.enqueueAction(action);
		helper.getAllFavoritos(component);
		
		helper.mostrarToast('Servicio eliminado de favoritos', 'Se ha eliminado el servicio de favoritos correctamente.', '3000', 'info', 'dismissible');

	},



	addRowToSelects: function (component, event, helper) {

		var rowId = event.getSource().get("v.value");
		var NumItem = component.get("v.loadingFilterData")

		var filterData = component.get("v.loadingFilterData");
		var data = component.get("v.productData");
        
        
        
		data = data == undefined ? data = [] : data;

		var rowToAdd = {};


		var copyFilterData = JSON.parse(JSON.stringify(filterData));

		copyFilterData.forEach(function (item, index) {
			if (item.producto.Id == rowId) {
				console.log('JMCB que lleva ' + JSON.stringify(item));
                
                console.log('JMCB que lleva de importe ' + component.get("v.importeLinea"));
                item.TotalPrice = component.get("v.importeLinea");
                console.log('JMCB que lleva ' + JSON.stringify(item));
				helper.inicializarPrecios(component, helper, item, data, data.length, 1);
                
                var action = component.get("c.AnadirServicio");
				action.setParams({
				"idOportunidad": component.get("v.recordId"),				
				"item": item
                   }); 
                action.setCallback(this, function (response) {

				var state = response.getState();
				var responseData = response.getReturnValue();
				
				if (component.isValid() && state === "SUCCESS" && !response.getReturnValue().includes('ERROR:')) {
					console.log('Llega a entrar');
					
					responseData = JSON.parse(responseData);
                    console.log('que llega en el response: ' + responseData);
					
					component.set("v.loadingFilterData", null);
				
				
                    helper.mostrarToast('Servicio añadido a la oportunidad', 'Se ha añadido el Servicio a la oportunidad correctamente.', '2000', 'success', 'dismissible');
					helper.doSearchInicio(component, event, helper);
				

					//component.set("v.step", "3");
				} else {
                    console.log('Llega a entrar mal');
					helper.mostrarToast('Error', 'Ha ocurrido un error en la creación del borrador:\n' + responseData, '5000', 'error', 'sticky');
					 

				}
				component.set("v.cargandoSpiner", false);

			});

				$A.enqueueAction(action);
				            
			helper.doSearchInicio(component, event, helper);	

			}
		});
        
       	
    	

	

	},
	

	asignarPrecio: function (component, event, helper) {

		var valor = event.getSource().get("v.value");
		var target = event.getSource().get("v.name");
		var idField = target.split("-");
		var recordId = idField[0];
		var lineNumber = idField[2];
 		console.log("Valor: " + valor);
        console.log("Target: " + target);
        console.log("lineNumber: " + lineNumber);
        
        component.set("v.importeLinea", valor);
		
       
		//helper.calcularTotalPedido(component);
        
        

	},
	guardarDatos: function (component, event, helper) {

		var valor = parseFloat(event.getSource().get("v.value"));
		var target = event.getSource().get("v.name");
		var idField = target.split("-");
		var recordId = idField[0];
		var field = idField[1];
		var lineNumber = idField[2];
		component.set("v.Deshabilitado",true);
		var finalData = component.get("v.productData");
		var data = finalData[lineNumber];
		console.log("JMCB  DATA " + JSON.stringify(data));
        
        
		
		var reloadProdData = true;

		switch (field) {
			case 'Cantidad':
				data.Cantidad = valor == "" ? valor : valor < 0 ? 1 : helper.round10(valor);
				data.ImporteTotal = helper.round10(data.Cantidad * data.PrecioFinal * data.producto.CG_NavCantidadPorCaja__c);
				helper.compruebaStock(component, helper, data, finalData, lineNumber);
				
				break;
			case 'PrecioFinal':
				data.PrecioFinal = valor == "" || valor.endsWith('.') ? valor : /*valor == undefined ||*/ valor < 0 ? 0 : helper.round10(valor);
				data.Descuento = data.PrecioBase == undefined || data.PrecioBase == 0 ? 0 : helper.round10((1 - (data.PrecioFinal / data.PrecioBase)) * 100) /*-(Math.round(data.PrecioFinal - data.PrecioBase)/Math.round(data.PrecioBase)) * 100*/ ;
				data.Descuento = data.Descuento > 100 ? 100 : /*data.Descuento < 0? 0 :*/ helper.round10(data.Descuento); //1-(Preciofinal/preciobase)
				data.DescuentoAnterior = data.Descuento;
				break;
			case 'Descuento':

				if (valor != data.DescuentoAnterior) {
					data.DescuentoAnterior = data.Descuento;
					if (isNaN(data.Descuento)) {
						data.PrecioFinal = data.PrecioUnitario;
						data.PrecioFinalCaja = data.PrecioCaja;
					} else {
						data.PrecioFinal = data.Descuento == 0 ? data.PrecioUnitario : helper.round1000(data.PrecioUnitario * (1 - (data.Descuento / 100)));
						data.PrecioFinalCaja = data.Descuento == 0 ? data.PrecioCaja : helper.round10(data.PrecioCaja * (1 - (data.Descuento / 100)));
					}
					data.ImporteTotal = helper.round10(data.Cantidad * data.PrecioFinal * data.producto.CG_NavCantidadPorCaja__c);
				} else {
					reloadProdData = false;
				}
				

				break;
			case 'Descripcion':
				data.Descripcion = valor;
				break;

			case 'PrecioUnitario':
				data.PrecioCaja = helper.round10(data.PrecioUnitario * data.producto.CG_NavCantidadPorCaja__c);
				if (isNaN(data.Descuento)) {
					data.PrecioFinal = data.PrecioUnitario;
					data.PrecioFinalCaja = data.PrecioCaja;
				} else {
					data.PrecioFinal = helper.round1000(data.PrecioUnitario * (1 - (data.Descuento / 100)));
					data.PrecioFinalCaja = helper.round10(data.PrecioCaja * (1 - data.Descuento / 100));
				}
				data.ImporteTotal = helper.round10(data.Cantidad * data.PrecioFinal * data.producto.CG_NavCantidadPorCaja__c);
				
				break;

			case 'PrecioCaja':

				data.PrecioUnitario = helper.round1000(data.PrecioCaja / data.producto.CG_NavCantidadPorCaja__c);
				if (isNaN(data.Descuento)) {
					data.PrecioFinal = data.PrecioUnitario;
					data.PrecioFinalCaja = helper.round10(data.PrecioCaja * (1 - data.Descuento / 100));

				} else {
					data.PrecioFinal = helper.round1000(data.PrecioUnitario * (1 - (data.Descuento / 100)));

					data.PrecioFinalCaja = helper.round10(data.PrecioCaja * (1 - data.Descuento / 100));
				}
				data.ImporteTotal = helper.round10(data.Cantidad * data.PrecioFinal * data.producto.CG_NavCantidadPorCaja__c);
				
				break;


			default:
				break;

		}


		if (!isNaN(data.PrecioFinal) && !isNaN(data.Descuento) /*&& data.PrecioFinal != 0*/ ) {
			data.PrecioTotal = helper.round10(data.Cantidad * data.PrecioFinal);

		}


		if (reloadProdData) {
			// finalData[lineNumber] = data;
			component.set("v.productData", finalData);
			// helper.calcularTotalPedido(component);
		}

	},

	




	removeRowProducts: function (component, event, helper) {

		var valorToDelete = event.getSource().get("v.value");
		component.set("v.Deshabilitado",true);
        
        
		var idField = valorToDelete.split("-");
		var recordId = idField[0];
		var lineNumber = idField[1];
		var finalData = component.get("v.productData");
		var item = finalData[lineNumber]

		var data = component.get("v.productData");
		var contSubItems = 1;
		
        
        var action = component.get("c.EliminarServicio");
				action.setParams({				
				"idOportunidad": component.get("v.recordId"),				
				"item": item
                   }); 
                action.setCallback(this, function (response) {

				var state = response.getState();
				var responseData = response.getReturnValue();
				
				if (component.isValid() && state === "SUCCESS" && !response.getReturnValue().includes('ERROR:')) {
					console.log('Llega a entrar');
					
					responseData = JSON.parse(responseData);
                    console.log('que llega en el response: ' + responseData);
					
					//component.set("v.loadingFilterData", null);
					//*Eliminamos productos de la lista de añadidos
                    data.splice(lineNumber, contSubItems);
            
                    component.set("v.productData", data);

				
                    helper.mostrarToast('Servicio eliminado de la oportunidad', 'Se ha eliminado el Servicio de la oportunidad correctamente.', '2000', 'error', 'dismissible');
				
				

					//component.set("v.step", "3");
				} else {
                    console.log('Llega a entrar mal');
					helper.mostrarToast('Error', 'Ha ocurrido un error en la eliminacion del servicio:\n' + responseData, '5000', 'error', 'sticky');
					 

				}
				component.set("v.cargandoSpiner", false);

			});

				$A.enqueueAction(action);
        

	
		
		


	},
    
    
    GuardarRowProducts: function (component, event, helper) {
        
        var valorToActualziar = event.getSource().get("v.name");
        component.set("v.Deshabilitado",true);
         console.log('que valor tiene' + valorToActualziar);
        
        var idField = valorToActualziar.split("-");
        var recordId = idField[0];
        var lineNumber = idField[2];
        var finalData = component.get("v.productData");
        var item = finalData[lineNumber]
        
        var data = component.get("v.productData");
        var contSubItems = 1;
        
         if (item.TotalPrice != ''){
              var action = component.get("c.ActualizarServicio");
        action.setParams({				
            "idOportunidad": component.get("v.recordId"),				
            "item": item
        }); 
        action.setCallback(this, function (response) {
            
            var state = response.getState();
            var responseData = response.getReturnValue();
            
            if (component.isValid() && state === "SUCCESS" && !response.getReturnValue().includes('ERROR:')) {
                console.log('Llega a entrar');
                
                responseData = JSON.parse(responseData);
                console.log('que llega en el response: ' + responseData);
                
                //component.set("v.loadingFilterData", null);
                //*Eliminamos productos de la lista de añadidos
                //data.splice(lineNumber, contSubItems);
                
                component.set("v.productData", data);
                
                
                helper.mostrarToast('Importe modificado correctamente','El Importe del servicio ha sido modificado correctamente', '3000', 'info', 'dismissible');
                
                
                
                //component.set("v.step", "3");
            } else {
                console.log('Llega a entrar mal');
                helper.mostrarToast('Error', 'Ha ocurrido un error en la actualizacion del servicio:\n' + responseData, '5000', 'error', 'sticky');
                
                
            }
            component.set("v.cargandoSpiner", false);
            
        });
        
        $A.enqueueAction(action);
         }else{
              helper.mostrarToast('Error', 'Debes añadir un importe correcto. El campo Importe no puede ser vacio', '5000', 'error', 'sticky');
         }
       
        
        
        
        
        
        
        
    },



	
	/*
	 *****************************************************************************************************************************************
	 *													BOTONES	
	 *****************************************************************************************************************************************
	 */
	
	

	guardarBorradorPedido: function (component, event, helper) {

		var todoOk = '';
		console.log('Y Aqui llega??? ' + component.get("v.productData"));
		// Validamos la información
		var confirmarDatos = component.get("v.productData");
	


		

		
		console.log('Todo ok');
		if (todoOk == '') {
			component.set("v.cargandoSpiner", true);
			console.log('Todo ok  SEGURO');
            console.log('Id oportunidad' + component.get("v.recordId"))
			var action = component.get("c.guardarBorrador");
			action.setParams({
				"idOportunidad": component.get("v.recordId"),				
				"lineasData": JSON.stringify(component.get("v.productData"))
				            
			});

			action.setCallback(this, function (response) {

				var state = response.getState();
				var responseData = response.getReturnValue();
				
				if (component.isValid() && state === "SUCCESS" && !response.getReturnValue().includes('ERROR:')) {
					console.log('Llega a entrar');
					
					responseData = JSON.parse(responseData);
                    console.log('que llega en el response: ' + responseData);
					//component.set("v.idPedido", responseData.idOportunidad);
					// component.set("v.productData", JSON.parse(responseData.datosLineas));
					component.set("v.loadingFilterData", null);
				
					//helper.mostrarToast('Servicio añadido correctamente', ' ', '2000', 'warning', 'sticky');
                    helper.mostrarToast('Servicios Modificados en la oportunidad', 'Se ha modificado los Servicios de la oportunidad correctamente.', '2000', 'success', 'dismissible');
					helper.doSearchInicio(component, event, helper);
				
                    

					//component.set("v.step", "3");
				} else {
                    console.log('Llega a entrar mal');
					helper.mostrarToast('Error', 'Ha ocurrido un error en la creación del borrador:\n' + responseData, '5000', 'error', 'sticky');
					 

				}
				component.set("v.cargandoSpiner", false);

			});

			$A.enqueueAction(action);
		} else {
			helper.mostrarToast(' ' + todoOk + ' Por favor, cumplimente todos los requisitos antes de avanzar', ' ', '2000', 'warning', 'sticky');
		}
       
	},
	

})