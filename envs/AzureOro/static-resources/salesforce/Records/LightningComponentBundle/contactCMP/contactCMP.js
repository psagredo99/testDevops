import { LightningElement, api } from 'lwc';
import ObtenerIdCampo from '@salesforce/apex/ComponenteFoto.obtenerIdCampo';
import ObtenerCampos from '@salesforce/apex/ComponenteFoto.obtenerCampos';
import ObtenerDatosFoto from '@salesforce/apex/ComponenteFoto.obtenerDatosFoto';

export default class ComponenteFoto extends LightningElement
{
    @api objectApiName;
    @api Objeto;
    @api recordId;
    @api Campo_recordId;
    @api Mostrar_campos;
    @api Accion_Rapida;
    @api Campo_URLFoto;
    @api Campo_TextoFoto;
    @api Campo_AlturaFoto;
    @api Campo_Titulo;

    objetoSeleccionado = '';
    idRegistroSeleccionado = '';
    campos = [];
    Foto = 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png';
    TextoFoto = '';
    UrlTextoFoto = '';
    bShowModal = false;
    renderControl = true;

    renderedCallback()
    {
        let Imagenes  = this.template.querySelectorAll('.Campo_AlturaFoto');
        for (let imagen of Imagenes)
        {
            imagen.style.width = this.Campo_AlturaFoto + "px";
            imagen.style.height = this.Campo_AlturaFoto + "px";
         }

        if (this.renderControl)
        {
            this.renderControl = false;

            this.Objeto ? this.objetoSeleccionado = this.Objeto : this.objetoSeleccionado = this.objectApiName;
            if (!this.Campo_recordId)
            {
                this.idRegistroSeleccionado = this.recordId;
                if (this.idRegistroSeleccionado)
                {
                    this.Mostrar_campos ? this.accionRapida() : this.urlFoto();
                }
            }else{
                if (this.recordId && this.objectApiName && this.Campo_recordId)
                {
                    const obtenerIdCampo = Promise.resolve(ObtenerIdCampo({recordId: this.recordId, objectApiName: this.objectApiName, campoRecordId: this.Campo_recordId}));
    
                    obtenerIdCampo.then((idRegistroSeleccionado) => {
                        let array = this.Campo_recordId.split(".");
                        let ArrayLen = array.length;
                
                        switch (ArrayLen)
                        {
                            case 1:
                                this.idRegistroSeleccionado = idRegistroSeleccionado[array[0]];
                                break;
                            case 2:
                                this.idRegistroSeleccionado = idRegistroSeleccionado[array[0]][array[1]];
                                break;
                            case 3:
                                this.idRegistroSeleccionado = idRegistroSeleccionado[array[0]][array[1]][array[2]];
                                break;
                            case 4:
                                this.idRegistroSeleccionado = idRegistroSeleccionado[array[0]][array[1]][array[2]][array[3]];
                                break;
                            case 5:
                                this.idRegistroSeleccionado = idRegistroSeleccionado[array[0]][array[1]][array[2]][array[3]][array[4]];
                                break;
                        }
                        
                        if (this.idRegistroSeleccionado)
                        {
                            this.Mostrar_campos ? this.accionRapida() : this.urlFoto();
                        }
                    });
                }
            }       
        }
    }

    accionRapida()
    {
        const obtenerCampos = Promise.resolve(ObtenerCampos({objetoSeleccionado: this.objetoSeleccionado, accionRapida: this.Accion_Rapida}));

        obtenerCampos.then((campos) => {
            if (campos) {
                this.campos = campos;
                this.urlFoto();
            }
        });
    }

    urlFoto() 
    {
        const obtenerDatosFoto = Promise.resolve(ObtenerDatosFoto({idRegistroSeleccionado: this.idRegistroSeleccionado, objetoSeleccionado: this.objetoSeleccionado, campoURLFoto: this.Campo_URLFoto, campoTextoFoto: this.Campo_TextoFoto}));

        obtenerDatosFoto.then((datosFoto) => {
            if (datosFoto)
            {
                if (this.Campo_TextoFoto)
                {
                    this.Foto = datosFoto[this.Campo_URLFoto] ? datosFoto[this.Campo_URLFoto] : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png';
                    this.TextoFoto = datosFoto[this.Campo_TextoFoto];
                    this.UrlTextoFoto = window.location.origin + "/lightning/r/" + this.objetoSeleccionado + "/" + this.idRegistroSeleccionado + "/view";
                }else {
                    this.Foto = datosFoto[this.Campo_URLFoto] ? datosFoto[this.Campo_URLFoto] : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png';
                }
            }
        });
    }

    openModal()
    {
        this.bShowModal = true;
    }

    closeModal()
    {
        this.bShowModal = false;
    }

    onSuccess()
    {
        this.urlFoto();
        this.bShowModal = false;
    }
}