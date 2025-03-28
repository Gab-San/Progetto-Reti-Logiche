# Progetto di Reti Logiche

> For the english version refer to [Digital Design Logic Project](./en/README.md)

Il progetto di reti logiche è il secondo dei tre progetti obbligatori richiesti al Polimi nel corso di Laura Triennale in Ingegneria Informatica.

Tale progetto consiste nel modellare un circuito, usando un linguaggio di descrizione dell'hardware, che rispetti il funzionamento richiesto dalle specifiche.
Poiché è stato scelto VHDL come linguaggio di descrizione, il livello di modellazione è stato lasciato decidere al progettista tra comportamentale e register-transfer.

## Specifiche di progetto

Il componente da progettare s'interfaccia con una memoria da cui riceve una sequenza di K _parole_. L'elaborazione della sequenza consiste nello scrivere in memoria accanto a ogni _parola_ il valore di credibilità corrispondente: il conto del numero di occorrenze consecutive della stessa _parola_ all'interno della sequenza, a partire da 31 fino a 0 (arrivati a 0 si continua a scrivere 0).
  
![interfaccia generale di specifica](./images/General_Schematic)

Nel completo le specifiche sono descritte [qui](./specifications/PFRL_Specifica_23_24_V_22_12_2023.pdf)

## Descrizione del componente

![componente completo](./images/Project_Schematic)

Il componente progettato è divisibile in 4 sezioni:

- un contatore per la credibilità;
- un contatore per tenere traccia dell'indice di sequenza;
- un contatore per tenere traccia dell'indirizzo;
- un modulo per la gestione delle _parole_.

Queste quattro sezioni funzionano tutte in parallelo con dei segnali di controllo intermodulo che permettono la corretta scrittura e lettura dei registri.

La descrizione delle componenti è riportata nella sezione [architettura del modello](./docs/Project_Report_10807746.pdf) della documentazione.

### Il codice

Il codice è stato richiesto in un unico file. Quindi i codici che descrivono i vari componenti sono tutti inclusi nel file presente in _src_.

> Il codice è suddiviso tramite dei commenti nei vari moduli, per maggiore chiarezza.
