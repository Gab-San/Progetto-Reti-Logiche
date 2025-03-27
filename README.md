# Progetto di Reti Logiche

> For the english version refer to [Digital Design Logic Project]()

Il progetto di reti logiche è il secondo dei tre progetti obbligatori richiesti al Polimi nel corso di Laura Triennale in Ingegneria Informatica.

Tale progetto consiste nel modellare un circuito in un linguaggio di descrizione dell'hardware che rispetti il funzionamento richiesto.
Poiché è stato scelto VHDL come linguaggio di descrizione, il livello di modellazione è stato lasciato decidere al progettista tra comportamentale e register-transfer.

## Specifiche di progetto

Il componente da progettare s'interfaccia con una memoria da cui riceve una sequenza di K _parole_. L'elaborazione della sequenza consiste nello scrivere in memoria accanto a ogni _parola_ il valore di credibilità corrispondente: il conto del numero di occorrenze consecutive dello stesso valore all'interno della sequenza a partire da 31 fino a 0 (arrivati a 0 si continua a scrivere 0).

Nel completo le specifiche sono descritte [qui](./specifications/PFRL_Specifica_23_24_V_22_12_2023.pdf)
