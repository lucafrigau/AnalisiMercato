
// La casella «Binarie di presenza/assenza» conta solo con la distanza di
// Gower, l'unica che tratta la co-assenza in modo diverso dalle altre
// coppie. Con le altre distanze le sue variabili passano nella base della
// segmentazione, dove la distanza scelta le tratta come tutte le altre: sia
// quando si cambia distanza, sia quando ve ne si mette una nuova. In jamovi
// 2.7 `enable` non impedisce di riempire una casella di variabili, e la
// nota in fondo alla casella dice che è attiva solo con Gower.

const events = {

    update: function(ui) {
        sistemaBinarie(ui);
    },

    onChange_dis: function(ui) {
        sistemaBinarie(ui);
    },

    onChange_asimm: function(ui) {
        sistemaBinarie(ui);
    }
};

// con l'interfaccia jus 3.0 il contesto dei gestori non ha clone(): gli
// elenchi si copiano a mano
const copia = function(valore) {
    return Array.isArray(valore) ? valore.slice() : [];
};

const sistemaBinarie = function(ui) {

    let gower = ui.dis.value() === 'gower';

    if ( ! gower) {
        let binarie = copia(ui.asimm.value());
        if (binarie.length > 0) {
            let base = copia(ui.vars.value());
            for (let nome of binarie) {
                if ( ! base.includes(nome))
                    base.push(nome);
            }
            ui.vars.setValue(base);
            ui.asimm.setValue([]);
        }
    }

    // la nota in fondo alla casella non va a capo: deve stare in una riga
    // di una trentina di caratteri
    if (gower)
        ui.asimm.setPropertyValue('infoText', _('0/1: shared 0s do not count'));
    else
        ui.asimm.setPropertyValue('infoText', _('Active only with Gower'));
};

module.exports = events;
