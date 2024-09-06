import { LightningElement,wire,track, api } from 'lwc';
import NAV2SFJobs from '@salesforce/apex/NAV2SFJobs.getJobsForAccount';
import { getRecord } from 'lightning/uiRecordApi';
import getJobsForAccount from '@salesforce/apex/NAV2SFJobs.getJobsForAccount';

const data = [];
var thereIsData = true;

const columns = [
    {   
        label: 'Fecha', 
        fieldName: 'FechaInicial', 
        type: 'date',
        typeAttributes:{ month: "2-digit", year: "numeric"},   
        wrapText: true, 
        sortable: true,
        cellAttributes: { alignment: 'center' },
        hideDefaultActions: "true",
        fixedWidth: 85,
    }, 
    {
        label: 'Importe',
        fieldName: "HonorariosPrevistos",
        type: 'currency',
        typeAttributes: {
            minimumFractionDigits: '0',
            maximumFractionDigits: '0',
        },
        wrapText: true, 
        sortable: true,
        cellAttributes: { alignment: 'right' },
        hideDefaultActions: "true",
        fixedWidth: 105,
    },
    { 
        label: 'Descripción', 
        fieldName: 'DescripcionProyecto', 
        type: 'text' , 
        wrapText: true, 
        sortable: true,
        cellAttributes: { alignment: 'left' },
        hideDefaultActions: "true",
        fixedWidth: 170,
    },
    {
        label: 'Tipo',
        fieldName: "NombreTipoJob",
        type: 'text',
        wrapText: true, 
        sortable: true,
        cellAttributes: { alignment: 'left' },
        hideDefaultActions: "true",
        fixedWidth: 170,
    },
    {
        label: 'Subtipo',
        fieldName: "NombreSubTipoJob",
        type: 'text',
        wrapText: true, 
        sortable: true,
        cellAttributes: { alignment: 'left' },
        hideDefaultActions: "true",
        fixedWidth: 120,
    },
    {
        label: 'Socio',
        fieldName: "NombreSocio",
        type: 'text',
        wrapText: true, 
        sortable: true,
        cellAttributes: { alignment: 'left' },
        hideDefaultActions: "true",
        fixedWidth: 170,
    }
    /**,
    { 
        label: 'Área', 
        fieldName: 'NombreArea', 
        type: 'text' , 
        wrapText: true, 
        sortable: true,
        cellAttributes: { alignment: 'left' },
        hideDefaultActions: "true",
        fixedWidth: 85,
    },
    {
        label: '% Facturado',
        fieldName: "PorcentajeFacturacionEmitida",
        type: 'percent',
        typeAttributes: {
            step: '0.001',
            minimumFractionDigits: '0',
            maximumFractionDigits: '0',
        },
        wrapText: true, 
        sortable: true,
        cellAttributes: { alignment: 'right' },
        hideDefaultActions: "true",
        fixedWidth: 90,
    },
    {
        label: 'H. previstas',
        fieldName: "HorasPrevistas",
        type: 'number',
        typeAttributes: {
            minimumFractionDigits: '0',
            maximumFractionDigits: '0',
        },
        wrapText: true, 
        sortable: true,
        cellAttributes: { alignment: 'right' },
        hideDefaultActions: "true",
        fixedWidth: 105,
    },
    {
        label: 'Avance',
        fieldName: "PorcentajeHorasEjecutadas",
        type: 'percent',
        typeAttributes: {
            step: '0.001',
            minimumFractionDigits: '0',
            maximumFractionDigits: '0',
        },
        wrapText: true, 
        sortable: true,
        cellAttributes: { alignment: 'right' },
        hideDefaultActions: "true",
        fixedWidth: 90,
    },
    {
        label: 'Compras y subc.',
        fieldName: "ComprasSubcontrataciones",
        type: 'currency',
        typeAttributes: {
            minimumFractionDigits: '0',
            maximumFractionDigits: '0',
        },
        wrapText: true, 
        sortable: true,
        cellAttributes: { alignment: 'right' },
        hideDefaultActions: "true",
        fixedWidth: 120,
    } **/
];

export default class DemoApp extends LightningElement {
    @api recordId;
    columns = columns;
    defaultSortDirection = 'desc';
    sortDirection = 'desc';
    sortedBy = 'FechaInicial';
    casesSpinner = true;
    @track thereIsData = true;
    @track data = [];
    connectedCallback(){
        this.thereIsData = true;
        console.log('recordId');
        console.log(this.recordId);
        getJobsForAccount({accountId : this.recordId}).then(response => {
            console.log(JSON.stringify(response));
            this.data = response.sort((a, b) => (a.FechaInicial > b.FechaInicial) ? -1 : 1);
            this.casesSpinner = false;
            if (response.length === 0) { this.thereIsData = false; }
        }).catch(error => {
            console.log('Error: ' +JSON.stringify(error));
            this.casesSpinner = false;
            this.thereIsData = false; 
        });
    }

    // Used to sort columns
    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field];
              };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }
}